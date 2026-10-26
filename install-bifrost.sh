#!/bin/bash
# Bifrost Service Installation Script with --system support
set -euo pipefail

# ---------------------------------------------------------------------------
# Default configuration
# ---------------------------------------------------------------------------
PREFIX="/usr/local"
ServerName="bifrost-http"
ServiceUser="bifrost"
ServiceGroup="bifrost"
SystemDeployment=false
BinaryDir="${PREFIX}/bin"
BinaryPath="${BinaryDir}/bifrost-http"
BinaryCliPath="${BinaryDir}/bifrost"
WorkingDir="${HOME}/.config/bifrost"
AppDir="${WorkingDir}"
LogPath="/home/sheldon/.local/state/bifrost/bifrost.log"
EnvFile="${WorkingDir}/service.env"
RestartMode="always"
RestartSeconds="10s"
TemplateDir="/resources/inference-serving/localai-services/bifrost"

BASE_URL="https://downloads.getmaxim.ai"
BifrostVersion="latest"
BifrostHttpVersion="v2.3.2"

# Platform detection
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "${ARCH}" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
esac

case "${OS}" in
  linux) PlatformDir="linux" ;;
  darwin) PlatformDir="darwin" ;;
  mingw*|msys*|cygwin*|windows) PlatformDir="windows" ;;
esac

# Binary names based on platform
if [ "${PlatformDir}" = "windows" ]; then
  BifrostBinaryName="bifrost.exe"
  BifrostHttpBinaryName="bifrost-http.exe"
else
  BifrostBinaryName="bifrost"
  BifrostHttpBinaryName="bifrost-http"
fi

# ---------------------------------------------------------------------------
# Parse command line arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
      BinaryDir="${PREFIX}/bin"
      BinaryPath="${BinaryDir}/bifrost-http"
      BinaryCliPath="${BinaryDir}/bifrost"
      WorkingDir="${HOME}/.config/bifrost"
      AppDir="${WorkingDir}"
      LogPath="/home/sheldon/.local/state/bifrost/bifrost.log"
      EnvFile="${WorkingDir}/service.env"
      shift 2
      ;;
    --system)
      SystemDeployment=true
      shift
      ;;
    --bifrost-binary)
      BinaryPath="$2"
      shift 2
      ;;
    --bifrost-cli-binary)
      BinaryCliPath="$2"
      shift 2
      ;;
    --bifrost-args)
      BifrostArgs="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Adjust paths for system deployment
# ---------------------------------------------------------------------------
if [ "${SystemDeployment}" = true ] || [ "$(id -u)" -eq 0 ] || [ -n "${SUDO_USER:-}" ]; then
  SystemDeployment=true
  PREFIX="/usr/local"
  BinaryDir="${PREFIX}/bin"
  BinaryPath="${BinaryDir}/bifrost-http"
  BinaryCliPath="${BinaryDir}/bifrost"
  AppDir="/var/lib/bifrost"
  WorkingDir="${AppDir}"
  LogPath="/var/lib/bifrost/bifrost.log"
  EnvFile="${AppDir}/service.env"
fi

# ---------------------------------------------------------------------------
# Detect database paths based on user context
# ---------------------------------------------------------------------------
if [ "${SystemDeployment}" = true ]; then
  ConfigStorePath="${AppDir}/config.db"
  LogsStorePath="${AppDir}/logs.db"
else
  ConfigStorePath="config.db"
  LogsStorePath="logs.db"
fi

# ---------------------------------------------------------------------------
# Detect bifrost version from latest-release endpoint
# ---------------------------------------------------------------------------
echo "Detecting latest bifrost release version..."
if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  DetectedVersion=$(curl -fsSL "https://getbifrost.ai/latest-release" 2>/dev/null | jq -r '.name // "latest"' 2>/dev/null) || DetectedVersion="latest"
  if [ -n "${DetectedVersion}" ] && [ "${DetectedVersion}" != "null" ]; then
    BifrostVersion="${DetectedVersion}"
    BifrostHttpVersion="${DetectedVersion}"
  fi
else
  BifrostVersion="latest"
  BifrostHttpVersion="latest"
fi
echo "Using bifrost version: ${BifrostVersion}"
echo "Using bifrost-http version: ${BifrostHttpVersion}"

# ---------------------------------------------------------------------------
# Download and install binaries
# ---------------------------------------------------------------------------
echo "Downloading bifrost binaries..."

# Create installation directories
mkdir -p "${BinaryDir}"
mkdir -p "${AppDir}"
mkdir -p "$(dirname "${LogPath}")"

# Download bifrost CLI
BifrostUrl="${BASE_URL}/bifrost-cli/${BifrostVersion}/${PlatformDir}/${ARCH}/${BifrostBinaryName}"
echo "Downloading bifrost CLI from ${BifrostUrl}..."
if [ ! -x "${BinaryCliPath}" ]; then
  if ! curl -fsSL -o "${BinaryCliPath}" "${BifrostUrl}"; then
    echo "Warning: Failed to download bifrost CLI from ${BifrostUrl}, trying 'latest' version..."
    BifrostVersion="latest"
    BifrostUrl="${BASE_URL}/bifrost-cli/${BifrostVersion}/${PlatformDir}/${ARCH}/${BifrostBinaryName}"
    if ! curl -fsSL -o "${BinaryCliPath}" "${BifrostUrl}"; then
      echo "Error: Failed to download bifrost CLI from ${BifrostUrl}"
      exit 1
    fi
  fi
fi
chmod +x "${BinaryCliPath}"
echo "Installed bifrost CLI to ${BinaryCliPath}"

# Download bifrost-http
BifrostHttpUrl="${BASE_URL}/bifrost/${BifrostHttpVersion}/${PlatformDir}/${ARCH}/${BifrostHttpBinaryName}"
echo "Downloading bifrost-http from ${BifrostHttpUrl}..."
if [ ! -x "${BinaryPath}" ]; then
  if ! curl -fsSL -o "${BinaryPath}" "${BifrostHttpUrl}"; then
    echo "Warning: Failed to download bifrost-http from ${BifrostHttpUrl}, trying 'latest' version..."
    BifrostHttpVersion="latest"
    BifrostHttpUrl="${BASE_URL}/bifrost/${BifrostHttpVersion}/${PlatformDir}/${ARCH}/${BifrostHttpBinaryName}"
    if ! curl -fsSL -o "${BinaryPath}" "${BifrostHttpUrl}"; then
      echo "Error: Failed to download bifrost-http from ${BifrostHttpUrl}"
      exit 1
    fi
  fi
fi
chmod +x "${BinaryPath}"
echo "Installed bifrost-http to ${BinaryPath}"

# ---------------------------------------------------------------------------
# Generate setup token
# ---------------------------------------------------------------------------
echo "Generating BIFROST_SETUP_TOKEN..."
if command -v openssl >/dev/null 2>&1; then
  BIFROST_SETUP_TOKEN=$(openssl rand -hex 32)
else
  BIFROST_SETUP_TOKEN=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-z0-9' | head -c 32)
fi
export BIFROST_SETUP_TOKEN
echo "BIFROST_SETUP_TOKEN generated (length: ${#BIFROST_SETUP_TOKEN})"

# ---------------------------------------------------------------------------
# Create service environment file (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating service environment file at ${EnvFile}..."

if [ -f "${EnvFile}" ]; then
  echo "  Service environment file already exists, preserving existing config."
else
  # Determine BIFROST_APP_DIR: check if config.db exists in AppDir
  if [ -f "${AppDir}/config.db" ]; then
    BIFROST_APP_DIR="${AppDir}"
  else
    BIFROST_APP_DIR="/tmp/bifrost-app"
    mkdir -p "${BIFROST_APP_DIR}"
  fi

  cat > "${EnvFile}" << EOF
# Environment variables for ${ServerName}
# These are sourced by the systemd service ExecStart

BIFROST_HOST=localhost
BIFROST_PORT=8080
BIFROST_SETUP_TOKEN=${BIFROST_SETUP_TOKEN}
BIFROST_ADMIN_USERNAME="bifrost"
BIFROST_ADMIN_PASSWORD="ChangeMe"
BIFROST_APP_DIR=${BIFROST_APP_DIR}
LLAMA_ARG_HOST=127.0.0.1
LLAMA_ARG_PORT=9931
LOG_LEVEL=info
BINARY_PATH=${BinaryPath}
HTTP_BINARY_PATH=${BinaryPath}
WORKING_DIR=${WorkingDir}
LOG_PATH=${LogPath}
APP_DIR=${AppDir}
CONFIG_STORE_PATH=${ConfigStorePath}
LOGS_STORE_PATH=${LogsStorePath}
GOVERNANCE_ADMIN_USERNAME="bifrost"
GOVERNANCE_ADMIN_PASSWORD="ChangeMe"
GOVERNANCE_CHANGE_ON_LOGON=true
EOF
fi

chmod 644 "${EnvFile}"

# ---------------------------------------------------------------------------
# Build ExecStart command
# ---------------------------------------------------------------------------
# Build extra args string if provided
BifrostArgsStr="${BifrostArgs:-}"

ExecStartCmd="bash -c 'source ${EnvFile}; ${BinaryPath} -port \${BIFROST_PORT:-8080}'"

if [ "${SystemDeployment}" = true ]; then
  ExecStartCmd="bash -c 'source ${EnvFile}; ${BinaryPath} -port \${BIFROST_PORT:-8080} --app-dir ${AppDir}'"
fi

# ---------------------------------------------------------------------------
# Create systemd service (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating systemd service..."

SERVICE_FILE="/etc/systemd/system/${ServerName}.service"

if [ ! -f "${ServiceFile}" ] && [ -f "${TemplateDir}/service.template" ]; then
  cp "${TemplateDir}/service.template" "${ServiceFile}.tmp"

  # Build sed replacements
  sed_cmd="s|__SERVICE_NAME__|${ServerName}|g"
  sed_cmd="${sed_cmd}; s|__WORKING_DIR__|${WorkingDir}|g"
  sed_cmd="${sed_cmd}; s|__LOG_PATH__|${LogPath}|g"
  sed_cmd="${sed_cmd}; s|__ENV_FILE__|${EnvFile}|g"

  if [ "${SystemDeployment}" = true ]; then
    sed_cmd="${sed_cmd}; s|USER=__SERVICE_USER__|User=${ServiceUser}|g"
    sed_cmd="${sed_cmd}; s|GROUP=__SERVICE_GROUP__|Group=${ServiceGroup}|g"
    sed_cmd="${sed_cmd}; s|__RESTART_MODE__|${RestartMode}|g"
    sed_cmd="${sed_cmd}; s|__RESTART_SECONDS__|${RestartSeconds}|g"
    sed_cmd="${sed_cmd}; s|ExecStart=__BINARY_PATH__ __ARGS__|ExecStart=${ExecStartCmd}|g"
  else
    sed_cmd="${sed_cmd}; /USER=__SERVICE_USER__/d"
    sed_cmd="${sed_cmd}; /GROUP=__SERVICE_GROUP__/d"
    sed_cmd="${sed_cmd}; s|__RESTART_MODE__|${RestartMode}|g"
    sed_cmd="${sed_cmd}; s|__RESTART_SECONDS__|${RestartSeconds}|g"
    sed_cmd="${sed_cmd}; s|ExecStart=__BINARY_PATH__ __ARGS__|ExecStart=${ExecStartCmd}|g"
    sed_cmd="${sed_cmd}; s|WantedBy=multi-user.target|WantedBy=default.target|g"
  fi

  sed -e "${sed_cmd}" "${ServiceFile}.tmp" > "${ServiceFile}"
  rm -f "${ServiceFile}.tmp"
else
  # Create basic service file from scratch (only if it doesn't exist)
  if [ "${SystemDeployment}" = true ]; then
    if [ ! -f "${ServiceFile}" ]; then
      sudo tee "${ServiceFile}" > /dev/null << EOF
[Unit]
Description=${ServerName}
After=network.target

[Service]
Type=simple
User=${ServiceUser}
Group=${ServiceGroup}
WorkingDirectory=${WorkingDir}
EnvironmentFile=${EnvFile}
ExecStart=${ExecStartCmd}
Restart=${RestartMode}
RestartSec=${RestartSeconds}
StandardOutput=journal
StandardError=journal
ReadWritePaths=${WorkingDir} ${LogPath}

[Install]
WantedBy=multi-user.target
EOF
    fi
  else
    if [ ! -f "${ServiceFile}" ]; then
      tee "${ServiceFile}" > /dev/null << EOF
[Unit]
Description=${ServerName}
After=network.target

[Service]
Type=simple
WorkingDirectory=${WorkingDir}
EnvironmentFile=${EnvFile}
ExecStart=${ExecStartCmd}
Restart=${RestartMode}
RestartSec=${RestartSeconds}
StandardOutput=journal
StandardError=journal
ReadWritePaths=${WorkingDir} ${LogPath}

[Install]
WantedBy=default.target
EOF
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Create logrotate configuration (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating logrotate configuration..."

LOGROTATE_FILE="/etc/logrotate.d/${ServerName}"

if [ "${SystemDeployment}" = true ]; then
  if [ ! -f "${LOGROTATE_FILE}" ]; then
    if [ -f "${TemplateDir}/logrotate.template" ]; then
      sudo cp "${TemplateDir}/logrotate.template" "${LOGROTATE_FILE}"
      sudo sed -i "s|__LOG_PATH__|${LogPath}|g" "${LOGROTATE_FILE}"
      sudo sed -i "s|__SERVICE_NAME__|${ServerName}|g" "${LOGROTATE_FILE}"
      sudo sed -i "s|__SERVICE_USER__|${ServiceUser}|g" "${LOGROTATE_FILE}"
      sudo sed -i "s|__SERVICE_GROUP__|${ServiceGroup}|g" "${LOGROTATE_FILE}"
    else
      sudo tee "${LOGROTATE_FILE}" > /dev/null << EOF
${LogPath} {
    daily
    rotate 7
    maxsize 100M
    missingok
    notifempty
    copytruncate
    compress
    delaycompress
    create 644 ${ServiceUser} ${ServiceGroup}
    postrotate
        systemctl restart ${ServerName} > /dev/null 2>&1 || true
    endscript
}
EOF
    fi
  else
    echo "  Logrotate config already exists, skipping."
  fi
else
  echo "  Skipping logrotate (requires root access to /etc/logrotate.d/)"
fi

# ---------------------------------------------------------------------------
# Create service account if needed
# ---------------------------------------------------------------------------
if [ "${SystemDeployment}" = true ]; then
  echo "Creating service account..."
  if ! id "${ServiceUser}" >/dev/null 2>&1; then
    sudo useradd -r -s /bin/false "${ServiceUser}" 2>/dev/null || true
  fi

  sudo mkdir -p "${AppDir}"
  sudo chown -R "${ServiceUser}:${ServiceGroup}" "${AppDir}" 2>/dev/null || true
  sudo chown "${ServiceUser}:${ServiceGroup}" "$(dirname "${LogPath}")" 2>/dev/null || true
  sudo touch "${LogPath}" 2>/dev/null || true
  sudo chown "${ServiceUser}:${ServiceGroup}" "${LogPath}" 2>/dev/null || true
  if [ -f "${EnvFile}" ]; then
    sudo chown "${ServiceUser}:${ServiceGroup}" "${EnvFile}" 2>/dev/null || true
  fi
else
  mkdir -p "${AppDir}"
  chown -R "${ServiceUser}:${ServiceGroup}" "${WorkingDir}" 2>/dev/null || true
  chown "${ServiceUser}:${ServiceGroup}" "$(dirname "${LogPath}")" 2>/dev/null || true
  touch "${LogPath}" 2>/dev/null || true
  chown "${ServiceUser}:${ServiceGroup}" "${LogPath}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Enable and start service
# ---------------------------------------------------------------------------
echo "Enabling and starting service..."

if [ "${SystemDeployment}" = true ]; then
  sudo systemctl --system daemon-reload
  sudo systemctl enable "${ServerName}.service"
  sudo systemctl start "${ServerName}.service"
else
  systemctl --user daemon-reload
  systemctl --user enable "${ServerName}.service"
  systemctl --user start "${ServerName}.service"
fi

# ---------------------------------------------------------------------------
# Wait for bifrost-http to be ready
# ---------------------------------------------------------------------------
echo "Waiting for bifrost-http to be ready on port ${BifrostPort}..."
BifrostPort="${BIFROST_PORT:-8080}"
for i in $(seq 1 30); do
  if curl -fsS "http://localhost:${BifrostPort}/api/config" >/dev/null 2>&1; then
    echo "bifrost-http is ready"
    break
  fi
  echo "Waiting... (${i}/30)"
  sleep 2
done

# ---------------------------------------------------------------------------
# Complete setup via PUT /api/config
# ---------------------------------------------------------------------------
SETUP_TOKEN="${BIFROST_SETUP_TOKEN}"
ADMIN_USERNAME="bifrost"
ADMIN_PASSWORD="ChangeMe"

echo "Completing bifrost setup via PUT /api/config..."

# Build the config payload
CONFIG_PAYLOAD=$(cat << EOF
{
  "\$schema": "https://www.getbifrost.ai/schema",
  "setup_token": "${SETUP_TOKEN}",
  "client": {
    "enforce_auth_on_inference": true,
    "log_retention_days": 365
  },
  "governance": {
    "auth_config": {
      "admin_username": "${ADMIN_USERNAME}",
      "admin_password": "${ADMIN_PASSWORD}",
      "is_enabled": true
    }
  }
}
EOF
)

# Send the setup request
if command -v curl >/dev/null 2>&1; then
  echo "Sending PUT /api/config with X-Bifrost-Setup-Token header..."

  SetupResponse=$(curl -s -w "\n%{http_code}" -X PUT "http://localhost:${BifrostPort}/api/config" \
    -H "X-Bifrost-Setup-Token: ${SETUP_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${CONFIG_PAYLOAD}" 2>/dev/null) || true

  SetupHttpCode=$(echo "${SetupResponse}" | tail -n1)
  SetupBody=$(echo "${SetupResponse}" | sed '$d')

  echo "Setup response HTTP code: ${SetupHttpCode}"
  echo "Setup response body: ${SetupBody}"

  if [ "${SetupHttpCode}" = "200" ] || [ "${SetupHttpCode}" = "201" ] || [ "${SetupHttpCode}" = "204" ]; then
    echo "Bifrost setup completed successfully!"
  else
    echo "Warning: Setup call returned HTTP ${SetupHttpCode}. You may need to complete setup manually."
  fi
else
  echo "curl not available. Manual setup required."
fi

# ---------------------------------------------------------------------------
# Register llama-server as a provider via API calls
# ---------------------------------------------------------------------------
echo "Registering llama-server as a provider in bifrost-http via API..."

BifrostUrl="http://localhost:${BifrostPort}"

# Generate virtual key value
VK_VALUE="sk-vk-llama-server-$(openssl rand -hex 16 2>/dev/null || head -c 16 /dev/urandom | base64 | tr -dc 'a-z0-9' | head -c 16)"

# Helper: make authenticated API call
api_call() {
  local method="$1"
  local endpoint="$2"
  local payload="$3"

  curl -s -w "\n%{http_code}" -X "${method}" "${BifrostUrl}${endpoint}" \
    -H "X-Bifrost-Setup-Token: ${SETUP_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${payload}" 2>/dev/null
}

# 1. Register llama-server provider
echo "  Registering provider: llama-server..."
ProviderPayload=$(cat << EOF
{
  "name": "llama-server",
  "type": "openai",
  "base_url": "http://127.0.0.1:9931/v1",
  "api_key": "",
  "status": "active",
  "description": "Llama.cpp server registered via install script"
}
EOF
)
api_call "POST" "/api/v1/providers" "${ProviderPayload}" || echo "  Warning: Provider registration API call failed"

# 2. Register API key for the provider
echo "  Registering API key..."
KeyPayload=$(cat << EOF
{
  "provider": "llama-server",
  "key_id": "llama-server-key",
  "name": "llama-server-key",
  "value": "sk-llama-server",
  "enabled": true
}
EOF
)
api_call "POST" "/api/v1/keys" "${KeyPayload}" || echo "  Warning: Key registration API call failed"

# 3. Discover and register models from llama-server
echo "  Discovering llama-server models..."
LlamaModels=$(curl -fsS "http://localhost:9931/v1/models" 2>/dev/null || echo "{}")

if command -v jq >/dev/null 2>&1; then
  ModelNames=$(echo "${LlamaModels}" | jq -r '.data[].id // empty' 2>/dev/null || echo "")
else
  ModelNames=$(echo "${LlamaModels}" | grep -o '"id": *"[^"]*"' | sed 's/"id": *//; s/"//g' 2>/dev/null || echo "")
fi

if [ -n "${ModelNames}" ]; then
  echo "  Discovered models:"
  echo "${ModelNames}" | while read -r ModelName; do
    [ -z "${ModelName}" ] && continue
    echo "    Registering model: ${ModelName}"
    ModelPayload=$(cat << EOF
{
  "provider": "llama-server",
  "model": "${ModelName}",
  "name": "${ModelName}"
}
EOF
)
    api_call "POST" "/api/v1/models" "${ModelPayload}" || echo "  Warning: Failed to register model ${ModelName}"
  done
else
  echo "  Warning: No models discovered from llama-server, skipping model registration"
fi

# 4. Create routing rule
echo "  Creating routing rule..."
RoutePayload=$(cat << EOF
{
  "id": "route-llama-server",
  "name": "Route to llama-server",
  "description": "Route all requests to llama-server provider",
  "enabled": true,
  "cel_expression": "true",
  "scope": "global",
  "priority": 100
}
EOF
)
api_call "POST" "/api/v1/routing-rules" "${RoutePayload}" || echo "  Warning: Routing rule creation API call failed"

# 5. Create routing target for each model
echo "  Creating routing targets..."
for ModelName in ${ModelNames}; do
  [ -z "${ModelName}" ] && continue
  TargetPayload=$(cat << EOF
{
  "rule_id": "route-llama-server",
  "provider": "llama-server",
  "model": "${ModelName}",
  "key_id": "llama-server-key",
  "weight": 1.0
}
EOF
)
    api_call "POST" "/api/v1/routing-targets" "${TargetPayload}" || echo "  Warning: Failed to create routing target for ${ModelName}"
done

# 6. Create virtual key
echo "  Creating virtual key..."
VkPayload=$(cat << EOF
{
  "id": "vk-llama-server",
  "name": "llama-server-key",
  "value": "${VK_VALUE}",
  "is_active": true,
  "allow_all_providers": true
}
EOF
)
api_call "POST" "/api/v1/governance/virtual-keys" "${VkPayload}" || echo "  Warning: Virtual key creation API call failed"

# 7. Create virtual key provider config with discovered models
echo "  Creating virtual key provider config..."
ModelsJson=$(echo "${ModelNames}" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
VkProviderPayload=$(cat << EOF
{
  "virtual_key_id": "vk-llama-server",
  "provider": "llama-server",
  "allowed_models": ${ModelsJson},
  "blacklisted_models": [],
  "allow_all_keys": true,
  "weight": 1.0
}
EOF
)
api_call "POST" "/api/v1/governance/virtual-key-provider-configs" "${VkProviderPayload}" || echo "  Warning: Virtual key provider config API call failed"

echo "llama-server provider registration attempted via bifrost-http API"
echo "  Virtual key: ${VK_VALUE}"
echo "  Provider: llama-server (http://127.0.0.1:${LlamaPort}/v1)"
echo "  Models: ${ModelNames} discovered and registered"

# ---------------------------------------------------------------------------
# Final status
# ---------------------------------------------------------------------------
echo ""
echo "Bifrost service installation complete!"
echo ""
echo "Installation summary:"
echo "  Binary:          ${BinaryPath}"
echo "  CLI Binary:      ${BinaryCliPath}"
echo "  Working Dir:     ${WorkingDir}"
echo "  App Dir:         ${AppDir}"
echo "  Config Store:    ${ConfigStorePath}"
echo "  Logs Store:      ${LogsStorePath}"
echo "  Log Path:        ${LogPath}"
echo "  Env File:        ${EnvFile}"
echo "  Service File:    ${SERVICE_FILE}"
echo "  Setup Token:     ${BIFROST_SETUP_TOKEN}"
echo "  Admin User:      bifrost"
echo "  Admin Password:  ChangeMe"
echo ""
echo "To complete setup manually (if not done above):"
echo "  curl -X PUT http://localhost:${BifrostPort}/api/config \\"
echo "    -H \"X-Bifrost-Setup-Token: ${BIFROST_SETUP_TOKEN}\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"\$schema\": \"https://www.getbifrost.ai/schema\", \"setup_token\": \"${BIFROST_SETUP_TOKEN}\", \"client\": {\"enforce_auth_on_inference\": true}, \"governance\": {\"auth_config\": {\"admin_username\": \"bifrost\", \"admin_password\": \"ChangeMe\", \"is_enabled\": true}}}'"
echo ""
if command -v systemctl >/dev/null 2>&1; then
  echo "Service status:"
  if [ "${SystemDeployment}" = true ]; then
    sudo systemctl status "${ServerName}" --no-pager 2>/dev/null || echo "Could not retrieve service status"
  else
    systemctl --user status "${ServerName}" --no-pager 2>/dev/null || echo "Could not retrieve service status"
  fi
fi

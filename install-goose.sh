#!/bin/bash
# Goose Service Installation Script with --system support
# Installs goose as ACP server, configures providers (bifrost, llama-server) and MCP servers (bifrost Gateway)
set -euo pipefail

# ---------------------------------------------------------------------------
# Default configuration
# ---------------------------------------------------------------------------
ServerName="goose"
ServiceUser="goose"
ServiceGroup="goose"
WorkingDir="${HOME}/.local/share/goose"
ConfigDir="${HOME}/.config/goose"
ConfigFile="${ConfigDir}/config.yaml"
LogPath="${HOME}/.local/state/goose/goose.log"
SystemDeployment=false
SYSTEM_DEPLOYMENT=false

# Service ports
GoosePort="3284"
BifrostPort="8080"
LlamaPort="9931"

# Service restart settings
RestartMode="always"
RestartSeconds="10s"

# ---------------------------------------------------------------------------
# Parse command line arguments
# ---------------------------------------------------------------------------
usage() {
  echo "Usage: $0 [--system] [--goose-binary <path>] [--goose-args <args>] [--help]"
  echo ""
  echo "  --system         System-wide deployment (default: user deployment)"
  echo "  --goose-binary   Path to existing goose binary (skip download)"
  echo "  --goose-args     Extra arguments to pass to goose serve"
  echo "  --help           Show this help message"
  echo ""
  echo "Ports:"
  echo "  goose:        3284"
  echo "  bifrost-http: 8080"
  echo "  llama-server: 9931"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system)
      SystemDeployment=true
      shift
      ;;
    --goose-binary)
      BinaryPath="$2"
      shift 2
      ;;
    --goose-args)
      GooseArgs="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
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
  SYSTEM_DEPLOYMENT=true
  WorkingDir="/srv/goose/.local/share/goose"
  ConfigDir="/srv/goose/.config/goose"
  ConfigFile="${ConfigDir}/config.yaml"
  LogPath="/var/log/goose/goose.log"
fi

# Use sudo only when not already running as root (containers often lack sudo)
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "Goose installation mode: $( [ "${SYSTEM_DEPLOYMENT}" = true ] && echo system || echo user )"
echo "Config file: ${ConfigFile}"
echo "Working dir: ${WorkingDir}"

# ---------------------------------------------------------------------------
# Detect and install goose binary
# ---------------------------------------------------------------------------
echo "Detecting goose binary..."

GOOSE_BINARY=""

# Check for existing goose binary
if command -v goose >/dev/null 2>&1; then
  GOOSE_BINARY="$(command -v goose)"
  echo "Found goose in PATH: ${GOOSE_BINARY}"
elif [ -x "${HOME}/.local/bin/goose" ]; then
  GOOSE_BINARY="${HOME}/.local/bin/goose"
  echo "Found goose at ${HOME}/.local/bin/goose"
elif [ -x "/usr/local/bin/goose" ]; then
  GOOSE_BINARY="/usr/local/bin/goose"
  echo "Found goose at /usr/local/bin/goose"
fi

# If not found, download from GitHub releases
if [ -z "${GOOSE_BINARY}" ]; then
  echo "Goose binary not found. Downloading from GitHub releases..."

  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)

  case "${ARCH}" in
    x86_64|amd64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
  esac

  case "${OS}" in
    linux) Platform="linux" ;;
    darwin) Platform="darwin" ;;
    *) echo "Unsupported OS: ${OS}" >&2; exit 1 ;;
  esac

  # Map platform/arch to the release target triple
  case "${Platform}/${ARCH}" in
    linux/x86_64)   Target="x86_64-unknown-linux-gnu" ;;
    linux/aarch64)  Target="aarch64-unknown-linux-gnu" ;;
    darwin/aarch64) Target="aarch64-apple-darwin" ;;
    darwin/x86_64)  Target="x86_64-apple-darwin" ;;
    *) echo "Error: Unsupported platform/arch: ${Platform}/${ARCH}" >&2; exit 1 ;;
  esac

  # Resolve the latest release tag from the GitHub API (no 'stable' tag exists)
  GOOSE_REPO="aaif-goose/goose"
  LatestJson=$(curl -fsSL "https://api.github.com/repos/${GOOSE_REPO}/releases/latest" 2>/dev/null) || LatestJson=""
  if command -v jq >/dev/null 2>&1; then
    GOOSE_TAG=$(echo "${LatestJson}" | jq -r '.tag_name // ""' 2>/dev/null) || GOOSE_TAG=""
  else
    GOOSE_TAG=$(echo "${LatestJson}" | grep -m1 '"tag_name"' | sed 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/') || GOOSE_TAG=""
  fi
  if [ -z "${GOOSE_TAG}" ]; then
    echo "Warning: Could not detect latest goose release, falling back to pinned version v1.61.1"
    GOOSE_TAG="v1.61.1"
  fi

  GOOSE_URL="https://github.com/${GOOSE_REPO}/releases/download/${GOOSE_TAG}/goose-${Target}.tar.gz"
  TMP_DL_DIR=$(mktemp -d)
  trap 'rm -rf "${TMP_DL_DIR}"' EXIT

  echo "Downloading goose from ${GOOSE_URL}..."
  if ! curl -fsSL -o "${TMP_DL_DIR}/goose.tar.gz" "${GOOSE_URL}"; then
    echo "Error: Failed to download goose from ${GOOSE_URL}" >&2
    exit 1
  fi
  tar -xzf "${TMP_DL_DIR}/goose.tar.gz" -C "${TMP_DL_DIR}"
  if [ ! -f "${TMP_DL_DIR}/goose" ]; then
    FoundBinary=$(find "${TMP_DL_DIR}" -type f -name goose | head -n1)
    if [ -z "${FoundBinary}" ]; then
      echo "Error: 'goose' binary not found inside downloaded archive" >&2
      exit 1
    fi
    mv "${FoundBinary}" "${TMP_DL_DIR}/goose"
  fi
  chmod +x "${TMP_DL_DIR}/goose"
  GOOSE_BINARY="${TMP_DL_DIR}/goose"
fi

# Verify binary
if [ ! -x "${GOOSE_BINARY}" ]; then
  echo "Error: Goose binary not executable at ${GOOSE_BINARY}" >&2
  exit 1
fi

echo "Goose binary: ${GOOSE_BINARY}"

# ---------------------------------------------------------------------------
# Install binary
# ---------------------------------------------------------------------------
echo "Installing goose binary..."

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  InstallDir="/usr/local/bin"
  BinaryPath="${InstallDir}/goose"
  echo "Installing goose (superuser) to ${BinaryPath}..."
  if [ ! -x "${BinaryPath}" ]; then
    ${SUDO} mkdir -p "${InstallDir}"
    ${SUDO} cp "${GOOSE_BINARY}" "${BinaryPath}"
    ${SUDO} chmod +x "${BinaryPath}"
  else
    echo "  Binary already exists at ${BinaryPath}, keeping existing."
  fi
else
  InstallDir="${HOME}/.local/bin"
  BinaryPath="${InstallDir}/goose"
  echo "Installing goose (user) to ${BinaryPath}..."
  if [ ! -x "${BinaryPath}" ]; then
    mkdir -p "${InstallDir}"
    cp "${GOOSE_BINARY}" "${BinaryPath}"
    chmod +x "${BinaryPath}"
  else
    echo "  Binary already exists at ${BinaryPath}, keeping existing."
  fi
fi

if [ ! -x "${BinaryPath}" ]; then
  echo "Error: Goose not installed at ${BinaryPath}" >&2
  exit 1
fi

echo "Goose binary found at ${BinaryPath}"

# ---------------------------------------------------------------------------
# Create directories
# ---------------------------------------------------------------------------
mkdir -p "${WorkingDir}"
mkdir -p "${ConfigDir}"
mkdir -p "$(dirname "${LogPath}")"

# ---------------------------------------------------------------------------
# Discover bifrost virtual key and llama-server model dynamically
# ---------------------------------------------------------------------------

# Load BIFROST_SETUP_TOKEN from the bifrost service env file if not in
# the environment (mirrors install-goose.ps1 behavior)
if [ -z "${BIFROST_SETUP_TOKEN:-}" ]; then
  for BifrostEnvCandidate in /var/lib/bifrost/service.env "${HOME}/.config/bifrost/service.env"; do
    if [ -f "${BifrostEnvCandidate}" ]; then
      BIFROST_SETUP_TOKEN="$(grep -E '^BIFROST_SETUP_TOKEN=' "${BifrostEnvCandidate}" | tail -n1 | cut -d= -f2- || true)"
      if [ -n "${BIFROST_SETUP_TOKEN}" ]; then
        echo "Loaded BIFROST_SETUP_TOKEN from ${BifrostEnvCandidate}"
        break
      fi
    fi
  done
fi

# Discover BIFROST_VK from bifrost-http governance API
BIFROST_VK=""
BifrostBaseUrl="http://127.0.0.1:${BifrostPort}"
if command -v curl >/dev/null 2>&1; then
  echo "Discovering bifrost virtual key from ${BifrostBaseUrl}..."
  VKResponse=$(curl -s "${BifrostBaseUrl}/api/v1/governance/virtual-keys" \
    -H "X-Bifrost-Setup-Token: ${BIFROST_SETUP_TOKEN:-}" 2>/dev/null) || true

  if [ -n "${VKResponse}" ]; then
    # Extract the first virtual key value
    BIFROST_VK=$(echo "${VKResponse}" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    keys = data.get('keys', data if isinstance(data, list) else [])
    if keys:
        print(keys[0].get('value', ''))
except:
    pass
" 2>/dev/null) || true
  fi
fi

# If not discovered from API, generate one (will be registered by bifrost install)
if [ -z "${BIFROST_VK}" ]; then
  echo "Warning: Could not discover BIFROST_VK from bifrost-http API"
  echo "  Ensure bifrost-http is running and setup is complete"
  BIFROST_VK="CHANGE_ME"
fi

echo "BIFROST_VK: ${BIFROST_VK}"

# Discover llama-server model from /v1/models endpoint
LlamaModel="ggml-org/gemma-4-E2B-it-GGUF:Q4_0"
LlamaBaseUrl="http://127.0.0.1:${LlamaPort}"

if command -v curl >/dev/null 2>&1; then
  echo "Discovering llama-server model from ${LlamaBaseUrl}/v1/models..."
  ModelsResponse=$(curl -s "${LlamaBaseUrl}/v1/models" 2>/dev/null) || true

  if [ -n "${ModelsResponse}" ]; then
    DiscoveredModel=$(echo "${ModelsResponse}" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = data.get('data', [])
    if models:
        print(models[0].get('id', ''))
except:
    pass
" 2>/dev/null) || true

    if [ -n "${DiscoveredModel}" ]; then
      LlamaModel="${DiscoveredModel}"
    fi
  fi
fi

echo "Llama model: ${LlamaModel:-NOT_FOUND}"

# ---------------------------------------------------------------------------
# Create service environment file (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating service environment file at ${ConfigDir}/goose.env..."

EnvFile="${ConfigDir}/goose.env"

if [ -f "${EnvFile}" ]; then
  echo "  Service environment file already exists, preserving existing config."
else
  cat > "${EnvFile}" << EOF
# Environment variables for ${ServerName}
# Sourced by the systemd service ExecStart

GOOSE_PORT=${GoosePort}
GOOSE_HOST=127.0.0.1
GOOSE_WORKING_DIR=${WorkingDir}
GOOSE_LOG_PATH=${LogPath}
BIFROST_HOST=127.0.0.1
BIFROST_PORT=${BifrostPort}
BIFROST_VK=${BIFROST_VK}
LLAMA_ARG_HOST=127.0.0.1
LLAMA_ARG_PORT=${LlamaPort}
LOG_LEVEL=info
EOF
fi

chmod 600 "${EnvFile}"

# ---------------------------------------------------------------------------
# Create goose configuration YAML (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating goose configuration at ${ConfigFile}..."

if [ -f "${ConfigFile}" ]; then
  echo "  Service config file already exists, preserving existing config."
else
  # Build the new config
  cat > "${ConfigFile}" << YAMLEOF
# Goose Configuration
# Generated by install-goose.sh

GOOSE_TELEMETRY_ENABLED: false
GOOSE_PORT: ${GoosePort}
GOOSE_HOST: 127.0.0.1

# Provider: bifrost (AI Gateway)
providers:
  bifrost:
    enabled: true
    model: default
    base_url: http://127.0.0.1:${BifrostPort}/v1
    api_key: "${BIFROST_VK}"
    configured: true

# Provider: llama-server (local inference)
  llama-server:
    enabled: true
    model: ${LlamaModel}
    base_url: http://127.0.0.1:${LlamaPort}/v1
    api_key: ""
    configured: true

active_provider: bifrost

# MCP Server: bifrost (Gateway mode - connects to bifrost-http MCP Gateway endpoint)
extensions:
  bifrost-mcp:
    enabled: true
    type: http
    name: Bifrost MCP Gateway
    description: Bifrost AI Gateway as MCP server (Gateway mode)
    url: http://127.0.0.1:${BifrostPort}/mcp
    headers:
      x-bf-vk: "${BIFROST_VK}"
    timeout: 300
    bundled: null

OPENAI_BASE_URL: http://127.0.0.1:${BifrostPort}/v1
OPENAI_HOST: http://127.0.0.1:${BifrostPort}
OPENAI_TIMEOUT: '600'
OPENAI_BASE_PATH: v1/chat/completions
LLAMA_HOST: http://127.0.0.1:${LlamaPort}
GOOSE_THINKING_EFFORT: max
GOOSE_AUTO_COMPACT_TOKEN_LIMIT: 800000
YAMLEOF
fi

chmod 600 "${ConfigFile}"

echo "Goose configuration written to ${ConfigFile}"

# ---------------------------------------------------------------------------
# Create systemd service file (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating systemd service..."

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  ServiceFile="/etc/systemd/system/${ServerName}.service"
  echo "Installing system service"
else
  ServiceFile="${HOME}/.config/systemd/user/${ServerName}.service"
  echo "Installing user service"
fi

echo "Creating service file at ${ServiceFile}"
mkdir -p "$(dirname "${ServiceFile}")"

# Build ExecStart command
# Goose serve runs ACP server over HTTP and WebSocket
# Note: systemd expands ${VAR} from the unit's environment (EnvironmentFile
# provides GOOSE_HOST/GOOSE_PORT); shell-style ${VAR:-default} is not supported.
ExecStartCmd="bash -c 'source ${EnvFile}; exec ${BinaryPath} serve --dangerously-unauthenticated --host \${GOOSE_HOST} --port \${GOOSE_PORT}${GooseArgs:+ ${GooseArgs}}'"

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  if [ ! -f "${ServiceFile}" ]; then
    ${SUDO} tee "${ServiceFile}" > /dev/null << EOF
[Unit]
Description=${ServerName} ACP Server
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
ReadWritePaths=${WorkingDir} ${LogPath} ${ConfigDir}

[Install]
WantedBy=multi-user.target
EOF
  fi
else
  if [ ! -f "${ServiceFile}" ]; then
    tee "${ServiceFile}" > /dev/null << EOF
[Unit]
Description=${ServerName} ACP Server
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
ReadWritePaths=${WorkingDir} ${LogPath} ${ConfigDir}

[Install]
WantedBy=default.target
EOF
  fi
fi

# ---------------------------------------------------------------------------
# Create logrotate configuration (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating logrotate configuration..."

LOGROTATE_FILE="/etc/logrotate.d/${ServerName}"

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  if [ ! -f "${LOGROTATE_FILE}" ]; then
    ${SUDO} tee "${LOGROTATE_FILE}" > /dev/null << EOF
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
  else
    echo "  Logrotate config already exists, skipping."
  fi
else
  echo "  Skipping logrotate (requires root access to /etc/logrotate.d/)"
fi

# ---------------------------------------------------------------------------
# Create service account if needed
# ---------------------------------------------------------------------------
if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  echo "Creating system user ${ServiceUser} and setting ownership..."
  if ! id "${ServiceUser}" >/dev/null 2>&1; then
    ${SUDO} useradd -r -s /bin/false -m -d /srv/goose "${ServiceUser}" 2>/dev/null || true
  fi

  ${SUDO} mkdir -p "${WorkingDir}"
  ${SUDO} chown -R "${ServiceUser}:${ServiceGroup}" "${WorkingDir}" 2>/dev/null || true
  ${SUDO} mkdir -p "${ConfigDir}"
  ${SUDO} chown -R "${ServiceUser}:${ServiceGroup}" "${ConfigDir}" 2>/dev/null || true
  GooseHome="$(getent passwd "${ServiceUser}" 2>/dev/null | cut -d: -f6 || true)"
  if [ -n "${GooseHome}" ]; then
    ${SUDO} chown "${ServiceUser}:${ServiceGroup}" "${GooseHome}" 2>/dev/null || true
  fi
  ${SUDO} chown "${ServiceUser}:${ServiceGroup}" "$(dirname "${LogPath}")" 2>/dev/null || true
  ${SUDO} touch "${LogPath}" 2>/dev/null || true
  ${SUDO} chown "${ServiceUser}:${ServiceGroup}" "${LogPath}" 2>/dev/null || true
else
  if [ "$(id -u)" -eq 0 ] || [ -n "${SUDO_USER:-}" ]; then
    echo "Creating system user ${ServiceUser} (running with privileges)"
    if ! id "${ServiceUser}" >/dev/null 2>&1; then
      ${SUDO} useradd -r -s /bin/false -m -d /srv/goose "${ServiceUser}" 2>/dev/null || true
    fi

    mkdir -p "${WorkingDir}"
    chown -R "${ServiceUser}:${ServiceGroup}" "${WorkingDir}" 2>/dev/null || true
    mkdir -p "${ConfigDir}"
    chown -R "${ServiceUser}:${ServiceGroup}" "${ConfigDir}" 2>/dev/null || true
    GooseHome="$(getent passwd "${ServiceUser}" 2>/dev/null | cut -d: -f6 || true)"
    if [ -n "${GooseHome}" ]; then
      chown "${ServiceUser}:${ServiceGroup}" "${GooseHome}" 2>/dev/null || true
    fi
    chown "${ServiceUser}:${ServiceGroup}" "$(dirname "${LogPath}")" 2>/dev/null || true
    touch "${LogPath}" 2>/dev/null || true
    chown "${ServiceUser}:${ServiceGroup}" "${LogPath}" 2>/dev/null || true
  else
    echo "Running as user: $(whoami). Service will run as current user via systemd user service."
    echo "To run as a dedicated 'goose' user, re-run with --system or as root."
    mkdir -p "${ConfigDir}"
    chown -R "$(whoami):$(id -gn)" "${ConfigDir}" 2>/dev/null || true
    chown "$(whoami):$(id -gn)" "$(dirname "${LogPath}")" 2>/dev/null || true
    touch "${LogPath}" 2>/dev/null || true
    chown "$(whoami):$(id -gn)" "${LogPath}" 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------------------------
# Enable and start service
# ---------------------------------------------------------------------------
echo "Enabling and starting service..."

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  ${SUDO} systemctl --system daemon-reload
  ${SUDO} systemctl enable "${ServerName}.service"
  ${SUDO} systemctl start "${ServerName}.service"
else
  systemctl --user daemon-reload
  systemctl --user enable "${ServerName}.service"
  systemctl --user start "${ServerName}.service"
fi

# ---------------------------------------------------------------------------
# Wait for goose to be ready
# ---------------------------------------------------------------------------
echo "Waiting for goose ACP server to be ready on port ${GoosePort}..."
for i in $(seq 1 30); do
  if curl -fsS "http://localhost:${GoosePort}/" >/dev/null 2>&1; then
    echo "goose ACP server is ready"
    break
  fi
  echo "Waiting... (${i}/30)"
  sleep 2
done

# ---------------------------------------------------------------------------
# Final status
# ---------------------------------------------------------------------------
echo ""
echo "Goose service installation complete!"
echo ""
echo "Installation summary:"
echo "  Binary:       ${BinaryPath}"
echo "  Working Dir:  ${WorkingDir}"
echo "  Config Dir:   ${ConfigDir}"
echo "  Config File:  ${ConfigFile}"
echo "  Env File:     ${EnvFile}"
echo "  Log Path:     ${LogPath}"
echo "  Service File: ${ServiceFile}"
echo "  Service User: ${ServiceUser}"
echo "  Service Group: ${ServiceGroup}"
echo "  Goose Port:   ${GoosePort}"
echo "  Bifrost Port: ${BifrostPort}"
echo "  Llama Port:   ${LlamaPort}"
echo "  BIFROST_VK:   ${BIFROST_VK}"
echo "  Llama Model:  ${LlamaModel}"
echo ""
echo "Providers configured:"
echo "  - bifrost (AI Gateway): http://127.0.0.1:${BifrostPort}/v1"
echo "  - llama-server: http://127.0.0.1:${LlamaPort}/v1 (model: ${LlamaModel})"
echo ""
echo "MCP servers configured:"
echo "  - bifrost-mcp: http://127.0.0.1:${BifrostPort}/mcp (Gateway mode)"
echo ""
echo "To start manually:"
echo "  ${BinaryPath} serve --dangerously-unauthenticated --host 127.0.0.1 --port ${GoosePort}"
echo ""
if command -v systemctl >/dev/null 2>&1; then
  echo "Service status:"
  if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
    ${SUDO} systemctl status "${ServerName}" --no-pager 2>/dev/null || echo "Could not retrieve service status"
  else
    systemctl --user status "${ServerName}" --no-pager 2>/dev/null || echo "Could not retrieve service status"
  fi
fi

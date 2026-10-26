#!/bin/bash
# llama-server Installation Script with --system support
set -euo pipefail

# ---------------------------------------------------------------------------
# Default configuration
# ---------------------------------------------------------------------------
ServerName="llama-server"
ServiceUser="llama"
ServiceGroup="llama"
WorkingDir="${HOME}/.local/share/llama"
BinaryPath=""
LogPath="${HOME}/.local/state/llama/llama-server.log"
SystemDeployment=false

# ---------------------------------------------------------------------------
# Parse command line arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --system)
      SystemDeployment=true
      shift
      ;;
    --llama-binary)
      BinaryPath="$2"
      shift 2
      ;;
    --llama-args)
      LlamaArgs="$2"
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
  SYSTEM_DEPLOYMENT=true
  WorkingDir="/var/lib/llama"
  if [ -z "${BinaryPath}" ]; then
    BinaryPath="/usr/local/bin/llama"
  fi
  LogPath="/var/lib/llama/llama-server.log"
fi

echo "llama-server installation mode: ${SYSTEM_DEPLOYMENT:+system}"

# ---------------------------------------------------------------------------
# Detect OS and architecture
# ---------------------------------------------------------------------------
case "$(uname -m)" in
  arm64|aarch64) ARCH=aarch64 ;;
  amd64|x86_64)  ARCH=x86_64 ;;
  *) echo "Error: Arch not supported: $(uname -m)" >&2; exit 1 ;;
esac

case "$(uname -s)" in
  Linux)   OS=linux ;;
  FreeBSD) OS=freebsd ;;
  Darwin)  OS=macos ;;
  *) echo "Error: OS not supported: $(uname -s)" >&2; exit 1 ;;
esac

echo "Detected OS: ${OS}, ARCH: ${ARCH}"

# ---------------------------------------------------------------------------
# Platform probe functions
# ---------------------------------------------------------------------------
LLAMA_BUCKET="ggml-org/install.sh"
REPO="https://huggingface.co/buckets/${LLAMA_BUCKET}/resolve"

dl_bin() {
  local dest="$1"
  local url="$2"
  [ -x "$dest" ] && return 0
  command -v curl >/dev/null 2>&1 || { echo "Error: curl not found" >&2; return 1; }
  echo "Downloading $(basename "$dest")..."
  if [[ "$url" == *.zst ]]; then
    command -v zstd >/dev/null 2>&1 || { echo "Error: zstd not found" >&2; return 1; }
    curl -fsSL "$url" 2>/dev/null | zstd -d > "${dest}.tmp" 2>/dev/null &&
      chmod +x "${dest}.tmp" && mv "${dest}.tmp" "$dest" && return 0
  else
    curl -fsSL "$url" > "${dest}.tmp" 2>/dev/null &&
      chmod +x "${dest}.tmp" && mv "${dest}.tmp" "$dest" && return 0
  fi
  echo "Failed to download $dest" >&2
  return 1
}

unzstd() {
  command -v zstd >/dev/null 2>&1 && exec zstd -d
  dl_bin "./unzstd" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/unzstd" || return 1
  exec ./unzstd
}

probe_cuda() {
  [ -z "${SKIP_CUDA:-}" ] || return 1
  echo "Probing CUDA..."
  dl_bin "./cuda-probe" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/cuda/probe/probe.zst" || return 1
  CONFIG=$(./cuda-probe 2>/dev/null) || return 1
  echo "Found CUDA config: ${CONFIG}"
  dl_bin "./llama-app" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/cuda/${CONFIG}/llama-app.zst" || return 1
  return 0
}

probe_rocm() {
  [ -z "${SKIP_ROCM:-}" ] || return 1
  echo "Probing ROCm..."
  dl_bin "./rocm-probe" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/rocm/probe/probe.zst" || return 1
  CONFIG=$(./rocm-probe 2>/dev/null) || return 1
  echo "Found ROCm config: ${CONFIG}"
  dl_bin "./llama-app" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/rocm/${CONFIG}/llama-app.zst" || return 1
  return 0
}

probe_vulkan() {
  [ -z "${SKIP_VULKAN:-}" ] || return 1
  echo "Probing Vulkan..."
  dl_bin "./vulkan-probe" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/vulkan/probe/probe.zst" || return 1
  dl_bin "./featcode" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/featcode" || return 1
  CONFIG=$(./vulkan-probe && ./featcode 2>/dev/null) || return 1
  for F in $(./featcode "$CONFIG"); do
    echo "Found Vulkan feature: ${F}"
  done
  dl_bin "./llama-app" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/vulkan/${CONFIG}/llama-app.zst" || return 1
  return 0
}

probe_cpu() {
  echo "Probing CPU..."
  dl_bin "./featcode" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/featcode" || return 1
  CONFIG=$(./featcode 2>/dev/null) || return 1
  for F in $(./featcode "$CONFIG"); do
    echo "Found CPU feature: ${F}"
  done
  dl_bin "./llama-app" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/cpu/${CONFIG}/llama-app.zst" || return 1
  return 0
}

probe_metal_cpu() {
  read -r apple cpu _
  [ "$apple" = "Apple" ] || return 1
  case "$cpu" in
    M[12345]|A18) echo "$cpu" | tr '[:upper:]' '[:lower:]' ;;
    *) return 1 ;;
  esac
}

probe_metal() {
  [ -z "${SKIP_METAL:-}" ] || return 1
  echo "Probing Metal..."
  CONFIG=$(sysctl -n machdep.cpu.brand_string 2>/dev/null | probe_metal_cpu) || return 1
  echo "Found Metal config: ${CONFIG}"
  dl_bin "./llama-app" "${REPO}/${LLAMA_VERSION}/${ARCH}/${OS}/metal/${CONFIG}/llama-app.zst" || return 1
  return 0
}

# ---------------------------------------------------------------------------
# Determine binary download URL
# ---------------------------------------------------------------------------
echo "Fetching latest llama-app version..."
LLAMA_VERSION=$(curl -fsSL "${REPO}/latest" 2>/dev/null) || {
  echo "Error: Could not determine latest llama-app version" >&2
  exit 1
}
echo "Latest llama-app version: ${LLAMA_VERSION}"

# Create temporary working directory for download
TMP_DL_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DL_DIR}"' EXIT

cd "${TMP_DL_DIR}"

# ---------------------------------------------------------------------------
# Try platform probes in order of preference
# ---------------------------------------------------------------------------
BACKEND=""

case "${OS}" in
  macos)
    probe_metal && BACKEND="metal" || true
    ;;
  linux)
    probe_cuda && BACKEND="cuda" || true
    probe_rocm && BACKEND="rocm" || true
    probe_vulkan && BACKEND="vulkan" || true
    probe_cpu && BACKEND="cpu" || true
    ;;
  freebsd)
    probe_cpu && BACKEND="cpu" || true
    ;;
esac

if [ -z "${BACKEND}" ]; then
  echo "Error: No prebuilt llama-app binary available for ${ARCH}/${OS}" >&2
  exit 1
fi

echo "Selected backend: ${BACKEND}"

# Verify binary was downloaded
if [ ! -x "./llama-app" ]; then
  echo "Error: llama-app binary not downloaded" >&2
  exit 1
fi

echo "llama-app binary downloaded successfully"

# ---------------------------------------------------------------------------
# Install binary (rename llama-app -> llama)
# ---------------------------------------------------------------------------
if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  InstallDir="/usr/local/bin"
  BinaryPath="${InstallDir}/llama"
  echo "Installing llama-app binary (superuser) to ${BinaryPath}..."
  if [ ! -x "${BinaryPath}" ]; then
    sudo mkdir -p "${InstallDir}"
    sudo cp "./llama-app" "${BinaryPath}"
    sudo chmod +x "${BinaryPath}"
  else
    echo "  Binary already exists at ${BinaryPath}, keeping existing."
  fi
else
  InstallDir="${HOME}/.local/bin"
  BinaryPath="${InstallDir}/llama"
  echo "Installing llama-app binary (user) to ${BinaryPath}..."
  if [ ! -x "${BinaryPath}" ]; then
    mkdir -p "${InstallDir}"
    cp "./llama-app" "${BinaryPath}"
    chmod +x "${BinaryPath}"
  else
    echo "  Binary already exists at ${BinaryPath}, keeping existing."
  fi
fi

# Verify installation
if [ ! -x "${BinaryPath}" ]; then
  echo "Error: llama binary not installed at ${BinaryPath}" >&2
  exit 1
fi

echo "llama binary found at ${BinaryPath} (installed from llama-app)"

# ---------------------------------------------------------------------------
# Create directories
# ---------------------------------------------------------------------------
mkdir -p "${WorkingDir}"
mkdir -p "$(dirname "${LogPath}")"

# ---------------------------------------------------------------------------
# Create service environment file (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating service environment file at ${WorkingDir}/service.env..."

EnvFile="${WorkingDir}/service.env"

if [ -f "${EnvFile}" ]; then
  echo "  Service environment file already exists, preserving existing config."
else
  cat > "${EnvFile}" << 'EOF'
# Service environment variables for llama-server
# These are sourced by the systemd service ExecStart

LLAMA_ARG_HOST=127.0.0.1
LLAMA_ARG_PORT=9931
NGL_LEVEL=auto
CONTEXT_SIZE=0
JINJA_ENABLED=true
AGENT_MODE_ENABLED=true
EMBEDDINGS_ENABLED=true
EMBEDDINGS_POOLING_TYPE=mean
SLEEP_IDLE_SECONDS=
LOG_LEVEL=info
EOF
fi

chmod 644 "${EnvFile}"

# ---------------------------------------------------------------------------
# Build ExecStart command (modeled after llama-server pattern)
# ---------------------------------------------------------------------------
# Build extra args string if provided
LlamaArgsStr="${LlamaArgs:-}"

ExecStartCmd="bash -c 'source ${EnvFile}; ${BinaryPath} serve --host \"\${HOST}\" --port \"\${PORT}\" -ngl \"\${NGL_LEVEL}\" --ctx-size \"\${CONTEXT_SIZE}\" --log-file \"${LogPath}\" --log-timestamps \$([ \"\${JINJA_ENABLED}\" = \"true\" ] && echo \"--jinja\" || true) \$([ \"\${AGENT_MODE_ENABLED}\" = \"true\" ] && echo \"--agent\" || true) \$([ \"\${EMBEDDINGS_ENABLED}\" = \"true\" ] && echo \"--embeddings\" || true) \$([ \"\${EMBEDDINGS_ENABLED}\" = \"true\" ] && [ -n \"\${EMBEDDINGS_POOLING_TYPE}\" ] && echo \"--pooling \${EMBEDDINGS_POOLING_TYPE}\" || true) \$([ -n \"\${SLEEP_IDLE_SECONDS}\" ] && echo \"--sleep-idle-seconds \${SLEEP_IDLE_SECONDS}\"  || true) ${LlamaArgsStr}'"

# ---------------------------------------------------------------------------
# Create systemd service file (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating systemd service..."

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  ServiceFile="/etc/systemd/system/${ServerName}.service"
  SUDO_CMD="sudo"
  echo "Installing system service"
else
  ServiceFile="${HOME}/.config/systemd/user/${ServerName}.service"
  SUDO_CMD=""
  echo "Installing user service"
fi

echo "Creating service file at ${ServiceFile}"

# Write service file using quoted heredoc (no bash expansion), then sed for simple replacements
if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
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

# ---------------------------------------------------------------------------
# Create logrotate configuration (only if it doesn't exist)
# ---------------------------------------------------------------------------
echo "Creating logrotate configuration..."

LOGROTATE_FILE="/etc/logrotate.d/${ServerName}"

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  if [ ! -f "${LOGROTATE_FILE}" ]; then
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
    sudo useradd -r -s /bin/false "${ServiceUser}" 2>/dev/null || true
  fi

  sudo mkdir -p "${WorkingDir}"
  sudo chown -R "${ServiceUser}:${ServiceGroup}" "${WorkingDir}" 2>/dev/null || true
  sudo chown "${ServiceUser}:${ServiceGroup}" "$(dirname "${LogPath}")" 2>/dev/null || true
  sudo touch "${LogPath}" 2>/dev/null || true
  sudo chown "${ServiceUser}:${ServiceGroup}" "${LogPath}" 2>/dev/null || true
else
  if [ "$(id -u)" -eq 0 ] || [ -n "${SUDO_USER:-}" ]; then
    echo "Creating system user ${ServiceUser} (running with privileges)"
    useradd -r -s /bin/false "${ServiceUser}" 2>/dev/null || true

    mkdir -p "${WorkingDir}"
    chown -R "${ServiceUser}:${ServiceGroup}" "${WorkingDir}" 2>/dev/null || true
    chown "${ServiceUser}:${ServiceGroup}" "$(dirname "${LogPath}")" 2>/dev/null || true
    touch "${LogPath}" 2>/dev/null || true
    chown "${ServiceUser}:${ServiceGroup}" "${LogPath}" 2>/dev/null || true
  else
    echo "Running as user: $(whoami). Service will run as current user via systemd user service."
    echo "To run as a dedicated 'llama' user, re-run with --system or as root."
  fi

  mkdir -p "${WorkingDir}"
  chown -R "$(whoami):$(id -gn)" "${WorkingDir}" 2>/dev/null || true
  chown "$(whoami):$(id -gn)" "$(dirname "${LogPath}")" 2>/dev/null || true
  touch "${LogPath}" 2>/dev/null || true
  chown "$(whoami):$(id -gn)" "${LogPath}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Enable and start service
# ---------------------------------------------------------------------------
echo "Enabling and starting service..."

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  sudo systemctl --system daemon-reload
  sudo systemctl enable "${ServerName}.service"
  sudo systemctl start "${ServerName}.service"
else
  systemctl --user daemon-reload
  systemctl --user enable "${ServerName}.service"
  systemctl --user start "${ServerName}.service"
fi

# ---------------------------------------------------------------------------
# Final status
# ---------------------------------------------------------------------------
echo ""
echo "llama-server service installation complete!"
echo ""
echo "Installation summary:"
echo "  Binary:      ${BinaryPath}"
echo "  Working Dir: ${WorkingDir}"
echo "  Env File:    ${EnvFile}"
echo "  Log Path:    ${LogPath}"
echo "  Service File: ${ServiceFile}"
echo "  Service User: ${ServiceUser}"
echo "  Service Group: ${ServiceGroup}"
echo "  Backend:     ${BACKEND}"
echo ""
echo "Status check:"
if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  sudo systemctl status "${ServerName}.service" --no-pager 2>/dev/null || echo "Could not retrieve service status"
else
  systemctl --user status "${ServerName}.service" --no-pager 2>/dev/null || echo "Could not retrieve service status"
fi

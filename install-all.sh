#!/bin/bash
# All-in-One Installation Script for llama-server → bifrost-http → goose
# Installs and configures the complete stack in the correct order
set -euo pipefail

# ---------------------------------------------------------------------------
# Default configuration
# ---------------------------------------------------------------------------
SystemDeployment=false
SkipLlama=false
SkipBifrost=false
SkipGoose=false

# ---------------------------------------------------------------------------
# Parse command line arguments
# ---------------------------------------------------------------------------
usage() {
  echo "Usage: $0 [--system] [--skip-llama] [--skip-bifrost] [--skip-goose] [--help]"
  echo ""
  echo "  --system        System-wide deployment (default: user deployment)"
  echo "  --skip-llama    Skip llama-server installation"
  echo "  --skip-bifrost  Skip bifrost-http installation"
  echo "  --skip-goose    Skip goose installation"
  echo "  --help          Show this help message"
  echo ""
  echo "Installation order: llama-server → bifrost-http → goose"
  echo ""
  echo "Ports:"
  echo "  llama-server: 9931"
  echo "  bifrost-http: 8080"
  echo "  goose:        3284"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system)
      SystemDeployment=true
      shift
      ;;
    --skip-llama)
      SkipLlama=true
      shift
      ;;
    --skip-bifrost)
      SkipBifrost=true
      shift
      ;;
    --skip-goose)
      SkipGoose=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve script directory for sibling scripts
# ---------------------------------------------------------------------------
RAW_BASE="https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/resources/inference-serving/localai-services"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Detect if running from a URL download (curl | bash) where BASH_SOURCE is empty
# or the directory doesn't contain the sibling scripts
if [ -z "${SCRIPT_DIR}" ] || [ ! -f "${SCRIPT_DIR}/install-llama-server.sh" ]; then
  echo "Running from remote download, fetching sibling scripts to temp directory..."
  TMP_SCRIPT_DIR=$(mktemp -d)
  trap 'rm -rf "${TMP_SCRIPT_DIR}"' EXIT
  
  for script in install-llama-server.sh install-bifrost.sh install-goose.sh; do
    if ! curl -fsSL "${RAW_BASE}/${script}" -o "${TMP_SCRIPT_DIR}/${script}"; then
      echo "Error: Failed to download ${script} from ${RAW_BASE}" >&2
      exit 1
    fi
    chmod +x "${TMP_SCRIPT_DIR}/${script}"
  done
  
  SCRIPT_DIR="${TMP_SCRIPT_DIR}"
fi

echo "============================================="
echo "  All-in-One Bifrost Stack Installation"
echo "============================================="
echo ""
echo "Mode: ${SystemDeployment:+system}user"
echo "Script dir: ${SCRIPT_DIR}"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Install llama-server
# ---------------------------------------------------------------------------
if [ "${SkipLlama}" = true ]; then
  echo ""
  echo "=== SKIPPING: llama-server installation ==="
else
  echo ""
  echo "============================================="
  echo "  Step 1: Installing llama-server"
  echo "============================================="
  echo ""

  LlamaArgs=""
  if [ "${SystemDeployment}" = true ]; then
    LlamaArgs="--system"
  fi

  bash "${SCRIPT_DIR}/install-llama-server.sh" ${LlamaArgs}

  echo ""
  echo "=== Step 1 Complete: llama-server installed ==="
fi

# ---------------------------------------------------------------------------
# Step 2: Install bifrost-http
# ---------------------------------------------------------------------------
if [ "${SkipBifrost}" = true ]; then
  echo ""
  echo "=== SKIPPING: bifrost-http installation ==="
else
  echo ""
  echo "============================================="
  echo "  Step 2: Installing bifrost-http"
  echo "============================================="
  echo ""

  BifrostArgs=""
  if [ "${SystemDeployment}" = true ]; then
    BifrostArgs="--system"
  fi

  bash "${SCRIPT_DIR}/install-bifrost.sh" ${BifrostArgs}

  echo ""
  echo "=== Step 2 Complete: bifrost-http installed ==="
fi

# ---------------------------------------------------------------------------
# Step 3: Install goose
# ---------------------------------------------------------------------------
if [ "${SkipGoose}" = true ]; then
  echo ""
  echo "=== SKIPPING: goose installation ==="
else
  echo ""
  echo "============================================="
  echo "  Step 3: Installing goose"
  echo "============================================="
  echo ""

  GooseArgs=""
  if [ "${SystemDeployment}" = true ]; then
    GooseArgs="--system"
  fi

  bash "${SCRIPT_DIR}/install-goose.sh" ${GooseArgs}

  echo ""
  echo "=== Step 3 Complete: goose installed ==="
fi

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================="
echo "  All-in-One Installation Complete"
echo "============================================="
echo ""
echo "Stack:"
echo "  llama-server: port 9931 (local inference)"
echo "  bifrost-http:  port 8080 (AI Gateway)"
echo "  goose:         port 3284 (ACP server)"
echo ""
echo "Providers registered in goose:"
echo "  - bifrost (AI Gateway): http://127.0.0.1:8080/v1"
echo "  - llama-server: http://127.0.0.1:9931/v1"
echo ""
echo "MCP servers in goose:"
echo "  - bifrost-mcp: http://127.0.0.1:8080/mcp (Gateway mode)"
echo ""
echo "To uninstall (reverse order):"
echo "  ./uninstall-goose.sh${SystemDeployment:+ --system}"
echo "  ./uninstall-bifrost.sh${SystemDeployment:+ --system}"
echo "  ./uninstall-llama-server.sh${SystemDeployment:+ --system}"
echo ""
echo "Service status:"
if command -v systemctl >/dev/null 2>&1; then
  if [ "${SystemDeployment}" = true ]; then
    sudo systemctl status llama-server.service --no-pager 2>/dev/null || true
    sudo systemctl status bifrost-http.service --no-pager 2>/dev/null || true
    sudo systemctl status goose.service --no-pager 2>/dev/null || true
  else
    systemctl --user status llama-server.service --no-pager 2>/dev/null || true
    systemctl --user status bifrost-http.service --no-pager 2>/dev/null || true
    systemctl --user status goose.service --no-pager 2>/dev/null || true
  fi
fi

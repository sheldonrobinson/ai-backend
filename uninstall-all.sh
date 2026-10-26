#!/bin/bash
# All-in-One Uninstall Script for goose → bifrost-http → llama-server
# Removes the complete stack in the correct reverse order
set -euo pipefail

# ---------------------------------------------------------------------------
# Default configuration
# ---------------------------------------------------------------------------
SystemDeployment=false
Purge=false

# ---------------------------------------------------------------------------
# Parse command line arguments
# ---------------------------------------------------------------------------
usage() {
  echo "Usage: $0 [--system] [--purge] [--help]"
  echo ""
  echo "  --system   System-wide uninstallation (default: user deployment)"
  echo "  --purge    Purge all data directories (models, configs, caches)"
  echo "  --help     Show this help message"
  echo ""
  echo "Uninstall order: goose → bifrost-http → llama-server"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system)
      SystemDeployment=true
      shift
      ;;
    --purge)
      Purge=true
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================="
echo "  All-in-One Bifrost Stack Uninstallation"
echo "============================================="
echo ""
echo "Mode: ${SystemDeployment:+system}user ${Purge:+purge}"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Uninstall goose
# ---------------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Step 1: Uninstalling goose"
echo "============================================="
echo ""

GooseArgs=""
if [ "${SystemDeployment}" = true ]; then
  GooseArgs="--system"
fi
if [ "${Purge}" = true ]; then
  GooseArgs="${GooseArgs} --purge"
fi

bash "${SCRIPT_DIR}/uninstall-goose.sh" ${GooseArgs}

echo ""
echo "=== Step 1 Complete: goose uninstalled ==="

# ---------------------------------------------------------------------------
# Step 2: Uninstall bifrost-http
# ---------------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Step 2: Uninstalling bifrost-http"
echo "============================================="
echo ""

BifrostArgs=""
if [ "${SystemDeployment}" = true ]; then
  BifrostArgs="--system"
fi
if [ "${Purge}" = true ]; then
  BifrostArgs="${BifrostArgs} --purge"
fi

bash "${SCRIPT_DIR}/uninstall-bifrost.sh" ${BifrostArgs}

echo ""
echo "=== Step 2 Complete: bifrost-http uninstalled ==="

# ---------------------------------------------------------------------------
# Step 3: Uninstall llama-server
# ---------------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Step 3: Uninstalling llama-server"
echo "============================================="
echo ""

LlamaArgs=""
if [ "${SystemDeployment}" = true ]; then
  LlamaArgs="--system"
fi
if [ "${Purge}" = true ]; then
  LlamaArgs="${LlamaArgs} --purge"
fi

bash "${SCRIPT_DIR}/uninstall-llama-server.sh" ${LlamaArgs}

echo ""
echo "=== Step 3 Complete: llama-server uninstalled ==="

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================="
echo "  All-in-One Uninstallation Complete"
echo "============================================="
echo ""
echo "All services removed:"
echo "  - goose (ACP server)"
echo "  - bifrost-http (AI Gateway)"
echo "  - llama-server (local inference)"
if [ "${Purge}" = true ]; then
  echo "  All data directories purged"
fi

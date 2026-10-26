#!/bin/bash
# goose Uninstall Script with --system and --purge support
set -euo pipefail

# ---------------------------------------------------------------------------
# Default configuration (must match install script defaults)
# ---------------------------------------------------------------------------
ServerName="goose"
ServiceUser="goose"
ServiceGroup="goose"
WorkingDir="${HOME}/.local/share/goose"
ConfigDir="${HOME}/.config/goose"
BinaryPath="/usr/local/bin/goose"
LogPath="/var/log/goose.log"
SystemDeployment=false
Purge=false
GoosePort="3284"

# ---------------------------------------------------------------------------
# Parse command line arguments
# ---------------------------------------------------------------------------
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
  WorkingDir="/var/lib/goose"
  ConfigDir="/etc/goose"
  BinaryPath="/usr/local/bin/goose"
  LogPath="/var/log/goose.log"
fi

echo "goose uninstallation mode: ${SYSTEM_DEPLOYMENT:+system} ${Purge:+purge}"

# ---------------------------------------------------------------------------
# Stop and disable service
# ---------------------------------------------------------------------------
echo "Stopping and disabling goose service..."

if command -v systemctl >/dev/null 2>&1; then
  if [ "${SystemDeployment}" = true ]; then
    sudo systemctl stop "${ServerName}.service" 2>/dev/null || true
    sudo systemctl disable "${ServerName}.service" 2>/dev/null || true
  else
    systemctl --user stop "${ServerName}.service" 2>/dev/null || true
    systemctl --user disable "${ServerName}.service" 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------------------------
# Remove service file
# ---------------------------------------------------------------------------
echo "Removing service file..."

if [ "${SystemDeployment}" = true ]; then
  sudo rm -f "/etc/systemd/system/${ServerName}.service" 2>/dev/null || true
  sudo systemctl daemon-reload 2>/dev/null || true
else
  rm -f "${HOME}/.config/systemd/user/${ServerName}.service" 2>/dev/null || true
  systemctl --user daemon-reload 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Remove logrotate configuration
# ---------------------------------------------------------------------------
echo "Removing logrotate configuration..."

if [ "${SystemDeployment}" = true ]; then
  sudo rm -f "/etc/logrotate.d/${ServerName}" 2>/dev/null || true
else
  rm -f "/etc/logrotate.d/${ServerName}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Remove binary
# ---------------------------------------------------------------------------
echo "Removing binary..."

if [ "${SystemDeployment}" = true ]; then
  sudo rm -f "${BinaryPath}" 2>/dev/null || true
else
  rm -f "${BinaryPath}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Remove directories and config
# ---------------------------------------------------------------------------
echo "Removing directories and configuration..."

if [ "${SystemDeployment}" = true ]; then
  sudo rm -rf "${WorkingDir}" 2>/dev/null || true
  sudo rm -rf "${ConfigDir}" 2>/dev/null || true
  sudo rm -f "${LogPath}" 2>/dev/null || true
else
  rm -rf "${WorkingDir}" 2>/dev/null || true
  rm -rf "${ConfigDir}" 2>/dev/null || true
  rm -f "${LogPath}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Purge all data directories (--purge flag)
# ---------------------------------------------------------------------------
if [ "${Purge}" = true ]; then
  echo "Purging all data directories..."

  if [ "${SystemDeployment}" = true ]; then
    sudo rm -rf "${WorkingDir}" 2>/dev/null || true
    sudo rm -rf "${ConfigDir}" 2>/dev/null || true
    sudo rm -f "${LogPath}" 2>/dev/null || true
    sudo rm -rf "/var/lib/goose" 2>/dev/null || true
    sudo rm -rf "/etc/goose" 2>/dev/null || true
    sudo rm -rf "/var/log/goose" 2>/dev/null || true
  else
    rm -rf "${WorkingDir}" 2>/dev/null || true
    rm -rf "${ConfigDir}" 2>/dev/null || true
    rm -f "${LogPath}" 2>/dev/null || true
    rm -rf "/home/sheldon/.local/share/goose" 2>/dev/null || true
    rm -rf "/home/sheldon/.config/goose" 2>/dev/null || true
    rm -rf "/home/sheldon/.local/state/goose" 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------------------------
# Remove service account (system deployment only)
# ---------------------------------------------------------------------------
if [ "${SystemDeployment}" = true ]; then
  echo "Removing service account ${ServiceUser}..."
  sudo userdel "${ServiceUser}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Final status
# ---------------------------------------------------------------------------
echo ""
echo "goose uninstallation complete!"
echo ""
echo "Removed:"
echo "  Service:   ${ServerName}"
echo "  Binary:    ${BinaryPath}"
echo "  Working Dir: ${WorkingDir}"
echo "  Config Dir:  ${ConfigDir}"
echo "  Log Path:  ${LogPath}"
if [ "${Purge}" = true ]; then
  echo "  All data directories purged"
fi
echo ""
if [ "${SystemDeployment}" = true ]; then
  echo "Service account ${ServiceUser} removed."
fi

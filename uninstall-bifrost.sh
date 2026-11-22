#!/bin/bash
# bifrost-http Uninstall Script with --system and --purge support
set -euo pipefail

# ---------------------------------------------------------------------------
# Default configuration (must match install script defaults)
# ---------------------------------------------------------------------------
ServerName="bifrost-http"
ServiceUser="bifrost"
ServiceGroup="bifrost"
WorkingDir="${HOME}/.config/bifrost"
BinaryPath="/usr/local/bin/bifrost-http"
CLIPath="/usr/local/bin/bifrost"
LogPath="${HOME}/.local/state/bifrost/bifrost.log"
EnvFile="${WorkingDir}/service.env"
SystemDeployment=false
Purge=false
BifrostPort="8080"

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
  SYSTEM_DEPLOYMENT=true
  BinaryPath="/usr/local/bin/bifrost-http"
  CLIPath="/usr/local/bin/bifrost"
  WorkingDir="/var/lib/bifrost"
  LogPath="/var/log/bifrost/bifrost.log"
  EnvFile="${WorkingDir}/service.env"
fi

echo "bifrost-http uninstallation mode: ${SYSTEM_DEPLOYMENT:+system} ${Purge:+purge}"

# ---------------------------------------------------------------------------
# Stop and disable service
# ---------------------------------------------------------------------------
echo "Stopping and disabling bifrost-http service..."

if command -v systemctl >/dev/null 2>&1; then
  if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
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

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
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

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  sudo rm -f "/etc/logrotate.d/${ServerName}" 2>/dev/null || true
else
  rm -f "/etc/logrotate.d/${ServerName}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Remove binaries
# ---------------------------------------------------------------------------
echo "Removing binaries..."

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  sudo rm -f "${BinaryPath}" 2>/dev/null || true
  sudo rm -f "${CLIPath}" 2>/dev/null || true
else
  rm -f "${BinaryPath}" 2>/dev/null || true
  rm -f "${CLIPath}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Remove environment file and directories
# ---------------------------------------------------------------------------
echo "Removing environment file and directories..."

if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  sudo rm -f "${EnvFile}" 2>/dev/null || true
  sudo rm -f "${LogPath}" 2>/dev/null || true
else
  rm -f "${EnvFile}" 2>/dev/null || true
  rm -f "${LogPath}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Purge all data directories (--purge flag)
# ---------------------------------------------------------------------------
if [ "${Purge}" = true ]; then
  echo "Purging all data directories..."

  if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
    sudo rm -rf "/var/lib/bifrost" 2>/dev/null || true
    sudo rm -rf "/var/lib/bifrost-http" 2>/dev/null || true
    sudo rm -rf "/var/log/bifrost" 2>/dev/null || true
    sudo rm -rf "/srv/bifrost" 2>/dev/null || true
    sudo rm -rf "/tmp/bifrost-app" 2>/dev/null || true
    sudo rm -rf "/tmp/bifrost-http" 2>/dev/null || true
  else
    rm -rf "${HOME}/.config/bifrost" 2>/dev/null || true
    rm -rf "${HOME}/.local/share/bifrost" 2>/dev/null || true
    rm -rf "${HOME}/.local/state/bifrost" 2>/dev/null || true
    rm -rf "/tmp/bifrost-app" 2>/dev/null || true
    rm -rf "/tmp/bifrost-http" 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------------------------
# Remove service account (system deployment only)
# ---------------------------------------------------------------------------
if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  echo "Removing service account ${ServiceUser}..."
  sudo userdel "${ServiceUser}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Final status
# ---------------------------------------------------------------------------
echo ""
echo "bifrost-http uninstallation complete!"
echo ""
echo "Removed:"
echo "  Service:   ${ServerName}"
echo "  Binary:    ${BinaryPath}"
echo "  CLI:       ${CLIPath}"
echo "  Working Dir: ${AppDir}"
echo "  Env File:  ${EnvFile}"
echo "  Log Path:  ${LogPath}"
if [ "${Purge}" = true ]; then
  echo "  All data directories purged"
fi
echo ""
if [ "${SYSTEM_DEPLOYMENT}" = true ]; then
  echo "Service account ${ServiceUser} removed."
fi

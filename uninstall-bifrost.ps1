#!/usr/bin/env pwsh
#==============================================================================
# bifrost-http Uninstall Script for Windows
# Supports --system (system-wide) and --purge (remove all data) flags
#==============================================================================
[CmdletBinding()]
param(
  [switch]$System,
  [switch]$Purge,
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: ./uninstall-bifrost.ps1 [--system] [--purge] [--help]"
  Write-Host ""
  Write-Host "  --system   System-wide uninstallation (default: user deployment)"
  Write-Host "  --purge    Purge all data directories (models, configs, caches)"
  Write-Host "  --help     Show this help message"
  exit 0
}

$ErrorActionPreference = "Continue"

#==============================================================================
# Default configuration (must match install script defaults)
#==============================================================================
$ServerName = "bifrost-http"
$ServiceUser = "bifrost"
$ServiceGroup = "bifrost"
$BifrostPort = 8080

# Determine deployment mode
$IsSystem = $System.IsPresent -or ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

if ($IsSystem) {
  $AppDir = "C:\ProgramData\bifrost"
  $WorkingDir = $AppDir
  $BinaryPath = "C:\Program Files\bifrost\bin\bifrost-http.exe"
  $CliPath = "C:\Program Files\bifrost\bin\bifrost.exe"
  $EnvFile = Join-Path $AppDir "service.env"
  $LogPath = Join-Path $AppDir "bifrost.log"
  $ConfigStorePath = Join-Path $AppDir "config.db"
  $LogsStorePath = Join-Path $AppDir "logs.db"
} else {
  $AppDir = Join-Path $env:APPDATA "bifrost"
  $WorkingDir = $AppDir
  $BinaryPath = Join-Path $env:LOCALAPPDATA "bin\bifrost-http.exe"
  $CliPath = Join-Path $env:LOCALAPPDATA "bin\bifrost.exe"
  $EnvFile = Join-Path $AppDir "service.env"
  $LogPath = Join-Path $AppDir "bifrost.log"
  $ConfigStorePath = Join-Path $AppDir "config.db"
  $LogsStorePath = Join-Path $AppDir "logs.db"
}

$ModeStr = if ($IsSystem) { "system" } else { "user" }
$PurgeStr = if ($Purge) { "purge" } else { "" }
Write-Host "bifrost-http uninstallation mode: $ModeStr $PurgeStr"

#==============================================================================
# Stop and remove service
#==============================================================================
Write-Host "Stopping and removing bifrost-http service..."

$NssmPath = Get-Command nssm -ErrorAction SilentlyContinue
if ($NssmPath) {
  try {
    & $NssmPath stop $ServerName 2>$null
    & $NssmPath remove $ServerName -confirm 2>$null
    Write-Host "  Service $ServerName removed." -ForegroundColor Green
  } catch {
    Write-Host "  Warning: Could not remove service $ServerName via NSSM: $_" -ForegroundColor Yellow
  }
} else {
  try {
    sc.exe stop $ServerName 2>$null
    sc.exe delete $ServerName 2>$null
    Write-Host "  Service $ServerName removed via sc.exe." -ForegroundColor Green
  } catch {
    Write-Host "  Warning: Could not remove service $ServerName." -ForegroundColor Yellow
  }
}

#==============================================================================
# Remove binaries
#==============================================================================
Write-Host "Removing binaries..."
foreach ($path in @($BinaryPath, $CliPath)) {
  if (Test-Path $path) {
    Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed: $path"
  } else {
    Write-Host "  Not found: $path, skipping."
  }
}

#==============================================================================
# Remove environment file and directories
#==============================================================================
Write-Host "Removing environment file and directories..."
foreach ($path in @($EnvFile, $AppDir, $LogPath)) {
  if (Test-Path $path) {
    if (Test-Path -PathType Container $path) {
      Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    } else {
      Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  Removed: $path"
  } else {
    Write-Host "  Not found: $path, skipping."
  }
}

#==============================================================================
# Purge all data directories (--purge flag)
#==============================================================================
if ($Purge) {
  Write-Host "Purging all data directories..."

  if ($IsSystem) {
    $PurgePaths = @(
      $AppDir,
      "C:\ProgramData\bifrost",
      "C:\ProgramData\bifrost-http",
      "C:\Program Files\bifrost",
      "C:\Program Files\bifrost-http",
      "C:\ProgramData\bifrost\config",
      "C:\ProgramData\bifrost\logs",
      (Join-Path $env:TEMP "bifrost-app"),
      (Join-Path $env:TEMP "bifrost-http")
    )
  } else {
    $PurgePaths = @(
      $AppDir,
      (Join-Path $env:APPDATA "bifrost"),
      (Join-Path $env:LOCALAPPDATA "bifrost"),
      (Join-Path $env:LOCALAPPDATA "bifrost-http"),
      (Join-Path $env:LOCALAPPDATA "state\bifrost"),
      (Join-Path $env:TEMP "bifrost-app"),
      (Join-Path $env:TEMP "bifrost-http")
    )
  }

  foreach ($path in $PurgePaths) {
    if (Test-Path $path) {
      Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "  Purged: $path"
    }
  }
}

#==============================================================================
# Final status
#==============================================================================
Write-Host ""
Write-Host "bifrost-http uninstallation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Removed:"
Write-Host "  Service:   $ServerName"
Write-Host "  Binary:    $BinaryPath"
Write-Host "  CLI:       $CliPath"
Write-Host "  Working Dir: $AppDir"
Write-Host "  Env File:  $EnvFile"
Write-Host "  Log Path:  $LogPath"
if ($Purge) {
  Write-Host "  All data directories purged"
}
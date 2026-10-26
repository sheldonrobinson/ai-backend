#!/usr/bin/env pwsh
#==============================================================================
# goose Uninstall Script for Windows
# Supports --system (system-wide) and --purge (remove all data) flags
#==============================================================================
[CmdletBinding()]
param(
  [switch]$System,
  [switch]$Purge,
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: ./uninstall-goose.ps1 [--system] [--purge] [--help]"
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
$ServerName = "goose"
$ServiceUser = "goose"
$ServiceGroup = "goose"
$GoosePort = 3284

# Determine deployment mode
$IsSystem = $System.IsPresent -or ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

if ($IsSystem) {
  $WorkingDir = "C:\ProgramData\goose"
  $ConfigDir = "C:\ProgramData\goose\config"
  $BinaryPath = "C:\Program Files\goose\goose.exe"
  $LogPath = Join-Path $WorkingDir "goose.log"
  $ConfigFile = Join-Path $ConfigDir "config.yaml"
  $EnvFile = Join-Path $ConfigDir "goose.env"
} else {
  $WorkingDir = Join-Path $env:APPDATA "goose"
  $ConfigDir = Join-Path $env:APPDATA "goose\config"
  $BinaryPath = Join-Path $env:LOCALAPPDATA "bin\goose.exe"
  $LogPath = Join-Path $WorkingDir "goose.log"
  $ConfigFile = Join-Path $ConfigDir "config.yaml"
  $EnvFile = Join-Path $ConfigDir "goose.env"
}

$ModeStr = if ($IsSystem) { "system" } else { "user" }
$PurgeStr = if ($Purge) { "purge" } else { "" }
Write-Host "goose uninstallation mode: $ModeStr $PurgeStr"

#==============================================================================
# Stop and remove service
#==============================================================================
Write-Host "Stopping and removing goose service..."

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
# Remove binary
#==============================================================================
Write-Host "Removing binary..."
if (Test-Path $BinaryPath) {
  Remove-Item -Path $BinaryPath -Force -ErrorAction SilentlyContinue
  Write-Host "  Removed: $BinaryPath"
} else {
  Write-Host "  Binary not found at $BinaryPath, skipping."
}

#==============================================================================
# Remove directories and config
#==============================================================================
Write-Host "Removing directories and configuration..."
foreach ($path in @($WorkingDir, $ConfigDir, $LogPath, $ConfigFile, $EnvFile)) {
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
      $WorkingDir,
      $ConfigDir,
      "C:\ProgramData\goose",
      "C:\ProgramData\goose\config",
      "C:\Program Files\goose",
      "C:\Program Files\goose\config",
      "C:\ProgramData\goose\log",
      "C:\Program Files\goose\log"
    )
  } else {
    $PurgePaths = @(
      $WorkingDir,
      $ConfigDir,
      (Join-Path $env:LOCALAPPDATA "goose"),
      (Join-Path $env:LOCALAPPDATA "goose\config"),
      (Join-Path $env:APPDATA "goose"),
      (Join-Path $env:APPDATA "goose\config"),
      (Join-Path $env:LOCALAPPDATA "state\goose")
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
Write-Host "goose uninstallation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Removed:"
Write-Host "  Service:   $ServerName"
Write-Host "  Binary:    $BinaryPath"
Write-Host "  Working Dir: $WorkingDir"
Write-Host "  Config Dir:  $ConfigDir"
Write-Host "  Log Path:  $LogPath"
if ($Purge) {
  Write-Host "  All data directories purged"
}
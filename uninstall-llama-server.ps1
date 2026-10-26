#!/usr/bin/env pwsh
#==============================================================================
# llama-server Uninstall Script for Windows
# Supports --system (system-wide) and --purge (remove all data) flags
#==============================================================================
[CmdletBinding()]
param(
  [switch]$System,
  [switch]$Purge,
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: ./uninstall-llama-server.ps1 [--system] [--purge] [--help]"
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
$ServerName = "llama-server"
$ServiceUser = "llama"
$ServiceGroup = "llama"
$LlamaPort = 9931

# Determine deployment mode
$IsSystem = $System.IsPresent -or ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

if ($IsSystem) {
  $WorkingDir = "C:\ProgramData\llama"
  $BinaryPath = "C:\Program Files\llama\llama.exe"
  $LogPath = Join-Path $WorkingDir "llama-server.log"
  $ConfigDir = "C:\ProgramData\llama\config"
} else {
  $WorkingDir = Join-Path $env:APPDATA "llama"
  $BinaryPath = Join-Path $env:LOCALAPPDATA "bin\llama.exe"
  $LogPath = Join-Path $WorkingDir "llama-server.log"
  $ConfigDir = Join-Path $env:APPDATA "llama\config"
}

$ModeStr = if ($IsSystem) { "system" } else { "user" }
$PurgeStr = if ($Purge) { "purge" } else { "" }
Write-Host "llama-server uninstallation mode: $ModeStr $PurgeStr"

#==============================================================================
# Stop and remove service
#==============================================================================
Write-Host "Stopping and removing llama-server service..."

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
  # Try sc.exe
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
# Remove directories
#==============================================================================
Write-Host "Removing directories..."
foreach ($dir in @($WorkingDir, $ConfigDir)) {
  if (Test-Path $dir) {
    Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed: $dir"
  } else {
    Write-Host "  Not found: $dir, skipping."
  }
}

if (Test-Path $LogPath) {
  Remove-Item -Path $LogPath -Force -ErrorAction SilentlyContinue
  Write-Host "  Removed: $LogPath"
}

#==============================================================================
# Purge all data directories (--purge flag)
#==============================================================================
if ($Purge) {
  Write-Host "Purging all data directories..."

  if ($IsSystem) {
    $PurgePaths = @(
      $WorkingDir,
      "C:\ProgramData\llama",
      "C:\Program Files\llama",
      "C:\ProgramData\llama\config",
      "C:\Program Files\llama\config",
      "C:\ProgramData\llama\models",
      "C:\Program Files\llama\models",
      "C:\ProgramData\llama\cache",
      "C:\Program Files\llama\cache"
    )
  } else {
    $PurgePaths = @(
      $WorkingDir,
      (Join-Path $env:LOCALAPPDATA "llama"),
      (Join-Path $env:LOCALAPPDATA "llama.cpp"),
      (Join-Path $env:LOCALAPPDATA "llama.cpp-server"),
      (Join-Path $env:LOCALAPPDATA "llama\models"),
      (Join-Path $env:LOCALAPPDATA "llama\cache"),
      (Join-Path $env:APPDATA "llama"),
      (Join-Path $env:APPDATA "llama\config")
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
Write-Host "llama-server uninstallation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Removed:"
Write-Host "  Service:   $ServerName"
Write-Host "  Binary:    $BinaryPath"
Write-Host "  Working Dir: $WorkingDir"
Write-Host "  Log Path:  $LogPath"
if ($Purge) {
  Write-Host "  All data directories purged"
}
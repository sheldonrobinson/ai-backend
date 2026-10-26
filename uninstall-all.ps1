#!/usr/bin/env pwsh
#==============================================================================
# All-in-One Uninstall Script for goose -> bifrost-http -> llama-server on Windows
# Removes the complete stack in the correct reverse order
#==============================================================================
[CmdletBinding()]
param(
  [switch]$System,
  [switch]$Purge,
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: ./uninstall-all.ps1 [--system] [--purge] [--help]"
  Write-Host ""
  Write-Host "  --system   System-wide uninstallation (default: user deployment)"
  Write-Host "  --purge    Purge all data directories (models, configs, caches)"
  Write-Host "  --help     Show this help message"
  Write-Host ""
  Write-Host "Uninstall order: goose -> bifrost-http -> llama-server"
  exit 0
}

$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------------------
# Resolve script directory for sibling scripts
# ---------------------------------------------------------------------------
$RawBase = "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/resources/inference-serving/localai-services"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Detect if running from a remote download (iex Invoke-WebRequest) where
# MyInvocation.MyCommand.Definition is empty or the directory doesn't
# contain the sibling scripts
if ([string]::IsNullOrEmpty($ScriptDir) -or -not (Test-Path (Join-Path $ScriptDir "uninstall-goose.ps1"))) {
  Write-Host "Running from remote download, fetching sibling scripts to temp directory..." -ForegroundColor Yellow
  $ScriptDir = Join-Path $env:TEMP "bifrost-uninstall-$(Get-Random)"
  New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null

  foreach ($script in @("uninstall-goose.ps1", "uninstall-bifrost.ps1", "uninstall-llama-server.ps1")) {
    $dest = Join-Path $ScriptDir $script
    try {
      $ProgressPreference = "SilentlyContinue"
      Invoke-WebRequest -Uri "$RawBase/$script" -OutFile $dest -UseBasicParsing -ErrorAction Stop
      $ProgressPreference = "Continue"
    } catch {
      Write-Host "Error: Failed to download $script from $RawBase" -ForegroundColor Red
      exit 1
    }
  }
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  All-in-One Bifrost Stack Uninstallation (Windows)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
$ModeStr = if ($System) { "system" } else { "user" }
$PurgeStr = if ($Purge) { "purge" } else { "" }
Write-Host "Mode: $ModeStr $PurgeStr"
Write-Host ""

#==============================================================================
# Step 1: Uninstall goose
#==============================================================================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Step 1: Uninstalling goose" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

$GooseArgs = @()
if ($System) { $GooseArgs += "--system" }
if ($Purge) { $GooseArgs += "--purge" }

& "$ScriptDir/uninstall-goose.ps1" @GooseArgs

Write-Host ""
Write-Host "=== Step 1 Complete: goose uninstalled ===" -ForegroundColor Green

#==============================================================================
# Step 2: Uninstall bifrost-http
#==============================================================================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Step 2: Uninstalling bifrost-http" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

$BifrostArgs = @()
if ($System) { $BifrostArgs += "--system" }
if ($Purge) { $BifrostArgs += "--purge" }

& "$ScriptDir/uninstall-bifrost.ps1" @BifrostArgs

Write-Host ""
Write-Host "=== Step 2 Complete: bifrost-http uninstalled ===" -ForegroundColor Green

#==============================================================================
# Step 3: Uninstall llama-server
#==============================================================================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Step 3: Uninstalling llama-server" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

$LlamaArgs = @()
if ($System) { $LlamaArgs += "--system" }
if ($Purge) { $LlamaArgs += "--purge" }

& "$ScriptDir/uninstall-llama-server.ps1" @LlamaArgs

Write-Host ""
Write-Host "=== Step 3 Complete: llama-server uninstalled ===" -ForegroundColor Green

#==============================================================================
# Final summary
#==============================================================================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  All-in-One Uninstallation Complete" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All services removed:"
Write-Host "  - goose (ACP server)"
Write-Host "  - bifrost-http (AI Gateway)"
Write-Host "  - llama-server (local inference)"
if ($Purge) {
  Write-Host "  All data directories purged"
}
Write-Host ""
Write-Host "To verify removal:"
Write-Host "  Get-Service -Name goose -ErrorAction SilentlyContinue"
Write-Host "  Get-Service -Name bifrost-http -ErrorAction SilentlyContinue"
Write-Host "  Get-Service -Name llama-server -ErrorAction SilentlyContinue"
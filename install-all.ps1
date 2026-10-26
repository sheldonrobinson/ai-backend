#!/usr/bin/env pwsh
#==============================================================================
# All-in-One Installation Script for llama-server -> bifrost-http -> goose on Windows
# Installs and configures the complete stack in the correct order:
#   1. llama-server (local inference)
#   2. bifrost-http (AI Gateway) - registers llama-server as provider
#   3. goose (ACP server) - registers bifrost and llama-server as providers
#==============================================================================
[CmdletBinding()]
param(
  [switch]$System,
  [switch]$SkipLlama,
  [switch]$SkipBifrost,
  [switch]$SkipGoose,
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: ./install-all.ps1 [--system] [--skip-llama] [--skip-bifrost] [--skip-goose] [--help]"
  Write-Host ""
  Write-Host "  --system        System-wide deployment (default: user deployment)"
  Write-Host "  --skip-llama    Skip llama-server installation"
  Write-Host "  --skip-bifrost  Skip bifrost-http installation"
  Write-Host "  --skip-goose    Skip goose installation"
  Write-Host "  --help          Show this help message"
  Write-Host ""
  Write-Host "Installation order: llama-server -> bifrost-http -> goose"
  Write-Host ""
  Write-Host "Ports:"
  Write-Host "  llama-server: 9931"
  Write-Host "  bifrost-http: 8080"
  Write-Host "  goose:        3284"
  exit 0
}

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Resolve script directory for sibling scripts
# ---------------------------------------------------------------------------
$RawBase = "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Detect if running from a remote download (iex Invoke-WebRequest) where
# MyInvocation.MyCommand.Definition is empty or the directory doesn't
# contain the sibling scripts
if ([string]::IsNullOrEmpty($ScriptDir) -or -not (Test-Path (Join-Path $ScriptDir "install-llama-server.ps1"))) {
  Write-Host "Running from remote download, fetching sibling scripts to temp directory..." -ForegroundColor Yellow
  $ScriptDir = Join-Path $env:TEMP "bifrost-install-$(Get-Random)"
  New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null

  foreach ($script in @("install-llama-server.ps1", "install-bifrost.ps1", "install-goose.ps1")) {
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
Write-Host "  All-in-One Bifrost Stack Installation (Windows)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
$ModeStr = if ($System) { "system" } else { "user" }
Write-Host "Mode: $ModeStr"
Write-Host "Script dir: $ScriptDir"
Write-Host ""

#==============================================================================
# Step 1: Install llama-server
#==============================================================================
if ($SkipLlama) {
  Write-Host ""
  Write-Host "=== SKIPPING: llama-server installation ===" -ForegroundColor Yellow
} else {
  Write-Host ""
  Write-Host "==============================================" -ForegroundColor Cyan
  Write-Host "  Step 1: Installing llama-server" -ForegroundColor Cyan
  Write-Host "==============================================" -ForegroundColor Cyan
  Write-Host ""

  $LlamaArgs = @()
  if ($System) { $LlamaArgs += "--system" }

  & "$ScriptDir/install-llama-server.ps1" @LlamaArgs

  Write-Host ""
  Write-Host "=== Step 1 Complete: llama-server installed ===" -ForegroundColor Green
}

#==============================================================================
# Step 2: Install bifrost-http
#==============================================================================
if ($SkipBifrost) {
  Write-Host ""
  Write-Host "=== SKIPPING: bifrost-http installation ===" -ForegroundColor Yellow
} else {
  Write-Host ""
  Write-Host "==============================================" -ForegroundColor Cyan
  Write-Host "  Step 2: Installing bifrost-http" -ForegroundColor Cyan
  Write-Host "==============================================" -ForegroundColor Cyan
  Write-Host ""

  $BifrostArgs = @()
  if ($System) { $BifrostArgs += "--system" }

  & "$ScriptDir/install-bifrost.ps1" @BifrostArgs

  Write-Host ""
  Write-Host "=== Step 2 Complete: bifrost-http installed ===" -ForegroundColor Green
}

#==============================================================================
# Step 3: Install goose
#==============================================================================
if ($SkipGoose) {
  Write-Host ""
  Write-Host "=== SKIPPING: goose installation ===" -ForegroundColor Yellow
} else {
  Write-Host ""
  Write-Host "==============================================" -ForegroundColor Cyan
  Write-Host "  Step 3: Installing goose" -ForegroundColor Cyan
  Write-Host "==============================================" -ForegroundColor Cyan
  Write-Host ""

  $GooseArgs = @()
  if ($System) { $GooseArgs += "--system" }

  & "$ScriptDir/install-goose.ps1" @GooseArgs

  Write-Host ""
  Write-Host "=== Step 3 Complete: goose installed ===" -ForegroundColor Green
}

#==============================================================================
# Final summary
#==============================================================================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  All-in-One Installation Complete" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stack:"
Write-Host "  llama-server: port 9931 (local inference)"
Write-Host "  bifrost-http:  port 8080 (AI Gateway)"
Write-Host "  goose:         port 3284 (ACP server)"
Write-Host ""
Write-Host "Providers registered in goose:"
Write-Host "  - bifrost (AI Gateway): http://127.0.0.1:8080/v1"
Write-Host "  - llama-server: http://127.0.0.1:9931/v1"
Write-Host ""
Write-Host "MCP servers in goose:"
Write-Host "  - bifrost-mcp: http://127.0.0.1:8080/mcp (Gateway mode)"
Write-Host ""
$SystemFlag = if ($System) { " --system" } else { "" }
Write-Host "To uninstall (reverse order):"
Write-Host "  ./uninstall-goose.ps1$SystemFlag"
Write-Host "  ./uninstall-bifrost.ps1$SystemFlag"
Write-Host "  ./uninstall-llama-server.ps1$SystemFlag"
Write-Host ""
Write-Host "Or use the all-in-one uninstaller:"
Write-Host "  ./uninstall-all.ps1$SystemFlag"
Write-Host ""
Write-Host "Service status:"
Write-Host "  Get-Service -Name llama-server -ErrorAction SilentlyContinue"
Write-Host "  Get-Service -Name bifrost-http -ErrorAction SilentlyContinue"
Write-Host "  Get-Service -Name goose -ErrorAction SilentlyContinue"
Write-Host ""
Write-Host "Test endpoints:"
Write-Host "  Invoke-WebRequest http://127.0.0.1:9931/v1/models"
Write-Host "  Invoke-WebRequest http://127.0.0.1:8080/api_config"
Write-Host "  Invoke-WebRequest http://127.0.0.1:3284/"
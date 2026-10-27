#!/usr/bin/env pwsh
#==============================================================================
# Goose Installation Script for Windows
# Installs goose as ACP server, configures providers (bifrost, llama-server)
# and MCP servers (bifrost Gateway)
# Supports --system (system-wide) and --user (per-user) deployment modes
# Non-destructive: skips existing files and configurations
#==============================================================================
[CmdletBinding()]
param(
  [switch]$System,
  [string]$GooseBinary,
  [string]$GooseArgs,
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: ./install-goose.ps1 [--system] [--goose-binary <path>] [--goose-args <args>] [--help]"
  Write-Host ""
  Write-Host "  --system         System-wide deployment (default: user deployment)"
  Write-Host "  --goose-binary   Path to existing goose binary (skip download)"
  Write-Host "  --goose-args     Extra arguments to pass to goose serve"
  Write-Host "  --help           Show this help message"
  Write-Host ""
  Write-Host "Ports:"
  Write-Host "  goose: 3284"
  Write-Host "  bifrost-http: 8080"
  Write-Host "  llama-server: 9931"
  exit 0
}

$ErrorActionPreference = "Stop"

#==============================================================================
# Default configuration
#==============================================================================
$ServerName = "goose"
$ServiceUser = "goose"
$ServiceGroup = "goose"
$GoosePort = 3284
$BifrostPort = 8080
$LlamaPort = 9931
$RestartMode = "always"
$RestartSeconds = 10s

# Determine deployment mode
$IsSystem = $System.IsPresent -or ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

if ($IsSystem) {
  $BinaryDir = "C:\Program Files\goose"
  $BinaryPath = Join-Path $BinaryDir "goose.exe"
  $WorkingDir = "C:\ProgramData\goose"
  $ConfigDir = "C:\ProgramData\goose\config"
  $ConfigFile = Join-Path $ConfigDir "config.yaml"
  $LogPath = Join-Path $WorkingDir "goose.log"
  $EnvFile = Join-Path $ConfigDir "goose.env"
} else {
  $BinaryDir = Join-Path $env:LOCALAPPDATA "bin"
  $BinaryPath = Join-Path $BinaryDir "goose.exe"
  $WorkingDir = Join-Path $env:APPDATA "goose"
  $ConfigDir = Join-Path $env:APPDATA "goose\config"
  $ConfigFile = Join-Path $ConfigDir "config.yaml"
  $LogPath = Join-Path $WorkingDir "goose.log"
  $EnvFile = Join-Path $ConfigDir "goose.env"
}

Write-Host "goose installation mode: $($IsSystem ? "system" : "user")"
Write-Host "Binary path: $BinaryPath"
Write-Host "Config file: $ConfigFile"
Write-Host "Working dir: $WorkingDir"

#==============================================================================
# Download helper
#==============================================================================
function Download-File {
  param(
    [string]$Url,
    [string]$Destination
  )
  
  if (Test-Path $Destination) {
    Write-Host "  File already exists at $Destination, skipping download."
    return $true
  }
  
  Write-Host "  Downloading from $Url..."
  try {
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
    $ProgressPreference = "Continue"
    return $true
  } catch {
    Write-Host "  Failed to download $Url : $_" -ForegroundColor Yellow
    return $false
  }
}

#==============================================================================
# Detect and install goose binary
#==============================================================================
Write-Host "Detecting goose binary..."

$GooseBinaryFound = $false

# Check for existing goose binary
if ($GooseBinary) {
  $BinaryPath = $GooseBinary
  $GooseBinaryFound = $true
  Write-Host "  Using existing goose binary: $BinaryPath"
} elseif (Get-Command goose -ErrorAction SilentlyContinue) {
  $BinaryPath = (Get-Command goose).Source
  $GooseBinaryFound = $true
  Write-Host "Found goose in PATH: $BinaryPath"
} elseif (Test-Path "$env:LOCALAPPDATA\bin\goose.exe") {
  $BinaryPath = "$env:LOCALAPPDATA\bin\goose.exe"
  $GooseBinaryFound = $true
  Write-Host "Found goose at $env:LOCALAPPDATA\bin\goose.exe"
} elseif (Test-Path "C:\Program Files\goose\goose.exe") {
  $BinaryPath = "C:\Program Files\goose\goose.exe"
  $GooseBinaryFound = $true
  Write-Host "Found goose at C:\Program Files\goose\goose.exe"
}

# If not found, download from GitHub releases
if (-not $GooseBinaryFound) {
  Write-Host "Goose binary not found. Downloading from GitHub releases..."
  
  $Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
  $OsName = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
  
  $GooseArch = switch -Regex ($Arch) {
    "X64"   { "x86_64" }
    "Arm64" { "aarch64" }
    default { throw "Error: Architecture not supported: $Arch" }
  }
  
  $GooseOs = "windows"
  $GooseUrl = "https://github.com/aaif-goose/goose/releases/download/stable/goose-$GooseOs-$GooseArch.exe"
  
  $TempDir = Join-Path $env:TEMP "goose-install-$(Get-Random)"
  New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
  
  $GooseDownloadDest = Join-Path $TempDir "goose.exe"
  
  if (-not (Download-File -Url $GooseUrl -Destination $GooseDownloadDest)) {
    throw "Error: Failed to download goose from $GooseUrl"
  }
  
  $BinaryPathForInstall = $GooseDownloadDest
} else {
  $BinaryPathForInstall = $BinaryPath
}

# Verify binary
if (-not (Test-Path $BinaryPathForInstall)) {
  throw "Error: Goose binary not found at $BinaryPathForInstall"
}

Write-Host "Goose binary: $BinaryPathForInstall"

#==============================================================================
# Install binary
#==============================================================================
Write-Host "Installing goose binary..."

if (-not (Test-Path $BinaryDir)) {
  New-Item -ItemType Directory -Path $BinaryDir -Force | Out-Null
}

if (Test-Path $BinaryPath) {
  Write-Host "  Binary already exists at $BinaryPath, keeping existing." -ForegroundColor Yellow
} else {
  Write-Host "Installing goose to $BinaryPath..."
  Copy-Item -Path $BinaryPathForInstall -Destination $BinaryPath -Force
}

if (-not (Test-Path $BinaryPath)) {
  throw "Error: Goose not installed at $BinaryPath"
}

Write-Host "Goose binary found at $BinaryPath"

#==============================================================================
# Create directories
#==============================================================================
foreach ($dir in @($WorkingDir, $ConfigDir, (Split-Path -Parent $LogPath))) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
}

#==============================================================================
# Discover bifrost virtual key and llama-server model dynamically
#==============================================================================
$BifrostBaseUrl = "http://127.0.0.1:$BifrostPort"
$LlamaBaseUrl = "http://127.0.0.1:$LlamaPort"

# Read BIFROST_SETUP_TOKEN from bifrost env file if available
$BifrostSetupToken = ""
$BifrostEnvFile = Join-Path $env:APPDATA "bifrost\service.env"
if (-not (Test-Path $BifrostEnvFile)) {
  $BifrostEnvFile = "C:\ProgramData\bifrost\service.env"
}
if (Test-Path $BifrostEnvFile) {
  $EnvContent = Get-Content $BifrostEnvFile -Raw
  $Match = [regex]::Match($EnvContent, '(?m)^BIFROST_SETUP_TOKEN=(.*)$')
  if ($Match.Success) {
    $BifrostSetupToken = $Match.Groups[1].Value.Trim()
  }
}

# Discover BIFROST_VK from bifrost-http governance API
$BifrostVk = ""
Write-Host "Discovering bifrost virtual key from $BifrostBaseUrl..."

try {
  $VkResponse = Invoke-WebRequest -Uri "$BifrostBaseUrl/api/v1/governance/virtual-keys" `
    -Headers @{ "X-Bifrost-Setup-Token" = $BifrostSetupToken } `
    -UseBasicParsing -ErrorAction Stop
  $VkData = $VkResponse.Content | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
  
  if ($VkData) {
    # Try different response shapes
    $Keys = $null
    if ($VkData.PSObject.Properties.Name -contains "keys") {
      $Keys = $VkData.keys
    } elseif ($VkData -is [array]) {
      $Keys = $VkData
    }
    
    if ($Keys -and $Keys.Count -gt 0) {
      $BifrostVk = $Keys[0].value
      Write-Host "  Discovered BIFROST_VK from API"
    }
  }
} catch {
  Write-Host "  Warning: Could not discover BIFROST_VK from bifrost-http API" -ForegroundColor Yellow
}

if (-not $BifrostVk) {
  Write-Host "  Warning: Could not discover BIFROST_VK from bifrost-http API" -ForegroundColor Yellow
  Write-Host "  Ensure bifrost-http is running and setup is complete"
  $BifrostVk = "CHANGE_ME"
}

Write-Host "BIFROST_VK: $BifrostVk"

# Discover llama-server model from /v1/models endpoint
$LlamaModel = "JetBrains/Mellum2.1-12B-A2.5B-Thinking-GGUF:Q4_K_M"
Write-Host "Discovering llama-server model from $LlamaBaseUrl/v1/models..."

try {
  $ModelsResponse = Invoke-WebRequest -Uri "$LlamaBaseUrl/v1/models" -UseBasicParsing -ErrorAction Stop
  $ModelsData = $ModelsResponse.Content | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
  
  if ($ModelsData -and $ModelsData.PSObject.Properties.Name -contains "data") {
    $FirstModel = $ModelsData.data[0]
    if ($FirstModel -and $FirstModel.id) {
      $LlamaModel = $FirstModel.id
      Write-Host "  Discovered model: $LlamaModel"
    }
  }
} catch {
  Write-Host "  Warning: Could not discover model from llama-server, using default: $LlamaModel" -ForegroundColor Yellow
}

Write-Host "Llama model: $LlamaModel"

#==============================================================================
# Create service environment file (only if it doesn't exist)
#==============================================================================
Write-Host "Creating service environment file at $EnvFile..."

if (Test-Path $EnvFile) {
  Write-Host "  Service environment file already exists, preserving existing config." -ForegroundColor Yellow
} else {
  @"
# Environment variables for $ServerName
# Sourced by the Windows service wrapper

GOOSE_PORT=$GoosePort
GOOSE_HOST=127.0.0.1
GOOSE_PATH_ROOT=$WorkingDir
GOOSE_WORKING_DIR=$WorkingDir
GOOSE_CONFIG_DIR=$ConfigDir
GOOSE_LOG_PATH=$LogPath
BIFROST_HOST=127.0.0.1
BIFROST_PORT=$BifrostPort
BIFROST_VK=$BifrostVk
LLAMA_ARG_HOST=127.0.0.1
LLAMA_ARG_PORT=$LlamaPort
LOG_LEVEL=info
"@ | Out-File -FilePath $EnvFile -Encoding utf8
}

#==============================================================================
# Create goose configuration YAML (only if it doesn't exist)
#==============================================================================
Write-Host "Creating goose configuration at $ConfigFile..."

if (Test-Path $ConfigFile) {
  Write-Host "  Service config file already exists, preserving existing config." -ForegroundColor Yellow
} else {
  $ConfigContent = @"
# Goose Configuration
# Generated by install-goose.ps1

GOOSE_TELEMETRY_ENABLED: false
GOOSE_PORT: $GoosePort
GOOSE_HOST: 127.0.0.1

# Provider: bifrost (AI Gateway)
providers:
  bifrost:
    enabled: true
    model: default
    base_url: http://127.0.0.1:$BifrostPort/v1
    api_key: "$BifrostVk"
    configured: true

# Provider: llama-server (local inference)
  llama-server:
    enabled: true
    model: $LlamaModel
    base_url: http://127.0.0.1:$LlamaPort/v1
    api_key: ""
    configured: true

active_provider: bifrost

# MCP Server: bifrost (Gateway mode - connects to bifrost-http MCP Gateway endpoint)
extensions:
  bifrost-mcp:
    enabled: true
    type: http
    name: Bifrost MCP Gateway
    description: Bifrost AI Gateway as MCP server (Gateway mode)
    url: http://127.0.0.1:$BifrostPort/mcp
    headers:
      X-Bifrost-Setup-Token: "$BifrostVk"
    timeout: 300
    bundled: null

OPENAI_BASE_URL: http://127.0.0.1:$BifrostPort/v1
OPENAI_HOST: http://127.0.0.1:$BifrostPort
OPENAI_TIMEOUT: '600'
OPENAI_BASE_PATH: v1/chat/completions
LLAMA_HOST: http://127.0.0.1:$LlamaPort
GOOSE_THINKING_EFFORT: max
GOOSE_AUTO_COMPACT_TOKEN_LIMIT: 800000
"@
  $ConfigContent | Out-File -FilePath $ConfigFile -Encoding utf8
}

Write-Host "Goose configuration written to $ConfigFile"

#==============================================================================
# Create Windows service using NSSM
#==============================================================================
Write-Host "Creating Windows service..."

$NssmPath = Get-Command nssm -ErrorAction SilentlyContinue
if (-not $NssmPath) {
  Write-Host "NSSM not found. Installing via winget..." -ForegroundColor Yellow
  winget install nssm --accept-package-agreements --accept-source-agreements 2>$null
  $NssmPath = Get-Command nssm -ErrorAction SilentlyContinue
  if (-not $NssmPath) {
    Write-Host "Warning: NSSM installation via winget failed. Service will not be created automatically." -ForegroundColor Yellow
  }
}

if ($NssmPath) {
  Write-Host "  Using NSSM at $NssmPath to create service $ServerName..."
  
  # Stop and remove existing service
  & $NssmPath stop $ServerName 2>$null
  & $NssmPath remove $ServerName -confirm 2>$null
  
  # Create service
  $GooseArgsStr = if ($GooseArgs) { " $GooseArgs" } else { "" }
  & $NssmPath install $ServerName $BinaryPath "serve --dangerously-unauthenticated --host 127.0.0.1 --port $GoosePort$GooseArgsStr"
  & $NssmPath set $ServerName DisplayName "goose ACP Server"
  & $NssmPath set $ServerName Description "Goose AI Agent ACP server"
  & $NssmPath set $ServerName Start SERVICE_AUTO_START
  & $NssmPath set $ServerName RestartDelay $RestartSeconds.TotalSeconds
  & $NssmPath set $ServerName AppDirectory $WorkingDir
  & $NssmPath set $ServerName AppStdout $LogPath
  & $NssmPath set $ServerName AppStderr $LogPath
  & $NssmPath set $ServerName RotateFiles 1
  & $NssmPath set $ServerName RotateOnline 1
  
  # Set environment variables
  $EnvExtra = "GOOSE_PORT=$GoosePort;GOOSE_HOST=127.0.0.1;GOOSE_PATH_ROOT=$WorkingDir;BIFROST_HOST=127.0.0.1;BIFROST_PORT=$BifrostPort;BIFROST_VK=$BifrostVk;LLAMA_ARG_HOST=127.0.0.1;LLAMA_ARG_PORT=$LlamaPort;LOG_LEVEL=info"
  & $NssmPath set $ServerName EnvExtra $EnvExtra
  
  # Start the service
  try {
    & $NssmPath start $ServerName
    Write-Host "  Service $ServerName started." -ForegroundColor Green
  } catch {
    Write-Host "  Warning: Could not start service $ServerName. You may need to start it manually." -ForegroundColor Yellow
  }
} else {
  Write-Host "  NSSM not available. Service not created automatically." -ForegroundColor Yellow
  Write-Host "  To create the service manually, install NSSM (winget install nssm) and run:"
  Write-Host "    nssm install $ServerName `"$BinaryPath`" serve --dangerously-unauthenticated --host 127.0.0.1 --port $GoosePort"
  Write-Host "    nssm start $ServerName"
}

#==============================================================================
# Wait for goose to be ready
#==============================================================================
Write-Host "Waiting for goose ACP server to be ready on port $GoosePort..."
$Ready = $false
for ($i = 1; $i -le 30; $i++) {
  try {
    $Response = Invoke-WebRequest -Uri "http://localhost:$GoosePort/" -UseBasicParsing -ErrorAction Stop
    $Ready = $true
    Write-Host "goose ACP server is ready" -ForegroundColor Green
    break
  } catch {
    Write-Host "  Waiting... ($i/30)"
    Start-Sleep -Seconds 2
  }
}

if (-not $Ready) {
  Write-Host "Warning: goose did not become ready within 60 seconds." -ForegroundColor Yellow
}

#==============================================================================
# Final status
#==============================================================================
Write-Host ""
Write-Host "Goose service installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Installation summary:"
Write-Host "  Binary:       $BinaryPath"
Write-Host "  Working Dir:  $WorkingDir"
Write-Host "  Config Dir:   $ConfigDir"
Write-Host "  Config File:  $ConfigFile"
Write-Host "  Env File:     $EnvFile"
Write-Host "  Log Path:     $LogPath"
Write-Host "  Goose Port:   $GoosePort"
Write-Host "  Bifrost Port: $BifrostPort"
Write-Host "  Llama Port:   $LlamaPort"
Write-Host "  BIFROST_VK:   $BifrostVk"
Write-Host "  Llama Model:  $LlamaModel"
Write-Host ""
Write-Host "Providers configured:"
Write-Host "  - bifrost (AI Gateway): http://127.0.0.1:$BifrostPort/v1"
Write-Host "  - llama-server: http://127.0.0.1:$LlamaPort/v1 (model: $LlamaModel)"
Write-Host ""
Write-Host "MCP servers configured:"
Write-Host "  - bifrost-mcp: http://127.0.0.1:$BifrostPort/mcp (Gateway mode)"
Write-Host ""
Write-Host "To start manually:"
Write-Host "  & `"$BinaryPath`" serve --dangerously-unauthenticated --host 127.0.0.1 --port $GoosePort"
Write-Host ""
Write-Host "Service status:"
Write-Host "  Get-Service -Name $ServerName -ErrorAction SilentlyContinue"
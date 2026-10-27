#!/usr/bin/env pwsh
#==============================================================================
# Bifrost-http Installation Script for Windows
# Installs bifrost and bifrost-http binaries, configures via API with idempotency
# Supports --system (system-wide) and --user (per-user) deployment modes
# Non-destructive: skips existing files and configurations
# Idempotent API calls: GET-before-POST/PUT to avoid duplicates
#==============================================================================
[CmdletBinding()]
param(
  [switch]$System,
  [string]$Prefix = "C:\Program Files",
  [string]$BifrostBinary,
  [string]$BifrostCliBinary,
  [string]$BifrostArgs,
  [string]$BifrostVersion = "latest",
  [string]$BifrostHttpVersion = "v2.3.2",
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: ./install-bifrost.ps1 [--system] [--prefix <path>] [--bifrost-binary <path>] [--bifrost-cli-binary <path>] [--bifrost-args <args>] [--help]"
  Write-Host ""
  Write-Host "  --system            System-wide deployment (default: user deployment)"
  Write-Host "  --prefix            Installation prefix (default: C:\Program Files)"
  Write-Host "  --bifrost-binary    Path to existing bifrost-http binary (skip download)"
  Write-Host "  --bifrost-cli-binary Path to existing bifrost CLI binary (skip download)"
  Write-Host "  --bifrost-args      Extra arguments to pass to bifrost-http"
  Write-Host "  --bifrost-version   Bifrost CLI version (default: latest)"
  Write-Host "  --bifrost-http-version Bifrost-http version (default: v2.3.2)"
  Write-Host "  --help              Show this help message"
  Write-Host ""
  Write-Host "Ports:"
  Write-Host "  bifrost-http: 8080"
  exit 0
}

$ErrorActionPreference = "Stop"

#==============================================================================
# Default configuration
#==============================================================================
$ServerName = "bifrost-http"
$ServiceUser = "bifrost"
$ServiceGroup = "bifrost"
$DefaultAdminPassword = "ChangeMe"
$BifrostPort = 8080
$RestartMode = "always"
$RestartSeconds = 10s
$BaseUrl = "https://downloads.getmaxim.ai"

# Determine deployment mode
$IsSystem = $System.IsPresent -or ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

if ($IsSystem) {
  $BinaryDir = Join-Path $Prefix "bin"
  $BinaryPath = Join-Path $BinaryDir "bifrost-http.exe"
  $BinaryCliPath = Join-Path $BinaryDir "bifrost.exe"
  $AppDir = "C:\ProgramData\bifrost"
  $WorkingDir = $AppDir
  $LogPath = Join-Path $AppDir "bifrost.log"
  $EnvFile = Join-Path $AppDir "service.env"
  $ConfigStorePath = Join-Path $AppDir "config.db"
  $LogsStorePath = Join-Path $AppDir "logs.db"
} else {
  $BinaryDir = Join-Path $env:LOCALAPPDATA "bin"
  $BinaryPath = Join-Path $BinaryDir "bifrost-http.exe"
  $BinaryCliPath = Join-Path $BinaryDir "bifrost.exe"
  $AppDir = Join-Path $env:APPDATA "bifrost"
  $WorkingDir = $AppDir
  $LogPath = Join-Path $AppDir "bifrost.log"
  $EnvFile = Join-Path $AppDir "service.env"
  $ConfigStorePath = Join-Path $AppDir "config.db"
  $LogsStorePath = Join-Path $AppDir "logs.db"
}

# Detect OS architecture for download
$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
$PlatformDir = "windows"
$ArchName = switch -Regex ($Arch) {
  "X64"   { "amd64" }
  "Arm64" { "arm64" }
  default { throw "Error: Architecture not supported: $Arch" }
}

$BifrostBinaryName = "bifrost-http.exe"
$BifrostCliBinaryName = "bifrost.exe"

Write-Host "bifrost-http installation mode: $($IsSystem ? "system" : "user")"
Write-Host "Binary path: $BinaryPath"
Write-Host "App dir: $AppDir"

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
# Create directories
#==============================================================================
Write-Host "Creating installation directories..."
foreach ($dir in @($BinaryDir, $AppDir, (Split-Path -Parent $LogPath))) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  Created: $dir"
  }
}

#==============================================================================
# Download and install binaries
#==============================================================================
Write-Host "Downloading bifrost binaries..."

# Download bifrost CLI
if ($BifrostCliBinary) {
  $BinaryCliPath = $BifrostCliBinary
  Write-Host "  Using existing bifrost CLI: $BinaryCliPath"
} else {
  $BifrostCliUrl = "$BaseUrl/bifrost-cli/$BifrostVersion/$PlatformDir/$ArchName/$BifrostCliBinaryName"
  Write-Host "Downloading bifrost CLI from $BifrostCliUrl..."
  
  $Downloaded = Download-File -Url $BifrostCliUrl -Destination $BinaryCliPath
  
  if (-not $Downloaded -and $BifrostVersion -ne "latest") {
    Write-Host "  Retrying with 'latest' version..." -ForegroundColor Yellow
    $BifrostVersion = "latest"
    $BifrostCliUrl = "$BaseUrl/bifrost-cli/$BifrostVersion/$PlatformDir/$ArchName/$BifrostCliBinaryName"
    $Downloaded = Download-File -Url $BifrostCliUrl -Destination $BinaryCliPath
  }
  
  if (-not $Downloaded) {
    throw "Error: Failed to download bifrost CLI"
  }
}

# Download bifrost-http
if ($BifrostBinary) {
  $BinaryPath = $BifrostBinary
  Write-Host "  Using existing bifrost-http binary: $BinaryPath"
} else {
  $BifrostHttpUrl = "$BaseUrl/bifrost/$BifrostHttpVersion/$PlatformDir/$ArchName/$BifrostBinaryName"
  Write-Host "Downloading bifrost-http from $BifrostHttpUrl..."
  
  $Downloaded = Download-File -Url $BifrostHttpUrl -Destination $BinaryPath
  
  if (-not $Downloaded -and $BifrostHttpVersion -ne "latest") {
    Write-Host "  Retrying with 'latest' version..." -ForegroundColor Yellow
    $BifrostHttpVersion = "latest"
    $BifrostHttpUrl = "$BaseUrl/bifrost/$BifrostHttpVersion/$PlatformDir/$ArchName/$BifrostBinaryName"
    $Downloaded = Download-File -Url $BifrostHttpUrl -Destination $BinaryPath
  }
  
  if (-not $Downloaded) {
    throw "Error: Failed to download bifrost-http"
  }
}

Write-Host "Installed bifrost CLI to $BinaryCliPath"
Write-Host "Installed bifrost-http to $BinaryPath"

#==============================================================================
# Generate setup token
#==============================================================================
Write-Host "Generating BIFROST_SETUP_TOKEN..."
$BifrostSetupToken = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32) | ForEach-Object { $_.ToString("x2") } -join ""
Write-Host "BIFROST_SETUP_TOKEN generated (length: $($BifrostSetupToken.Length))"

#==============================================================================
# Create service environment file (only if it doesn't exist)
#==============================================================================
Write-Host "Creating service environment file at $EnvFile..."

if (Test-Path $EnvFile) {
  Write-Host "  Service environment file already exists, preserving existing config." -ForegroundColor Yellow
} else {
  # Determine BIFROST_APP_DIR: check if config.db exists in AppDir
  if (Test-Path $ConfigStorePath) {
    $BifrostAppDir = $AppDir
  } else {
    $BifrostAppDir = Join-Path $env:TEMP "bifrost-app"
    if (-not (Test-Path $BifrostAppDir)) {
      New-Item -ItemType Directory -Path $BifrostAppDir -Force | Out-Null
    }
  }
  
  @"
# Environment variables for $ServerName
# These are sourced by the Windows service wrapper

BIFROST_HOST=localhost
BIFROST_PORT=$BifrostPort
BIFROST_SETUP_TOKEN=$BifrostSetupToken
BIFROST_ADMIN_USERNAME="bifrost"
BIFROST_ADMIN_PASSWORD="$DefaultAdminPassword"
BIFROST_APP_DIR=$BifrostAppDir
LLAMA_ARG_HOST=127.0.0.1
LLAMA_ARG_PORT=9931
LOG_LEVEL=info
BINARY_PATH=$BinaryPath
HTTP_BINARY_PATH=$BinaryPath
WORKING_DIR=$WorkingDir
LOG_PATH=$LogPath
APP_DIR=$AppDir
CONFIG_STORE_PATH=$ConfigStorePath
LOGS_STORE_PATH=$LogsStorePath
GOVERNANCE_ADMIN_USERNAME="bifrost"
GOVERNANCE_ADMIN_PASSWORD="$DefaultAdminPassword"
GOVERNANCE_CHANGE_ON_LOGON=true
"@ | Out-File -FilePath $EnvFile -Encoding utf8
}

#==============================================================================
# Build ExecStart command
#==============================================================================
$BifrostArgsStr = if ($BifrostArgs) { " $BifrostArgs" } else { "" }

$BifrostPortEnv = $env:BIFROST_PORT
if (-not $BifrostPortEnv) { $BifrostPortEnv = $BifrostPort }

if ($IsSystem) {
  $ExecStartCmd = """$BinaryPath"" -port $BifrostPortEnv --app-dir $AppDir$BifrostArgsStr"
} else {
  $ExecStartCmd = """$BinaryPath"" -port $BifrostPortEnv$BifrostArgsStr"
}

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
  & $NssmPath install $ServerName $BinaryPath "-port 8080 --app-dir $AppDir $BifrostArgsStr"
  & $NssmPath set $ServerName DisplayName "bifrost-http"
  & $NssmPath set $ServerName Description "Bifrost AI Gateway HTTP service"
  & $NssmPath set $ServerName Start SERVICE_AUTO_START
  & $NssmPath set $ServerName RestartDelay $RestartSeconds.TotalSeconds
  & $NssmPath set $ServerName AppDirectory $AppDir
  & $NssmPath set $ServerName AppStdout $LogPath
  & $NssmPath set $ServerName AppStderr $LogPath
  & $NssmPath set $ServerName RotateFiles 1
  & $NssmPath set $ServerName RotateOnline 1
  
  # Set environment variables
  $EnvExtra = "BIFROST_HOST=localhost;BIFROST_PORT=$BifrostPort;BIFROST_SETUP_TOKEN=$BifrostSetupToken;BIFROST_APP_DIR=$BifrostAppDir;LLAMA_ARG_HOST=127.0.0.1;LLAMA_ARG_PORT=9931;LOG_LEVEL=info"
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
  Write-Host "    nssm install $ServerName `"$BinaryPath`" -port 8080 --app-dir $AppDir"
  Write-Host "    nssm start $ServerName"
}

#==============================================================================
# Wait for bifrost-http to be ready
#==============================================================================
Write-Host "Waiting for bifrost-http to be ready on port $BifrostPort..."
$BifrostUrl = "http://localhost:$BifrostPort"
$Ready = $false
for ($i = 1; $i -le 30; $i++) {
  try {
    $Response = Invoke-WebRequest -Uri "$BifrostUrl/api/config" -UseBasicParsing -ErrorAction Stop
    $Ready = $true
    Write-Host "bifrost-http is ready" -ForegroundColor Green
    break
  } catch {
    Write-Host "  Waiting... ($i/30)"
    Start-Sleep -Seconds 2
  }
}

if (-not $Ready) {
  Write-Host "Warning: bifrost-http did not become ready within 60 seconds. API setup may fail." -ForegroundColor Yellow
}

#==============================================================================
# Idempotent API helper functions
#==============================================================================
function Invoke-BifrostApi {
  param(
    [string]$Method,
    [string]$Endpoint,
    [string]$Payload = $null
  )
  
  $Headers = @{
    "X-Bifrost-Setup-Token" = $BifrostSetupToken
    "Content-Type" = "application/json"
  }
  
  $Splat = @{
    Uri         = "$BifrostUrl$Endpoint"
    Method      = $Method
    Headers     = $Headers
    UseBasicParsing = $true
    ErrorAction = "SilentlyContinue"
  }
  
  if ($Payload) {
    $Splat["Body"] = $Payload
  }
  
  try {
    $Response = Invoke-WebRequest @Splat
    $Body = $Response.Content | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
    return @{ StatusCode = $Response.StatusCode; Body = $Body; Raw = $Response.Content }
  } catch {
    if ($_.Exception.Response) {
      $StatusCode = [int]$_.Exception.Response.StatusCode
      $Body = $_.Exception.Response.GetResponseStream() | StreamReader -ReadToEnd | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
      return @{ StatusCode = $StatusCode; Body = $Body; Raw = $_.Exception.Response.GetResponseStream() | StreamReader -ReadToEnd }
    }
    return @{ StatusCode = 0; Body = $null; Raw = $_.Exception.Message }
  }
}

function Test-BifrostApiExists {
  param(
    [string]$Endpoint
  )
  
  $Result = Invoke-BifrostApi -Method "GET" -Endpoint $Endpoint
  return $Result.StatusCode -eq 200
}

#==============================================================================
# Complete setup via PUT /api/config (idempotent)
#==============================================================================
Write-Host "Completing bifrost setup via PUT /api/config..."

$AdminUsername = "bifrost"
$AdminPassword = $DefaultAdminPassword

$ConfigPayload = @{
    "$schema" = "https://www.getbifrost.ai/schema"
    "setup_token" = $BifrostSetupToken
    "client" = @{
        "enforce_auth_on_inference" = $true
        "log_retention_days" = 365
    }
    "governance" = @{
        "auth_config" = @{
            "admin_username" = $AdminUsername
            "admin_password" = $AdminPassword
            "is_enabled" = $true
        }
    }
} | ConvertTo-Json -Depth 10

# Check if setup is already complete (idempotency guard)
$ConfigExists = Test-BifrostApiExists -Endpoint "/api/config"
if ($ConfigExists) {
  Write-Host "  bifrost-http already configured (GET /api/config returned 200), skipping setup." -ForegroundColor Yellow
} else {
  $SetupResult = Invoke-BifrostApi -Method "PUT" -Endpoint "/api/config" -Payload $ConfigPayload
  if ($SetupResult.StatusCode -in @(200, 201, 204)) {
    Write-Host "  Bifrost setup completed successfully!" -ForegroundColor Green
  } else {
    Write-Host "  Warning: Setup call returned HTTP $($SetupResult.StatusCode). You may need to complete setup manually." -ForegroundColor Yellow
    Write-Host "  Response: $($SetupResult.Raw)"
  }
}

#==============================================================================
# Register llama-server as a provider (idempotent)
#==============================================================================
Write-Host "Registering llama-server as a provider in bifrost-http via API..."

# Generate virtual key value
$VkValue = "sk-vk-llama-server-$([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16) | ForEach-Object { $_.ToString('x2') } -join '')"

# 1. Register llama-server provider (idempotent: GET before POST)
$ProviderEndpoint = "/api/v1/providers/llama-server"
$ProviderExists = Test-BifrostApiExists -Endpoint $ProviderEndpoint

if ($ProviderExists) {
  Write-Host "  Provider 'llama-server' already exists, skipping." -ForegroundColor Yellow
} else {
  $ProviderPayload = @{
    "name" = "llama-server"
    "type" = "openai"
    "base_url" = "http://127.0.0.1:9931/v1"
    "api_key" = ""
    "status" = "active"
    "description" = "Llama.cpp server registered via install script"
  } | ConvertTo-Json -Depth 10
  
  $ProviderResult = Invoke-BifrostApi -Method "POST" -Endpoint "/api/v1/providers" -Payload $ProviderPayload
  if ($ProviderResult.StatusCode -in @(200, 201, 204)) {
    Write-Host "  Provider 'llama-server' registered successfully." -ForegroundColor Green
  } else {
    Write-Host "  Warning: Provider registration returned HTTP $($ProviderResult.StatusCode)" -ForegroundColor Yellow
  }
}

# 2. Register API key for the provider (idempotent)
$KeyEndpoint = "/api/v1/keys/llama-server-key"
$KeyExists = Test-BifrostApiExists -Endpoint $KeyEndpoint

if ($KeyExists) {
  Write-Host "  API key 'llama-server-key' already exists, skipping." -ForegroundColor Yellow
} else {
  $KeyPayload = @{
    "provider" = "llama-server"
    "key_id" = "llama-server-key"
    "name" = "llama-server-key"
    "value" = "sk-llama-server"
    "enabled" = $true
  } | ConvertTo-Json -Depth 10
  
  $KeyResult = Invoke-BifrostApi -Method "POST" -Endpoint "/api/v1/keys" -Payload $KeyPayload
  if ($KeyResult.StatusCode -in @(200, 201, 204)) {
    Write-Host "  API key 'llama-server-key' registered successfully." -ForegroundColor Green
  } else {
    Write-Host "  Warning: Key registration returned HTTP $($KeyResult.StatusCode)" -ForegroundColor Yellow
  }
}

# 3. Discover and register models from llama-server (idempotent)
Write-Host "Discovering llama-server models..."
$LlamaModels = @{}
try {
  $ModelsResponse = Invoke-WebRequest -Uri "http://localhost:9931/v1/models" -UseBasicParsing -ErrorAction Stop
  $LlamaModels = $ModelsResponse.Content | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
} catch {
  Write-Host "  Warning: Could not discover models from llama-server (not running yet?)" -ForegroundColor Yellow
}

$ModelNames = @()
if ($LlamaModels -and $LlamaModels.PSObject.Properties.Name -contains "data") {
  foreach ($m in $LlamaModels.data) {
    $ModelNames += $m.id
  }
}

if ($ModelNames.Count -gt 0) {
  Write-Host "  Discovered $($ModelNames.Count) model(s):"
  foreach ($ModelName in $ModelNames) {
    Write-Host "    - $ModelName"
    
    # Check if model already exists (idempotent)
    $ModelEndpoint = "/api/v1/models/$ModelName"
    $ModelExists = Test-BifrostApiExists -Endpoint $ModelEndpoint
    
    if ($ModelExists) {
      Write-Host "      Model '$ModelName' already exists, skipping." -ForegroundColor Yellow
    } else {
      $ModelPayload = @{
        "provider" = "llama-server"
        "model" = $ModelName
        "name" = $ModelName
      } | ConvertTo-Json -Depth 10
      
      $ModelResult = Invoke-BifrostApi -Method "POST" -Endpoint "/api/v1/models" -Payload $ModelPayload
      if ($ModelResult.StatusCode -in @(200, 201, 204)) {
        Write-Host "      Model '$ModelName' registered." -ForegroundColor Green
      } else {
        Write-Host "      Warning: Failed to register model '$ModelName' (HTTP $($ModelResult.StatusCode))" -ForegroundColor Yellow
      }
    }
  }
} else {
  Write-Host "  Warning: No models discovered from llama-server, skipping model registration" -ForegroundColor Yellow
}

# 4. Create routing rule (idempotent)
Write-Host "Creating routing rule..."
$RouteEndpoint = "/api/v1/routing-rules/route-llama-server"
$RouteExists = Test-BifrostApiExists -Endpoint $RouteEndpoint

if ($RouteExists) {
  Write-Host "  Routing rule 'route-llama-server' already exists, skipping." -ForegroundColor Yellow
} else {
  $RoutePayload = @{
    "id" = "route-llama-server"
    "name" = "Route to llama-server"
    "description" = "Route all requests to llama-server provider"
    "enabled" = $true
    "cel_expression" = "true"
    "scope" = "global"
    "priority" = 100
  } | ConvertTo-Json -Depth 10
  
  $RouteResult = Invoke-BifrostApi -Method "POST" -Endpoint "/api/v1/routing-rules" -Payload $RoutePayload
  if ($RouteResult.StatusCode -in @(200, 201, 204)) {
    Write-Host "  Routing rule 'route-llama-server' created." -ForegroundColor Green
  } else {
    Write-Host "  Warning: Routing rule creation returned HTTP $($RouteResult.StatusCode)" -ForegroundColor Yellow
  }
}

# 5. Create routing targets for each model (idempotent)
Write-Host "Creating routing targets..."
foreach ($ModelName in $ModelNames) {
  $TargetEndpoint = "/api/v1/routing-targets/route-llama-server-$ModelName"
  $TargetExists = Test-BifrostApiExists -Endpoint $TargetEndpoint
  
  if ($TargetExists) {
    Write-Host "  Routing target for '$ModelName' already exists, skipping." -ForegroundColor Yellow
    continue
  }
  
  $TargetPayload = @{
    "rule_id" = "route-llama-server"
    "provider" = "llama-server"
    "model" = $ModelName
    "key_id" = "llama-server-key"
    "weight" = 1.0
  } | ConvertTo-Json -Depth 10
  
  $TargetResult = Invoke-BifrostApi -Method "POST" -Endpoint "/api/v1/routing-targets" -Payload $TargetPayload
  if ($TargetResult.StatusCode -in @(200, 201, 204)) {
    Write-Host "  Routing target for '$ModelName' created." -ForegroundColor Green
  } else {
    Write-Host "  Warning: Failed to create routing target for '$ModelName' (HTTP $($TargetResult.StatusCode))" -ForegroundColor Yellow
  }
}

# 6. Create virtual key (idempotent)
Write-Host "Creating virtual key..."
$VkEndpoint = "/api/v1/governance/virtual-keys/vk-llama-server"
$VkExists = Test-BifrostApiExists -Endpoint $VkEndpoint

if ($VkExists) {
  Write-Host "  Virtual key 'vk-llama-server' already exists, skipping." -ForegroundColor Yellow
} else {
  $VkPayload = @{
    "id" = "vk-llama-server"
    "name" = "llama-server-key"
    "value" = $VkValue
    "is_active" = $true
    "allow_all_providers" = $true
  } | ConvertTo-Json -Depth 10
  
  $VkResult = Invoke-BifrostApi -Method "POST" -Endpoint "/api/v1/governance/virtual-keys" -Payload $VkPayload
  if ($VkResult.StatusCode -in @(200, 201, 204)) {
    Write-Host "  Virtual key 'vk-llama-server' created." -ForegroundColor Green
  } else {
    Write-Host "  Warning: Virtual key creation returned HTTP $($VkResult.StatusCode)" -ForegroundColor Yellow
  }
}

# 7. Create virtual key provider config (idempotent)
Write-Host "Creating virtual key provider config..."
$VkProviderEndpoint = "/api/v1/governance/virtual-key-provider-configs/vk-llama-server-llama-server"
$VkProviderExists = Test-BifrostApiExists -Endpoint $VkProviderEndpoint

if ($VkProviderExists) {
  Write-Host "  Virtual key provider config already exists, skipping." -ForegroundColor Yellow
} else {
  $ModelsJson = $ModelNames | ConvertTo-Json -Compress
  $VkProviderPayload = @{
    "virtual_key_id" = "vk-llama-server"
    "provider" = "llama-server"
    "allowed_models" = $ModelNames
    "blacklisted_models" = @()
    "allow_all_keys" = $true
    "weight" = 1.0
  } | ConvertTo-Json -Depth 10
  
  $VkProviderResult = Invoke-BifrostApi -Method "POST" -Endpoint "/api/v1/governance/virtual-key-provider-configs" -Payload $VkProviderPayload
  if ($VkProviderResult.StatusCode -in @(200, 201, 204)) {
    Write-Host "  Virtual key provider config created." -ForegroundColor Green
  } else {
    Write-Host "  Warning: Virtual key provider config returned HTTP $($VkProviderResult.StatusCode)" -ForegroundColor Yellow
  }
}

#==============================================================================
# Final status
#==============================================================================
Write-Host ""
Write-Host "Bifrost service installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Installation summary:"
Write-Host "  Binary:          $BinaryPath"
Write-Host "  CLI Binary:      $BinaryCliPath"
Write-Host "  Working Dir:     $WorkingDir"
Write-Host "  App Dir:         $AppDir"
Write-Host "  Config Store:    $ConfigStorePath"
Write-Host "  Logs Store:      $LogsStorePath"
Write-Host "  Log Path:        $LogPath"
Write-Host "  Env File:        $EnvFile"
Write-Host "  Setup Token:     $BifrostSetupToken"
Write-Host "  Admin User:      $AdminUsername"
Write-Host "  Admin Password:  $DefaultAdminPassword"
Write-Host "  Virtual Key:     $VkValue"
Write-Host ""
Write-Host "To complete setup manually (if not done above):"
$setupBody = @{
    '$schema' = "https://www.getbifrost.ai/schema"
    setup_token = $BifrostSetupToken
    client = @{
        enforce_auth_on_inference = $true
    }
    governance = @{
        auth_config = @{
            admin_username = "bifrost"
            admin_password = $DefaultAdminPassword
            is_enabled = $true
        }
    }
} | ConvertTo-Json -Depth 10
Write-Host "  Invoke-WebRequest -Method PUT -Uri http://localhost:$BifrostPort/api_config"
Write-Host "    -Headers @{`"X-Bifrost-Setup-Token`"=`"$BifrostSetupToken`";`"Content-Type`"=`"application/json`"}"
Write-Host "    -Body $setupBody"
Write-Host ""
Write-Host "Service status:"
Write-Host "  Get-Service -Name $ServerName -ErrorAction SilentlyContinue"
Write-Host "  Or test endpoint: Invoke-WebRequest http://127.0.0.1:$BifrostPort/api_config"
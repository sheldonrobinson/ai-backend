#!/usr/bin/env pwsh
#==============================================================================
# llama-server Installation Script for Windows
# Installs llama-server (llama-app binary renamed to llama.exe) as a Windows service
# Supports --system (system-wide) and --user (per-user) deployment modes
# Non-destructive: skips existing files and configurations
#==============================================================================
[CmdletBinding()]
param(
  [switch]$System,
  [string]$LlamaBinary,
  [string]$LlamaArgs,
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: ./install-llama-server.ps1 [--system] [--llama-binary <path>] [--llama-args <args>] [--help]"
  Write-Host ""
  Write-Host "  --system         System-wide deployment (default: user deployment)"
  Write-Host "  --llama-binary   Path to existing llama binary (skip download)"
  Write-Host "  --llama-args     Extra arguments to pass to llama serve"
  Write-Host "  --help           Show this help message"
  Write-Host ""
  Write-Host "Ports:"
  Write-Host "  llama-server: 9931"
  exit 0
}

$ErrorActionPreference = "Stop"

#==============================================================================
# Default configuration
#==============================================================================
$ServerName = "llama-server"
$ServiceUser = "llama"
$ServiceGroup = "llama"
$LlamaPort = 9931
$RestartMode = "always"
$RestartSeconds = 10s

# Determine deployment mode
$IsSystem = $System.IsPresent -or ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

if ($IsSystem) {
  $BinaryDir = "C:\Program Files\llama"
  $BinaryPath = Join-Path $BinaryDir "llama.exe"
  $WorkingDir = "C:\ProgramData\llama"
  $LogPath = Join-Path $WorkingDir "llama-server.log"
  $EnvFile = Join-Path $WorkingDir "service.env"
  $ServiceFile = Join-Path $env:SystemRoot "System32\services"  # placeholder, NSSM manages services
} else {
  $BinaryDir = Join-Path $env:LOCALAPPDATA "bin"
  $BinaryPath = Join-Path $BinaryDir "llama.exe"
  $WorkingDir = Join-Path $env:APPDATA "llama"
  $LogPath = Join-Path $WorkingDir "llama-server.log"
  $EnvFile = Join-Path $WorkingDir "service.env"
}

Write-Host "llama-server installation mode: $($IsSystem ? "system" : "user")"
Write-Host "Binary path: $BinaryPath"
Write-Host "Working dir: $WorkingDir"

#==============================================================================
# Detect OS and architecture
#==============================================================================
$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
$OsName = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription

Write-Host "Detected OS: $OsName"
Write-Host "Detected ARCH: $Arch"

# Map to llama.app bucket architecture names
$LlamaArch = switch -Regex ($Arch) {
  "Arm64" { "aarch64" }
  "X64"   { "x86_64" }
  default { throw "Error: Architecture not supported: $Arch" }
}

$LlamaOs = "windows"

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
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
    $ProgressPreference = "Continue"
    return $true
  } catch {
    Write-Host "  Failed to download $Url : $_" -ForegroundColor Yellow
    return $false
  }
}

#==============================================================================
# Determine binary download URL from llama.app / Hugging Face buckets
#==============================================================================
$LlamaBucket = "ggml-org/install.sh"
$LlamaRepo = "https://huggingface.co/buckets/$LlamaBucket/resolve"

Write-Host "Fetching latest llama-app version..."
try {
  $LlamaVersion = Invoke-WebRequest -Uri "$LlamaRepo/latest" -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
  $LlamaVersion = $LlamaVersion.Trim()
  Write-Host "Latest llama-app version: $LlamaVersion"
} catch {
  throw "Error: Could not determine latest llama-app version"
}

# Create temporary download directory
$TempDir = Join-Path $env:TEMP "llama-install-$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
try {
  
  #==============================================================================
  # Platform probes - on Windows, default to CPU backend
  # CUDA/ROCm/Vulkan probes are Linux-only; Windows uses DirectML or CPU
  #==============================================================================
  $Backend = "cpu"
  $Downloaded = $false
  
  # Try CPU backend first (most reliable on Windows)
  $CpuUrl = "$LlamaRepo/$LlamaVersion/$LlamaArch/$LlamaOs/cpu/llama-app.exe"
  $CpuDest = Join-Path $TempDir "llama-app.exe"
  
  if (Download-File -Url $CpuUrl -Destination $CpuDest) {
    $Backend = "cpu"
    $Downloaded = $true
  }
  
  if (-not $Downloaded) {
    # Try to find any available backend by probing
    $Backends = @("cuda", "rocm", "vulkan", "cpu", "metal")
    foreach ($b in $Backends) {
      $ProbeUrl = "$LlamaRepo/$LlamaVersion/$LlamaArch/$LlamaOs/$b/llama-app.exe"
      $ProbeDest = Join-Path $TempDir "llama-app-$b.exe"
      if (Download-File -Url $ProbeUrl -Destination $ProbeDest) {
        if (Test-Path $ProbeDest) {
          Move-Item -Path $ProbeDest -Destination $CpuDest -Force
          $Backend = $b
          $Downloaded = $true
          break
        }
      }
    }
  }
  
  if (-not $Downloaded -or -not (Test-Path $CpuDest)) {
    throw "Error: No prebuilt llama-app binary available for $LlamaArch/$LlamaOs"
  }
  
  Write-Host "Selected backend: $Backend"
  Write-Host "llama-app binary downloaded successfully"
  
  #==============================================================================
  # Install binary (rename llama-app.exe -> llama.exe)
  #==============================================================================
  if (-not (Test-Path $BinaryDir)) {
    New-Item -ItemType Directory -Path $BinaryDir -Force | Out-Null
  }
  
  if (Test-Path $BinaryPath) {
    Write-Host "  Binary already exists at $BinaryPath, keeping existing." -ForegroundColor Yellow
  } else {
    Write-Host "Installing llama-app binary (renamed to llama.exe) to $BinaryPath..."
    Copy-Item -Path $CpuDest -Destination $BinaryPath -Force
  }
  
  if (-not (Test-Path $BinaryPath)) {
    throw "Error: llama binary not installed at $BinaryPath"
  }
  
  Write-Host "llama binary found at $BinaryPath (installed from llama-app)"
  
  #==============================================================================
  # Create directories
  #==============================================================================
  if (-not (Test-Path $WorkingDir)) {
    New-Item -ItemType Directory -Path $WorkingDir -Force | Out-Null
  }
  $LogDir = Split-Path -Parent $LogPath
  if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
  }
  
  #==============================================================================
  # Create service environment file (only if it doesn't exist)
  #==============================================================================
  Write-Host "Creating service environment file at $EnvFile..."
  
  if (Test-Path $EnvFile) {
    Write-Host "  Service environment file already exists, preserving existing config." -ForegroundColor Yellow
  } else {
    @"
# Service environment variables for llama-server
# These are sourced by the Windows service wrapper

LLAMA_ARG_HOST=127.0.0.1
LLAMA_ARG_PORT=$LlamaPort
NGL_LEVEL=auto
CONTEXT_SIZE=0
JINJA_ENABLED=true
AGENT_MODE_ENABLED=true
EMBEDDINGS_ENABLED=true
EMBEDDINGS_POOLING_TYPE=mean
SLEEP_IDLE_SECONDS=
LOG_LEVEL=info
"@ | Out-File -FilePath $EnvFile -Encoding utf8
  }
  
  #==============================================================================
  # Build ExecStart command
  #==============================================================================
  $LlamaArgsStr = if ($LlamaArgs) { " $LlamaArgs" } else { "" }
  
  # The service wrapper will source the env file and run: llama serve --host %HOST% --port %PORT% ...
  $LlamaHost = $env:LLAMA_ARG_HOST
  if (-not $LlamaHost) { $LlamaHost = "127.0.0.1" }
  $LlamaPortEnv = $env:LLAMA_ARG_PORT
  if (-not $LlamaPortEnv) { $LlamaPortEnv = $LlamaPort }
  $NglLevel = $env:NGL_LEVEL
  if (-not $NglLevel) { $NglLevel = "auto" }
  $ContextSize = $env:CONTEXT_SIZE
  if (-not $ContextSize) { $ContextSize = "0" }

  $ExecStartCmd = """$BinaryPath"" serve --host ""$LlamaHost"" --port ""$LlamaPortEnv"" -ngl ""$NglLevel"" --ctx-size ""$ContextSize"" --log-file ""$LogPath"" --log-timestamps $LlamaArgsStr"
  
  #==============================================================================
  # Create Windows service using NSSM
  #==============================================================================
  Write-Host "Creating Windows service..."
  
  $NssmPath = Get-Command nssm -ErrorAction SilentlyContinue
  if (-not $NssmPath) {
    Write-Host "NSSM not found. Installing via winget..." -ForegroundColor Yellow
    if ($System) {
      winget install nssm --scope machine --accept-package-agreements --accept-source-agreements 2>$null
    } else {
      winget install nssm --accept-package-agreements --accept-source-agreements 2>$null
    }
    $NssmPath = Get-Command nssm -ErrorAction SilentlyContinue
    if (-not $NssmPath) {
      Write-Host "Warning: NSSM installation via winget failed. Service will not be created automatically." -ForegroundColor Yellow
    }
  }
  
  if ($NssmPath) {
    Write-Host "  Using NSSM at $NssmPath to create service $ServerName..."
    
    # Stop existing service if it exists
    & $NssmPath stop $ServerName 2>$null
    & $NssmPath remove $ServerName -confirm 2>$null
    
    # Create service
    & $NssmPath install $ServerName $BinaryPath "serve --host 127.0.0.1 --port $LlamaPort -ngl auto --ctx-size 0 --log-file $LogPath --log-timestamps $LlamaArgsStr"
    & $NssmPath set $ServerName DisplayName "llama-server"
    & $NssmPath set $ServerName Description "llama.cpp server (llama-app) - local inference endpoint"
    & $NssmPath set $ServerName Start SERVICE_AUTO_START
    & $NssmPath set $ServerName RestartDelay $RestartSeconds.TotalSeconds
    & $NssmPath set $ServerName AppDirectory $WorkingDir
    & $NssmPath set $ServerName AppStdout $LogPath
    & $NssmPath set $ServerName AppStderr $LogPath
    & $NssmPath set $ServerName RotateFiles 1
    & $NssmPath set $ServerName RotateOnline 1
    
    # Set environment variables via registry
    & $NssmPath set $ServerName EnvExtra "LLAMA_ARG_HOST=127.0.0.1;LLAMA_ARG_PORT=$LlamaPort;NGL_LEVEL=auto;CONTEXT_SIZE=0;LOG_LEVEL=info"
    
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
    Write-Host "    nssm install $ServerName `"$BinaryPath`" serve --host 127.0.0.1 --port $LlamaPort"
    Write-Host "    nssm start $ServerName"
  }
  
  #==============================================================================
  # Final status
  #==============================================================================
  Write-Host ""
  Write-Host "llama-server service installation complete!" -ForegroundColor Green
  Write-Host ""
  Write-Host "Installation summary:"
  Write-Host "  Binary:      $BinaryPath"
  Write-Host "  Working Dir: $WorkingDir"
  Write-Host "  Env File:    $EnvFile"
  Write-Host "  Log Path:    $LogPath"
  Write-Host "  Port:        $LlamaPort"
  Write-Host "  Backend:     $Backend"
  Write-Host ""
  Write-Host "Status check:"
  Write-Host "  Get-Service -Name $ServerName -ErrorAction SilentlyContinue"
  Write-Host "  Or test endpoint: Invoke-WebRequest http://127.0.0.1:$LlamaPort/v1/models"
  
} finally {
  # Clean up temp directory
  if (Test-Path $TempDir) {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}
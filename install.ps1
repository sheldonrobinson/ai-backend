$ErrorActionPreference = 'Stop'

# Check for Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script requires Administrator privileges to install all components."
    Write-Warning "Attempting to elevate privileges. Please click 'Yes' on the UAC prompt..."
    
    $scriptUrl = "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/install.ps1"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iex (Invoke-WebRequest -Uri '$scriptUrl').Content`"" -Verb RunAs
    exit
}

Write-Host "Installing AI Backend components for Windows..."

# General Dependencies
winget install Chocolatey.Chocolatey --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
choco install visualstudio2026buildtools 118.6.1 -y
winget install Microsoft.VCRedist.2015+.x64 --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
choco install make -y
winget install KhronosGroup.VulkanRT --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Python.Python.3.14 --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install pnpm.pnpm --accept-package-agreements --accept-source-agreements --silent --disable-interactivity

# pipx
python -m pip install --quiet --user pipx
pipx.exe ensurepath

# Sugar
pipx install sugarai

# Build tools & VCS
winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install JernejSimoncic.Wget --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Ninja-build.Ninja --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Git.Git --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install GitHub.GitLFS --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Kitware.CMake --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Xmake-io.Xmake --accept-package-agreements --accept-source-agreements --silent --disable-interactivity

Write-Host "Determining best ggml-backend..."
$hasNvidia = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
$hasAmd = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD" }
if ($hasNvidia) {
    Write-Host "NVIDIA GPU detected. Optimal backend is CUDA."
} elseif ($hasAmd) {
    Write-Host "AMD GPU detected. Optimal backend is Vulkan/ROCm."
} else {
    Write-Host "No dedicated GPU detected. Optimal backend is CPU/Vulkan."
}

# llamacpp
Write-Host "Installing llamacpp via winget..."
winget install ggml.llamacpp --accept-package-agreements --accept-source-agreements --silent --disable-interactivity

# Helper to automatically fetch and install the latest GitHub release assets
function Install-GitHubRelease {
    param(
        [string]$Repo,
        [string]$Match = "\.(exe|msi)$"
    )
    Write-Host "Fetching latest release for $Repo..."
    $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
    try {
        $release = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -match $Match } | Select-Object -First 1
        if ($asset) {
            $downloadUrl = $asset.browser_download_url
            $fileName = "$env:TEMP\$($asset.name)"
            Write-Host "Downloading $($asset.name)..."
            Invoke-WebRequest -Uri $downloadUrl -OutFile $fileName
            Write-Host "Installing $($asset.name)..."
            Start-Process -FilePath $fileName -ArgumentList "/quiet", "/passive", "/norestart" -Wait -NoNewWindow
            Write-Host "Successfully installed $($asset.name)"
        } else {
            Write-Host "No installable asset matching '$Match' found for $Repo."
        }
    } catch {
        Write-Host "Failed to fetch or install release for $Repo. Error: $_"
    }
}

# agentgateway
Install-GitHubRelease -Repo "sheldonrobinson/agentgateway.install"

# mcpjungle
Install-GitHubRelease -Repo "sheldonrobinson/mcpjungle.install"

# goose-cli
Write-Host "Installing goose-cli..."
$env:Configure="false"; iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aaif-goose/goose/main/download_cli.ps1").Content

# Goose Desktop
Install-GitHubRelease -Repo "sheldonrobinson/aaif-goose.install"

# Setup local-mcp configuration
Write-Host "Setting up local-mcp configuration..."
if (Get-Command npx -ErrorAction SilentlyContinue) {
    $env:LMCP_REF="67df72f4"
    try {
        npx -y local-mcp@latest setup
    } catch {
        Write-Host "local-mcp setup failed, continuing..."
    }
} else {
    Write-Host "npx not found, falling back to powershell install..."
    try {
        Invoke-RestMethod -Uri "https://local-mcp.com/install-windows?ref=67df72f4" | Invoke-Expression
    } catch {
        Write-Host "local-mcp fallback install failed, continuing..."
    }
}

Write-Host "Installation script completed successfully."
# Keep window open for a few seconds to see result
Start-Sleep -Seconds 5

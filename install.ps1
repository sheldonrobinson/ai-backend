$ErrorActionPreference = 'Stop'

Write-Host "Installing AI Backend components for Windows..."

# General Dependencies
winget install Chocolatey.Chocolatey --accept-package-agreements --accept-source-agreements
choco install visualstudio2026buildtools 118.6.1 -y
winget install Microsoft.VCRedist.2015+.x64 --accept-package-agreements --accept-source-agreements
choco install make -y
winget install KhronosGroup.VulkanRT --accept-package-agreements --accept-source-agreements
winget install Python.Python.3.14 --accept-package-agreements --accept-source-agreements
winget install pnpm.pnpm --accept-package-agreements --accept-source-agreements

# pipx
python -m pip install --user pipx
pipx.exe ensurepath

# Sugar
pipx install sugarai

# Build tools & VCS
winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
winget install JernejSimoncic.Wget --accept-package-agreements --accept-source-agreements
winget install Ninja-build.Ninja --accept-package-agreements --accept-source-agreements
winget install Git.Git --accept-package-agreements --accept-source-agreements
winget install GitHub.GitLFS --accept-package-agreements --accept-source-agreements
winget install Kitware.CMake --accept-package-agreements --accept-source-agreements
winget install Xmake-io.Xmake --accept-package-agreements --accept-source-agreements

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
winget install ggml.llamacpp --accept-package-agreements --accept-source-agreements

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

Write-Host "Installation script completed successfully."

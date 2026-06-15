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

# agentgateway & mcpjungle
Write-Host "Please download agentgateway manually from https://github.com/sheldonrobinson/agentgateway.install/releases"
Write-Host "Please download mcpjungle manually from https://github.com/sheldonrobinson/mcpjungle.install/releases"

# goose-cli
Write-Host "Installing goose-cli..."
$env:Configure="false"; iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aaif-goose/goose/main/download_cli.ps1").Content

# Goose Desktop
Write-Host "Please download Goose Desktop manually from https://github.com/sheldonrobinson/aaif-goose.install/releases"

Write-Host "Installation script completed successfully."

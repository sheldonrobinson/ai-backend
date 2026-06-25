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
winget install Microsoft.VisualStudio.BuildTools --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Microsoft.VCRedist.2015+.x64 --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
choco install make -y
winget install KhronosGroup.VulkanRT --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Python.Python.3.14 --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install pnpm.pnpm --accept-package-agreements --accept-source-agreements --silent --disable-interactivity

# pipx
python -m pip install --quiet --user pipx
winget install astral-sh.uv --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
pipx.exe ensurepath

# Sugar
pipx install sugarai
sugar init

# Build tools & VCS
winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install JernejSimoncic.Wget --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Ninja-build.Ninja --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Git.Git --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install GitHub.GitLFS --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Kitware.CMake --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install Xmake-io.Xmake --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
winget install alirezagsm.trayy --accept-package-agreements --accept-source-agreements --silent --disable-interactivity


# Helper to automatically fetch and install the latest GitHub release assets (specifically enduser variant)
function Install-GitHubRelease {
    param(
        [string]$Repo,
        [string]$Match = "enduser.*\.msi$"
    )

    Write-Host "Fetching latest release for $Repo..."
    $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"

    try {
        $release = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -match $Match } | Select-Object -First 1

        if (-not $asset) {
            Write-Host "No installable asset matching '$Match' found for $Repo."
            return
        }

        $downloadUrl = $asset.browser_download_url
        $fileName = Join-Path $env:TEMP $asset.name

        Write-Host "Downloading $($asset.name)..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $fileName

        Write-Host "Installing $($asset.name)..."

        if ($fileName -match "\.msi$") {
            # Install MSI silently
            Start-Process "msiexec.exe" -ArgumentList "/i `"$fileName`" /qn /norestart" -Wait -NoNewWindow
        }
        elseif ($fileName -match "\.exe$") {
            # Install EXE silently
            Start-Process -FilePath $fileName -ArgumentList "/quiet", "/passive", "/norestart" -Wait -NoNewWindow
        }
        else {
            throw "Unsupported installer type: $fileName"
        }

        Write-Host "Successfully installed $($asset.name)"
    }
    catch {
        Write-Host "Failed to fetch or install release for $Repo. Error: $_"
    }
}

Write-Host "Determining best ggml-backend..."
$hasNvidia = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
$hasAmd = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD" }
$hasIntel  = $gpus | Where-Object { $_.Name -match "Intel" }

# Detect Intel oneAPI runtimes (Level Zero, DPC++, OpenCL)
$oneApiRoot = "C:\Program Files (x86)\Intel\oneAPI"
$oneApiInstalled = Test-Path $oneApiRoot

# Optional: check for specific SYCL components
$hasDpcpp = Test-Path "$oneApiRoot\compiler"
$hasLevelZero = Test-Path "$oneApiRoot\level-zero"
$hasOpenCL = Test-Path "$oneApiRoot\opencl"

$syclRuntimeAvailable = $oneApiInstalled -and ($hasDpcpp -or $hasLevelZero -or $hasOpenCL)

# llamacpp
if ($hasNvidia) {
    Write-Host "NVIDIA GPU detected. Optimal backend is CUDA."
    Install-GitHubRelease -Repo "sheldonrobinson/llamacpp.install" -Match "enduser-cuda-12.4.*\.msi$"
} elseif ($hasAmd) {
    Write-Host "AMD GPU detected. Optimal backend is Vulkan/ROCm."
    Install-GitHubRelease -Repo "sheldonrobinson/llamacpp.install" -Match "enduser-hip-radeon.*\.msi$"
} elseif ($hasIntel -and $syclRuntimeAvailable) {
    Write-Host "Intel GPU + oneAPI runtime detected. Optimal backend is SYCL."
    Install-GitHubRelease -Repo "sheldonrobinson/llamacpp.install" -Match "enduser-sycl.*\.msi$"
} elseif ($hasIntel -and -not $syclRuntimeAvailable) {
    Write-Host "Intel GPU detected, but oneAPI runtime missing. Recommend installing oneAPI for SYCL."
    Write-Host "Falling back to CPU/Vulkan."
    Install-GitHubRelease -Repo "sheldonrobinson/llamacpp.install" -Match "enduser-vulkan.*\.msi$"
} else {
    Write-Host "No dedicated GPU detected. Optimal backend is CPU/Vulkan."
    Install-GitHubRelease -Repo "sheldonrobinson/llamacpp.install" -Match "enduser-cpu.*\.msi$"
}

# agentgateway
Install-GitHubRelease -Repo "sheldonrobinson/agentgateway.install"

# mcpjungle
Install-GitHubRelease -Repo "sheldonrobinson/mcpjungle.install"

# goose-cli
Write-Host "Installing goose-cli..."
$env:Configure="false"; iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aaif-goose/goose/main/download_cli.ps1").Content
# Set environment variable GOOSE_BIN
[System.Environment]::SetEnvironmentVariable("GOOSE_BIN", "%USERPROFILE%\.local\bin\goose.exe", "User")

# Create the registry key if missing
New-Item -Path "HKCU:\Software\Konnek\Goose" -Force
# Set a string value for a registry key
Set-ItemProperty -Path "HKCU:\Software\Konnek\Goose" -Name "Executable" -Value "%USERPROFILE%\.local\bin\goose.exe" -Type String -Force

# Goose Desktop
Install-GitHubRelease -Repo "sheldonrobinson/aaif-goose.install"

# Copy start script into local user Programs folder and create per-user shortcuts (no elevation required)
$InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\Konnek\AI-Backend'
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

$InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\Konnek\AI-Backend'
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# URLs for your scripts
$startUrl = "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/tools/start-all.ps1"
$uninstallUrl = "https://raw.githubusercontent.com/sheldonrobinson/ai-backend/main/tools/uninstall.ps1"

$destScript = Join-Path $InstallDir 'start-all.ps1'
$destUninstall = Join-Path $InstallDir 'uninstall.ps1'

# Download scripts
Invoke-WebRequest -Uri $startUrl -OutFile $destScript -UseBasicParsing
Invoke-WebRequest -Uri $uninstallUrl -OutFile $destUninstall -UseBasicParsing

Write-Host "Downloaded start-all.ps1 to $destScript"
Write-Host "Downloaded uninstall.ps1 to $destUninstall"

# Create Start Menu and Desktop shortcuts (Current User)
try {
    $wsh = New-Object -ComObject WScript.Shell

    $startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Konnek'
    New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null
    $startMenuShortcut = Join-Path $startMenuDir 'AI Backend.lnk'
    $sc = $wsh.CreateShortcut($startMenuShortcut)
    $sc.TargetPath = Join-Path $env:SystemRoot 'system32\WindowsPowerShell\v1.0\powershell.exe'
    $sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$destScript`""
    $sc.WorkingDirectory = $InstallDir
    $sc.IconLocation = "shell32.dll,16801"
    $sc.Save()
    Write-Host "Created Start Menu shortcut: $startMenuShortcut"

    $desktop = Join-Path $env:USERPROFILE 'Desktop'
    $desktopShortcut = Join-Path $desktop 'AI Backend.lnk'
    $sc2 = $wsh.CreateShortcut($desktopShortcut)
    $sc2.TargetPath = $sc.TargetPath
    $sc2.Arguments = $sc.Arguments
    $sc2.WorkingDirectory = $sc.WorkingDirectory
    $sc2.IconLocation = $sc.IconLocation
    $sc2.Save()
    Write-Host "Created Desktop shortcut: $desktopShortcut"

    # Create Startup shortcut to auto-run the start script on login (hidden by default)
    $startupDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
    New-Item -ItemType Directory -Path $startupDir -Force | Out-Null
    $startupShortcut = Join-Path $startupDir 'AI Backend.lnk'
    $sc3 = $wsh.CreateShortcut($startupShortcut)
    $sc3.TargetPath = $sc.TargetPath
    # do not pass -Visible; default start-all.ps1 runs hidden
    $sc3.Arguments = $sc.Arguments
    $sc3.WorkingDirectory = $sc.WorkingDirectory
    $sc3.IconLocation = $sc.IconLocation
    $sc3.Save()
    Write-Host "Created Startup shortcut: $startupShortcut"

    # Create Uninstall shortcut in Start Menu
    $uninstallShortcut = Join-Path $startMenuDir 'Uninstall AI Backend.lnk'
    $scU = $wsh.CreateShortcut($uninstallShortcut)
    $scU.TargetPath = Join-Path $env:SystemRoot 'system32\WindowsPowerShell\v1.0\powershell.exe'
    $scU.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$destUninstall`""
    $scU.WorkingDirectory = $InstallDir
    $scU.IconLocation = "shell32.dll,254"
    $scU.Save()
    Write-Host "Created Uninstall shortcut: $uninstallShortcut"
    # Remove environment variable GOOSE_BIN
    [System.Environment]::SetEnvironmentVariable("GOOSE_BIN", "", "User")
    # Remove registry variable
    Remove-ItemProperty -Path "HKCU:\Software\Konnek\Goose" -Name "Executable" -Force
} catch {
    Write-Warning "Failed to create shortcuts: $_"
}

Write-Host "Installation script completed successfully."
# Keep window open for a few seconds to see result
Start-Sleep -Seconds 15


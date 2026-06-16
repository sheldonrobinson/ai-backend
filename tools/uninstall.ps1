<#
Uninstall-AIBackend.ps1
Removes per-user installation folder and shortcuts created by install.ps1
#>
$ErrorActionPreference = 'Stop'

$InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\Konnek\AI-Backend'
$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Konnek'
$startMenuShortcut = Join-Path $startMenuDir 'AI Backend.lnk'
$desktopShortcut = Join-Path (Join-Path $env:USERPROFILE 'Desktop') 'AI Backend.lnk'
$startupDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$startupShortcut = Join-Path $startupDir 'AI Backend.lnk'

Write-Host "Uninstalling AI Backend (per-user)..."

try {
    if (Test-Path $startMenuShortcut) {
        Remove-Item $startMenuShortcut -Force
        Write-Host "Removed Start Menu shortcut: $startMenuShortcut"
    }
    if (Test-Path $desktopShortcut) {
        Remove-Item $desktopShortcut -Force
        Write-Host "Removed Desktop shortcut: $desktopShortcut"
    }
    if (Test-Path $startupShortcut) {
        Remove-Item $startupShortcut -Force
        Write-Host "Removed Startup shortcut: $startupShortcut"
    }

    if (Test-Path $InstallDir) {
        # Remove the install directory
        Remove-Item -LiteralPath $InstallDir -Recurse -Force
        Write-Host "Removed installation directory: $InstallDir"
    }

    # Remove Konnek start menu folder if empty
    if (Test-Path $startMenuDir) {
        $children = Get-ChildItem -Path $startMenuDir -Force -ErrorAction SilentlyContinue
        if (-not $children) {
            Remove-Item -LiteralPath $startMenuDir -Force
            Write-Host "Removed empty Start Menu folder: $startMenuDir"
        }
    }

    Write-Host "Uninstall completed."
} catch {
    Write-Warning "Uninstall encountered errors: $_"
}

<#
Start-All.ps1
Starts Llama.C++ HTTP server, agentgateway, and MCPJungle.
Installs to %LOCALAPPDATA%\Programs\Konnek\AI-Backend when provided by installer.
#>

$ErrorActionPreference = 'Stop'


# Configurable values
$InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\Konnek\AI-Backend'
$LogDir = Join-Path $env:TEMP "AI-Backend-Logs"
New-Item -Path $LogDir -ItemType Directory -Force | Out-Null

# Log configuration
$retentionDays = 7
$maxLogSizeMB = 10  # rotate when log >= 10 MB
$compressAfterDays = 1 # compress raw .log files older than this (days)
$maxLogSize = $maxLogSizeMB * 1MB

function Compress-LogFile {
    param([string]$Path)
    try {
        $zipPath = "{0}.zip" -f $Path
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
        Compress-Archive -Path $Path -DestinationPath $zipPath -Force -ErrorAction Stop
        Remove-Item $Path -Force -ErrorAction SilentlyContinue
        Write-Host ("Compressed {0} -> {1}" -f $Path, $zipPath)
    } catch {
        Write-Warning ("Failed to compress {0}: $_" -f $Path)
    }
}

function Rotate-LogIfNeeded {
    param(
        [string]$LogFile,
        [int64]$MaxSizeBytes
    )
    try {
        if (Test-Path $LogFile) {
            $size = (Get-Item $LogFile).Length
            if ($size -ge $MaxSizeBytes) {
                $timestamp = Get-Date -Format yyyyMMddHHmmss
                $rotated = "{0}.{1}" -f $LogFile, $timestamp
                Move-Item -Path $LogFile -Destination $rotated -Force
                Compress-LogFile -Path $rotated
                Write-Host ("Rotated and compressed {0} -> {1}.zip" -f $LogFile, $rotated)
            }
        }
    } catch {
        Write-Warning ("Rotate-LogIfNeeded failed for {0}: $_" -f $LogFile)
    }
}

# Compress raw .log files older than $compressAfterDays
try {
    $compressThreshold = (Get-Date).AddDays(-$compressAfterDays)
    Get-ChildItem -Path $LogDir -Filter '*.log' -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $compressThreshold } | ForEach-Object { Compress-LogFile -Path $_.FullName }
} catch {
    Write-Warning "Compress old logs failed: $_"
}

# Remove archived files older than retention (both .log and .zip)
try {
    $threshold = (Get-Date).AddDays(-$retentionDays)
    Get-ChildItem -Path $LogDir -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $threshold } | Remove-Item -Force -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Log retention cleanup failed: $_"
}

function Find-Exe {
    param(
        [string[]]$Names,
        [string]$BaseDir
    )

    foreach ($n in $Names) {

        # 1. Check PATH
        $cmd = Get-Command $n -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Path }

        # 2. Check BaseDir (your real install location)
        if ($BaseDir) {
            $candidate = Join-Path $BaseDir $n
            if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }

            if (Test-Path ($candidate + ".exe")) {
                return (Resolve-Path ($candidate + ".exe")).Path
            }
        }

        # 3. Fallback search
        $fallbacks = @(
            (Join-Path $InstallDir $n)
            (Join-Path $InstallDir ("bin\" + $n))
            (Join-Path $env:ProgramFiles $n)
            (Join-Path $env:LOCALAPPDATA ("Programs\$n"))
        )

        foreach ($p in $fallbacks) {
            if (Test-Path $p) { return (Resolve-Path $p).Path }
            if (Test-Path ($p + ".exe")) { return (Resolve-Path ($p + ".exe")).Path }
        }
    }

    return $null
}


function Start-Component {
    param(
        [string]$Name,
        [string[]]$ExeNames,
        [string]$CommandArgs ,
        [string]$WorkingDir = $InstallDir,
        [switch]$Visible
    )

    Write-Host ("Starting {0}..." -f $Name)

    $exe = Find-Exe -Names $ExeNames -BaseDir $WorkingDir
    if (-not $exe) {
        Write-Warning ("Could not find executable for {0} (tried: $($ExeNames -join ', ')). Skipping." -f $Name)
        return
    }

    $safeName = ($Name -replace '[^a-zA-Z0-9]','_')
    $datePart = Get-Date -Format yyyy-MM-dd
    $logFile = Join-Path $LogDir "$($safeName)-$datePart.log"

    Rotate-LogIfNeeded -LogFile $logFile -MaxSizeBytes $maxLogSize

    # Build the full command exactly once  
    $full = "`"$exe $CommandArgs`""

    if ($Visible) {
        $psiArgs = @('/k', $full)
        Start-Process -FilePath "cmd.exe" -ArgumentList $psiArgs -WorkingDirectory $WorkingDir -WindowStyle Normal
    }
    else {
        $redir = ">> `"$logFile`" 2>&1"
        $psiArgs = @('/c', $full, $redir)
        Write-Host "ArgumentList $($psiArgs -join ' | ')"   # DEBUG ONLY
        Start-Process -FilePath "cmd.exe" -ArgumentList $psiArgs -WorkingDirectory $WorkingDir -WindowStyle Hidden
    }

}


# Default component configurations (adjust ports/args below if needed)
$components = @(
    @{
        Name = 'Llama.C++ HTTP Server'
        BaseDir = Join-Path $env:LOCALAPPDATA 'Programs\Konnek\llamacpp'
        Exes = @('llama-server.exe')
        Args = ''
        Visible = $true
    },
    @{
        Name = 'agentgateway LLM proxy'
        BaseDir = Join-Path $env:LOCALAPPDATA 'Programs\Konnek\agentgateway'
        Exes = @('agentgateway.exe')
        Args = ''
        Visible = $true
    },
    @{
        Name = 'MCPJungle MCP gateway'
        BaseDir = Join-Path $env:LOCALAPPDATA 'Programs\Konnek\mcpjungle'
        Exes = @('mcpjungle.exe')
        Args = "start --port 8080 --sqlite-db-path `"$env:APPDATA\Konnek\mcpjungle\mcpjungle.db`""
        Visible = $true
    }
)


foreach ($c in $components) {

    Start-Component -Name $c.Name -ExeNames $c.Exes -CommandArgs  $c.Args -WorkingDir $c.BaseDir -Visible:$($c.Visible)
}


Write-Host "All start requests issued. Check console windows for each component's logs."

# End of script

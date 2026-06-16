<#
Start-All.ps1
Starts Llama.C++ HTTP server, agentgateway, and MCPJungle.
Default behavior runs components hidden/background. Use -Visible to open console windows.
Installs to %LOCALAPPDATA%\Programs\Konnek\AI-Backend when provided by installer.
#>
param(
    [switch]$Visible
)

$ErrorActionPreference = 'Stop'

# By default run hidden/background. Use -Visible to open consoles.
$Hidden = -not $Visible

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
        $zipPath = "$Path.zip"
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
        Compress-Archive -Path $Path -DestinationPath $zipPath -Force -ErrorAction Stop
        Remove-Item $Path -Force -ErrorAction SilentlyContinue
        Write-Host "Compressed $Path -> $zipPath"
    } catch {
        Write-Warning "Failed to compress $Path: $_"
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
                $rotated = "$LogFile.$timestamp"
                Move-Item -Path $LogFile -Destination $rotated -Force
                Compress-LogFile -Path $rotated
                Write-Host "Rotated and compressed $LogFile -> $rotated.zip"
            }
        }
    } catch {
        Write-Warning "Rotate-LogIfNeeded failed for $LogFile: $_"
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
    param([string[]]$Names)
    foreach ($n in $Names) {
        # Check PATH
        try { $cmd = Get-Command $n -ErrorAction SilentlyContinue } catch { $cmd = $null }
        if ($cmd) { return $cmd.Path }
        # Check common install locations
        $candidates = @(
            Join-Path $InstallDir $n,
            Join-Path $InstallDir ("bin\" + $n),
            Join-Path $env:ProgramFiles $n,
            Join-Path $env:ProgramFiles ("\" + $n),
            Join-Path $env:LOCALAPPDATA "Programs\$n"
        )
        foreach ($p in $candidates) {
            if (Test-Path $p) { return (Resolve-Path $p).Path }
            if (Test-Path ($p + '.exe')) { return (Resolve-Path ($p + '.exe')).Path }
        }
    }
    return $null
}

function Start-Component {
    param(
        [string]$Name,
        [string[]]$ExeNames,
        [string]$Args = '',
        [string]$WorkingDir = $InstallDir
    )

    Write-Host "Starting $Name..."
    $exe = Find-Exe -Names $ExeNames
    if (-not $exe) {
        Write-Warning "Could not find executable for $Name (tried: $($ExeNames -join ', ')). Skipping."
        return
    }

    $safeName = ($Name -replace '[^a-zA-Z0-9]','_')
    $datePart = Get-Date -Format yyyy-MM-dd
    $logFile = Join-Path $LogDir "$($safeName)-$datePart.log"

    # Rotate/compress logs if they exceed size or are old (size-rotation will compress rotated file)
    Rotate-LogIfNeeded -LogFile $logFile -MaxSizeBytes $maxLogSize

    $cmd = "`"$exe`" $Args"
    if ($Hidden) {
        # Start hidden/background with log redirection (append into daily file)
        try {
            $redir = ">> `"$logFile`" 2>&1"
            $psiArgs = "/c `"$exe`" $Args $redir"
            Start-Process -FilePath "cmd.exe" -ArgumentList $psiArgs -WorkingDirectory $WorkingDir -WindowStyle Hidden -ErrorAction Stop
            Write-Host "$Name started (hidden) (executable: $exe), logging to $logFile"
        } catch {
            Write-Warning "Failed to start $Name hidden: $_"
        }
    } else {
        # Open a new cmd window and run the command so output is visible and persists
        $psiArgs = "/k `"$exe`" $Args"
        Start-Process -FilePath "cmd.exe" -ArgumentList $psiArgs -WorkingDirectory $WorkingDir -WindowStyle Normal
        Write-Host "$Name started (visible) (executable: $exe)"
    }
}

# Default component configurations (adjust ports/args below if needed)
$components = @(
    @{ Name = 'Llama.C++ HTTP Server'; Exes = @('llama-server.exe','llama-server','llama.exe'); Args = '' },
    @{ Name = 'agentgateway LLM proxy'; Exes = @('agentgateway.exe','agentgateway'); Args = '' },
    @{ Name = 'MCPJungle MCP gateway'; Exes = @('mcpjungle.exe','mcpjungle-server.exe','mcpjungle'); Args = '' }
)

# Ensure MCPJUNGLE_ARGS exists (from env, args file, or default)
$McpArgsFile = Join-Path $env:USERPROFILE '.konnek\mcpjungle\args.txt'
if (-not $env:MCPJUNGLE_ARGS) {
    if (Test-Path $McpArgsFile) {
        try { $env:MCPJUNGLE_ARGS = Get-Content -Path $McpArgsFile -Raw -ErrorAction Stop } catch { $env:MCPJUNGLE_ARGS = $null }
    }
    if (-not $env:MCPJUNGLE_ARGS) {
        $env:MCPJUNGLE_ARGS = "--sqlite-db-path $env:USERPROFILE\.konnek\mcpjungle\mcpjungle.db"
    }
}

foreach ($c in $components) {
    $args = $c.Args
    if (($c.Name -like '*MCPJungle*' -or $c.Name -like '*MCP Jungle*') -and ([string]::IsNullOrEmpty($args))) {
        $args = $env:MCPJUNGLE_ARGS
    }
    Start-Component -Name $c.Name -ExeNames $c.Exes -Args $args -WorkingDir $InstallDir
}

Write-Host "All start requests issued. Check console windows for each component's logs."

# End of script

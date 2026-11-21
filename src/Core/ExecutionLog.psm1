<#
    .SYNOPSIS
        NH Win Debloater - Execution & Logging Engine
    .DESCRIPTION
        Provides structured level-based logging, dry-run preview support,
        execution tracking, and backup inventory discovery.
    .MODULEVERSION
        0.5.3
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
param()

$script:LogFilePath = $null
$script:ExecutionMetrics = [ordered]@{
    TotalOperations   = 0
    SuccessfulActions = 0
    SkippedActions    = 0
    FailedActions     = 0
    PreviewActions    = 0
}

function Initialize-DebloatLogger {
    <#
        .SYNOPSIS
            Initializes the debloat session log file.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogDirectory,

        [Parameter(Mandatory = $false)]
        [string]$Version
    )

    if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
        $LogDirectory = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Logs"
    }

    if (-not (Test-Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    $script:LogFilePath = Join-Path $LogDirectory "NHWinDebloater.log"

    if ([string]::IsNullOrWhiteSpace($Version)) {
        $projRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $vFile = Join-Path $projRoot "VERSION.txt"
        if (Test-Path $vFile) {
            $Version = (Get-Content -Path $vFile -Raw).Trim()
        } else {
            $Version = "0.5"
        }
    }
    $verDisplay = if ($Version.StartsWith("v")) { $Version } else { "v$Version" }

    # Suppress duplicate session initialization header within 10 seconds (e.g. during STA / elevation handoffs)
    $shouldWriteInit = $true
    if (Test-Path $script:LogFilePath) {
        $lastLines = Get-Content -Path $script:LogFilePath -Tail 5 -ErrorAction SilentlyContinue
        if ($lastLines) {
            foreach ($line in ($lastLines | Select-Object -Last 2)) {
                if ($line -match '=== NH Win Debloater .* Session Initialized: (.*) ===') {
                    $lastDateStr = $Matches[1]
                    try {
                        $lastDate = [datetime]::ParseExact($lastDateStr, 'yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
                        if (((Get-Date) - $lastDate).TotalSeconds -lt 10) {
                            $shouldWriteInit = $false
                            break
                        }
                    } catch {
                        # Ignore parse errors
                    }
                }
            }
        }
    }

    if ($shouldWriteInit) {
        $initMsg = "=== NH Win Debloater $verDisplay Session Initialized: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) ==="
        Add-Content -Path $script:LogFilePath -Value $initMsg -Encoding UTF8
    }

    return $script:LogFilePath
}

function Write-DebloatLog {
    <#
        .SYNOPSIS
            Writes a timestamped and formatted log entry.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "PREVIEW")]
        [string]$Level = "INFO",

        [switch]$NoConsole
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] [$Level] $Message"

    if ($null -eq $script:LogFilePath) {
        Initialize-DebloatLogger | Out-Null
    }

    if ($null -ne $script:LogFilePath -and (Test-Path (Split-Path $script:LogFilePath))) {
        try {
            Add-Content -Path $script:LogFilePath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch {
            Write-Verbose "Logging write error: $($_.Exception.Message)"
        }
    }

    if (-not $NoConsole) {
        $color = switch ($Level) {
            "INFO"    { "Gray" }
            "WARN"    { "Yellow" }
            "ERROR"   { "Red" }
            "SUCCESS" { "Green" }
            "PREVIEW" { "Cyan" }
        }
        Write-Host " [$Level] " -NoNewline -ForegroundColor $color
        Write-Host $Message -ForegroundColor White
    }
}

function Get-DebloatLog {
    <#
        .SYNOPSIS
            Retrieves recent log entries.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Tail = 50
    )

    if ($script:LogFilePath -and (Test-Path $script:LogFilePath)) {
        return @(Get-Content -Path $script:LogFilePath -Tail $Tail)
    }

    return @()
}

function Invoke-DebloatAction {
    <#
        .SYNOPSIS
            Executes a debloat action block with logging and error handling.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ActionName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [switch]$DryRun
    )

    $script:ExecutionMetrics.TotalOperations++

    if ($DryRun -or (-not $PSCmdlet.ShouldProcess("Action: $ActionName", "Execute debloat operation"))) {
        $script:ExecutionMetrics.PreviewActions++
        Write-DebloatLog -Message "DRY-RUN PREVIEW: Would execute '$ActionName'" -Level "PREVIEW"
        return [PSCustomObject]@{
            Action = $ActionName
            Status = "Preview"
            Error  = $null
        }
    }

    try {
        Write-DebloatLog -Message "Starting: $ActionName..." -Level "INFO"
        $result = & $ScriptBlock
        $script:ExecutionMetrics.SuccessfulActions++
        Write-DebloatLog -Message "Completed: $ActionName successfully." -Level "SUCCESS"
        return [PSCustomObject]@{
            Action = $ActionName
            Status = "Success"
            Result = $result
            Error  = $null
        }
    }
    catch {
        $script:ExecutionMetrics.FailedActions++
        $errMsg = $_.Exception.Message
        Write-DebloatLog -Message "Failed: $ActionName - $errMsg" -Level "ERROR"
        return [PSCustomObject]@{
            Action = $ActionName
            Status = "Error"
            Result = $null
            Error  = $errMsg
        }
    }
}

function Get-DebloatBackup {
    <#
        .SYNOPSIS
            Discovers existing registry backup snapshots.
    #>
    [CmdletBinding()]
    param(
        [string]$BackupDirectory
    )

    if ([string]::IsNullOrWhiteSpace($BackupDirectory)) {
        $BackupDirectory = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups"
    }

    if (-not (Test-Path $BackupDirectory)) {
        return @()
    }

    $files = Get-ChildItem -Path $BackupDirectory -Filter "RegistrySnapshot_*.json" -ErrorAction SilentlyContinue
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($f in $files) {
        $results.Add([PSCustomObject]@{
            FileName     = $f.Name
            FilePath     = $f.FullName
            SizeKb       = [math]::Round($f.Length / 1KB, 2)
            LastModified = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        })
    }

    return @($results.ToArray())
}

function Clear-DebloatTempSession {
    <#
        .SYNOPSIS
            Cleans up transient runtime staging, lock, and temporary sandbox directories
            in %TEMP%\NHWinDebloater* while strictly preserving backups and logs in %LOCALAPPDATA%.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TempRoot
    )

    if ([string]::IsNullOrWhiteSpace($TempRoot)) {
        $TempRoot = $env:TEMP
    }

    $removedItems = [System.Collections.Generic.List[string]]::new()
    $cleanPatterns = @(
        "NHWinDebloater*",
        "nh-win-debloater*"
    )

    foreach ($pattern in $cleanPatterns) {
        $searchPath = Join-Path $TempRoot $pattern
        $targets = Get-Item -Path $searchPath -ErrorAction SilentlyContinue
        foreach ($target in $targets) {
            # Critical Safety Check: Never touch anything in LOCALAPPDATA, Backups, or Logs
            $fullPath = $target.FullName
            if ($fullPath -like "*LOCALAPPDATA*" -or $fullPath -like "*Backups*" -or $fullPath -like "*Logs*") {
                continue
            }

            if ($PSCmdlet.ShouldProcess($fullPath, "Remove transient temporary item")) {
                try {
                    Remove-Item -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue
                    $removedItems.Add($fullPath)
                } catch {
                    Write-Verbose "Could not remove '$fullPath': $($_.Exception.Message)"
                }
            }
        }
    }

    return @($removedItems.ToArray())
}

Export-ModuleMember -Function Initialize-DebloatLogger, Write-DebloatLog, Get-DebloatLog, Invoke-DebloatAction, Get-DebloatBackup, Clear-DebloatTempSession

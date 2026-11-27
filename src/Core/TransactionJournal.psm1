<#
    .SYNOPSIS
        NH Win Debloater - Structured JSON Transaction Journal & Recovery Gate
    .DESCRIPTION
        Manages per-session recovery directories, enforces the mandatory recovery-before-mutate
        gate, writes structured JSON transaction records per operation, generates execution reports,
        and exports redacted diagnostic bundles.
        Developed by Mohammed Nadeem BM (NH Digital - https://nhdigital.shop).
    .MODULEVERSION
        1.4.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
param()

function New-TransactionSession {
    <#
        .SYNOPSIS
            Creates a unique session directory with journal, user log, debug log, and before-state paths.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BaseDirectory
    )

    if ([string]::IsNullOrWhiteSpace($BaseDirectory)) {
        $BaseDirectory = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Sessions"
    }

    $shortGuid = ([guid]::NewGuid().ToString("N")).Substring(0, 8)
    $sessionId = "$((Get-Date).ToString('yyyyMMdd_HHmmss'))_$shortGuid"
    $sessionDir = Join-Path $BaseDirectory $sessionId

    if (-not (Test-Path $sessionDir)) {
        New-Item -Path $sessionDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    $journalPath = Join-Path $sessionDir "journal.json"
    $userLogPath = Join-Path $sessionDir "user.log"
    $debugLogPath = Join-Path $sessionDir "debug.log"
    $beforeStatePath = Join-Path $sessionDir "before-state.json"

    "[]" | Set-Content -Path $journalPath -Encoding UTF8 -Force
    "=== Session $sessionId Started ===" | Set-Content -Path $userLogPath -Encoding UTF8 -Force
    "=== Debug Log $sessionId Started ===" | Set-Content -Path $debugLogPath -Encoding UTF8 -Force

    return [PSCustomObject]@{
        SessionId       = $sessionId
        SessionDir      = $sessionDir
        JournalPath     = $journalPath
        UserLogPath     = $userLogPath
        DebugLogPath    = $debugLogPath
        BeforeStatePath = $beforeStatePath
        CreatedAt       = (Get-Date).ToString("o")
    }
}

function Save-SessionRecoveryData {
    <#
        .SYNOPSIS
            Mandatory Step 3 gate: persists before-state recovery data and optionally attempts a System Restore Point.
            Halts execution if recovery protection fails unless ForceOverride is explicitly specified.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [object]$BeforeStateData,

        [Parameter(Mandatory = $false)]
        [bool]$AttemptRestorePoint = $false,

        [Parameter(Mandatory = $false)]
        [scriptblock]$RestorePointAction,

        [Parameter(Mandatory = $false)]
        [switch]$ForceOverride
    )

    $missingProtections = [System.Collections.Generic.List[string]]::new()
    $recoveryWritten = $false
    $rpStatus = "Skipped"

    try {
        $BeforeStateData | ConvertTo-Json -Depth 6 | Set-Content -Path $Session.BeforeStatePath -Encoding UTF8 -ErrorAction Stop
        $recoveryWritten = (Test-Path $Session.BeforeStatePath)
        if (-not $recoveryWritten) {
            $missingProtections.Add("Session before-state recovery file was not created.")
        }
    }
    catch {
        $missingProtections.Add("Failed to write session recovery data: $($_.Exception.Message)")
    }

    if ($AttemptRestorePoint) {
        try {
            $rpRes = if ($RestorePointAction) {
                & $RestorePointAction
            } elseif (Get-Command "New-DebloatRestorePoint" -ErrorAction SilentlyContinue) {
                New-DebloatRestorePoint -Description "NH Win Debloater Session $($Session.SessionId)"
            } else {
                [PSCustomObject]@{ Status = "Error"; Message = "Restore Point cmdlet unavailable." }
            }

            if ($rpRes -and $rpRes.Status -eq "Success") {
                $rpStatus = "Success"
            } else {
                $rpStatus = "Failed"
                $msg = if ($rpRes -and $rpRes.Message) { $rpRes.Message } else { "System Restore Point creation failed or was denied." }
                $missingProtections.Add("System Restore Point unavailable: $msg")
            }
        }
        catch {
            $rpStatus = "Failed"
            $missingProtections.Add("System Restore Point exception: $($_.Exception.Message)")
        }
    }

    $hasMissing = ($missingProtections.Count -gt 0)
    $halted = ($hasMissing -and (-not $ForceOverride))

    if ($hasMissing) {
        $warnLine = "[WARN] Recovery protection incomplete: $($missingProtections -join ' | ') (Override=$ForceOverride)"
        Add-Content -Path $Session.UserLogPath -Value $warnLine -Encoding UTF8 -ErrorAction SilentlyContinue
        Add-Content -Path $Session.DebugLogPath -Value $warnLine -Encoding UTF8 -ErrorAction SilentlyContinue
    }

    return [PSCustomObject]@{
        Success            = (-not $halted)
        Halted             = $halted
        RequiresOverride   = $hasMissing
        Overridden         = ($hasMissing -and [bool]$ForceOverride)
        MissingProtections = $missingProtections.ToArray()
        RecoveryFile       = $Session.BeforeStatePath
        RestorePointStatus = $rpStatus
    }
}

function Add-TransactionRecord {
    <#
        .SYNOPSIS
            Appends a structured JSON transaction record to the session journal and logs.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [string]$OperationId,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $false)]
        [object]$PreviousState = $null,

        [Parameter(Mandatory = $false)]
        [object]$RequestedState = $null,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Success", "Failed", "Skipped", "PendingRestart")]
        [string]$Result,

        [Parameter(Mandatory = $false)]
        [bool]$Verified = $false,

        [Parameter(Mandatory = $false)]
        [bool]$RollbackAvailable = $false,

        [Parameter(Mandatory = $false)]
        [string]$ErrorDetail = "",

        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 0
    )

    $record = [PSCustomObject]@{
        sessionId         = $Session.SessionId
        operationId       = $OperationId
        category          = $Category
        target            = $Target
        previousState     = $PreviousState
        requestedState    = $RequestedState
        result            = $Result
        verified          = $Verified
        rollbackAvailable = $RollbackAvailable
        errorDetail       = $ErrorDetail
        exitCode          = $ExitCode
        timestamp         = (Get-Date).ToString("o")
    }

    $existing = @()
    if (Test-Path $Session.JournalPath) {
        try {
            $raw = Get-Content -Path $Session.JournalPath -Raw -Encoding UTF8
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $parsed = $raw | ConvertFrom-Json
                if ($parsed) { $existing = @($parsed) }
            }
        } catch {
            $existing = @()
        }
    }

    $updated = @($existing) + @($record)
    $updated | ConvertTo-Json -Depth 6 | Set-Content -Path $Session.JournalPath -Encoding UTF8 -Force

    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $Session.UserLogPath -Value "[$ts] [$Result] $OperationId ($Target)" -Encoding UTF8 -ErrorAction SilentlyContinue
    Add-Content -Path $Session.DebugLogPath -Value "[$ts] [$Result] $OperationId | Category=$Category | Target=$Target | Verified=$Verified | ExitCode=$ExitCode | Error=$ErrorDetail" -Encoding UTF8 -ErrorAction SilentlyContinue

    return $record
}

function Invoke-TransactionalOperation {
    <#
        .SYNOPSIS
            Executes a single operation inside try/catch, verifies post-apply state, and records to the transaction journal.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [string]$OperationId,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $false)]
        [object]$PreviousState = $null,

        [Parameter(Mandatory = $false)]
        [object]$RequestedState = $null,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [scriptblock]$VerifyAction,

        [Parameter(Mandatory = $false)]
        [bool]$RollbackAvailable = $true
    )

    $resultStatus = "Success"
    $verified = $false
    $errDetail = ""
    $exitCode = 0

    try {
        & $Action | Out-Null
        if ($VerifyAction) {
            $verified = [bool](& $VerifyAction)
        } else {
            $verified = $true
        }
    }
    catch {
        $resultStatus = "Failed"
        $verified = $false
        $errDetail = $_.Exception.Message
        $exitCode = 1
    }

    return (Add-TransactionRecord -Session $Session -OperationId $OperationId -Category $Category -Target $Target `
        -PreviousState $PreviousState -RequestedState $RequestedState -Result $resultStatus -Verified $verified `
        -RollbackAvailable $RollbackAvailable -ErrorDetail $errDetail -ExitCode $exitCode)
}

function Get-TransactionReport {
    <#
        .SYNOPSIS
            Summarizes Success, Failed, Skipped, and PendingRestart counts; never reports OverallSuccess if any operation failed.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session
    )

    $records = @()
    if (Test-Path $Session.JournalPath) {
        $raw = Get-Content -Path $Session.JournalPath -Raw -Encoding UTF8
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            $parsed = $raw | ConvertFrom-Json
            if ($parsed) { $records = @($parsed) }
        }
    }

    $successCount = @($records | Where-Object { $_.result -eq "Success" }).Count
    $failedCount = @($records | Where-Object { $_.result -eq "Failed" }).Count
    $skippedCount = @($records | Where-Object { $_.result -eq "Skipped" }).Count
    $pendingCount = @($records | Where-Object { $_.result -eq "PendingRestart" }).Count

    return [PSCustomObject]@{
        SessionId      = $Session.SessionId
        Total          = $records.Count
        Success        = $successCount
        Failed         = $failedCount
        Skipped        = $skippedCount
        PendingRestart = $pendingCount
        OverallSuccess = ($failedCount -eq 0)
        JournalPath    = $Session.JournalPath
    }
}

function Export-RedactedDiagnostics {
    <#
        .SYNOPSIS
            Exports a redacted diagnostic text report stripping username, user profile paths, and machine name.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("=== NH Win Debloater Redacted Diagnostics ===")
    $lines.Add("SessionId: $($Session.SessionId)")

    if (Test-Path $Session.DebugLogPath) {
        foreach ($line in (Get-Content -Path $Session.DebugLogPath -ErrorAction SilentlyContinue)) {
            $redacted = $line -replace [regex]::Escape($env:USERPROFILE), "C:\Users\<REDACTED>"
            if (-not [string]::IsNullOrWhiteSpace($env:USERNAME)) {
                $redacted = $redacted -replace [regex]::Escape($env:USERNAME), "<REDACTED>"
            }
            if (-not [string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
                $redacted = $redacted -replace [regex]::Escape($env:COMPUTERNAME), "<HOST>"
            }
            $lines.Add($redacted)
        }
    }

    Set-Content -Path $OutputPath -Value ($lines -join [Environment]::NewLine) -Encoding UTF8 -Force
    return $OutputPath
}

Export-ModuleMember -Function New-TransactionSession, Save-SessionRecoveryData, Add-TransactionRecord, Invoke-TransactionalOperation, Get-TransactionReport, Export-RedactedDiagnostics

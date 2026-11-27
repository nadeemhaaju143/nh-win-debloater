<#
    .SYNOPSIS
        NH Win Debloater - Session Rollback & Conflict Detection Engine
    .DESCRIPTION
        Provides single-item rollback, per-category rollback, and full-session rollback by sessionId
        with external-modification conflict detection and non-destructive backup preservation.
        Developed by Mohammed Nadeem BM (NH Digital - https://nhdigital.shop).
    .MODULEVERSION
        1.4.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
param()

function Test-RollbackConflict {
    <#
        .SYNOPSIS
            Detects whether a target's current state was modified externally after the session backup.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $false)]
        [object]$PreviousState,

        [Parameter(Mandatory = $false)]
        [object]$RequestedState,

        [Parameter(Mandatory = $false)]
        [object]$CurrentState
    )

    if ($null -eq $CurrentState) {
        return [PSCustomObject]@{
            Target        = $Target
            HasConflict   = $false
            Reason        = "No live state mismatch detected."
            CurrentState  = $CurrentState
            ExpectedState = $RequestedState
            PreviousState = $PreviousState
        }
    }

    $curStr = [string]$CurrentState
    $reqStr = if ($null -ne $RequestedState) { [string]$RequestedState } else { "" }
    $prevStr = if ($null -ne $PreviousState) { [string]$PreviousState } else { "" }

    $hasConflict = ($curStr -ne $reqStr -and $curStr -ne $prevStr)
    $reason = if ($hasConflict) {
        "Conflict: '$Target' current value '$curStr' differs from expected '$reqStr' and backup '$prevStr'."
    } else {
        "No conflict."
    }

    return [PSCustomObject]@{
        Target        = $Target
        HasConflict   = $hasConflict
        Reason        = $reason
        CurrentState  = $CurrentState
        ExpectedState = $RequestedState
        PreviousState = $PreviousState
    }
}

function Invoke-ItemRollback {
    <#
        .SYNOPSIS
            Rolls back a single journal record with conflict detection and optional ForceOverwrite.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Record,

        [Parameter(Mandatory = $false)]
        [object]$CurrentState = $null,

        [Parameter(Mandatory = $false)]
        [switch]$ForceOverwrite,

        [Parameter(Mandatory = $false)]
        [scriptblock]$RestoreAction
    )

    if (-not $Record.rollbackAvailable) {
        return [PSCustomObject]@{
            OperationId = $Record.operationId
            Target      = $Record.target
            Status      = "Skipped"
            Reason      = "Rollback not available for this operation."
        }
    }

    $conflict = Test-RollbackConflict -Target $Record.target -PreviousState $Record.previousState -RequestedState $Record.requestedState -CurrentState $CurrentState
    if ($conflict.HasConflict -and (-not $ForceOverwrite)) {
        Write-Warning $conflict.Reason
        return [PSCustomObject]@{
            OperationId = $Record.operationId
            Target      = $Record.target
            Status      = "Conflict"
            Reason      = $conflict.Reason
        }
    }

    if ($PSCmdlet.ShouldProcess($Record.target, "Rollback to previous state '$($Record.previousState)'")) {
        try {
            if ($RestoreAction) {
                & $RestoreAction $Record | Out-Null
            }
            return [PSCustomObject]@{
                OperationId = $Record.operationId
                Target      = $Record.target
                Status      = "Restored"
                Reason      = "Restored to '$($Record.previousState)'."
            }
        }
        catch {
            return [PSCustomObject]@{
                OperationId = $Record.operationId
                Target      = $Record.target
                Status      = "Failed"
                Reason      = $_.Exception.Message
            }
        }
    }

    return [PSCustomObject]@{
        OperationId = $Record.operationId
        Target      = $Record.target
        Status      = "Preview"
        Reason      = "WhatIf: Would restore '$($Record.target)' to '$($Record.previousState)'."
    }
}

function Invoke-CategoryRollback {
    <#
        .SYNOPSIS
            Rolls back all rollback-available operations for a specific category within a session.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [string]$SessionsDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$ForceOverwrite
    )

    return (Invoke-SessionRollback -SessionId $SessionId -SessionsDirectory $SessionsDirectory -CategoryFilter $Category -ForceOverwrite:$ForceOverwrite -WhatIf:$WhatIfPreference)
}

function Invoke-SessionRollback {
    <#
        .SYNOPSIS
            Rolls back an entire session by sessionId (or filtered by category) while preserving backup records.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId,

        [Parameter(Mandatory = $false)]
        [string]$SessionsDirectory,

        [Parameter(Mandatory = $false)]
        [string]$CategoryFilter,

        [Parameter(Mandatory = $false)]
        [switch]$ForceOverwrite
    )

    if ([string]::IsNullOrWhiteSpace($SessionsDirectory)) {
        $SessionsDirectory = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Sessions"
    }

    $sessionDir = Join-Path $SessionsDirectory $SessionId
    $journalPath = Join-Path $sessionDir "journal.json"
    if (-not (Test-Path $journalPath)) {
        throw "Session journal not found for '$SessionId' at '$journalPath'."
    }

    $raw = Get-Content -Path $journalPath -Raw -Encoding UTF8
    $records = if ([string]::IsNullOrWhiteSpace($raw)) { @() } else { @(($raw | ConvertFrom-Json) | ForEach-Object { $_ }) }
    if (-not [string]::IsNullOrWhiteSpace($CategoryFilter)) {
        $records = @($records | Where-Object { $_.category -eq $CategoryFilter })
    }

    if ($records.Count -gt 1) {
        $records = @($records[($records.Count - 1)..0])
    }
    $itemResults = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($rec in $records) {
        $res = Invoke-ItemRollback -Record $rec -ForceOverwrite:$ForceOverwrite -WhatIf:$WhatIfPreference
        $itemResults.Add($res)
    }

    return [PSCustomObject]@{
        SessionId       = $SessionId
        CategoryFilter  = $CategoryFilter
        TotalProcessed  = $itemResults.Count
        Restored        = @($itemResults | Where-Object { $_.Status -eq "Restored" }).Count
        Conflicts       = @($itemResults | Where-Object { $_.Status -eq "Conflict" }).Count
        Skipped         = @($itemResults | Where-Object { $_.Status -eq "Skipped" }).Count
        Failed          = @($itemResults | Where-Object { $_.Status -eq "Failed" }).Count
        BackupPreserved = (Test-Path $journalPath)
        Items           = $itemResults.ToArray()
    }
}

Export-ModuleMember -Function Test-RollbackConflict, Invoke-ItemRollback, Invoke-CategoryRollback, Invoke-SessionRollback

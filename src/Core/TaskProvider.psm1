<#
    .SYNOPSIS
        NH Win Debloater - Individual XML-Backed Scheduled Task Provider
    .DESCRIPTION
        Categorizes Windows scheduled tasks, protects maintenance, update, security, driver,
        and reliability tasks from telemetry cleanup, exports full task XML before disabling,
        verifies post-apply state, and restores original state + XML on rollback.
        Developed by Mohammed Nadeem BM (NH Digital - https://nhdigital.shop).
    .MODULEVERSION
        1.4.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
param()

function Get-ScheduledTaskCategory {
    <#
        .SYNOPSIS
            Categorizes a scheduled task by its path and name.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    $full = "$TaskPath$TaskName"
    if ($full -match "Windows Defender|ExploitGuard|Security") { return "Security & Defender" }
    if ($full -match "WindowsUpdate|UpdateOrchestrator|USO") { return "Windows Update" }
    if ($full -match "Driver|Plug and Play|DeviceInstall|PowerEfficiency") { return "Driver & Hardware Maintenance" }
    if ($full -match "TaskScheduler|Defrag|DiskCleanup|Chkdsk|Maintenance|Diagnosis|RAC|MemoryDiagnostic") { return "Windows Maintenance" }
    if ($full -match "Customer Experience Improvement|Application Experience|Autochk\\Proxy|Feedback\\Siuf") { return "Privacy & Telemetry" }
    if ($full -match "CloudExperienceHost|HelloFace|Shell|Maps") { return "User Experience" }
    return "Application Maintenance"
}

function Test-IsProtectedScheduledTask {
    <#
        .SYNOPSIS
            Ensures maintenance, security, update, driver, and reliability tasks are never disabled by telemetry cleanup.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    $cat = Get-ScheduledTaskCategory -TaskPath $TaskPath -TaskName $TaskName
    $protectedCategories = @(
        "Windows Maintenance",
        "Windows Update",
        "Security & Defender",
        "Driver & Hardware Maintenance",
        "Application Maintenance"
    )
    return ($protectedCategories -contains $cat)
}

function Backup-ScheduledTaskXml {
    <#
        .SYNOPSIS
            Captures task path, name, current State, and exports full task XML to a backup file.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$BackupDirectory
    )

    if ([string]::IsNullOrWhiteSpace($BackupDirectory)) {
        $BackupDirectory = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups\Tasks"
    }
    if (-not (Test-Path $BackupDirectory)) {
        New-Item -Path $BackupDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) {
        return [PSCustomObject]@{
            TaskPath   = $TaskPath
            TaskName   = $TaskName
            Exists     = $false
            State      = "NotFound"
            BackupFile = $null
        }
    }

    $xmlContent = Export-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop
    $safeName = ($TaskName -replace '[^A-Za-z0-9_-]', '_')
    $backupFile = Join-Path $BackupDirectory "${safeName}_$((Get-Date).ToString('yyyyMMdd_HHmmss')).json"

    $payload = [PSCustomObject]@{
        TaskPath   = $TaskPath
        TaskName   = $TaskName
        Category   = (Get-ScheduledTaskCategory -TaskPath $TaskPath -TaskName $TaskName)
        State      = [string]$task.State
        Xml        = $xmlContent
        CapturedAt = (Get-Date).ToString("o")
    }
    $payload | ConvertTo-Json -Depth 4 | Set-Content -Path $backupFile -Encoding UTF8 -Force

    return [PSCustomObject]@{
        TaskPath   = $TaskPath
        TaskName   = $TaskName
        Exists     = $true
        State      = [string]$task.State
        Xml        = $xmlContent
        BackupFile = $backupFile
    }
}

function Disable-TelemetryScheduledTask {
    <#
        .SYNOPSIS
            Exports full XML backup before disabling a non-protected telemetry task and verifies new state.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [string]$BackupDirectory
    )

    if (Test-IsProtectedScheduledTask -TaskPath $TaskPath -TaskName $TaskName) {
        return [PSCustomObject]@{
            TaskPath   = $TaskPath
            TaskName   = $TaskName
            Status     = "SkippedProtected"
            Verified   = $false
            BackupFile = $null
        }
    }

    $backup = Backup-ScheduledTaskXml -TaskPath $TaskPath -TaskName $TaskName -BackupDirectory $BackupDirectory
    if (-not $backup.Exists) {
        return [PSCustomObject]@{
            TaskPath   = $TaskPath
            TaskName   = $TaskName
            Status     = "NotFound"
            Verified   = $false
            BackupFile = $null
        }
    }

    if ($PSCmdlet.ShouldProcess("Scheduled Task: $TaskPath$TaskName", "Disable Task (XML backed up)")) {
        try {
            Disable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop | Out-Null
            $after = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
            $verified = ($null -ne $after -and [string]$after.State -eq "Disabled")
            return [PSCustomObject]@{
                TaskPath      = $TaskPath
                TaskName      = $TaskName
                Status        = "Success"
                Verified      = $verified
                BackupFile    = $backup.BackupFile
                PreviousState = $backup.State
            }
        }
        catch {
            return [PSCustomObject]@{
                TaskPath   = $TaskPath
                TaskName   = $TaskName
                Status     = "Error: $($_.Exception.Message)"
                Verified   = $false
                BackupFile = $backup.BackupFile
            }
        }
    }

    return [PSCustomObject]@{
        TaskPath   = $TaskPath
        TaskName   = $TaskName
        Status     = "Preview"
        Verified   = $false
        BackupFile = $backup.BackupFile
    }
}

function Restore-ScheduledTaskFromBackup {
    <#
        .SYNOPSIS
            Restores a scheduled task's original State and XML definition from backup.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupFile
    )

    if (-not (Test-Path $BackupFile)) {
        return [PSCustomObject]@{ Status = "NotFound"; Verified = $false }
    }

    $data = Get-Content -Path $BackupFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($PSCmdlet.ShouldProcess("Scheduled Task: $($data.TaskPath)$($data.TaskName)", "Restore State '$($data.State)' from XML")) {
        try {
            $existing = Get-ScheduledTask -TaskPath $data.TaskPath -TaskName $data.TaskName -ErrorAction SilentlyContinue
            if (-not $existing -and $data.Xml) {
                Register-ScheduledTask -TaskPath $data.TaskPath -TaskName $data.TaskName -Xml $data.Xml -Force -ErrorAction Stop | Out-Null
            }
            if ($data.State -eq "Disabled") {
                Disable-ScheduledTask -TaskPath $data.TaskPath -TaskName $data.TaskName -ErrorAction Stop | Out-Null
            } else {
                Enable-ScheduledTask -TaskPath $data.TaskPath -TaskName $data.TaskName -ErrorAction Stop | Out-Null
            }
            $after = Get-ScheduledTask -TaskPath $data.TaskPath -TaskName $data.TaskName -ErrorAction SilentlyContinue
            return [PSCustomObject]@{
                TaskPath = $data.TaskPath
                TaskName = $data.TaskName
                Status   = "Restored"
                Verified = ($null -ne $after)
            }
        }
        catch {
            return [PSCustomObject]@{
                TaskPath = $data.TaskPath
                TaskName = $data.TaskName
                Status   = "Error: $($_.Exception.Message)"
                Verified = $false
            }
        }
    }

    return [PSCustomObject]@{
        TaskPath = $data.TaskPath
        TaskName = $data.TaskName
        Status   = "Preview"
        Verified = $false
    }
}

Export-ModuleMember -Function Get-ScheduledTaskCategory, Test-IsProtectedScheduledTask, Backup-ScheduledTaskXml, Disable-TelemetryScheduledTask, Restore-ScheduledTaskFromBackup

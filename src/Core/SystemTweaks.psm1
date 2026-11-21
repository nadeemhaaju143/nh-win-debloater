<#
    .SYNOPSIS
        NH Win Debloater - System Tweaks & Recovery Engine
    .DESCRIPTION
        Disables Windows consumer features and promotional lock screen ads,
        manages classic context menu, mouse precision, sticky keys, fast startup,
        storage sense, Windows Update reboot policies, and optional Windows features
        (Sandbox, WSL), creates System Restore Points, and captures pre-modification
        registry snapshots for transactional rollback.
    .MODULEVERSION
        0.1.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
param()

function Set-TweakRegistryValue {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object]$Value,

        [ValidateSet("DWord", "String", "Binary", "MultiString", "ExpandString", "QWord")]
        [string]$PropertyType = "DWord"
    )

    if ($PSCmdlet.ShouldProcess("Key: $Path, Name: $Name", "Set Registry Value to $Value")) {
        try {
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            }
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction Stop | Out-Null
            return [PSCustomObject]@{
                Path   = $Path
                Name   = $Name
                Value  = $Value
                Status = "Success"
            }
        }
        catch {
            return [PSCustomObject]@{
                Path   = $Path
                Name   = $Name
                Value  = $Value
                Status = "Error: $($_.Exception.Message)"
            }
        }
    }
    else {
        return [PSCustomObject]@{
            Path   = $Path
            Name   = $Name
            Value  = $Value
            Status = "Preview"
        }
    }
}

function Set-ConsumerFeatureTweak {
    <#
        .SYNOPSIS
            Disables Windows consumer features and silent background app installations.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$Disable = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $cloudPolicyVal = if ($Disable) { 1 } else { 0 }
    $cdmVal = if ($Disable) { 0 } else { 1 }

    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value $cloudPolicyVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Value $cloudPolicyVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $ops.Add((Set-TweakRegistryValue -Path $cdmPath -Name "ContentDeliveryAllowed" -Value $cdmVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $cdmPath -Name "OemPreInstalledAppsEnabled" -Value $cdmVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $cdmPath -Name "PreInstalledAppsEnabled" -Value $cdmVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $cdmPath -Name "SilentInstalledAppsEnabled" -Value $cdmVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-LockScreenTweak {
    <#
        .SYNOPSIS
            Disables tips, fun facts, and promotional suggestions on the Windows lock screen.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$Disable = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $cdmVal = if ($Disable) { 0 } else { 1 }
    $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

    $ops.Add((Set-TweakRegistryValue -Path $cdmPath -Name "SubscribedContent-338387Enabled" -Value $cdmVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $cdmPath -Name "SubscribedContent-338388Enabled" -Value $cdmVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $cdmPath -Name "SubscribedContent-310093Enabled" -Value $cdmVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-ClassicContextMenuTweak {
    <#
        .SYNOPSIS
            Restores the Windows 10 classic context menu on Windows 11.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$EnableClassic = $true
    )

    $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

    if ($EnableClassic) {
        return (Set-TweakRegistryValue -Path $clsidPath -Name "(Default)" -Value "" -PropertyType "String" -WhatIf:$WhatIfPreference)
    } else {
        if ($PSCmdlet.ShouldProcess("CLSID: {86ca1aa0-34aa-4e8b-a509-50c905bae2a2}", "Revert to Windows 11 Modern Context Menu")) {
            $rootClsid = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            if (Test-Path $rootClsid) {
                Remove-Item -Path $rootClsid -Recurse -Force -ErrorAction SilentlyContinue
            }
            return [PSCustomObject]@{ Path = $rootClsid; Name = ""; Value = "Removed"; Status = "Success" }
        } else {
            return [PSCustomObject]@{ Path = $clsidPath; Name = ""; Value = "Removed"; Status = "Preview" }
        }
    }
}

function Set-MousePrecisionTweak {
    <#
        .SYNOPSIS
            Disables mouse acceleration / Enhance Pointer Precision for 1:1 input.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableAcceleration = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $speed = if ($DisableAcceleration) { "0" } else { "1" }
    $mousePath = "HKCU:\Control Panel\Mouse"

    $ops.Add((Set-TweakRegistryValue -Path $mousePath -Name "MouseSpeed" -Value $speed -PropertyType "String" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $mousePath -Name "MouseThreshold1" -Value "0" -PropertyType "String" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $mousePath -Name "MouseThreshold2" -Value "0" -PropertyType "String" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-StickyKeysTweak {
    <#
        .SYNOPSIS
            Disables the Sticky Keys activation shortcut dialog (pressing Shift 5x).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableShortcut = $true
    )

    $flags = if ($DisableShortcut) { "506" } else { "510" }
    return (Set-TweakRegistryValue -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value $flags -PropertyType "String" -WhatIf:$WhatIfPreference)
}

function Set-FastStartupTweak {
    <#
        .SYNOPSIS
            Enables or disables Windows Fast Startup hybrid hibernation.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableFastStartup = $true
    )

    $val = if ($DisableFastStartup) { 0 } else { 1 }
    return (Set-TweakRegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference)
}

function Set-StorageSenseTweak {
    <#
        .SYNOPSIS
            Configures Storage Sense automatic disk cleanup policy.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableStorageSense = $true
    )

    $val = if ($DisableStorageSense) { 0 } else { 1 }
    return (Set-TweakRegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference)
}

function Set-WindowsUpdatePolicyTweak {
    <#
        .SYNOPSIS
            Configures Windows Update reboot deadlines and third-party driver exclusion.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$PreventAutoReboot = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ExcludeDrivers = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($PreventAutoReboot) {
        $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }
    if ($ExcludeDrivers) {
        $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    return $ops.ToArray()
}

function Set-OptionalFeatureState {
    <#
        .SYNOPSIS
            Enables or disables optional Windows features (Windows Sandbox, WSL).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("WindowsSandbox", "WSL")]
        [string]$FeatureId,

        [Parameter(Mandatory = $false)]
        [bool]$Enable = $true
    )

    $featureName = switch ($FeatureId) {
        "WindowsSandbox" { "Containers-DisposableClientVM" }
        "WSL"            { "Microsoft-Windows-Subsystem-Linux" }
    }

    if ($PSCmdlet.ShouldProcess("Feature: $FeatureId ($featureName)", "Set State: $(if ($Enable) { 'Enable' } else { 'Disable' })")) {
        try {
            if ($Enable) {
                Enable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -ErrorAction Stop | Out-Null
            } else {
                Disable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -ErrorAction Stop | Out-Null
            }
            return [PSCustomObject]@{
                FeatureId   = $FeatureId
                FeatureName = $featureName
                Status      = "Success"
                Enabled     = $Enable
            }
        }
        catch {
            return [PSCustomObject]@{
                FeatureId   = $FeatureId
                FeatureName = $featureName
                Status      = "Error: $($_.Exception.Message)"
                Enabled     = $Enable
            }
        }
    }
    else {
        return [PSCustomObject]@{
            FeatureId   = $FeatureId
            FeatureName = $featureName
            Status      = "Preview"
            Enabled     = $Enable
        }
    }
}

function New-DebloatRestorePoint {
    <#
        .SYNOPSIS
            Creates a System Restore checkpoint before applying modifications.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Description = "NH Win Debloater Pre-Debloat Checkpoint"
    )

    if ($PSCmdlet.ShouldProcess("System Restore Point", "Create checkpoint: '$Description'")) {
        try {
            $srCheck = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
            Write-Verbose "Existing restore points found: $($srCheck.Count)"

            Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            return [PSCustomObject]@{
                Status      = "Success"
                Description = $Description
                Timestamp   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        catch {
            return [PSCustomObject]@{
                Status      = "Error"
                Description = $Description
                Timestamp   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Message     = $_.Exception.Message
            }
        }
    }
    else {
        return [PSCustomObject]@{
            Status      = "Preview"
            Description = "WhatIf: System restore point '$Description' would be created."
            Timestamp   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
}

function Export-RegistrySnapshot {
    <#
        .SYNOPSIS
            Exports current registry values of targeted paths to a JSON snapshot file.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RegistryPaths,

        [Parameter(Mandatory = $false)]
        [string]$BackupDirectory
    )

    if ([string]::IsNullOrWhiteSpace($BackupDirectory)) {
        $BackupDirectory = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups"
    }

    if (-not (Test-Path $BackupDirectory)) {
        New-Item -Path $BackupDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $snapshotFile = Join-Path $BackupDirectory "RegistrySnapshot_$timestamp.json"

    $snapshotData = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($path in $RegistryPaths) {
        if (Test-Path $path) {
            $item = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if ($item) {
                $propNames = $item.PSObject.Properties |
                    Where-Object { $_.Name -notmatch "^PS" } |
                    Select-Object -ExpandProperty Name

                foreach ($prop in $propNames) {
                    $snapshotData.Add([PSCustomObject]@{
                        Path  = $path
                        Name  = $prop
                        Value = $item.$prop
                    })
                }
            }
        }
    }

    $snapshotData | ConvertTo-Json -Depth 4 | Set-Content -Path $snapshotFile -Encoding UTF8
    return $snapshotFile
}

function Restore-RegistrySnapshot {
    <#
        .SYNOPSIS
            Restores previous registry values from a JSON snapshot file.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SnapshotPath
    )

    if (-not (Test-Path $SnapshotPath)) {
        Write-Error "Registry snapshot file not found: $SnapshotPath"
        return @()
    }

    $data = Get-Content -Path $SnapshotPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($entry in $data) {
        if ($PSCmdlet.ShouldProcess("Registry Key: $($entry.Path), Name: $($entry.Name)", "Restore previous value: $($entry.Value)")) {
            try {
                if (-not (Test-Path $entry.Path)) {
                    New-Item -Path $entry.Path -Force -ErrorAction Stop | Out-Null
                }
                New-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -Force -ErrorAction Stop | Out-Null
                $results.Add([PSCustomObject]@{
                    Path   = $entry.Path
                    Name   = $entry.Name
                    Value  = $entry.Value
                    Status = "Restored"
                })
            }
            catch {
                $results.Add([PSCustomObject]@{
                    Path   = $entry.Path
                    Name   = $entry.Name
                    Value  = $entry.Value
                    Status = "Error: $($_.Exception.Message)"
                })
            }
        }
        else {
            $results.Add([PSCustomObject]@{
                Path   = $entry.Path
                Name   = $entry.Name
                Value  = $entry.Value
                Status = "Preview"
            })
        }
    }

    return @($results.ToArray())
}

function Set-GameDVRPlaybackTweak {
    <#
        .SYNOPSIS
            Disables Windows Game DVR background recording and Xbox Game Bar broadcast.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableGameDVR = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $dvrVal = if ($DisableGameDVR) { 0 } else { 1 }
    $fseVal = if ($DisableGameDVR) { 2 } else { 0 }

    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value $dvrVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value $fseVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value $dvrVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value $dvrVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-DeliveryOptimizationTweak {
    <#
        .SYNOPSIS
            Disables peer-to-peer Windows Update Delivery Optimization over the Internet.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableP2P = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $modeVal = if ($DisableP2P) { 0 } else { 3 }

    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value $modeVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "SystemSettingsDownloadMode" -Value $modeVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-TelemetryServiceTweak {
    <#
        .SYNOPSIS
            Disables the Connected User Experiences and Telemetry background services (DiagTrack and dmwappushservice).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableServices = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $targetServices = @("DiagTrack", "dmwappushservice")
    $startType = if ($DisableServices) { "Disabled" } else { "Automatic" }

    foreach ($svcName in $targetServices) {
        if ($PSCmdlet.ShouldProcess("Service: $svcName", "Set StartupType to $startType")) {
            try {
                $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                if ($svc) {
                    if ($DisableServices -and $svc.Status -eq "Running") {
                        Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                    }
                    Set-Service -Name $svcName -StartupType $startType -ErrorAction SilentlyContinue
                    $ops.Add([PSCustomObject]@{ Path = "Service:\$svcName"; Name = "StartupType"; Value = $startType; Status = "Success" })
                } else {
                    $ops.Add([PSCustomObject]@{ Path = "Service:\$svcName"; Name = "StartupType"; Value = $startType; Status = "Skipped (Not Found)" })
                }
            } catch {
                $ops.Add([PSCustomObject]@{ Path = "Service:\$svcName"; Name = "StartupType"; Value = $startType; Status = "Error: $($_.Exception.Message)" })
            }
        } else {
            $ops.Add([PSCustomObject]@{ Path = "Service:\$svcName"; Name = "StartupType"; Value = $startType; Status = "Preview" })
        }
    }

    return $ops.ToArray()
}

function Set-StartMenuRecommendedTweak {
    <#
        .SYNOPSIS
            Hides the Recommended section and recent item tracking in the Windows 11 Start Menu.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$HideRecommended = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $recVal = if ($HideRecommended) { 1 } else { 0 }
    $trackVal = if ($HideRecommended) { 0 } else { 1 }

    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecommendedSection" -Value $recVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value $trackVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_AccountNotifications" -Value $trackVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-EdgeBackgroundTweak {
    <#
        .SYNOPSIS
            Disables Microsoft Edge startup boost and background extension processes.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableEdgeBackground = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    $val = if ($DisableEdgeBackground) { 0 } else { 1 }

    $ops.Add((Set-TweakRegistryValue -Path $edgePolicyPath -Name "StartupBoostEnabled" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $edgePolicyPath -Name "BackgroundModeEnabled" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-TelemetryScheduledTasksTweak {
    <#
        .SYNOPSIS
            Disables Windows Customer Experience Improvement Program and diagnostic scheduled tasks.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableTasks = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $tasks = @(
        @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" },
        @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip" },
        @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser" },
        @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "ProgramDataUpdater" }
    )

    foreach ($t in $tasks) {
        $taskFull = "$($t.Path)$($t.Name)"
        $action = if ($DisableTasks) { "Disable Task" } else { "Enable Task" }

        if ($PSCmdlet.ShouldProcess("Scheduled Task: $taskFull", $action)) {
            try {
                $existing = Get-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue
                if ($existing) {
                    if ($DisableTasks) {
                        Disable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null
                    } else {
                        Enable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null
                    }
                    $ops.Add([PSCustomObject]@{ Path = $t.Path; Name = $t.Name; Value = $action; Status = "Success" })
                } else {
                    $ops.Add([PSCustomObject]@{ Path = $t.Path; Name = $t.Name; Value = $action; Status = "Skipped (Not Found)" })
                }
            } catch {
                $ops.Add([PSCustomObject]@{ Path = $t.Path; Name = $t.Name; Value = $action; Status = "Error: $($_.Exception.Message)" })
            }
        } else {
            $ops.Add([PSCustomObject]@{ Path = $t.Path; Name = $t.Name; Value = $action; Status = "Preview" })
        }
    }

    return $ops.ToArray()
}

function Set-HibernationStorageTweak {
    <#
        .SYNOPSIS
            Disables Windows Hibernation to reclaim gigabytes of storage from hiberfil.sys.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableHibernation = $true
    )

    $action = if ($DisableHibernation) { "Disable Hibernation (powercfg /h off)" } else { "Enable Hibernation (powercfg /h on)" }

    if ($PSCmdlet.ShouldProcess("System Power Management", $action)) {
        try {
            $arg = if ($DisableHibernation) { "/hibernate off" } else { "/hibernate on" }
            Start-Process -FilePath "powercfg.exe" -ArgumentList $arg -NoNewWindow -Wait -ErrorAction Stop
            return [PSCustomObject]@{ Path = "powercfg.exe"; Name = "Hibernation"; Value = $arg; Status = "Success" }
        } catch {
            return [PSCustomObject]@{ Path = "powercfg.exe"; Name = "Hibernation"; Value = $action; Status = "Error: $($_.Exception.Message)" }
        }
    } else {
        return [PSCustomObject]@{ Path = "powercfg.exe"; Name = "Hibernation"; Value = $action; Status = "Preview" }
    }
}

function Set-MultitaskingTweak {
    <#
        .SYNOPSIS
            Configures Windows 11 Snap Assist and multitasking suggestions.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableSnapSuggestions = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $val = if ($DisableSnapSuggestions) { 0 } else { 1 }

    $ops.Add((Set-TweakRegistryValue -Path $advPath -Name "SnapAssist" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path $advPath -Name "EnableTaskGroups" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-CopilotAITweak {
    <#
        .SYNOPSIS
            Disables Windows Copilot policies, taskbar button, and optionally removes Copilot AppX packages.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableCopilot = $true,

        [Parameter(Mandatory = $false)]
        [bool]$RemoveAppxPackage = $false
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $copilotVal = if ($DisableCopilot) { 1 } else { 0 }
    $btnVal = if ($DisableCopilot) { 0 } else { 1 }

    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value $copilotVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value $copilotVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value $btnVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    if ($RemoveAppxPackage) {
        $copilotPkgs = @("Microsoft.Copilot", "Microsoft.Windows.Copilot")
        foreach ($pkg in $copilotPkgs) {
            if ($PSCmdlet.ShouldProcess("AppX Package: $pkg", "Remove Copilot AppX Package")) {
                try {
                    $found = Get-AppxPackage -Name "*$pkg*" -ErrorAction SilentlyContinue
                    if ($found) {
                        Remove-AppxPackage -Package $found.PackageFullName -ErrorAction Stop
                        $ops.Add([PSCustomObject]@{ Path = "AppX"; Name = $pkg; Value = "Removed"; Status = "Success" })
                    } else {
                        $ops.Add([PSCustomObject]@{ Path = "AppX"; Name = $pkg; Value = "Not Found"; Status = "Skipped" })
                    }
                } catch {
                    $ops.Add([PSCustomObject]@{ Path = "AppX"; Name = $pkg; Value = "Error"; Status = "Error: $($_.Exception.Message)" })
                }
            } else {
                $ops.Add([PSCustomObject]@{ Path = "AppX"; Name = $pkg; Value = "Remove Package"; Status = "Preview" })
            }
        }
    }

    return $ops.ToArray()
}

function Set-RecallAITweak {
    <#
        .SYNOPSIS
            Disables Windows Recall, screen analysis, Click to Do, and snapshot stores.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableRecall = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $aiVal = if ($DisableRecall) { 1 } else { 0 }
    $snapVal = if ($DisableRecall) { 0 } else { 1 }

    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value $aiVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value $aiVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "AllowSnapshotStore" -Value $snapVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "AllowSnapshotStore" -Value $snapVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\ClickToDo" -Name "ClickToDoAllowed" -Value $snapVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ClickToDo" -Name "ClickToDoAllowed" -Value $snapVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))

    return $ops.ToArray()
}

function Set-ApplicationAITweak {
    <#
        .SYNOPSIS
            Disables integrated AI features in Microsoft Edge, Paint (Cocreator), and Notepad (Cowriter).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$DisableEdgeAI = $true,

        [Parameter(Mandatory = $false)]
        [bool]$DisablePaintAI = $false,

        [Parameter(Mandatory = $false)]
        [bool]$DisableNotepadAI = $false
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($DisableEdgeAI) {
        $edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        $ops.Add((Set-TweakRegistryValue -Path $edgePath -Name "HubsSidebarEnabled" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-TweakRegistryValue -Path $edgePath -Name "ComposeInlineEnabled" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    if ($DisablePaintAI) {
        $paintPath = "HKCU:\Software\Microsoft\Paint\Settings"
        $ops.Add((Set-TweakRegistryValue -Path $paintPath -Name "EnableCocreator" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Policies\Microsoft\Paint" -Name "DisableCocreator" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    if ($DisableNotepadAI) {
        $notepadPath = "HKCU:\Software\Microsoft\Notepad"
        $ops.Add((Set-TweakRegistryValue -Path $notepadPath -Name "EnableAI" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-TweakRegistryValue -Path "HKCU:\Software\Policies\Microsoft\Notepad" -Name "DisableCowriter" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    return $ops.ToArray()
}

function Get-DebloatSafetyImpact {
    <#
        .SYNOPSIS
            Evaluates the combined safety and impact level of selected debloat actions.
        .DESCRIPTION
            Analyzes the quantity of packages and specific system tweak configurations,
            categorizing them into LOW / SAFE, MODERATE / CAUTION, or HIGH IMPACT.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [int]$AppCount = 0,

        [Parameter(Mandatory = $false)]
        [hashtable]$TweakFlags = @{}
    )

    $highImpactKeys = @("WindowsSandbox", "WSL")
    $cautionKeys = @("TelemetryService", "Hibernation", "FastStartup", "StorageSense", "PaintAI", "NotepadAI")

    $hasHigh = $false
    $hasCaution = $false
    $selectedTweakCount = 0

    foreach ($key in $TweakFlags.Keys) {
        if ($TweakFlags[$key] -eq $true) {
            $selectedTweakCount++
            if ($highImpactKeys -contains $key) {
                $hasHigh = $true
            }
            elseif ($cautionKeys -contains $key) {
                $hasCaution = $true
            }
        }
    }

    $totalOps = $AppCount + $selectedTweakCount

    if ($hasHigh) {
        return [PSCustomObject]@{
            Level         = "High"
            Rating        = "HIGH IMPACT"
            BadgeText     = "HIGH IMPACT"
            BgColor       = "#881337"
            BorderColor   = "#E11D48"
            FgColor       = "#F87171"
            IconKey       = "IconAlertOctagon"
            AppCount      = $AppCount
            TweakCount    = $selectedTweakCount
            TotalCount    = $totalOps
            SummaryText   = "$AppCount Apps • $selectedTweakCount Tweaks Selected"
            Description   = "System virtualization features selected (Hyper-V / WSL)."
        }
    }
    elseif ($hasCaution) {
        return [PSCustomObject]@{
            Level         = "Moderate"
            Rating        = "MODERATE / CAUTION"
            BadgeText     = "MODERATE / CAUTION"
            BgColor       = "#78350F"
            BorderColor   = "#D97706"
            FgColor       = "#FBBF24"
            IconKey       = "IconAlertTriangle"
            AppCount      = $AppCount
            TweakCount    = $selectedTweakCount
            TotalCount    = $totalOps
            SummaryText   = "$AppCount Apps • $selectedTweakCount Tweaks Selected"
            Description   = "Advanced tweaks selected (Services / Hibernation / App AI)."
        }
    }
    else {
        return [PSCustomObject]@{
            Level         = "Safe"
            Rating        = "LOW / SAFE"
            BadgeText     = "LOW / SAFE"
            BgColor       = "#064E3B"
            BorderColor   = "#059669"
            FgColor       = "#34D399"
            IconKey       = "IconCheckCircle"
            AppCount      = $AppCount
            TweakCount    = $selectedTweakCount
            TotalCount    = $totalOps
            SummaryText   = "$AppCount Apps • $selectedTweakCount Tweaks Selected"
            Description   = "All selected items are safe recommended optimizations."
        }
    }
}

Export-ModuleMember -Function Set-ConsumerFeatureTweak, Set-LockScreenTweak, Set-ClassicContextMenuTweak, Set-MousePrecisionTweak, Set-StickyKeysTweak, Set-FastStartupTweak, Set-StorageSenseTweak, Set-WindowsUpdatePolicyTweak, Set-OptionalFeatureState, Set-GameDVRPlaybackTweak, Set-DeliveryOptimizationTweak, Set-TelemetryServiceTweak, Set-StartMenuRecommendedTweak, Set-EdgeBackgroundTweak, Set-TelemetryScheduledTasksTweak, Set-HibernationStorageTweak, Set-MultitaskingTweak, Set-CopilotAITweak, Set-RecallAITweak, Set-ApplicationAITweak, Get-DebloatSafetyImpact, New-DebloatRestorePoint, Export-RegistrySnapshot, Restore-RegistrySnapshot

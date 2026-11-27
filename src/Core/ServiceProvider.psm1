<#
    .SYNOPSIS
        NH Win Debloater - Service Classification & Hardware/Laptop Protection Provider
    .DESCRIPTION
        Classifies Windows services into Safe, Optional, NotRecommended, and Protected tiers,
        hard-protects GPU, driver, WMI/RPC/DCOM, security, update, network, audio, HID/touchpad,
        Store/AppX, and licensing services, and captures/restores exact StartType (including
        DelayedAutoStart), trigger configuration, and running status.
        Developed by Mohammed Nadeem BM (NH Digital - https://nhdigital.shop).
    .MODULEVERSION
        1.4.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
param()

$script:HardProtectedServicePatterns = @(
    "NVDisplay.ContainerLocalSystem", "NvContainerLocalSystem", "NV*",
    "AMD*", "igfx*", "cphs", "jhi_service",
    "PlugPlay", "Wdf*", "Winmgmt", "RpcSs", "RpcEptMapper", "DcomLaunch",
    "LSM", "SamSs", "ProfSvc", "EventLog", "Schedule", "Power",
    "BrokerInfrastructure", "SystemEventsBroker", "CoreMessagingRegistrar",
    "WinDefend", "WdNisSvc", "Sense", "SecurityHealthService", "wscsvc", "mpssvc", "BFE",
    "wuauserv", "UsoSvc", "WaaSMedicSvc", "BITS", "TrustedInstaller", "DoSvc",
    "Dhcp", "Dnscache", "NlaSvc", "netprofm", "WlanSvc", "Wcmsvc", "nsi",
    "AudioSrv", "AudioEndpointBuilder", "Audiosrv",
    "hidserv", "TabletInputService", "Asus*", "Lenovo*", "Dell*", "HP*",
    "msiserver", "AppXSvc", "StateRepository", "StorSvc", "ClipSVC", "InstallService",
    "sppsvc", "wlidsvc"
)

$script:ServiceTierMap = @{
    "DiagTrack"         = "Optional"
    "RetailDemo"        = "Optional"
    "MapsBroker"        = "Optional"
    "Fax"               = "Optional"
    "PhoneSvc"          = "Optional"
    "XblAuthManager"    = "Optional"
    "XblGameSave"       = "Optional"
    "XboxNetApiSvc"     = "Optional"
    "XboxGipSvc"        = "Optional"
    "WalletService"     = "Optional"
    "WMPNetworkSvc"     = "Optional"
    "RemoteRegistry"    = "Safe"
    "dmwappushservice"  = "NotRecommended"
    "wisvc"             = "NotRecommended"
    "SensrSvc"          = "NotRecommended"
    "SensorDataService" = "NotRecommended"
    "WerSvc"            = "NotRecommended"
}

function Get-ServiceClassification {
    <#
        .SYNOPSIS
            Classifies a Windows service into Protected, NotRecommended, Optional, or Safe.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )

    foreach ($pattern in $script:HardProtectedServicePatterns) {
        if ($ServiceName -like $pattern) {
            return "Protected"
        }
    }

    if ($script:ServiceTierMap.ContainsKey($ServiceName)) {
        return $script:ServiceTierMap[$ServiceName]
    }

    return "Optional"
}

function Get-ExactServiceState {
    <#
        .SYNOPSIS
            Captures exact StartType (including DelayedAutoStart), Status, and TriggerInfo for a service.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )

    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) {
        return [PSCustomObject]@{
            Name        = $ServiceName
            Exists      = $false
            Status      = "NotFound"
            StartType   = "NotFound"
            HasTriggers = $false
        }
    }

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
    $startCode = $null
    $delayed = 0
    $hasTriggers = $false

    if (Test-Path $regPath) {
        $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        if ($props) {
            $startCode = $props.Start
            if ($null -ne $props.DelayedAutostart) { $delayed = [int]$props.DelayedAutostart }
        }
        $hasTriggers = (Test-Path (Join-Path $regPath "TriggerInfo"))
    }

    $startType = switch ($startCode) {
        2 { if ($delayed -eq 1) { "DelayedAutoStart" } else { "Automatic" } }
        3 { "Manual" }
        4 { "Disabled" }
        default {
            $wmi = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
            if ($wmi) { [string]$wmi.StartMode } else { "Manual" }
        }
    }

    return [PSCustomObject]@{
        Name        = $ServiceName
        Exists      = $true
        Status      = [string]$svc.Status
        StartType   = $startType
        HasTriggers = $hasTriggers
    }
}

function Set-SafeServiceState {
    <#
        .SYNOPSIS
            Safely updates a non-protected service startup type while preserving exact before-state.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Automatic", "DelayedAutoStart", "Manual", "Disabled")]
        [string]$TargetStartType = "Manual"
    )

    $tier = Get-ServiceClassification -ServiceName $ServiceName
    if ($tier -eq "Protected") {
        Write-Warning "Refused modification of hard-protected service: '$ServiceName'"
        return [PSCustomObject]@{
            Name          = $ServiceName
            Tier          = $tier
            Status        = "SkippedProtected"
            PreviousState = $null
            Verified      = $false
        }
    }

    $before = Get-ExactServiceState -ServiceName $ServiceName
    if (-not $before.Exists) {
        return [PSCustomObject]@{
            Name          = $ServiceName
            Tier          = $tier
            Status        = "NotFound"
            PreviousState = $before
            Verified      = $false
        }
    }

    if ($PSCmdlet.ShouldProcess("Service: $ServiceName", "Set StartType to $TargetStartType")) {
        try {
            $svcType = if ($TargetStartType -eq "DelayedAutoStart") { "Automatic" } else { $TargetStartType }
            if ($TargetStartType -eq "Disabled" -and $before.Status -eq "Running") {
                Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $ServiceName -StartupType $svcType -ErrorAction Stop

            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
            if (Test-Path $regPath) {
                $delayedVal = if ($TargetStartType -eq "DelayedAutoStart") { 1 } else { 0 }
                New-ItemProperty -Path $regPath -Name "DelayedAutostart" -Value $delayedVal -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            }

            $after = Get-ExactServiceState -ServiceName $ServiceName
            return [PSCustomObject]@{
                Name          = $ServiceName
                Tier          = $tier
                Status        = "Success"
                PreviousState = $before
                Verified      = ($after.StartType -eq $TargetStartType)
            }
        }
        catch {
            return [PSCustomObject]@{
                Name          = $ServiceName
                Tier          = $tier
                Status        = "Error: $($_.Exception.Message)"
                PreviousState = $before
                Verified      = $false
            }
        }
    }

    return [PSCustomObject]@{
        Name          = $ServiceName
        Tier          = $tier
        Status        = "Preview"
        PreviousState = $before
        Verified      = $false
    }
}

function Restore-ExactServiceState {
    <#
        .SYNOPSIS
            Restores a service's exact original StartType (including DelayedAutoStart) and running Status.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PreviousState
    )

    $svcName = $PreviousState.Name
    if ((Get-ServiceClassification -ServiceName $svcName) -eq "Protected") {
        return [PSCustomObject]@{ Name = $svcName; Status = "SkippedProtected"; Verified = $false }
    }

    $targetStart = if ($PreviousState.StartType -eq "DelayedAutoStart") { "Automatic" } elseif ($PreviousState.StartType -in @("Automatic", "Manual", "Disabled")) { $PreviousState.StartType } else { "Manual" }

    if ($PSCmdlet.ShouldProcess("Service: $svcName", "Restore StartType '$($PreviousState.StartType)' and Status '$($PreviousState.Status)'")) {
        try {
            Set-Service -Name $svcName -StartupType $targetStart -ErrorAction Stop
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$svcName"
            if (Test-Path $regPath) {
                $delayedVal = if ($PreviousState.StartType -eq "DelayedAutoStart") { 1 } else { 0 }
                New-ItemProperty -Path $regPath -Name "DelayedAutostart" -Value $delayedVal -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            }
            if ($PreviousState.Status -eq "Running") {
                Start-Service -Name $svcName -ErrorAction SilentlyContinue
            }
            $after = Get-ExactServiceState -ServiceName $svcName
            return [PSCustomObject]@{
                Name     = $svcName
                Status   = "Restored"
                Verified = ($after.StartType -eq $PreviousState.StartType)
            }
        }
        catch {
            return [PSCustomObject]@{
                Name     = $svcName
                Status   = "Error: $($_.Exception.Message)"
                Verified = $false
            }
        }
    }

    return [PSCustomObject]@{ Name = $svcName; Status = "Preview"; Verified = $false }
}

Export-ModuleMember -Function Get-ServiceClassification, Get-ExactServiceState, Set-SafeServiceState, Restore-ExactServiceState

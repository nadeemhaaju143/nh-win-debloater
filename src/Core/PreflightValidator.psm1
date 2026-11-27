<#
    .SYNOPSIS
        NH Win Debloater - System Preflight, Inventory & Validation Engine
    .DESCRIPTION
        Performs read-only system preflight checks, captures non-mutating system inventory,
        validates selected operations, generates structured dry-run previews, and evaluates
        approval requirements for scope and high-impact changes.
        Developed by Mohammed Nadeem BM (NH Digital - https://nhdigital.shop).
    .MODULEVERSION
        1.4.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param()

function Invoke-SystemPreflight {
    <#
        .SYNOPSIS
            Detects Windows edition/build, architecture, elevation, scope, disk space, and System Restore availability.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers", "DefaultUser")]
        [string]$Scope = "AllUsers"
    )

    $warnings = [System.Collections.Generic.List[string]]::new()

    $osCaption = "Windows"
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os -and $os.Caption) { $osCaption = $os.Caption.Trim() }
    } catch {}

    $build = 0
    try {
        $ntVer = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
        if ($ntVer -and $ntVer.CurrentBuild) { $build = [int]$ntVer.CurrentBuild }
    } catch {}

    $arch = $env:PROCESSOR_ARCHITECTURE
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $freeDiskGB = 0.0
    try {
        $sysDriveLetter = ($env:SystemDrive -replace ':', '').Trim()
        $drive = Get-PSDrive -Name $sysDriveLetter -ErrorAction SilentlyContinue
        if ($drive -and $null -ne $drive.Free) {
            $freeDiskGB = [math]::Round(($drive.Free / 1GB), 2)
        }
    } catch {}

    $srAvailable = $false
    try {
        $srPoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        $vssSvc = Get-Service -Name "VSS" -ErrorAction SilentlyContinue
        $srAvailable = ($null -ne $srPoints -or ($null -ne $vssSvc))
    } catch {}

    if ($Scope -ne "CurrentUser" -and -not $isAdmin) {
        $warnings.Add("Scope '$Scope' requires Administrator privileges for machine-wide policies and services.")
    }
    if ($freeDiskGB -gt 0 -and $freeDiskGB -lt 0.5) {
        $warnings.Add("Low system drive free space (${freeDiskGB} GB). Recovery snapshots may be constrained.")
    }

    return [PSCustomObject]@{
        Edition                = $osCaption
        Build                  = $build
        Architecture           = $arch
        IsAdmin                = $isAdmin
        Scope                  = $Scope
        FreeDiskSpaceGB        = $freeDiskGB
        SystemRestoreAvailable = $srAvailable
        Passed                 = ($warnings.Count -eq 0)
        Warnings               = $warnings.ToArray()
        Timestamp              = (Get-Date).ToString("o")
    }
}

function Get-ReadOnlySystemInventory {
    <#
        .SYNOPSIS
            Captures a read-only snapshot of services, registry values, tasks, packages, startup items, and powercfg state.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$RegistryPaths = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$ServiceNames = @()
    )

    $regSnapshot = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($path in $RegistryPaths) {
        if (Test-Path $path) {
            $item = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if ($item) {
                foreach ($prop in $item.PSObject.Properties) {
                    if ($prop.Name -notmatch '^PS') {
                        $regSnapshot.Add([PSCustomObject]@{
                            Path  = $path
                            Name  = $prop.Name
                            Value = $prop.Value
                        })
                    }
                }
            }
        }
    }

    $svcSnapshot = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($svcName in $ServiceNames) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            $wmi = Get-CimInstance -ClassName Win32_Service -Filter "Name='$svcName'" -ErrorAction SilentlyContinue
            $svcSnapshot.Add([PSCustomObject]@{
                Name        = $svcName
                Status      = [string]$svc.Status
                StartupType = if ($wmi) { [string]$wmi.StartMode } else { "Unknown" }
            })
        }
    }

    $startupEntries = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($runPath in @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")) {
        if (Test-Path $runPath) {
            $runItem = Get-ItemProperty -Path $runPath -ErrorAction SilentlyContinue
            if ($runItem) {
                foreach ($prop in $runItem.PSObject.Properties) {
                    if ($prop.Name -notmatch '^PS') {
                        $startupEntries.Add([PSCustomObject]@{ Path = $runPath; Name = $prop.Name; Value = $prop.Value })
                    }
                }
            }
        }
    }

    $activePowerScheme = ""
    try {
        $activePowerScheme = ((powercfg.exe /getactivescheme 2>$null) -join " ").Trim()
    } catch {}

    return [PSCustomObject]@{
        CapturedAt        = (Get-Date).ToString("o")
        RegistryValues    = $regSnapshot.ToArray()
        Services          = $svcSnapshot.ToArray()
        StartupEntries    = $startupEntries.ToArray()
        ActivePowerScheme = $activePowerScheme
    }
}

function Test-SelectedOperationValidity {
    <#
        .SYNOPSIS
            Validates selected operations against protected components, scope permissions, and current state.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Operations,

        [Parameter(Mandatory = $false)]
        [string[]]$ProtectedApps = @(),

        [Parameter(Mandatory = $false)]
        [bool]$IsAdmin = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers", "DefaultUser")]
        [string]$Scope = "AllUsers"
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($op in $Operations) {
        $valid = $true
        $status = "Valid"
        $reason = "Ready to apply."

        foreach ($prot in $ProtectedApps) {
            if ($op.Target -like "*$prot*") {
                $valid = $false
                $status = "SkippedProtected"
                $reason = "Target '$($op.Target)' is protected against modification."
                break
            }
        }

        if ($valid -and $op.RequiresAdmin -and -not $IsAdmin -and $Scope -ne "CurrentUser") {
            $valid = $false
            $status = "RequiresAdmin"
            $reason = "Operation '$($op.OperationId)' requires Administrator elevation."
        }

        if ($valid -and $null -ne $op.CurrentValue -and $op.CurrentValue -eq $op.RequestedValue) {
            $valid = $false
            $status = "AlreadyApplied"
            $reason = "Target already matches requested state '$($op.RequestedValue)'."
        }

        $results.Add([PSCustomObject]@{
            OperationId = $op.OperationId
            Target      = $op.Target
            Valid       = $valid
            Status      = $status
            Reason      = $reason
        })
    }

    return $results.ToArray()
}

function New-DryRunOperationPreview {
    <#
        .SYNOPSIS
            Formats queued operations into structured dry-run preview records.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Operations
    )

    $previews = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($op in $Operations) {
        $previews.Add([PSCustomObject]@{
            OperationId    = $op.OperationId
            Category       = $op.Category
            Target         = $op.Target
            CurrentValue   = if ($null -ne $op.CurrentValue) { [string]$op.CurrentValue } else { "Default/Unset" }
            ProposedValue  = [string]$op.RequestedValue
            ExpectedImpact = if ($op.ExpectedImpact) { $op.ExpectedImpact } else { "Low / Reversible" }
            RecoveryMethod = if ($op.RecoveryMethod) { $op.RecoveryMethod } else { "Session JSON Rollback" }
        })
    }
    return $previews.ToArray()
}

function Test-ApprovalRequirement {
    <#
        .SYNOPSIS
            Determines required user confirmation gates for execution scope and high-impact operations.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers", "DefaultUser")]
        [string]$Scope = "AllUsers",

        [Parameter(Mandatory = $false)]
        [bool]$HasHighImpact = $false
    )

    $requiresScopeConfirm = ($Scope -eq "AllUsers" -or $Scope -eq "DefaultUser")
    $messages = [System.Collections.Generic.List[string]]::new()
    if ($requiresScopeConfirm) {
        $messages.Add("System-wide scope ('$Scope') will modify machine policies and all-user packages.")
    }
    if ($HasHighImpact) {
        $messages.Add("High-impact virtualization or system-level changes are queued.")
    }

    return [PSCustomObject]@{
        RequiresPrimaryApproval           = $true
        RequiresElevatedScopeConfirmation = $requiresScopeConfirm
        RequiresHighImpactConfirmation    = $HasHighImpact
        PromptSummary                     = ($messages -join " ")
    }
}

Export-ModuleMember -Function Invoke-SystemPreflight, Get-ReadOnlySystemInventory, Test-SelectedOperationValidity, New-DryRunOperationPreview, Test-ApprovalRequirement

<#
    .SYNOPSIS
        NH Win Debloater - Application Management Engine
    .DESCRIPTION
        Safely identifies and removes bloatware AppX and provisioned packages,
        enforces non-bypassable protection for essential system components,
        supports multi-user and default-user Sysprep environments,
        and provides reinstall capability for default/Store apps.
    .MODULEVERSION
        0.1.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
param()

$script:ProtectedSystemPackages = @(
    "Microsoft.WindowsStore",
    "Microsoft.SecHealthUI",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.WindowsTerminal",
    "Microsoft.VCLibs",
    "Microsoft.NET.Native",
    "Microsoft.UI.Xaml",
    "Microsoft.Services.Store.Engagement",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Windows.ShellExperienceHost",
    "Microsoft.Windows.StartMenuExperienceHost",
    "Microsoft.Windows.Search"
)

function Get-ProtectedApp {
    <#
        .SYNOPSIS
            Retrieves the list of protected system applications.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string]$PresetsPath
    )

    if ($PresetsPath -and (Test-Path (Join-Path $PresetsPath "ProtectedApps.json"))) {
        try {
            $jsonList = Get-Content (Join-Path $PresetsPath "ProtectedApps.json") -Raw | ConvertFrom-Json
            if ($jsonList -and $jsonList.Count -gt 0) {
                return [string[]]$jsonList
            }
        }
        catch {
            Write-Verbose "Could not load ProtectedApps.json: $($_.Exception.Message)"
        }
    }

    return [string[]]$script:ProtectedSystemPackages
}

function Test-IsProtectedApp {
    <#
        .SYNOPSIS
            Tests whether a given package is protected against deletion.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId,

        [string]$PresetsPath
    )

    $protectedList = Get-ProtectedApp -PresetsPath $PresetsPath

    foreach ($protected in $protectedList) {
        if ($AppId -like "*$protected*" -or $protected -like "*$AppId*") {
            return $true
        }
    }

    return $false
}

function Get-DebloatPreset {
    <#
        .SYNOPSIS
            Loads an application debloat preset profile.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Minimal", "Deep")]
        [string]$PresetName,

        [Parameter(Mandatory = $true)]
        [string]$PresetsPath
    )

    $fileName = switch ($PresetName) {
        "Default" { "DefaultApps.json" }
        "Minimal" { "MinimalApps.json" }
        "Deep"    { "DeepDebloatApps.json" }
    }

    $filePath = Join-Path $PresetsPath $fileName
    if (-not (Test-Path $filePath)) {
        Write-Error "Preset file not found at path: $filePath"
        return @()
    }

    try {
        $data = Get-Content -Path $filePath -Raw -Encoding UTF8 | ConvertFrom-Json
        return @($data)
    }
    catch {
        Write-Error "Failed to parse preset file '$fileName': $($_.Exception.Message)"
        return @()
    }
}

function Get-InstalledDebloatApp {
    <#
        .SYNOPSIS
            Scans installed and provisioned AppX packages.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [string]$PresetsPath
    )

    $installedPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    $provisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($pkg in $installedPackages) {
        $isProtected = Test-IsProtectedApp -AppId $pkg.Name -PresetsPath $PresetsPath
        $results.Add([PSCustomObject]@{
            AppId           = $pkg.Name
            PackageFullName = $pkg.PackageFullName
            Publisher       = $pkg.PublisherId
            IsProvisioned   = $false
            IsProtected     = $isProtected
            Version         = $pkg.Version
        })
    }

    foreach ($prov in $provisionedPackages) {
        $existing = $results | Where-Object { $_.AppId -eq $prov.DisplayName }
        if ($null -ne $existing) {
            $existing.IsProvisioned = $true
        }
        else {
            $isProtected = Test-IsProtectedApp -AppId $prov.DisplayName -PresetsPath $PresetsPath
            $results.Add([PSCustomObject]@{
                AppId           = $prov.DisplayName
                PackageFullName = $prov.PackageName
                Publisher       = ""
                IsProvisioned   = $true
                IsProtected     = $isProtected
                Version         = $prov.Version
            })
        }
    }

    return $results.ToArray()
}

function Remove-DebloatApp {
    <#
        .SYNOPSIS
            Safely uninstalls selected bloatware packages with multi-user and Sysprep scope support.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$AppIdList,

        [Parameter(Mandatory = $false)]
        [bool]$AllUsers = $true,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers", "DefaultUser")]
        [string]$TargetScope = "AllUsers",

        [string]$PresetsPath
    )

    process {
        foreach ($appId in $AppIdList) {
            if ([string]::IsNullOrWhiteSpace($appId)) { continue }

            # Safety gate: Ensure protected system components cannot be removed
            if (Test-IsProtectedApp -AppId $appId -PresetsPath $PresetsPath) {
                Write-Warning "Skipped protected system package: '$appId'"
                [PSCustomObject]@{
                    AppId   = $appId
                    Status  = "SkippedProtected"
                    Message = "Package is protected against removal."
                }
                continue
            }

            if ($PSCmdlet.ShouldProcess("Package: $appId (Scope: $TargetScope)", "Remove AppX and Provisioned Package")) {
                $removed = $false
                $errorMessage = $null

                # 1. Remove Provisioned Package (Applies to AllUsers and DefaultUser / Sysprep)
                if ($TargetScope -eq "AllUsers" -or $TargetScope -eq "DefaultUser" -or $AllUsers) {
                    try {
                        $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                            Where-Object { $_.DisplayName -eq $appId -or $_.PackageName -like "*$appId*" }

                        foreach ($p in $prov) {
                            Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null
                            $removed = $true
                        }
                    }
                    catch {
                        $errorMessage = "Provisioned removal error: $($_.Exception.Message)"
                    }
                }

                # 2. Remove Current or AllUsers Installed Package
                if ($TargetScope -ne "DefaultUser") {
                    try {
                        $installed = if ($TargetScope -eq "AllUsers" -or $AllUsers) {
                            Get-AppxPackage -Name "*$appId*" -AllUsers -ErrorAction SilentlyContinue
                        } else {
                            Get-AppxPackage -Name "*$appId*" -ErrorAction SilentlyContinue
                        }

                        foreach ($pkg in $installed) {
                            if ($TargetScope -eq "AllUsers" -or $AllUsers) {
                                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop | Out-Null
                            } else {
                                Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop | Out-Null
                            }
                            $removed = $true
                        }
                    }
                    catch {
                        if ($null -eq $errorMessage) {
                            $errorMessage = "Installed removal error: $($_.Exception.Message)"
                        } else {
                            $errorMessage += " | Installed removal error: $($_.Exception.Message)"
                        }
                    }
                }

                if ($removed -and ($null -eq $errorMessage)) {
                    [PSCustomObject]@{
                        AppId   = $appId
                        Status  = "Success"
                        Message = "Package removed successfully (Scope: $TargetScope)."
                    }
                }
                elseif ($removed) {
                    [PSCustomObject]@{
                        AppId   = $appId
                        Status  = "Warning"
                        Message = "Package removed with warnings: $errorMessage"
                    }
                }
                else {
                    [PSCustomObject]@{
                        AppId   = $appId
                        Status  = "NotFound"
                        Message = "Package was not installed on this system."
                    }
                }
            }
            else {
                # WhatIf preview branch
                [PSCustomObject]@{
                    AppId   = $appId
                    Status  = "Preview"
                    Message = "WhatIf: Package '$appId' would be removed for scope: $TargetScope."
                }
            }
        }
    }
}

function Restore-DefaultApp {
    <#
        .SYNOPSIS
            Re-registers default or Store applications.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$AppId = "All"
    )

    if ($PSCmdlet.ShouldProcess("Target: $AppId", "Re-register Default / Microsoft Store Applications")) {
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()
        try {
            $manifestPattern = if ($AppId -eq "All") {
                "$env:ProgramFiles\WindowsApps\*\AppxManifest.xml"
            } else {
                "$env:ProgramFiles\WindowsApps\*$AppId*\AppxManifest.xml"
            }

            $manifests = Get-ChildItem -Path $manifestPattern -ErrorAction SilentlyContinue

            foreach ($manifest in $manifests) {
                try {
                    Add-AppxPackage -DisableDevelopmentMode -Register $manifest.FullName -ErrorAction Stop
                    $results.Add([PSCustomObject]@{
                        AppId   = $manifest.Directory.Name
                        Status  = "Success"
                        Message = "Re-registered from $($manifest.FullName)"
                    })
                }
                catch {
                    $results.Add([PSCustomObject]@{
                        AppId   = $manifest.Directory.Name
                        Status  = "Error"
                        Message = $_.Exception.Message
                    })
                }
            }
        }
        catch {
            $results.Add([PSCustomObject]@{
                AppId   = $AppId
                Status  = "Error"
                Message = "General re-registration error: $($_.Exception.Message)"
            })
        }

        return $results.ToArray()
    }
    else {
        return @([PSCustomObject]@{
            AppId   = $AppId
            Status  = "Preview"
            Message = "WhatIf: Default packages would be re-registered from WindowsApps."
        })
    }
}

Export-ModuleMember -Function Get-ProtectedApp, Test-IsProtectedApp, Get-DebloatPreset, Get-InstalledDebloatApp, Remove-DebloatApp, Restore-DefaultApp

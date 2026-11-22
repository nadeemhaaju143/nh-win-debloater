<#
    .SYNOPSIS
        NH Win Debloater - Application Management Engine
    .DESCRIPTION
        Safely identifies and removes bloatware AppX and provisioned packages,
        enforces non-bypassable protection for essential system components,
        supports multi-user and default-user Sysprep environments,
        and provides reinstall capability for default/Store apps.
    .MODULEVERSION
        1.3.0
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

$script:CachedProtectedApps = $null

function Get-ProtectedApp {
    <#
        .SYNOPSIS
            Retrieves the list of protected system applications with in-memory caching.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string]$PresetsPath
    )

    if ($null -ne $script:CachedProtectedApps) {
        return [string[]]$script:CachedProtectedApps
    }

    if ($PresetsPath -and (Test-Path (Join-Path $PresetsPath "ProtectedApps.json"))) {
        try {
            $jsonList = Get-Content (Join-Path $PresetsPath "ProtectedApps.json") -Raw | ConvertFrom-Json
            if ($jsonList -and $jsonList.Count -gt 0) {
                $script:CachedProtectedApps = [string[]]$jsonList
                return [string[]]$script:CachedProtectedApps
            }
        }
        catch {
            Write-Verbose "Could not load ProtectedApps.json: $($_.Exception.Message)"
        }
    }

    $script:CachedProtectedApps = [string[]]$script:ProtectedSystemPackages
    return [string[]]$script:CachedProtectedApps
}

function Test-IsProtectedApp {
    <#
        .SYNOPSIS
            Tests whether a given package is protected against deletion.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [object]$AppId,

        [string]$PresetsPath
    )

    if ($null -eq $AppId) { return $false }

    $appIdList = if ($AppId -is [System.Collections.IEnumerable] -and $AppId -isnot [string]) {
        @($AppId)
    } else {
        @([string]$AppId)
    }

    $protectedList = Get-ProtectedApp -PresetsPath $PresetsPath

    foreach ($singleId in $appIdList) {
        $idStr = [string]$singleId
        if ([string]::IsNullOrWhiteSpace($idStr)) { continue }
        foreach ($protected in $protectedList) {
            if ($idStr -like "*$protected*" -or $protected -like "*$idStr*") {
                return $true
            }
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
        $resultList = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($item in $data) {
            if (-not $item -or -not $item.AppId) { continue }
            if ($item.AppId -is [System.Collections.IEnumerable] -and $item.AppId -isnot [string]) {
                foreach ($id in $item.AppId) {
                    $idStr = [string]$id
                    if (-not [string]::IsNullOrWhiteSpace($idStr)) {
                        $resultList.Add([PSCustomObject]@{
                            AppId          = $idStr
                            DisplayName    = if ($item.DisplayName -is [string]) { $item.DisplayName } else { $idStr }
                            Recommendation = $item.Recommendation
                            RemovalMethod  = $item.RemovalMethod
                        })
                    }
                }
            } else {
                $idStr = [string]$item.AppId
                if (-not [string]::IsNullOrWhiteSpace($idStr)) {
                    $resultList.Add([PSCustomObject]@{
                        AppId          = $idStr
                        DisplayName    = if ($item.DisplayName -is [string]) { $item.DisplayName } else { $idStr }
                        Recommendation = $item.Recommendation
                        RemovalMethod  = $item.RemovalMethod
                    })
                }
            }
        }
        return @($resultList)
    }
    catch {
        Write-Error "Failed to parse preset file '$fileName': $($_.Exception.Message)"
        return @()
    }
}

function Get-InstalledDebloatApp {
    <#
        .SYNOPSIS
            Scans installed and provisioned AppX packages with high-performance dictionary indexing.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [string]$PresetsPath
    )

    $installedPackages = try { Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue 2>$null } catch { $null }
    if (-not $installedPackages -or $installedPackages.Count -eq 0) {
        $installedPackages = try { Get-AppxPackage -ErrorAction SilentlyContinue 2>$null } catch { $null }
    }
    $provisionedPackages = try { Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue 2>$null } catch { $null }

    $resultsDict = [System.Collections.Generic.Dictionary[string, PSCustomObject]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $protectedList = Get-ProtectedApp -PresetsPath $PresetsPath

    foreach ($pkg in $installedPackages) {
        if (-not $pkg.Name) { continue }
        $isProtected = $false
        foreach ($protected in $protectedList) {
            if ($pkg.Name -like "*$protected*" -or $protected -like "*$pkg.Name*") {
                $isProtected = $true
                break
            }
        }
        $resultsDict[$pkg.Name] = [PSCustomObject]@{
            AppId           = $pkg.Name
            PackageFullName = $pkg.PackageFullName
            Publisher       = $pkg.PublisherId
            IsProvisioned   = $false
            IsProtected     = $isProtected
            Version         = $pkg.Version
        }
    }

    if ($provisionedPackages) {
        foreach ($prov in $provisionedPackages) {
            if (-not $prov.DisplayName) { continue }
            if ($resultsDict.ContainsKey($prov.DisplayName)) {
                $resultsDict[$prov.DisplayName].IsProvisioned = $true
            }
            else {
                $isProtected = $false
                foreach ($protected in $protectedList) {
                    if ($prov.DisplayName -like "*$protected*" -or $protected -like "*$prov.DisplayName*") {
                        $isProtected = $true
                        break
                    }
                }
                $resultsDict[$prov.DisplayName] = [PSCustomObject]@{
                    AppId           = $prov.DisplayName
                    PackageFullName = $prov.PackageName
                    Publisher       = ""
                    IsProvisioned   = $true
                    IsProtected     = $isProtected
                    Version         = $prov.Version
                }
            }
        }
    }

    return [PSCustomObject[]]@($resultsDict.Values)
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

function Export-DebloatProfile {
    <#
        .SYNOPSIS
            Exports current selection of bloatware packages and system tweaks to a portable JSON profile.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$ProfileName = "Custom Preset Profile",

        [Parameter(Mandatory = $false)]
        [string[]]$SelectedApps = @(),

        [Parameter(Mandatory = $false)]
        [hashtable]$SelectedTweaks = @{},

        [Parameter(Mandatory = $false)]
        [string]$AppVersion = "0.5"
    )

    $parentDir = Split-Path -Parent $FilePath
    if (-not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }

    $profileData = [ordered]@{
        SchemaVersion  = "1.0"
        ProfileName    = $ProfileName
        AppVersion     = $AppVersion
        ExportedAt     = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        SelectedApps   = @($SelectedApps | Sort-Object -Unique)
        SelectedTweaks = $SelectedTweaks
    }

    $json = $profileData | ConvertTo-Json -Depth 5
    Set-Content -Path $FilePath -Value $json -Encoding UTF8 -Force
    return $FilePath
}

function Import-DebloatProfile {
    <#
        .SYNOPSIS
            Imports and validates a debloat preset JSON profile.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        throw "Profile file not found: '$FilePath'."
    }

    $rawContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($rawContent)) {
        throw "Profile file is empty: '$FilePath'."
    }

    try {
        $data = $rawContent | ConvertFrom-Json
    } catch {
        throw "Failed to parse JSON in profile '$FilePath': $($_.Exception.Message)"
    }

    if (-not $data) {
        throw "Invalid profile structure in '$FilePath'."
    }

    $apps = [System.Collections.Generic.List[string]]::new()
    if ($data.SelectedApps) {
        foreach ($app in $data.SelectedApps) {
            if (-not [string]::IsNullOrWhiteSpace($app)) {
                $apps.Add([string]$app)
            }
        }
    }

    $tweaks = @{}
    if ($data.SelectedTweaks) {
        foreach ($prop in $data.SelectedTweaks.PSObject.Properties) {
            $tweaks[$prop.Name] = [bool]$prop.Value
        }
    }

    $name = if ($data.ProfileName) { [string]$data.ProfileName } else { "Imported Profile" }
    $ver = if ($data.AppVersion) { [string]$data.AppVersion } else { "0.5" }

    return [PSCustomObject]@{
        ProfileName    = $name
        AppVersion     = $ver
        ExportedAt     = [string]$data.ExportedAt
        SelectedApps   = $apps.ToArray()
        SelectedTweaks = $tweaks
    }
}

function Install-CommonWindowsApp {
    <#
        .SYNOPSIS
            Reinstalls commonly needed built-in Windows applications and Microsoft Store.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Store", "Calculator", "Notepad", "Paint", "Photos", "Terminal")]
        [string]$AppName
    )

    $appCatalog = @{
        "Store"      = @{ Name = "Microsoft Store"; Package = "Microsoft.WindowsStore"; WingetId = "9WZDNCRFJBMP"; WsReset = $true }
        "Calculator" = @{ Name = "Windows Calculator"; Package = "Microsoft.WindowsCalculator"; WingetId = "9WZDNCRFHVN5"; WsReset = $false }
        "Notepad"    = @{ Name = "Windows Notepad"; Package = "Microsoft.WindowsNotepad"; WingetId = "9MSMLRH6LZF0"; WsReset = $false }
        "Paint"      = @{ Name = "Paint"; Package = "Microsoft.Paint"; WingetId = "9PCFS5B6T72H"; WsReset = $false }
        "Photos"     = @{ Name = "Microsoft Photos"; Package = "Microsoft.Windows.Photos"; WingetId = "9WZDNCRFJ3Q2"; WsReset = $false }
        "Terminal"   = @{ Name = "Windows Terminal"; Package = "Microsoft.WindowsTerminal"; WingetId = "9N0DX20HK701"; WsReset = $false }
    }

    $info = $appCatalog[$AppName]

    if ($PSCmdlet.ShouldProcess("App: $($info.Name)", "Reinstall/Register package")) {
        try {
            # Method 1: Store wsreset
            if ($info.WsReset) {
                Start-Process -FilePath "wsreset.exe" -ArgumentList "-i" -NoNewWindow -Wait -ErrorAction SilentlyContinue
                return [PSCustomObject]@{
                    AppName     = $AppName
                    DisplayName = $info.Name
                    Method      = "wsreset -i"
                    Status      = "Success"
                    Message     = "Microsoft Store registration initiated via wsreset -i"
                }
            }

            # Method 2: Re-register from WindowsApps manifest if present on system
            $manifest = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps\*$($info.Package)*\AppxManifest.xml" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($manifest) {
                Add-AppxPackage -DisableDevelopmentMode -Register $manifest.FullName -ErrorAction Stop
                return [PSCustomObject]@{
                    AppName     = $AppName
                    DisplayName = $info.Name
                    Method      = "AppX Manifest"
                    Status      = "Success"
                    Message     = "Re-registered from $($manifest.FullName)"
                }
            }

            # Method 3: Winget install fallback
            $wingetCmd = Get-Command "winget.exe" -ErrorAction SilentlyContinue
            if ($wingetCmd) {
                $wingetArgs = "install --id $($info.WingetId) --silent --accept-package-agreements --accept-source-agreements"
                $p = Start-Process -FilePath "winget.exe" -ArgumentList $wingetArgs -NoNewWindow -PassThru -Wait
                $status = if ($p.ExitCode -eq 0) { "Success" } else { "Notice" }
                return [PSCustomObject]@{
                    AppName     = $AppName
                    DisplayName = $info.Name
                    Method      = "winget"
                    Status      = $status
                    Message     = "Winget completed with exit code $($p.ExitCode)"
                }
            }

            return [PSCustomObject]@{
                AppName     = $AppName
                DisplayName = $info.Name
                Method      = "None"
                Status      = "Error"
                Message     = "Could not locate package manifest in WindowsApps and winget is not available."
            }
        }
        catch {
            return [PSCustomObject]@{
                AppName     = $AppName
                DisplayName = $info.Name
                Method      = "Exception"
                Status      = "Error"
                Message     = $_.Exception.Message
            }
        }
    }
    else {
        return [PSCustomObject]@{
            AppName     = $AppName
            DisplayName = $info.Name
            Method      = "WhatIf"
            Status      = "Preview"
            Message     = "Would reinstall / re-register $($info.Name) using AppX Manifest or winget ($($info.WingetId))."
        }
    }
}

Export-ModuleMember -Function Get-ProtectedApp, Test-IsProtectedApp, Get-DebloatPreset, Get-InstalledDebloatApp, Remove-DebloatApp, Restore-DefaultApp, Export-DebloatProfile, Import-DebloatProfile, Install-CommonWindowsApp

<#
    .SYNOPSIS
        NH Win Debloater - Application Management Engine
    .DESCRIPTION
        Safely identifies and removes bloatware AppX and provisioned packages,
        enforces non-bypassable protection for essential system components,
        supports multi-user and default-user Sysprep environments,
        and provides reinstall capability for default/Store apps.
    .MODULEVERSION
        1.4.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
param()

$script:ProtectedSystemPackages = @(
    "Microsoft.WindowsStore",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Services.Store.Engagement",
    "Microsoft.SecHealthUI",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.WindowsTerminal",
    "Microsoft.WindowsNotepad",
    "Microsoft.ScreenSketch",
    "Microsoft.Paint",
    "Microsoft.MSPaint",
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsCamera",
    "Microsoft.ZuneMusic",
    "Microsoft.WindowsMediaPlayer",
    "Microsoft.Windows.Photos",
    "Microsoft.VCLibs",
    "Microsoft.NET.Native",
    "Microsoft.UI.Xaml",
    "Microsoft.Windows.ShellExperienceHost",
    "Microsoft.Windows.StartMenuExperienceHost",
    "Microsoft.Windows.Search",
    "Microsoft.HEIFImageExtension",
    "Microsoft.HEVCVideoExtension",
    "Microsoft.WebpImageExtension",
    "Microsoft.WebMediaExtensions",
    "Microsoft.AV1VideoExtension",
    "Microsoft.VP9VideoExtensions",
    "Microsoft.RawImageExtension",
    "Microsoft.MPEG2VideoExtension",
    "NVIDIACorp.NVIDIAControlPanel",
    "NVIDIACorp.",
    "AppUp.IntelGraphicsExperience",
    "AppUp.ThunderboltControlCenter",
    "RealtekSemiconductorCorp.RealtekAudioControl",
    "Microsoft.MicrosoftEdge.Stable",
    "Microsoft.EdgeWebView2Runtime"
)

$script:BuiltinAppAliases = @{
    "Microsoft.Copilot"    = @("Microsoft.Copilot", "XP9CXNGPPJ97XX", "Microsoft.Windows.Ai.Copilot.Provider")
    "Microsoft.OneDrive"   = @("Microsoft.OneDrive", "Microsoft.OneDriveSync")
    "Facebook.Instagram"   = @("Facebook.Instagram", "Facebook.InstagramBeta")
    "LinkedInforWindows"   = @("LinkedInforWindows", "7EE7776C.LinkedInforWindows")
}

$script:CoreFrameworkPatterns = @(
    "MicrosoftWindows.Client.*",
    "*SecHealthUI*",
    "*ShellExperienceHost*",
    "*StartMenuExperienceHost*",
    "*MicrosoftEdge.Stable*",
    "*Microsoft.VCLibs*",
    "*Microsoft.UI.Xaml*",
    "*WindowsAppRuntime*",
    "*Microsoft.NET.Native*",
    "*Microsoft.DesktopAppInstaller*",
    "*Microsoft.AAD.BrokerPlugin*",
    "*Microsoft.AccountsControl*",
    "*Microsoft.AsyncTextService*",
    "*Microsoft.BioEnrollment*",
    "*Microsoft.CredDialogHost*",
    "*Microsoft.LockApp*",
    "*Microsoft.ECApp*",
    "*Microsoft.ApplicationCompatibilityEnhancements*",
    "*Microsoft.Windows.Search*",
    "*Microsoft.HEIFImageExtension*",
    "*Microsoft.HEVCVideoExtension*",
    "*Microsoft.WebpImageExtension*",
    "*Microsoft.WebMediaExtensions*",
    "*Microsoft.AV1VideoExtension*",
    "*Microsoft.VP9VideoExtensions*",
    "*Microsoft.RawImageExtension*",
    "*Microsoft.MPEG2VideoExtension*",
    "*NVIDIACorp.*",
    "*AppUp.IntelGraphicsExperience*",
    "*AppUp.ThunderboltControlCenter*",
    "*RealtekSemiconductorCorp.RealtekAudioControl*",
    "*Microsoft.EdgeWebView2Runtime*",
    "1527c705-839a-4832-9118-54d4Bd6a0c89",
    "c5e2524a-ea46-4f67-841f-6a9465d9d515",
    "E2A4F912-2574-4A75-9BB0-0D023378592B",
    "F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE"
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

function Test-IsCoreSystemFramework {
    <#
        .SYNOPSIS
            Tests whether a package ID belongs to a core Windows shell or runtime framework.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$AppId
    )

    if ([string]::IsNullOrWhiteSpace($AppId)) { return $false }

    foreach ($pattern in $script:CoreFrameworkPatterns) {
        if ($AppId -like $pattern) {
            return $true
        }
    }

    return $false
}

function Get-OneDriveInstallInfo {
    <#
        .SYNOPSIS
            Detects Microsoft OneDrive installation across Win32 setup/uninstall keys and AppX sync packages.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $setupCandidates = @(
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\Update\OneDriveSetup.exe"
    )

    $uninstallKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
    )

    $win32Detected = $false
    $foundSetupPath = $null
    $setupPathsList = [System.Collections.Generic.List[string]]::new()

    foreach ($uKey in $uninstallKeys) {
        if (Test-Path $uKey) {
            $win32Detected = $true
            $props = Get-ItemProperty -Path $uKey -ErrorAction SilentlyContinue
            if ($props) {
                foreach ($strProp in @($props.QuietUninstallString, $props.UninstallString)) {
                    if ($strProp -and $strProp -match '([A-Za-z]:\\[^"]*?OneDriveSetup\.exe)') {
                        $exePath = $Matches[1]
                        if (-not $foundSetupPath) { $foundSetupPath = $exePath }
                        if (-not $setupPathsList.Contains($exePath)) { $setupPathsList.Add($exePath) }
                    }
                }
            }
        }
    }

    foreach ($candidate in $setupCandidates) {
        if (Test-Path $candidate) {
            if (-not $foundSetupPath) { $foundSetupPath = $candidate }
            if (-not $setupPathsList.Contains($candidate)) { $setupPathsList.Add($candidate) }
            if ($candidate -like "*AppData*" -or (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe")) {
                $win32Detected = $true
            }
        }
    }

    $appxPackages = @(try { Get-AppxPackage -Name "Microsoft.OneDriveSync" -AllUsers -ErrorAction SilentlyContinue 2>$null } catch { @() })
    if (-not $appxPackages -or $appxPackages.Count -eq 0) {
        $appxPackages = @(try { Get-AppxPackage -Name "Microsoft.OneDriveSync" -ErrorAction SilentlyContinue 2>$null } catch { @() })
    }
    $appxInstalled = ($appxPackages.Count -gt 0)

    return [PSCustomObject]@{
        IsInstalled    = ($win32Detected -or $appxInstalled)
        Win32Installed = $win32Detected
        AppxInstalled  = $appxInstalled
        SetupPath      = $foundSetupPath
        SetupPaths     = $setupPathsList.ToArray()
        AppxPackages   = $appxPackages
    }
}

function Invoke-WingetUninstallRetry {
    <#
        .SYNOPSIS
            Executes a silent winget uninstall fallback for stubborn Store/WinGet packages.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )

    $wingetCmd = Get-Command "winget.exe" -ErrorAction SilentlyContinue
    if (-not $wingetCmd) { return $false }

    try {
        $wgArgs = "uninstall --id $PackageId --exact --silent --accept-source-agreements --accept-package-agreements"
        $wgProc = Start-Process -FilePath "winget.exe" -ArgumentList $wgArgs -NoNewWindow -PassThru -Wait -ErrorAction SilentlyContinue
        return ($null -ne $wgProc -and $wgProc.ExitCode -eq 0)
    }
    catch {
        Write-Verbose "WinGet uninstall skipped for '$PackageId': $($_.Exception.Message)"
        return $false
    }
}

function Register-DeprovisionedAppxKey {
    <#
        .SYNOPSIS
            Writes the Deprovisioned registry key so Windows 11 26H2 does not silently reinstall removed inbox AppX packages.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageFamilyName
    )

    if ([string]::IsNullOrWhiteSpace($PackageFamilyName)) { return $false }

    $deprovBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned"
    $deprovPath = Join-Path $deprovBase $PackageFamilyName

    if ($PSCmdlet.ShouldProcess($deprovPath, "Mark AppX package family as Deprovisioned")) {
        try {
            if (-not (Test-Path $deprovPath)) {
                New-Item -Path $deprovPath -Force -ErrorAction Stop | Out-Null
            }
            return $true
        }
        catch {
            Write-Verbose "Could not write Deprovisioned key '$deprovPath': $($_.Exception.Message)"
            return $false
        }
    }

    return $true
}

function Get-DebloatPreset {
    <#
        .SYNOPSIS
            Loads an application debloat preset profile with AppId alias array support.
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

            $aliasList = [System.Collections.Generic.List[string]]::new()
            $primaryId = $null

            if ($item.AppId -is [System.Collections.IEnumerable] -and $item.AppId -isnot [string]) {
                foreach ($id in $item.AppId) {
                    $idStr = [string]$id
                    if (-not [string]::IsNullOrWhiteSpace($idStr)) {
                        if (-not $primaryId) { $primaryId = $idStr }
                        if (-not $aliasList.Contains($idStr)) { $aliasList.Add($idStr) }
                    }
                }
            } else {
                $primaryId = [string]$item.AppId
                if (-not [string]::IsNullOrWhiteSpace($primaryId)) {
                    $aliasList.Add($primaryId)
                }
            }

            if ($item.PSObject.Properties["Aliases"] -and $item.Aliases) {
                foreach ($al in $item.Aliases) {
                    $alStr = [string]$al
                    if (-not [string]::IsNullOrWhiteSpace($alStr) -and -not $aliasList.Contains($alStr)) {
                        $aliasList.Add($alStr)
                    }
                }
            }

            if (-not [string]::IsNullOrWhiteSpace($primaryId)) {
                $resultList.Add([PSCustomObject]@{
                    AppId          = $primaryId
                    Aliases        = $aliasList.ToArray()
                    DisplayName    = if ($item.DisplayName -is [string]) { $item.DisplayName } else { $primaryId }
                    Recommendation = $item.Recommendation
                    RemovalMethod  = $item.RemovalMethod
                })
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
            Scans installed/provisioned AppX packages, OneDrive (Win32+AppX), and Copilot variants with dictionary indexing.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [string]$PresetsPath,

        [switch]$ExcludeCoreFrameworks
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
        $isCore = Test-IsCoreSystemFramework -AppId $pkg.Name
        if ($ExcludeCoreFrameworks -and $isCore) { continue }

        $isProtected = $false
        foreach ($protected in $protectedList) {
            if ($pkg.Name -like "*$protected*" -or $protected -like "*$($pkg.Name)*") {
                $isProtected = $true
                break
            }
        }
        $resultsDict[$pkg.Name] = [PSCustomObject]@{
            AppId             = $pkg.Name
            PackageFullName   = $pkg.PackageFullName
            PackageFamilyName = $pkg.PackageFamilyName
            Publisher         = $pkg.PublisherId
            IsProvisioned     = $false
            IsProtected       = $isProtected
            IsCoreFramework   = $isCore
            Version           = $pkg.Version
        }
    }

    if ($provisionedPackages) {
        foreach ($prov in $provisionedPackages) {
            if (-not $prov.DisplayName) { continue }
            $isCore = Test-IsCoreSystemFramework -AppId $prov.DisplayName
            if ($ExcludeCoreFrameworks -and $isCore) { continue }

            if ($resultsDict.ContainsKey($prov.DisplayName)) {
                $resultsDict[$prov.DisplayName].IsProvisioned = $true
            }
            else {
                $isProtected = $false
                foreach ($protected in $protectedList) {
                    if ($prov.DisplayName -like "*$protected*" -or $protected -like "*$($prov.DisplayName)*") {
                        $isProtected = $true
                        break
                    }
                }
                $resultsDict[$prov.DisplayName] = [PSCustomObject]@{
                    AppId             = $prov.DisplayName
                    PackageFullName   = $prov.PackageName
                    PackageFamilyName = ""
                    Publisher         = ""
                    IsProvisioned     = $true
                    IsProtected       = $isProtected
                    IsCoreFramework   = $isCore
                    Version           = $prov.Version
                }
            }
        }
    }

    # Hybrid OneDrive detection (Win32 OneDriveSetup + AppX Microsoft.OneDriveSync)
    $odInfo = Get-OneDriveInstallInfo
    if ($odInfo.IsInstalled -and -not $resultsDict.ContainsKey("Microsoft.OneDrive")) {
        $resultsDict["Microsoft.OneDrive"] = [PSCustomObject]@{
            AppId             = "Microsoft.OneDrive"
            PackageFullName   = if ($odInfo.SetupPath) { $odInfo.SetupPath } else { "Microsoft.OneDriveSync" }
            PackageFamilyName = "Microsoft.OneDriveSync_8wekyb3d8bbwe"
            Publisher         = "Microsoft"
            IsProvisioned     = $false
            IsProtected       = $false
            IsCoreFramework   = $false
            Version           = "Hybrid"
        }
    }

    # Normalize Copilot variants to Microsoft.Copilot if any Copilot package is present
    $hasCopilotVariant = @($resultsDict.Keys | Where-Object { $_ -like "*Copilot*" }).Count -gt 0
    if ($hasCopilotVariant -and -not $resultsDict.ContainsKey("Microsoft.Copilot")) {
        $resultsDict["Microsoft.Copilot"] = [PSCustomObject]@{
            AppId             = "Microsoft.Copilot"
            PackageFullName   = "Microsoft.Copilot"
            PackageFamilyName = ""
            Publisher         = "Microsoft"
            IsProvisioned     = $false
            IsProtected       = $false
            IsCoreFramework   = $false
            Version           = "Variant"
        }
    }

    return [PSCustomObject[]]@($resultsDict.Values)
}

function Get-AppPackageClassification {
    <#
        .SYNOPSIS
            Classifies an AppX/Store package into Protected, NotRecommended, Optional, or Safe.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId,

        [Parameter(Mandatory = $false)]
        [string]$PresetsPath
    )

    if (Test-IsProtectedApp -AppId $AppId -PresetsPath $PresetsPath) {
        return "Protected"
    }
    if (Test-IsCoreSystemFramework -AppId $AppId) {
        return "NotRecommended"
    }
    if ($AppId -match "OneDrive|Copilot|OutlookForWindows|Teams|YourPhone|QuickAssist|Xbox|Gaming") {
        return "Optional"
    }
    return "Safe"
}

function Test-HasProtectedDependent {
    <#
        .SYNOPSIS
            Checks if any installed protected package declares a dependency on the target AppId.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId,

        [Parameter(Mandatory = $false)]
        [string]$PresetsPath
    )

    try {
        $allPkgs = @(Get-AppxPackage -ErrorAction SilentlyContinue 2>$null)
        foreach ($pkg in $allPkgs) {
            if (-not $pkg.Dependencies) { continue }
            if (Test-IsProtectedApp -AppId $pkg.Name -PresetsPath $PresetsPath) {
                foreach ($dep in $pkg.Dependencies) {
                    if ($dep -like "*$AppId*") {
                        return $true
                    }
                }
            }
        }
    } catch {}
    return $false
}

function Get-PackageRemovalMetadata {
    <#
        .SYNOPSIS
            Inspects package existence, scopes, PackageFamilyName, dependencies, and reinstall metadata before removal.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppId
    )

    $curPkgs = @(try { Get-AppxPackage -Name "*$AppId*" -ErrorAction SilentlyContinue 2>$null } catch { @() })
    $allPkgs = @(try { Get-AppxPackage -Name "*$AppId*" -AllUsers -ErrorAction SilentlyContinue 2>$null } catch { @() })
    $provPkgs = @(try { Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue 2>$null | Where-Object { $_.DisplayName -eq $AppId -or $_.PackageName -like "*$AppId*" } } catch { @() })

    $scopes = [System.Collections.Generic.List[string]]::new()
    if ($curPkgs.Count -gt 0) { $scopes.Add("CurrentUser") }
    if ($allPkgs.Count -gt 0) { $scopes.Add("AllUsers") }
    if ($provPkgs.Count -gt 0) { $scopes.Add("Provisioned") }

    $firstPkg = if ($allPkgs.Count -gt 0) { $allPkgs[0] } elseif ($curPkgs.Count -gt 0) { $curPkgs[0] } else { $null }
    $deps = if ($firstPkg -and $firstPkg.Dependencies) { @($firstPkg.Dependencies) } else { @() }

    return [PSCustomObject]@{
        AppId             = $AppId
        Exists            = ($scopes.Count -gt 0)
        Scopes            = $scopes.ToArray()
        PackageFamilyName = if ($firstPkg) { $firstPkg.PackageFamilyName } else { "" }
        Dependencies      = $deps
        ReinstallMethod   = "Store / Add-AppxPackage -Register"
    }
}

function Remove-DebloatApp {
    <#
        .SYNOPSIS
            Safely uninstalls selected bloatware packages using scope-separated operations (CurrentUser, AllUsers, Provisioned, DefaultUserProfile).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$AppIdList,

        [Parameter(Mandatory = $false)]
        [bool]$AllUsers = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers", "Provisioned", "DefaultUserProfile", "DefaultUser")]
        [string]$TargetScope = "CurrentUser",

        [string]$PresetsPath
    )

    process {
        foreach ($appId in $AppIdList) {
            if ([string]::IsNullOrWhiteSpace($appId)) { continue }

            $candidateIds = [System.Collections.Generic.List[string]]::new()
            $candidateIds.Add($appId)
            if ($script:BuiltinAppAliases.ContainsKey($appId)) {
                foreach ($alias in $script:BuiltinAppAliases[$appId]) {
                    if (-not $candidateIds.Contains($alias)) { $candidateIds.Add($alias) }
                }
            }

            # Safety gate: Ensure protected system & hardware components cannot be removed
            if (Test-IsProtectedApp -AppId $candidateIds.ToArray() -PresetsPath $PresetsPath) {
                Write-Warning "Skipped protected system package: '$appId'"
                [PSCustomObject]@{
                    AppId   = $appId
                    Status  = "SkippedProtected"
                    Message = "Package is protected against removal."
                }
                continue
            }

            # Dependency guard: block removal if a protected package depends on it
            if (Test-HasProtectedDependent -AppId $appId -PresetsPath $PresetsPath) {
                Write-Warning "Skipped '$appId': required by a protected package."
                [PSCustomObject]@{
                    AppId   = $appId
                    Status  = "SkippedProtectedDependency"
                    Message = "Package is required as a dependency by a protected Windows component."
                }
                continue
            }

            if ($PSCmdlet.ShouldProcess("Package: $appId (Scope: $TargetScope)", "Remove via Scope-Separated Pipeline")) {
                $removed = $false
                $errorMessage = $null
                $deprovFamilies = [System.Collections.Generic.List[string]]::new()

                $isOneDrive = ($appId -eq "Microsoft.OneDrive" -or $appId -eq "Microsoft.OneDriveSync")
                $isCopilot  = ($appId -eq "Microsoft.Copilot" -or $appId -eq "XP9CXNGPPJ97XX" -or $appId -eq "Microsoft.Windows.Ai.Copilot.Provider")

                if ($isOneDrive) {
                    try {
                        $odProc = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
                        if ($odProc) { Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue }

                        $odInfo = Get-OneDriveInstallInfo
                        $odPaths = if ($odInfo.PSObject.Properties["SetupPaths"] -and $odInfo.SetupPaths) { $odInfo.SetupPaths } elseif ($odInfo.SetupPath) { @($odInfo.SetupPath) } else { @() }
                        foreach ($exePath in $odPaths) {
                            if ($exePath -and (Test-Path $exePath)) {
                                Start-Process -FilePath $exePath -ArgumentList "/uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                                $removed = $true
                            }
                        }
                    }
                    catch {
                        $errorMessage = "OneDrive Win32 uninstall error: $($_.Exception.Message)"
                    }
                }

                if ($isCopilot) {
                    try {
                        $copProc = Get-Process -Name "Copilot" -ErrorAction SilentlyContinue
                        if ($copProc) { Stop-Process -Name "Copilot" -Force -ErrorAction SilentlyContinue }
                    } catch {}
                }

                $doProvisioned = ($TargetScope -eq "Provisioned" -or $TargetScope -eq "AllUsers" -or $TargetScope -eq "DefaultUser" -or $TargetScope -eq "DefaultUserProfile" -or $AllUsers)
                $doInstalled = ($TargetScope -eq "CurrentUser" -or $TargetScope -eq "AllUsers" -or $AllUsers)
                $useAllUsersFlag = ($TargetScope -eq "AllUsers" -or $AllUsers)

                foreach ($targetId in $candidateIds) {
                    $appxPattern = if ($targetId -eq "Microsoft.Copilot") { "*Copilot*" } else { "*$targetId*" }

                    if ($doProvisioned) {
                        try {
                            $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                                Where-Object { $_.DisplayName -eq $targetId -or $_.PackageName -like $appxPattern }

                            foreach ($p in $prov) {
                                if ($isCopilot -and (Test-IsProtectedApp -AppId $p.DisplayName -PresetsPath $PresetsPath)) { continue }
                                Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null
                                $removed = $true
                            }
                        }
                        catch {
                            $errorMessage = if ($null -eq $errorMessage) { "Provisioned removal error: $($_.Exception.Message)" } else { "$errorMessage | Provisioned removal error: $($_.Exception.Message)" }
                        }
                    }

                    if ($doInstalled) {
                        try {
                            $installed = if ($useAllUsersFlag) {
                                Get-AppxPackage -Name $appxPattern -AllUsers -ErrorAction SilentlyContinue
                            } else {
                                Get-AppxPackage -Name $appxPattern -ErrorAction SilentlyContinue
                            }

                            foreach ($pkg in $installed) {
                                if ($isCopilot -and (Test-IsProtectedApp -AppId $pkg.Name -PresetsPath $PresetsPath)) { continue }
                                if ($pkg.PackageFamilyName -and -not $deprovFamilies.Contains($pkg.PackageFamilyName)) {
                                    $deprovFamilies.Add($pkg.PackageFamilyName)
                                }
                                if ($useAllUsersFlag) {
                                    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop | Out-Null
                                } else {
                                    Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop | Out-Null
                                }
                                $removed = $true
                            }
                        }
                        catch {
                            $errorMessage = if ($null -eq $errorMessage) { "Installed removal error: $($_.Exception.Message)" } else { "$errorMessage | Installed removal error: $($_.Exception.Message)" }
                        }
                    }
                }

                if ($removed -and $doProvisioned) {
                    foreach ($familyName in $deprovFamilies) {
                        Register-DeprovisionedAppxKey -PackageFamilyName $familyName | Out-Null
                    }
                }

                if ($isOneDrive) {
                    $odRemaining = Get-OneDriveInstallInfo
                    if ($odRemaining.IsInstalled) {
                        foreach ($wgId in @("Microsoft.OneDrive", "Microsoft.OneDriveSync")) {
                            if (Invoke-WingetUninstallRetry -PackageId $wgId) { $removed = $true }
                        }
                    }
                    $odRunPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                    if (Test-Path $odRunPath) {
                        $odRunProp = Get-ItemProperty -Path $odRunPath -Name "OneDrive" -ErrorAction SilentlyContinue
                        if ($odRunProp) {
                            Remove-ItemProperty -Path $odRunPath -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
                elseif ($isCopilot) {
                    $copRemaining = @(Get-AppxPackage -Name "*Copilot*" -AllUsers -ErrorAction SilentlyContinue | Where-Object { -not (Test-IsProtectedApp -AppId $_.Name -PresetsPath $PresetsPath) })
                    if ($copRemaining.Count -gt 0 -or -not $removed) {
                        foreach ($wgId in @("XP9CXNGPPJ97XX", "Microsoft.Copilot")) {
                            if (Invoke-WingetUninstallRetry -PackageId $wgId) { $removed = $true }
                        }
                    }
                    foreach ($polPath in @("HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot", "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot")) {
                        try {
                            if (-not (Test-Path $polPath)) { New-Item -Path $polPath -Force -ErrorAction SilentlyContinue | Out-Null }
                            New-ItemProperty -Path $polPath -Name "TurnOffWindowsCopilot" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                        } catch {}
                    }
                }
                else {
                    foreach ($targetId in $candidateIds) {
                        if ($targetId -match '^XP9[A-Z0-9]+$' -or $targetId -match '^9[A-Z0-9]{11}$') {
                            if (Invoke-WingetUninstallRetry -PackageId $targetId) { $removed = $true }
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
                        Status  = "Skipped - Not Installed"
                        Message = "Package was not installed on this system (Scope: $TargetScope)."
                    }
                }
            }
            else {
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

function Format-AppDisplayName {
    <#
        .SYNOPSIS
            Formats a raw AppX/Store package identifier into a clean human-readable display name using case-sensitive word-boundary splitting.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PackageName
    )

    if ([string]::IsNullOrWhiteSpace($PackageName)) { return "" }

    $name = $PackageName.Trim()
    $name = $name -replace "^Microsoft\.", ""
    $name = $name -replace "^king\.com\.", ""
    $name = $name -replace "^[0-9A-Za-z]+\.(?=WhatsApp|Instagram|LinkedIn|Netflix)", ""
    $name = $name -replace "[\._]+", " "
    $name = $name -replace "\s*-\s*", " - "
    $name = $name -creplace "([a-z0-9])([A-Z])", '$1 $2'
    $name = $name -creplace "([A-Z]+)([A-Z][a-z])", '$1 $2'
    $name = ($name -replace "\s+", " ").Trim()

    return $name
}

Export-ModuleMember -Function Get-ProtectedApp, Test-IsProtectedApp, Test-IsCoreSystemFramework, Get-AppPackageClassification, Test-HasProtectedDependent, Get-PackageRemovalMetadata, Format-AppDisplayName, Get-OneDriveInstallInfo, Invoke-WingetUninstallRetry, Register-DeprovisionedAppxKey, Get-DebloatPreset, Get-InstalledDebloatApp, Remove-DebloatApp, Restore-DefaultApp, Export-DebloatProfile, Import-DebloatProfile, Install-CommonWindowsApp

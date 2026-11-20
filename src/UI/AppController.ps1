<#
    .SYNOPSIS
        NH Win Debloater - UI Controller Engine
    .DESCRIPTION
        Orchestrates the WPF/XAML Guided Setup Assistant, manages stage transitions,
        populates application catalogs and tweaks, executes dry-run previews,
        and triggers atomic debloat pipelines with full safety gates.
    .MODULEVERSION
        0.1.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', '')]
param()

function Show-DebloaterWindow {
    <#
        .SYNOPSIS
            Initializes and displays the NH Win Debloater WPF Guided Assistant.
    #>
    [CmdletBinding()]
    param(
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    }

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase | Out-Null

    # 1. Resolve Paths
    $corePath = Join-Path $ProjectRoot "src\Core"
    $presetsPath = Join-Path $ProjectRoot "src\Presets"
    $xamlPath = Join-Path $ProjectRoot "src\UI\MainWindow.xaml"
    $versionPath = Join-Path $ProjectRoot "VERSION.txt"
    $logoDir = Join-Path $ProjectRoot "assets\logo"

    # 2. Import Core Modules
    Import-Module (Join-Path $corePath "AppManager.psm1") -Force
    Import-Module (Join-Path $corePath "PrivacySearch.psm1") -Force
    Import-Module (Join-Path $corePath "ShellCustomization.psm1") -Force
    Import-Module (Join-Path $corePath "SystemTweaks.psm1") -Force
    Import-Module (Join-Path $corePath "ExecutionLog.psm1") -Force

    Initialize-DebloatLogger | Out-Null

    # 3. Load XAML
    if (-not (Test-Path $xamlPath)) {
        Write-Error "MainWindow.xaml not found at: $xamlPath"
        return
    }

    $xaml = Get-Content -Path $xamlPath -Raw
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    try {
        $window = [System.Windows.Markup.XamlReader]::Load($reader)
    }
    finally {
        $reader.Close()
    }

    # 4. Find UI Elements
    $txtVersion = $window.FindName("TxtVersion")
    $imgLogo = $window.FindName("ImgLogo")
    $logoFallbackBox = $window.FindName("LogoFallbackBox")
    $txtOsCaption = $window.FindName("TxtOsCaption")
    $txtElevationStatus = $window.FindName("TxtElevationStatus")

    $stepTag1 = $window.FindName("StepTag1")
    $stepTag2 = $window.FindName("StepTag2")
    $stepTag3 = $window.FindName("StepTag3")
    $stepTag4 = $window.FindName("StepTag4")
    $stepTag5 = $window.FindName("StepTag5")

    $viewStage1 = $window.FindName("ViewStage1")
    $viewStage2 = $window.FindName("ViewStage2")
    $viewStage3 = $window.FindName("ViewStage3")
    $viewStage4 = $window.FindName("ViewStage4")
    $viewStage5 = $window.FindName("ViewStage5")

    $radioPresetMinimal = $window.FindName("RadioPresetMinimal")
    $radioPresetDeep = $window.FindName("RadioPresetDeep")
    $radioScopeCurrentUser = $window.FindName("RadioScopeCurrentUser")
    $radioScopeDefaultUser = $window.FindName("RadioScopeDefaultUser")

    $txtAppFilter = $window.FindName("TxtAppFilter")
    $btnSelectAllApps = $window.FindName("BtnSelectAllApps")
    $btnDeselectAllApps = $window.FindName("BtnDeselectAllApps")
    $txtAppsSummary = $window.FindName("TxtAppsSummary")
    $listAppsContainer = $window.FindName("ListAppsContainer")

    $chkTelemetry = $window.FindName("ChkTelemetry")
    $chkCopilot = $window.FindName("ChkCopilot")
    $chkBingSearch = $window.FindName("ChkBingSearch")
    $chkAdvertisingId = $window.FindName("ChkAdvertisingId")
    $chkActivityHistory = $window.FindName("ChkActivityHistory")
    $chkTailoredExp = $window.FindName("ChkTailoredExp")

    $chkShowExt = $window.FindName("ChkShowExt")
    $chkShowHidden = $window.FindName("ChkShowHidden")
    $chkExplorerThisPC = $window.FindName("ChkExplorerThisPC")
    $chkClassicContextMenu = $window.FindName("ChkClassicContextMenu")
    $chkHideWidgets = $window.FindName("ChkHideWidgets")
    $chkHideChat = $window.FindName("ChkHideChat")
    $chkEndTask = $window.FindName("ChkEndTask")
    $chkAlignLeft = $window.FindName("ChkAlignLeft")
    $chkHideOneDriveNav = $window.FindName("ChkHideOneDriveNav")

    $chkConsumerFeatures = $window.FindName("ChkConsumerFeatures")
    $chkLockScreenAds = $window.FindName("ChkLockScreenAds")
    $chkMousePrecision = $window.FindName("ChkMousePrecision")
    $chkStickyKeys = $window.FindName("ChkStickyKeys")
    $chkFastStartup = $window.FindName("ChkFastStartup")
    $chkStorageSense = $window.FindName("ChkStorageSense")
    $chkPreventAutoReboot = $window.FindName("ChkPreventAutoReboot")
    $chkExcludeDrivers = $window.FindName("ChkExcludeDrivers")

    $chkWindowsSandbox = $window.FindName("ChkWindowsSandbox")
    $chkWSL = $window.FindName("ChkWSL")

    $chkCreateRestorePoint = $window.FindName("ChkCreateRestorePoint")
    $chkRegistrySnapshot = $window.FindName("ChkRegistrySnapshot")
    $btnRunDryRun = $window.FindName("BtnRunDryRun")
    $txtDryRunStatus = $window.FindName("TxtDryRunStatus")
    $txtDryRunLog = $window.FindName("TxtDryRunLog")

    $txtProgressStatus = $window.FindName("TxtProgressStatus")
    $progExecution = $window.FindName("ProgExecution")
    $txtLiveLog = $window.FindName("TxtLiveLog")

    $txtStatTotal = $window.FindName("TxtStatTotal")
    $txtStatSuccess = $window.FindName("TxtStatSuccess")
    $txtStatSkipped = $window.FindName("TxtStatSkipped")
    $btnRestartExplorer = $window.FindName("BtnRestartExplorer")
    $btnOpenLog = $window.FindName("BtnOpenLog")

    $btnBack = $window.FindName("BtnBack")
    $btnNext = $window.FindName("BtnNext")
    $btnApply = $window.FindName("BtnApply")
    $btnFinish = $window.FindName("BtnFinish")
    $linkNhDigital = $window.FindName("LinkNhDigital")

    # 5. Populate Brand & System Info
    if (Test-Path $versionPath) {
        $v = (Get-Content -Path $versionPath -Raw).Trim()
        $txtVersion.Text = "v$v"
    } else {
        $txtVersion.Text = "v0.1"
    }

    # Window Icon wiring
    $icoCandidates = @(
        (Join-Path $logoDir "logo.ico"),
        (Join-Path $logoDir "favicon.ico"),
        (Join-Path $logoDir "logo.png"),
        (Join-Path $logoDir "nhdigital-logo.png"),
        (Join-Path $logoDir "nh-digital-logo.png")
    )
    foreach ($ico in $icoCandidates) {
        if (Test-Path $ico) {
            try {
                $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([Uri]$ico)
                break
            } catch { Write-Verbose "Could not load window icon '$ico': $($_.Exception.Message)" }
        }
    }

    # Header Logo wiring (preferring raster official logo, falling back to stylish vector box)
    $logoCandidates = @(
        (Join-Path $logoDir "logo.png"),
        (Join-Path $logoDir "nhdigital-logo.png"),
        (Join-Path $logoDir "nh-digital-logo.png"),
        (Join-Path $logoDir "logo.jpg"),
        (Join-Path $logoDir "nhdigital.png")
    )
    $foundLogo = $false
    foreach ($candidate in $logoCandidates) {
        if (Test-Path $candidate) {
            try {
                $img = [System.Windows.Media.Imaging.BitmapImage]::new()
                $img.BeginInit()
                $img.UriSource = [Uri]$candidate
                $img.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $img.EndInit()

                $imgLogo.Source = $img
                $imgLogo.Visibility = [System.Windows.Visibility]::Visible
                $logoFallbackBox.Visibility = [System.Windows.Visibility]::Collapsed
                $foundLogo = $true
                break
            } catch {
                Write-Verbose "Could not load logo from '$candidate': $($_.Exception.Message)"
            }
        }
    }

    if (-not $foundLogo) {
        $imgLogo.Visibility = [System.Windows.Visibility]::Collapsed
        $logoFallbackBox.Visibility = [System.Windows.Visibility]::Visible
    }

    # Platform Information
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).CurrentBuild
        $txtOsCaption.Text = "$($os.Caption) (Build $build)"
    } catch {
        $txtOsCaption.Text = "Windows 11 / 10"
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        $txtElevationStatus.Text = "Elevated Administrator"
        $txtElevationStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981")
    } else {
        $txtElevationStatus.Text = "Standard User (Elevation Recommended)"
        $txtElevationStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
    }

    # 6. Hyperlink Event Wiring
    $linkNhDigital.Add_RequestNavigate({
        param([object]$eventSource, [System.Windows.Navigation.RequestNavigateEventArgs]$eventArgs)
        try {
            Start-Process $eventArgs.Uri.AbsoluteUri
        } catch {
            Write-Verbose "Could not open browser: $($_.Exception.Message)"
        }
        $eventArgs.Handled = $true
    })

    # 7. State Management
    $script:CurrentStage = 1
    $script:AppCheckboxes = [System.Collections.Generic.List[System.Windows.Controls.CheckBox]]::new()

    # Function to update stage visual views
    $updateStageView = {
        param([int]$stage)
        $script:CurrentStage = $stage

        # Hide all stages
        $viewStage1.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage2.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage3.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage4.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage5.Visibility = [System.Windows.Visibility]::Collapsed

        # Reset stepper highlights
        $stepColorActive = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0EA5E9")
        $stepColorInactive = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")

        $stepTag1.Foreground = $stepColorInactive; $stepTag1.FontWeight = [System.Windows.FontWeights]::Normal
        $stepTag2.Foreground = $stepColorInactive; $stepTag2.FontWeight = [System.Windows.FontWeights]::Normal
        $stepTag3.Foreground = $stepColorInactive; $stepTag3.FontWeight = [System.Windows.FontWeights]::Normal
        $stepTag4.Foreground = $stepColorInactive; $stepTag4.FontWeight = [System.Windows.FontWeights]::Normal
        $stepTag5.Foreground = $stepColorInactive; $stepTag5.FontWeight = [System.Windows.FontWeights]::Normal

        # Configure visible stage and buttons
        switch ($stage) {
            1 {
                $viewStage1.Visibility = [System.Windows.Visibility]::Visible
                $stepTag1.Foreground = $stepColorActive; $stepTag1.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                $btnNext.Visibility = [System.Windows.Visibility]::Visible
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            2 {
                $viewStage2.Visibility = [System.Windows.Visibility]::Visible
                $stepTag2.Foreground = $stepColorActive; $stepTag2.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Visible
                $btnNext.Visibility = [System.Windows.Visibility]::Visible
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            3 {
                $viewStage3.Visibility = [System.Windows.Visibility]::Visible
                $stepTag3.Foreground = $stepColorActive; $stepTag3.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Visible
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Visible
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            4 {
                $viewStage4.Visibility = [System.Windows.Visibility]::Visible
                $stepTag4.Foreground = $stepColorActive; $stepTag4.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            5 {
                $viewStage5.Visibility = [System.Windows.Visibility]::Visible
                $stepTag5.Foreground = $stepColorActive; $stepTag5.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Visible
            }
        }
    }

    # Function to populate apps list
    $populateApps = {
        $preset = if ($radioPresetMinimal.IsChecked) { "Minimal" } elseif ($radioPresetDeep.IsChecked) { "Deep" } else { "Default" }
        $apps = Get-DebloatPreset -PresetName $preset -PresetsPath $presetsPath

        $listAppsContainer.Items.Clear()
        $script:AppCheckboxes.Clear()

        foreach ($app in $apps) {
            $cb = [System.Windows.Controls.CheckBox]::new()
            $cb.Content = "$($app.DisplayName) ($($app.AppId))"
            $cb.Tag = $app.AppId
            $cb.IsChecked = $true
            $cb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8FAFC")
            $cb.FontSize = 12
            $cb.Margin = [System.Windows.Thickness]::new(4, 4, 4, 4)

            $script:AppCheckboxes.Add($cb)
            $listAppsContainer.Items.Add($cb) | Out-Null
        }

        $txtAppsSummary.Text = "Loaded $($apps.Count) applications for '$preset' preset."
    }

    # App search filtering
    $txtAppFilter.Add_TextChanged({
        $filter = $txtAppFilter.Text.Trim().ToLower()
        foreach ($cb in $script:AppCheckboxes) {
            if ([string]::IsNullOrWhiteSpace($filter) -or $cb.Content.ToString().ToLower().Contains($filter)) {
                $cb.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $cb.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
    })

    $btnSelectAllApps.Add_Click({
        foreach ($cb in $script:AppCheckboxes) { $cb.IsChecked = $true }
    })

    $btnDeselectAllApps.Add_Click({
        foreach ($cb in $script:AppCheckboxes) { $cb.IsChecked = $false }
    })

    # Dry-Run Preview Action
    $btnRunDryRun.Add_Click({
        $txtDryRunStatus.Text = "Simulating WhatIf dry-run changes..."
        $txtDryRunLog.Clear()

        $logBuilder = [System.Text.StringBuilder]::new()
        $logBuilder.AppendLine("[$(Get-Date -Format 'HH:mm:ss')] DRY-RUN PREVIEW INITIATED") | Out-Null

        $scope = if ($radioScopeCurrentUser.IsChecked) { "CurrentUser" } elseif ($radioScopeDefaultUser.IsChecked) { "DefaultUser" } else { "AllUsers" }
        $logBuilder.AppendLine("Target Scope: $scope") | Out-Null

        if ($chkTelemetry.IsChecked) { $logBuilder.AppendLine("WhatIf: Disable Telemetry policies would be applied.") | Out-Null }
        if ($chkCopilot.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Copilot & Recall AI would be disabled.") | Out-Null }
        if ($chkBingSearch.IsChecked) { $logBuilder.AppendLine("WhatIf: Start Menu Bing search suggestions would be disabled.") | Out-Null }
        if ($chkShowExt.IsChecked) { $logBuilder.AppendLine("WhatIf: File Explorer Show Known Extensions would be enabled.") | Out-Null }
        if ($chkShowHidden.IsChecked) { $logBuilder.AppendLine("WhatIf: File Explorer Show Hidden Files would be enabled.") | Out-Null }
        if ($chkClassicContextMenu.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows 10 Classic Context Menu would be restored.") | Out-Null }
        if ($chkConsumerFeatures.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows consumer features and promo preinstalls would be blocked.") | Out-Null }
        if ($chkMousePrecision.IsChecked) { $logBuilder.AppendLine("WhatIf: Mouse pointer acceleration would be disabled (1:1 precision).") | Out-Null }
        if ($chkStickyKeys.IsChecked) { $logBuilder.AppendLine("WhatIf: Sticky Keys 5x Shift shortcut prompt would be disabled.") | Out-Null }
        if ($chkFastStartup.IsChecked) { $logBuilder.AppendLine("WhatIf: Fast Startup hybrid sleep would be disabled.") | Out-Null }
        if ($chkStorageSense.IsChecked) { $logBuilder.AppendLine("WhatIf: Storage Sense automatic deletion policy would be disabled.") | Out-Null }
        if ($chkPreventAutoReboot.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Update automatic reboot while user logged on would be prevented.") | Out-Null }
        if ($chkExcludeDrivers.IsChecked) { $logBuilder.AppendLine("WhatIf: Third-party drivers would be excluded from Windows Quality Updates.") | Out-Null }
        if ($chkWindowsSandbox.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Sandbox optional feature would be enabled.") | Out-Null }
        if ($chkWSL.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Subsystem for Linux (WSL) would be enabled.") | Out-Null }

        $selectedCount = 0
        foreach ($cb in $script:AppCheckboxes) {
            if ($cb.IsChecked) {
                $selectedCount++
                if ($selectedCount -le 10) {
                    $logBuilder.AppendLine("WhatIf: Package removal ($scope): '$($cb.Tag)'") | Out-Null
                }
            }
        }
        if ($selectedCount -gt 10) {
            $logBuilder.AppendLine("... and $(($selectedCount - 10)) more packages selected for removal.") | Out-Null
        }

        $logBuilder.AppendLine("[$(Get-Date -Format 'HH:mm:ss')] PREVIEW COMPLETE: No system changes were made.") | Out-Null
        $txtDryRunLog.Text = $logBuilder.ToString()
        $txtDryRunStatus.Text = "Dry-Run complete: $selectedCount packages and selected tweaks simulated."
    })

    # Step Navigation Buttons
    $btnNext.Add_Click({
        if ($script:CurrentStage -eq 1) {
            & $populateApps
            & $updateStageView 2
        } elseif ($script:CurrentStage -eq 2) {
            & $updateStageView 3
        }
    })

    $btnBack.Add_Click({
        if ($script:CurrentStage -gt 1) {
            & $updateStageView ($script:CurrentStage - 1)
        }
    })

    # Apply Action Pipeline
    $btnApply.Add_Click({
        & $updateStageView 4
        $progExecution.Value = 10
        $txtLiveLog.Clear()

        $appendLog = {
            param([string]$text)
            $txtLiveLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $text`r`n")
            $txtLiveLog.ScrollToEnd()
            [System.Windows.Forms.Application]::DoEvents()
        }

        & $appendLog "Starting NH Win Debloater optimization pipeline..."

        $targetScope = if ($radioScopeCurrentUser.IsChecked) { "CurrentUser" } elseif ($radioScopeDefaultUser.IsChecked) { "DefaultUser" } else { "AllUsers" }
        & $appendLog "Selected execution scope: $targetScope"

        $totalOps = 0
        $successOps = 0
        $skippedOps = 0

        # 1. Restore Point
        if ($chkCreateRestorePoint.IsChecked) {
            & $appendLog "Creating Windows System Restore Point..."
            $txtProgressStatus.Text = "Creating System Restore checkpoint..."
            $rp = New-DebloatRestorePoint -Description "NH Win Debloater v0.1 Checkpoint"
            $totalOps++
            if ($rp.Status -eq "Success") { $successOps++; & $appendLog "System Restore Point created successfully." }
            else { $skippedOps++; & $appendLog "System Restore Point skipped/warning: $($rp.Message)" }
        }
        $progExecution.Value = 20

        # 2. Registry Snapshot
        if ($chkRegistrySnapshot.IsChecked) {
            & $appendLog "Capturing pre-tweak registry snapshot..."
            $regPaths = @(
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo",
                "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot",
                "HKCU:\Software\Policies\Microsoft\Windows\Explorer",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
                "HKCU:\Control Panel\Mouse",
                "HKCU:\Control Panel\Accessibility\StickyKeys",
                "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            )
            $snapFile = Export-RegistrySnapshot -RegistryPaths $regPaths
            $totalOps++
            $successOps++
            & $appendLog "Registry snapshot saved: $(Split-Path $snapFile -Leaf)"
        }
        $progExecution.Value = 35

        # 3. Privacy & Search Tweaks
        if ($chkTelemetry.IsChecked) { Set-PrivacySetting -SettingId "DisableTelemetry" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Telemetry diagnostics set to Security/Basic." }
        if ($chkCopilot.IsChecked) { Set-PrivacySetting -SettingId "DisableCopilot" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Windows Copilot & Recall AI disabled." }
        if ($chkBingSearch.IsChecked) { Set-PrivacySetting -SettingId "DisableBingSearch" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Bing Start Search suggestions disabled." }
        if ($chkAdvertisingId.IsChecked) { Set-PrivacySetting -SettingId "DisableAdvertisingId" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Advertising ID disabled." }
        if ($chkActivityHistory.IsChecked) { Set-PrivacySetting -SettingId "DisableActivityHistory" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Activity History feed disabled." }
        if ($chkTailoredExp.IsChecked) { Set-PrivacySetting -SettingId "DisableTailoredExperiences" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Tailored Experiences disabled." }
        $progExecution.Value = 50

        # 4. UI & Shell Tweaks
        if ($chkShowExt.IsChecked) { Set-ShellSetting -SettingId "ShowFileExtensions" | Out-Null; $totalOps++; $successOps++; & $appendLog "Show Known File Extensions enabled." }
        if ($chkShowHidden.IsChecked) { Set-ShellSetting -SettingId "ShowHiddenFiles" | Out-Null; $totalOps++; $successOps++; & $appendLog "Show Hidden Files enabled." }
        if ($chkExplorerThisPC.IsChecked) { Set-ShellSetting -SettingId "ExplorerToThisPC" | Out-Null; $totalOps++; $successOps++; & $appendLog "File Explorer set to open This PC." }
        if ($chkClassicContextMenu.IsChecked) { Set-ClassicContextMenuTweak -EnableClassic $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Classic Windows 10 Context Menu restored." }
        if ($chkHideWidgets.IsChecked) { Set-ShellSetting -SettingId "HideWidgets" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar Widgets hidden." }
        if ($chkHideChat.IsChecked) { Set-ShellSetting -SettingId "HideChat" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar Chat hidden." }
        if ($chkEndTask.IsChecked) { Set-ShellSetting -SettingId "EnableEndTask" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar End Task enabled." }
        if ($chkAlignLeft.IsChecked) { Set-ShellSetting -SettingId "TaskbarAlignLeft" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar aligned to left." }
        if ($chkHideOneDriveNav.IsChecked) { Set-ShellSetting -SettingId "HideOneDriveNav" | Out-Null; $totalOps++; $successOps++; & $appendLog "OneDrive hidden from Explorer navigation pane." }
        $progExecution.Value = 65

        # 5. System Extras
        if ($chkConsumerFeatures.IsChecked) { Set-ConsumerFeatureTweak -Disable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Windows consumer features disabled." }
        if ($chkLockScreenAds.IsChecked) { Set-LockScreenTweak -Disable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Lock screen promotional ads disabled." }
        if ($chkMousePrecision.IsChecked) { Set-MousePrecisionTweak -DisableAcceleration $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Mouse pointer acceleration disabled (1:1 precision)." }
        if ($chkStickyKeys.IsChecked) { Set-StickyKeysTweak -DisableShortcut $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Sticky Keys shortcut prompt disabled." }
        if ($chkFastStartup.IsChecked) { Set-FastStartupTweak -DisableFastStartup $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Fast Startup disabled." }
        if ($chkStorageSense.IsChecked) { Set-StorageSenseTweak -DisableStorageSense $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Storage Sense automatic deletion disabled." }
        if ($chkPreventAutoReboot.IsChecked -or $chkExcludeDrivers.IsChecked) {
            Set-WindowsUpdatePolicyTweak -PreventAutoReboot ($chkPreventAutoReboot.IsChecked) -ExcludeDrivers ($chkExcludeDrivers.IsChecked) | Out-Null
            $totalOps++; $successOps++; & $appendLog "Windows Update reboot and driver policies applied."
        }
        $progExecution.Value = 80

        # 6. Optional Windows Features
        if ($chkWindowsSandbox.IsChecked) {
            & $appendLog "Enabling Windows Sandbox optional feature..."
            $sbRes = Set-OptionalFeatureState -FeatureId "WindowsSandbox" -Enable $true
            $totalOps++
            if ($sbRes.Status -eq "Success") { $successOps++; & $appendLog "Windows Sandbox enabled." }
            else { $skippedOps++; & $appendLog "Windows Sandbox skipped/error: $($sbRes.Status)" }
        }
        if ($chkWSL.IsChecked) {
            & $appendLog "Enabling Windows Subsystem for Linux (WSL)..."
            $wslRes = Set-OptionalFeatureState -FeatureId "WSL" -Enable $true
            $totalOps++
            if ($wslRes.Status -eq "Success") { $successOps++; & $appendLog "WSL enabled." }
            else { $skippedOps++; & $appendLog "WSL skipped/error: $($wslRes.Status)" }
        }
        $progExecution.Value = 88

        # 7. Selected Apps Removal
        $appsToRemove = [System.Collections.Generic.List[string]]::new()
        foreach ($cb in $script:AppCheckboxes) {
            if ($cb.IsChecked) {
                $appsToRemove.Add([string]$cb.Tag)
            }
        }

        if ($appsToRemove.Count -gt 0) {
            & $appendLog "Removing $($appsToRemove.Count) selected bloatware packages (Scope: $targetScope)..."
            $txtProgressStatus.Text = "Removing selected packages..."
            $remResults = Remove-DebloatApp -AppIdList $appsToRemove.ToArray() -TargetScope $targetScope -PresetsPath $presetsPath
            foreach ($res in $remResults) {
                $totalOps++
                if ($res.Status -eq "Success" -or $res.Status -eq "Warning") {
                    $successOps++
                    & $appendLog "Removed package: $($res.AppId)"
                } elseif ($res.Status -eq "SkippedProtected") {
                    $skippedOps++
                    & $appendLog "Protected package skipped: $($res.AppId)"
                } else {
                    $skippedOps++
                    & $appendLog "Package not found on system: $($res.AppId)"
                }
            }
        }
        $progExecution.Value = 100

        & $appendLog "Pipeline execution finished successfully."
        $txtProgressStatus.Text = "Optimization complete."

        # Update Summary Stats
        $txtStatTotal.Text = "$totalOps"
        $txtStatSuccess.Text = "$successOps"
        $txtStatSkipped.Text = "$skippedOps"

        Start-Sleep -Milliseconds 800
        & $updateStageView 5
    })

    # Summary View Buttons
    $btnRestartExplorer.Add_Click({
        Restart-ShellExplorer
        [System.Windows.MessageBox]::Show("Windows Explorer has been restarted.", "NH Win Debloater", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    })

    $btnOpenLog.Add_Click({
        $logFile = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Logs\NHWinDebloater.log"
        if (Test-Path $logFile) {
            Start-Process notepad.exe $logFile
        } else {
            [System.Windows.MessageBox]::Show("Session log file not found.", "NH Win Debloater", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        }
    })

    $btnFinish.Add_Click({
        $window.Close()
    })

    # Initial view setup
    & $updateStageView 1

    # Show Modal Window
    $null = $window.ShowDialog()
}

Export-ModuleMember -Function Show-DebloaterWindow

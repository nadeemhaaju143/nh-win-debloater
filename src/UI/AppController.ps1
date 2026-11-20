<#
    .SYNOPSIS
        NH Win Debloater - UI Controller Engine
    .DESCRIPTION
        Orchestrates the WPF/XAML Guided Setup Assistant, manages stage transitions with
        fluid animations, populates application catalogs with dark Material multi-select
        category filters, executes dry-run previews, and triggers atomic debloat pipelines
        with dedicated AI integration, privacy, gaming, and system tweak controls.
    .MODULEVERSION
        0.4.0
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
    $dotElevationStatus = $window.FindName("DotElevationStatus")

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

    # Tab 1: Apps & Multi-Select Category Filters
    $txtAppFilter = $window.FindName("TxtAppFilter")
    $toggleAppCategories = $window.FindName("ToggleAppCategories")
    $chkCatRecommended = $window.FindName("ChkCatRecommended")
    $chkCatMinimal = $window.FindName("ChkCatMinimal")
    $chkCatDeep = $window.FindName("ChkCatDeep")
    $chkCatOem = $window.FindName("ChkCatOem")
    $chkCatXbox = $window.FindName("ChkCatXbox")
    $chkCatMedia = $window.FindName("ChkCatMedia")
    $btnCatSelectAll = $window.FindName("BtnCatSelectAll")
    $btnCatClear = $window.FindName("BtnCatClear")

    $chkOnlyInstalled = $window.FindName("ChkOnlyInstalled")
    $btnSelectAllApps = $window.FindName("BtnSelectAllApps")
    $btnDeselectAllApps = $window.FindName("BtnDeselectAllApps")
    $btnInvertSelection = $window.FindName("BtnInvertSelection")
    $txtAppsSummary = $window.FindName("TxtAppsSummary")
    $listAppsContainer = $window.FindName("ListAppsContainer")

    # Tab 2: Privacy & Search
    $togglePrivacyPresets = $window.FindName("TogglePrivacyPresets")
    $btnPrivacyRecommended = $window.FindName("BtnPrivacyRecommended")
    $btnPrivacyStrict = $window.FindName("BtnPrivacyStrict")
    $btnSelectAllPrivacy = $window.FindName("BtnSelectAllPrivacy")
    $btnDeselectAllPrivacy = $window.FindName("BtnDeselectAllPrivacy")
    $chkTelemetry = $window.FindName("ChkTelemetry")
    $chkBingSearch = $window.FindName("ChkBingSearch")
    $chkAdvertisingId = $window.FindName("ChkAdvertisingId")
    $chkActivityHistory = $window.FindName("ChkActivityHistory")
    $chkTailoredExp = $window.FindName("ChkTailoredExp")

    # Tab 3: UI & Shell
    $toggleShellPresets = $window.FindName("ToggleShellPresets")
    $btnShellClean = $window.FindName("BtnShellClean")
    $btnShellPowerUser = $window.FindName("BtnShellPowerUser")
    $btnSelectAllShell = $window.FindName("BtnSelectAllShell")
    $btnDeselectAllShell = $window.FindName("BtnDeselectAllShell")
    $chkShowExt = $window.FindName("ChkShowExt")
    $chkShowHidden = $window.FindName("ChkShowHidden")
    $chkExplorerThisPC = $window.FindName("ChkExplorerThisPC")
    $chkClassicContextMenu = $window.FindName("ChkClassicContextMenu")
    $chkHideWidgets = $window.FindName("ChkHideWidgets")
    $chkHideChat = $window.FindName("ChkHideChat")
    $chkEndTask = $window.FindName("ChkEndTask")
    $chkAlignLeft = $window.FindName("ChkAlignLeft")
    $chkHideOneDriveNav = $window.FindName("ChkHideOneDriveNav")
    $chkSearchHighlights = $window.FindName("ChkSearchHighlights")
    $chkStartRecommended = $window.FindName("ChkStartRecommended")
    $chkCompactExplorer = $window.FindName("ChkCompactExplorer")
    $chkMultitasking = $window.FindName("ChkMultitasking")

    # Tab 4: Gaming & Performance
    $toggleGamingPresets = $window.FindName("ToggleGamingPresets")
    $btnGamingMaxPerformance = $window.FindName("BtnGamingMaxPerformance")
    $btnGamingStorage = $window.FindName("BtnGamingStorage")
    $btnSelectAllGaming = $window.FindName("BtnSelectAllGaming")
    $btnDeselectAllGaming = $window.FindName("BtnDeselectAllGaming")
    $chkGameDVR = $window.FindName("ChkGameDVR")
    $chkDeliveryOpt = $window.FindName("ChkDeliveryOpt")
    $chkEdgeBackground = $window.FindName("ChkEdgeBackground")
    $chkScheduledTasks = $window.FindName("ChkScheduledTasks")
    $chkTelemetryService = $window.FindName("ChkTelemetryService")
    $chkHibernation = $window.FindName("ChkHibernation")

    # Tab 5: System Extras
    $toggleExtrasPresets = $window.FindName("ToggleExtrasPresets")
    $btnExtrasRecommended = $window.FindName("BtnExtrasRecommended")
    $btnSelectAllExtras = $window.FindName("BtnSelectAllExtras")
    $btnDeselectAllExtras = $window.FindName("BtnDeselectAllExtras")
    $chkConsumerFeatures = $window.FindName("ChkConsumerFeatures")
    $chkLockScreenAds = $window.FindName("ChkLockScreenAds")
    $chkMousePrecision = $window.FindName("ChkMousePrecision")
    $chkStickyKeys = $window.FindName("ChkStickyKeys")
    $chkFastStartup = $window.FindName("ChkFastStartup")
    $chkStorageSense = $window.FindName("ChkStorageSense")
    $chkPreventAutoReboot = $window.FindName("ChkPreventAutoReboot")
    $chkExcludeDrivers = $window.FindName("ChkExcludeDrivers")

    # Tab 6: AI Integration (Dedicated Suite)
    $toggleAIPresets = $window.FindName("ToggleAIPresets")
    $btnAIAll = $window.FindName("BtnAIAll")
    $btnAISystemOnly = $window.FindName("BtnAISystemOnly")
    $btnAIAppsOnly = $window.FindName("BtnAIAppsOnly")
    $btnSelectAllAI = $window.FindName("BtnSelectAllAI")
    $btnDeselectAllAI = $window.FindName("BtnDeselectAllAI")
    $chkCopilotPolicy = $window.FindName("ChkCopilotPolicy")
    $chkCopilotAppx = $window.FindName("ChkCopilotAppx")
    $chkRecallAI = $window.FindName("ChkRecallAI")
    $chkEdgeAI = $window.FindName("ChkEdgeAI")
    $chkPaintAI = $window.FindName("ChkPaintAI")
    $chkNotepadAI = $window.FindName("ChkNotepadAI")

    # Tab 7: Optional Features
    $btnSelectAllFeatures = $window.FindName("BtnSelectAllFeatures")
    $btnDeselectAllFeatures = $window.FindName("BtnDeselectAllFeatures")
    $chkWindowsSandbox = $window.FindName("ChkWindowsSandbox")
    $chkWSL = $window.FindName("ChkWSL")

    # Safety & Dry-Run
    $chkCreateRestorePoint = $window.FindName("ChkCreateRestorePoint")
    $chkRegistrySnapshot = $window.FindName("ChkRegistrySnapshot")
    $btnRunDryRun = $window.FindName("BtnRunDryRun")
    $txtDryRunStatus = $window.FindName("TxtDryRunStatus")
    $txtDryRunLog = $window.FindName("TxtDryRunLog")

    # Execution Progress
    $txtProgressStatus = $window.FindName("TxtProgressStatus")
    $progExecution = $window.FindName("ProgExecution")
    $txtLiveLog = $window.FindName("TxtLiveLog")

    # Summary
    $txtStatTotal = $window.FindName("TxtStatTotal")
    $txtStatSuccess = $window.FindName("TxtStatSuccess")
    $txtStatSkipped = $window.FindName("TxtStatSkipped")
    $btnRestartExplorer = $window.FindName("BtnRestartExplorer")
    $btnOpenLog = $window.FindName("BtnOpenLog")
    $btnOpenBackups = $window.FindName("BtnOpenBackups")

    # Navigation & Promotion
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
        $txtVersion.Text = "v0.4"
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
            } catch {
                Write-Verbose "Could not load window icon '$ico': $($_.Exception.Message)"
            }
        }
    }

    # Header Logo wiring (preferring raster official logo, falling back to stylish vector box)
    $logoCandidates = @(
        (Join-Path $logoDir "nhdigital-logo.png"),
        (Join-Path $logoDir "logo.png"),
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
    if ($dotElevationStatus) {
        $dotElevationStatus.Fill = $txtElevationStatus.Foreground
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

    # 7. State Management & Animation Engine
    $script:CurrentStage = 1
    $script:AppCheckboxes = [System.Collections.Generic.List[System.Windows.Controls.CheckBox]]::new()
    $script:AppMetadata = @{}
    $script:InstalledAppMap = $null

    # Function to update stage views with smooth Material Design opacity transition
    $updateStageView = {
        param([int]$stage)
        $script:CurrentStage = $stage

        # Helper to smoothly reveal a target view
        $revealStage = {
            param([System.Windows.FrameworkElement]$target)
            $target.Visibility = [System.Windows.Visibility]::Visible
            try {
                $fadeAnim = [System.Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, [TimeSpan]::FromMilliseconds(180))
                $target.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeAnim)
            } catch {
                Write-Verbose "Animation suppressed: $($_.Exception.Message)"
            }
        }

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
                & $revealStage $viewStage1
                $stepTag1.Foreground = $stepColorActive; $stepTag1.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                $btnNext.Visibility = [System.Windows.Visibility]::Visible
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            2 {
                & $revealStage $viewStage2
                $stepTag2.Foreground = $stepColorActive; $stepTag2.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Visible
                $btnNext.Visibility = [System.Windows.Visibility]::Visible
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            3 {
                & $revealStage $viewStage3
                $stepTag3.Foreground = $stepColorActive; $stepTag3.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Visible
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Visible
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            4 {
                & $revealStage $viewStage4
                $stepTag4.Foreground = $stepColorActive; $stepTag4.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            5 {
                & $revealStage $viewStage5
                $stepTag5.Foreground = $stepColorActive; $stepTag5.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Visible
            }
        }
    }

    # Summary Text Updater
    $updateSummaryText = {
        $visibleCount = 0
        $selectedCount = 0
        foreach ($cb in $script:AppCheckboxes) {
            if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) {
                $visibleCount++
                if ($cb.IsChecked) { $selectedCount++ }
            }
        }
        if ($txtAppsSummary) {
            $txtAppsSummary.Text = "Showing $visibleCount apps ($selectedCount selected for removal)"
        }
    }

    # Dynamic App Search & Installed Filter Engine
    $filterApps = {
        $filter = if ($txtAppFilter) { $txtAppFilter.Text.Trim().ToLower() } else { "" }
        $onlyInst = if ($chkOnlyInstalled) { [bool]$chkOnlyInstalled.IsChecked } else { $false }

        foreach ($cb in $script:AppCheckboxes) {
            $meta = $script:AppMetadata[$cb]
            if (-not $meta) { continue }

            $matchesText = [string]::IsNullOrWhiteSpace($filter) -or
                ($meta.AppId.ToLower().Contains($filter)) -or
                ($meta.DisplayName.ToLower().Contains($filter))

            $matchesInstalled = (-not $onlyInst) -or ($meta.IsInstalled -eq $true)

            if ($matchesText -and $matchesInstalled) {
                $cb.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $cb.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }

        & $updateSummaryText
    }

    # Multi-Category Aggregation Engine for Bloatware Apps
    $populateApps = {
        # 1. Scan and cache installed packages once per session
        if ($null -eq $script:InstalledAppMap) {
            try {
                $scanned = Get-InstalledDebloatApp -PresetsPath $presetsPath
                $script:InstalledAppMap = @{}
                foreach ($item in $scanned) {
                    if ($item.AppId) {
                        $script:InstalledAppMap[$item.AppId.ToLower()] = $item
                    }
                }
            } catch {
                Write-Verbose "Could not scan installed packages: $($_.Exception.Message)"
                $script:InstalledAppMap = @{}
            }
        }

        # 2. Multi-category selection aggregation
        $appMap = @{}
        $selectedCatNames = [System.Collections.Generic.List[string]]::new()

        if ($chkCatRecommended -and $chkCatRecommended.IsChecked) {
            $selectedCatNames.Add("Recommended")
            $recList = Get-DebloatPreset -PresetName "Default" -PresetsPath $presetsPath
            foreach ($a in $recList) { $appMap[$a.AppId] = $a }
        }
        if ($chkCatMinimal -and $chkCatMinimal.IsChecked) {
            $selectedCatNames.Add("Minimal")
            $minList = Get-DebloatPreset -PresetName "Minimal" -PresetsPath $presetsPath
            foreach ($a in $minList) { $appMap[$a.AppId] = $a }
        }
        if ($chkCatDeep -and $chkCatDeep.IsChecked) {
            $selectedCatNames.Add("Deep")
            $deepList = Get-DebloatPreset -PresetName "Deep" -PresetsPath $presetsPath
            foreach ($a in $deepList) { $appMap[$a.AppId] = $a }
        }
        if ($chkCatOem -and $chkCatOem.IsChecked) {
            $selectedCatNames.Add("OEM")
            $deepList = Get-DebloatPreset -PresetName "Deep" -PresetsPath $presetsPath
            foreach ($a in ($deepList | Where-Object { -not ($_.AppId -like "Microsoft.*") })) {
                $appMap[$a.AppId] = $a
            }
        }
        if ($chkCatXbox -and $chkCatXbox.IsChecked) {
            $selectedCatNames.Add("Xbox")
            $deepList = Get-DebloatPreset -PresetName "Deep" -PresetsPath $presetsPath
            foreach ($a in ($deepList | Where-Object { $_.AppId -like "*Xbox*" -or $_.AppId -like "*Gaming*" -or $_.AppId -like "*GameOverlay*" })) {
                $appMap[$a.AppId] = $a
            }
        }
        if ($chkCatMedia -and $chkCatMedia.IsChecked) {
            $selectedCatNames.Add("Media")
            $deepList = Get-DebloatPreset -PresetName "Deep" -PresetsPath $presetsPath
            foreach ($a in ($deepList | Where-Object {
                $_.AppId -like "*BingNews*" -or $_.AppId -like "*BingWeather*" -or $_.AppId -like "*BingSports*" -or
                $_.AppId -like "*BingFinance*" -or $_.AppId -like "*Zune*" -or $_.AppId -like "*Clipchamp*" -or $_.AppId -like "*Photos*"
            })) {
                $appMap[$a.AppId] = $a
            }
        }

        # Update Toggle Header text
        if ($toggleAppCategories) {
            if ($selectedCatNames.Count -eq 0) {
                $toggleAppCategories.Content = "Categories: None Selected (0 Apps) ▼"
            } elseif ($selectedCatNames.Count -eq 6) {
                $toggleAppCategories.Content = "Categories: All Selected ($($appMap.Count) Apps) ▼"
            } else {
                $toggleAppCategories.Content = "Categories: $($selectedCatNames -join ', ') ($($appMap.Count) Apps) ▼"
            }
        }

        $listAppsContainer.Items.Clear()
        $script:AppCheckboxes.Clear()
        $script:AppMetadata.Clear()

        foreach ($app in $appMap.Values) {
            $isInst = $script:InstalledAppMap.ContainsKey($app.AppId.ToLower())

            $cb = [System.Windows.Controls.CheckBox]::new()
            $instIndicator = if ($isInst) { "  [INSTALLED]" } else { "" }
            $cb.Content = "$($app.DisplayName) ($($app.AppId))$instIndicator"
            $cb.Tag = $app.AppId
            $cb.IsChecked = $true
            $cb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8FAFC")
            $cb.FontSize = 12
            $cb.Margin = [System.Windows.Thickness]::new(4, 4, 4, 4)

            $script:AppMetadata[$cb] = @{
                AppId       = $app.AppId
                DisplayName = $app.DisplayName
                IsInstalled = $isInst
            }

            $cb.Add_Checked({
                param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
                & $updateSummaryText
            })
            $cb.Add_Unchecked({
                param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
                & $updateSummaryText
            })

            $script:AppCheckboxes.Add($cb)
            $listAppsContainer.Items.Add($cb) | Out-Null
        }

        & $filterApps
    }

    # Tab 1: Category Checkboxes Wiring
    $catCheckboxes = @($chkCatRecommended, $chkCatMinimal, $chkCatDeep, $chkCatOem, $chkCatXbox, $chkCatMedia)
    foreach ($chk in $catCheckboxes) {
        if ($chk) {
            $chk.Add_Click({
                param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
                & $populateApps
            })
        }
    }

    if ($btnCatSelectAll) {
        $btnCatSelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $catCheckboxes) { if ($chk) { $chk.IsChecked = $true } }
            & $populateApps
        })
    }

    if ($btnCatClear) {
        $btnCatClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $catCheckboxes) { if ($chk) { $chk.IsChecked = $false } }
            & $populateApps
        })
    }

    # App Search and Selection Action Wiring
    if ($txtAppFilter) {
        $txtAppFilter.Add_TextChanged({
            param([object]$eventSource, [System.Windows.Controls.TextChangedEventArgs]$eventArgs)
            & $filterApps
        })
    }

    if ($chkOnlyInstalled) {
        $chkOnlyInstalled.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $filterApps
        })
    }

    if ($btnSelectAllApps) {
        $btnSelectAllApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($cb in $script:AppCheckboxes) {
                if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = $true }
            }
            & $updateSummaryText
        })
    }

    if ($btnDeselectAllApps) {
        $btnDeselectAllApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($cb in $script:AppCheckboxes) {
                if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = $false }
            }
            & $updateSummaryText
        })
    }

    if ($btnInvertSelection) {
        $btnInvertSelection.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($cb in $script:AppCheckboxes) {
                if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = -not $cb.IsChecked }
            }
            & $updateSummaryText
        })
    }

    # Tab 2: Privacy Batch Presets & Selection
    if ($btnSelectAllPrivacy) {
        $btnSelectAllPrivacy.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) |
                Where-Object { $_ } | ForEach-Object { $_.IsChecked = $true }
        })
    }
    if ($btnDeselectAllPrivacy) {
        $btnDeselectAllPrivacy.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) |
                Where-Object { $_ } | ForEach-Object { $_.IsChecked = $false }
        })
    }
    if ($btnPrivacyRecommended) {
        $btnPrivacyRecommended.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkTelemetry) { $chkTelemetry.IsChecked = $true }
            if ($chkBingSearch) { $chkBingSearch.IsChecked = $true }
            if ($chkAdvertisingId) { $chkAdvertisingId.IsChecked = $true }
            if ($chkActivityHistory) { $chkActivityHistory.IsChecked = $true }
            if ($chkTailoredExp) { $chkTailoredExp.IsChecked = $true }
            if ($togglePrivacyPresets) { $togglePrivacyPresets.IsChecked = $false }
        })
    }
    if ($btnPrivacyStrict) {
        $btnPrivacyStrict.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) |
                Where-Object { $_ } | ForEach-Object { $_.IsChecked = $true }
            if ($togglePrivacyPresets) { $togglePrivacyPresets.IsChecked = $false }
        })
    }

    # Tab 3: Shell Batch Presets & Selection
    $shellCheckboxes = @($chkShowExt, $chkShowHidden, $chkExplorerThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking)
    if ($btnSelectAllShell) {
        $btnSelectAllShell.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $shellCheckboxes) { if ($chk) { $chk.IsChecked = $true } }
        })
    }
    if ($btnDeselectAllShell) {
        $btnDeselectAllShell.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $shellCheckboxes) { if ($chk) { $chk.IsChecked = $false } }
        })
    }
    if ($btnShellClean) {
        $btnShellClean.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkHideWidgets) { $chkHideWidgets.IsChecked = $true }
            if ($chkHideChat) { $chkHideChat.IsChecked = $true }
            if ($chkEndTask) { $chkEndTask.IsChecked = $true }
            if ($chkSearchHighlights) { $chkSearchHighlights.IsChecked = $true }
            if ($chkStartRecommended) { $chkStartRecommended.IsChecked = $true }
            if ($chkMultitasking) { $chkMultitasking.IsChecked = $true }
            if ($toggleShellPresets) { $toggleShellPresets.IsChecked = $false }
        })
    }
    if ($btnShellPowerUser) {
        $btnShellPowerUser.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkShowExt) { $chkShowExt.IsChecked = $true }
            if ($chkShowHidden) { $chkShowHidden.IsChecked = $true }
            if ($chkExplorerThisPC) { $chkExplorerThisPC.IsChecked = $true }
            if ($chkClassicContextMenu) { $chkClassicContextMenu.IsChecked = $true }
            if ($chkCompactExplorer) { $chkCompactExplorer.IsChecked = $true }
            if ($chkEndTask) { $chkEndTask.IsChecked = $true }
            if ($toggleShellPresets) { $toggleShellPresets.IsChecked = $false }
        })
    }

    # Tab 4: Gaming Batch Presets & Selection
    $gamingCheckboxes = @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks, $chkTelemetryService, $chkHibernation)
    if ($btnSelectAllGaming) {
        $btnSelectAllGaming.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $gamingCheckboxes) { if ($chk) { $chk.IsChecked = $true } }
        })
    }
    if ($btnDeselectAllGaming) {
        $btnDeselectAllGaming.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $gamingCheckboxes) { if ($chk) { $chk.IsChecked = $false } }
        })
    }
    if ($btnGamingMaxPerformance) {
        $btnGamingMaxPerformance.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkGameDVR) { $chkGameDVR.IsChecked = $true }
            if ($chkDeliveryOpt) { $chkDeliveryOpt.IsChecked = $true }
            if ($chkEdgeBackground) { $chkEdgeBackground.IsChecked = $true }
            if ($chkScheduledTasks) { $chkScheduledTasks.IsChecked = $true }
            if ($chkTelemetryService) { $chkTelemetryService.IsChecked = $true }
            if ($toggleGamingPresets) { $toggleGamingPresets.IsChecked = $false }
        })
    }
    if ($btnGamingStorage) {
        $btnGamingStorage.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkDeliveryOpt) { $chkDeliveryOpt.IsChecked = $true }
            if ($chkHibernation) { $chkHibernation.IsChecked = $true }
            if ($toggleGamingPresets) { $toggleGamingPresets.IsChecked = $false }
        })
    }

    # Tab 5: Extras Batch Presets & Selection
    $extrasCheckboxes = @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkFastStartup, $chkStorageSense, $chkPreventAutoReboot, $chkExcludeDrivers)
    if ($btnSelectAllExtras) {
        $btnSelectAllExtras.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $extrasCheckboxes) { if ($chk) { $chk.IsChecked = $true } }
        })
    }
    if ($btnDeselectAllExtras) {
        $btnDeselectAllExtras.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $extrasCheckboxes) { if ($chk) { $chk.IsChecked = $false } }
        })
    }
    if ($btnExtrasRecommended) {
        $btnExtrasRecommended.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkConsumerFeatures) { $chkConsumerFeatures.IsChecked = $true }
            if ($chkLockScreenAds) { $chkLockScreenAds.IsChecked = $true }
            if ($chkMousePrecision) { $chkMousePrecision.IsChecked = $true }
            if ($chkStickyKeys) { $chkStickyKeys.IsChecked = $true }
            if ($chkPreventAutoReboot) { $chkPreventAutoReboot.IsChecked = $true }
            if ($chkExcludeDrivers) { $chkExcludeDrivers.IsChecked = $true }
            if ($toggleExtrasPresets) { $toggleExtrasPresets.IsChecked = $false }
        })
    }

    # Tab 6: AI Integration Batch Presets & Selection
    $aiCheckboxes = @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI)
    if ($btnSelectAllAI) {
        $btnSelectAllAI.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $aiCheckboxes) { if ($chk) { $chk.IsChecked = $true } }
        })
    }
    if ($btnDeselectAllAI) {
        $btnDeselectAllAI.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $aiCheckboxes) { if ($chk) { $chk.IsChecked = $false } }
        })
    }
    if ($btnAIAll) {
        $btnAIAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($chk in $aiCheckboxes) { if ($chk) { $chk.IsChecked = $true } }
            if ($toggleAIPresets) { $toggleAIPresets.IsChecked = $false }
        })
    }
    if ($btnAISystemOnly) {
        $btnAISystemOnly.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkCopilotPolicy) { $chkCopilotPolicy.IsChecked = $true }
            if ($chkCopilotAppx) { $chkCopilotAppx.IsChecked = $true }
            if ($chkRecallAI) { $chkRecallAI.IsChecked = $true }
            if ($chkEdgeAI) { $chkEdgeAI.IsChecked = $false }
            if ($chkPaintAI) { $chkPaintAI.IsChecked = $false }
            if ($chkNotepadAI) { $chkNotepadAI.IsChecked = $false }
            if ($toggleAIPresets) { $toggleAIPresets.IsChecked = $false }
        })
    }
    if ($btnAIAppsOnly) {
        $btnAIAppsOnly.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkCopilotPolicy) { $chkCopilotPolicy.IsChecked = $false }
            if ($chkCopilotAppx) { $chkCopilotAppx.IsChecked = $false }
            if ($chkRecallAI) { $chkRecallAI.IsChecked = $false }
            if ($chkEdgeAI) { $chkEdgeAI.IsChecked = $true }
            if ($chkPaintAI) { $chkPaintAI.IsChecked = $true }
            if ($chkNotepadAI) { $chkNotepadAI.IsChecked = $true }
            if ($toggleAIPresets) { $toggleAIPresets.IsChecked = $false }
        })
    }

    # Tab 7: Features Selection
    if ($btnSelectAllFeatures) {
        $btnSelectAllFeatures.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkWindowsSandbox) { $chkWindowsSandbox.IsChecked = $true }
            if ($chkWSL) { $chkWSL.IsChecked = $true }
        })
    }
    if ($btnDeselectAllFeatures) {
        $btnDeselectAllFeatures.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkWindowsSandbox) { $chkWindowsSandbox.IsChecked = $false }
            if ($chkWSL) { $chkWSL.IsChecked = $false }
        })
    }

    # Dry-Run Preview Action
    $btnRunDryRun.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        $txtDryRunStatus.Text = "Simulating WhatIf dry-run changes..."
        $txtDryRunLog.Clear()

        $logBuilder = [System.Text.StringBuilder]::new()
        $logBuilder.AppendLine("[$(Get-Date -Format 'HH:mm:ss')] DRY-RUN PREVIEW INITIATED") | Out-Null

        $scope = if ($radioScopeCurrentUser.IsChecked) { "CurrentUser" } elseif ($radioScopeDefaultUser.IsChecked) { "DefaultUser" } else { "AllUsers" }
        $logBuilder.AppendLine("Target Scope: $scope") | Out-Null

        if ($chkTelemetry -and $chkTelemetry.IsChecked) { $logBuilder.AppendLine("WhatIf: Disable Telemetry policies would be applied.") | Out-Null }
        if ($chkBingSearch -and $chkBingSearch.IsChecked) { $logBuilder.AppendLine("WhatIf: Start Menu Bing search suggestions would be disabled.") | Out-Null }
        if ($chkShowExt -and $chkShowExt.IsChecked) { $logBuilder.AppendLine("WhatIf: File Explorer Show Known Extensions would be enabled.") | Out-Null }
        if ($chkShowHidden -and $chkShowHidden.IsChecked) { $logBuilder.AppendLine("WhatIf: File Explorer Show Hidden Files would be enabled.") | Out-Null }
        if ($chkClassicContextMenu -and $chkClassicContextMenu.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows 10 Classic Context Menu would be restored.") | Out-Null }
        if ($chkMultitasking -and $chkMultitasking.IsChecked) { $logBuilder.AppendLine("WhatIf: Snap Assist suggestions and Alt+Tab tab clutter would be disabled.") | Out-Null }
        if ($chkGameDVR -and $chkGameDVR.IsChecked) { $logBuilder.AppendLine("WhatIf: Game DVR background recording & Xbox Game Bar would be disabled.") | Out-Null }
        if ($chkDeliveryOpt -and $chkDeliveryOpt.IsChecked) { $logBuilder.AppendLine("WhatIf: Delivery Optimization P2P updates would be disabled.") | Out-Null }
        if ($chkEdgeBackground -and $chkEdgeBackground.IsChecked) { $logBuilder.AppendLine("WhatIf: Microsoft Edge background processes and Startup Boost would be disabled.") | Out-Null }
        if ($chkScheduledTasks -and $chkScheduledTasks.IsChecked) { $logBuilder.AppendLine("WhatIf: Telemetry scheduled tasks (Consolidator, Appraiser) would be disabled.") | Out-Null }
        if ($chkTelemetryService -and $chkTelemetryService.IsChecked) { $logBuilder.AppendLine("WhatIf: DiagTrack connected user experiences service would be disabled.") | Out-Null }
        if ($chkHibernation -and $chkHibernation.IsChecked) { $logBuilder.AppendLine("WhatIf: Hibernation storage would be reclaimed (powercfg /h off).") | Out-Null }
        if ($chkConsumerFeatures -and $chkConsumerFeatures.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows consumer features and promo preinstalls would be blocked.") | Out-Null }
        if ($chkMousePrecision -and $chkMousePrecision.IsChecked) { $logBuilder.AppendLine("WhatIf: Mouse pointer acceleration would be disabled (1:1 precision).") | Out-Null }
        if ($chkStickyKeys -and $chkStickyKeys.IsChecked) { $logBuilder.AppendLine("WhatIf: Sticky Keys 5x Shift shortcut prompt would be disabled.") | Out-Null }
        if ($chkFastStartup -and $chkFastStartup.IsChecked) { $logBuilder.AppendLine("WhatIf: Fast Startup hybrid sleep would be disabled.") | Out-Null }
        if ($chkStorageSense -and $chkStorageSense.IsChecked) { $logBuilder.AppendLine("WhatIf: Storage Sense automatic deletion policy would be disabled.") | Out-Null }
        if ($chkPreventAutoReboot -and $chkPreventAutoReboot.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Update automatic reboot while user logged on would be prevented.") | Out-Null }
        if ($chkExcludeDrivers -and $chkExcludeDrivers.IsChecked) { $logBuilder.AppendLine("WhatIf: Third-party drivers would be excluded from Windows Quality Updates.") | Out-Null }
        if ($chkSearchHighlights -and $chkSearchHighlights.IsChecked) { $logBuilder.AppendLine("WhatIf: Taskbar search highlights and doodles would be disabled.") | Out-Null }
        if ($chkStartRecommended -and $chkStartRecommended.IsChecked) { $logBuilder.AppendLine("WhatIf: Start Menu Recommended clutter would be hidden.") | Out-Null }
        if ($chkCompactExplorer -and $chkCompactExplorer.IsChecked) { $logBuilder.AppendLine("WhatIf: File Explorer compact view would be enabled.") | Out-Null }
        if ($chkWindowsSandbox -and $chkWindowsSandbox.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Sandbox optional feature would be enabled.") | Out-Null }
        if ($chkWSL -and $chkWSL.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Subsystem for Linux (WSL) would be enabled.") | Out-Null }

        # AI Suite Simulations
        if ($chkCopilotPolicy -and $chkCopilotPolicy.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Copilot taskbar button and group policies would be disabled.") | Out-Null }
        if ($chkCopilotAppx -and $chkCopilotAppx.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Copilot AppX package would be removed.") | Out-Null }
        if ($chkRecallAI -and $chkRecallAI.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Recall and AI screen analysis snapshots would be disabled.") | Out-Null }
        if ($chkEdgeAI -and $chkEdgeAI.IsChecked) { $logBuilder.AppendLine("WhatIf: Microsoft Edge Copilot & AI sidebar would be disabled.") | Out-Null }
        if ($chkPaintAI -and $chkPaintAI.IsChecked) { $logBuilder.AppendLine("WhatIf: Microsoft Paint Cocreator AI would be disabled.") | Out-Null }
        if ($chkNotepadAI -and $chkNotepadAI.IsChecked) { $logBuilder.AppendLine("WhatIf: Microsoft Notepad Cowriter AI would be disabled.") | Out-Null }

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
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        if ($script:CurrentStage -eq 1) {
            if ($radioPresetMinimal.IsChecked) {
                if ($chkCatMinimal) { $chkCatMinimal.IsChecked = $true }
                if ($chkCatRecommended) { $chkCatRecommended.IsChecked = $false }
                if ($chkCatDeep) { $chkCatDeep.IsChecked = $false }
                if ($chkCatOem) { $chkCatOem.IsChecked = $false }
                if ($chkCatXbox) { $chkCatXbox.IsChecked = $false }
                if ($chkCatMedia) { $chkCatMedia.IsChecked = $false }
            } elseif ($radioPresetDeep.IsChecked) {
                if ($chkCatDeep) { $chkCatDeep.IsChecked = $true }
                if ($chkCatRecommended) { $chkCatRecommended.IsChecked = $false }
                if ($chkCatMinimal) { $chkCatMinimal.IsChecked = $false }
                if ($chkCatOem) { $chkCatOem.IsChecked = $false }
                if ($chkCatXbox) { $chkCatXbox.IsChecked = $false }
                if ($chkCatMedia) { $chkCatMedia.IsChecked = $false }
            } else {
                if ($chkCatRecommended) { $chkCatRecommended.IsChecked = $true }
                if ($chkCatMinimal) { $chkCatMinimal.IsChecked = $false }
                if ($chkCatDeep) { $chkCatDeep.IsChecked = $false }
                if ($chkCatOem) { $chkCatOem.IsChecked = $false }
                if ($chkCatXbox) { $chkCatXbox.IsChecked = $false }
                if ($chkCatMedia) { $chkCatMedia.IsChecked = $false }
            }
            & $populateApps
            & $updateStageView 2
        } elseif ($script:CurrentStage -eq 2) {
            & $updateStageView 3
        }
    })

    $btnBack.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        if ($script:CurrentStage -gt 1) {
            & $updateStageView ($script:CurrentStage - 1)
        }
    })

    # Apply Action Pipeline
    $btnApply.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
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
            $rp = New-DebloatRestorePoint -Description "NH Win Debloater v0.4 Checkpoint"
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
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI",
                "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\ClickToDo",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\ClickToDo",
                "HKCU:\Software\Policies\Microsoft\Windows\Explorer",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
                "HKCU:\Control Panel\Mouse",
                "HKCU:\Control Panel\Accessibility\StickyKeys",
                "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
                "HKLM:\SOFTWARE\Policies\Microsoft\Edge",
                "HKCU:\Software\Microsoft\Paint\Settings",
                "HKCU:\Software\Policies\Microsoft\Paint",
                "HKCU:\Software\Microsoft\Notepad",
                "HKCU:\Software\Policies\Microsoft\Notepad"
            )
            $snapFile = Export-RegistrySnapshot -RegistryPaths $regPaths
            $totalOps++
            $successOps++
            & $appendLog "Registry snapshot saved: $(Split-Path $snapFile -Leaf)"
        }
        $progExecution.Value = 35

        # 3. Privacy & Search Tweaks
        if ($chkTelemetry.IsChecked) { Set-PrivacySetting -SettingId "DisableTelemetry" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Telemetry diagnostics set to Security/Basic." }
        if ($chkBingSearch.IsChecked) { Set-PrivacySetting -SettingId "DisableBingSearch" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Bing Start Search suggestions disabled." }
        if ($chkAdvertisingId.IsChecked) { Set-PrivacySetting -SettingId "DisableAdvertisingId" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Advertising ID disabled." }
        if ($chkActivityHistory.IsChecked) { Set-PrivacySetting -SettingId "DisableActivityHistory" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Activity History feed disabled." }
        if ($chkTailoredExp.IsChecked) { Set-PrivacySetting -SettingId "DisableTailoredExperiences" -Enable $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Tailored Experiences disabled." }
        $progExecution.Value = 48

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
        if ($chkSearchHighlights.IsChecked) { Set-ShellSetting -SettingId "HideSearchHighlights" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar search highlights disabled." }
        if ($chkStartRecommended.IsChecked) { Set-StartMenuRecommendedTweak -HideRecommended $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Start Menu Recommended clutter hidden." }
        if ($chkCompactExplorer.IsChecked) { Set-ShellSetting -SettingId "ShowCompactExplorer" | Out-Null; $totalOps++; $successOps++; & $appendLog "File Explorer compact view enabled." }
        if ($chkMultitasking.IsChecked) { Set-MultitaskingTweak -DisableSnapSuggestions $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Multitasking & Snap Assist suggestions disabled." }
        $progExecution.Value = 60

        # 5. Gaming & Performance Tweaks
        if ($chkGameDVR.IsChecked) { Set-GameDVRPlaybackTweak -DisableGameDVR $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Game DVR background recording disabled." }
        if ($chkDeliveryOpt.IsChecked) { Set-DeliveryOptimizationTweak -DisableP2P $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Delivery Optimization P2P disabled." }
        if ($chkEdgeBackground.IsChecked) { Set-EdgeBackgroundTweak -DisableEdgeBackground $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Edge background mode and Startup Boost disabled." }
        if ($chkScheduledTasks.IsChecked) { Set-TelemetryScheduledTasksTweak -DisableTasks $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Telemetry scheduled tasks disabled." }
        if ($chkTelemetryService.IsChecked) { Set-TelemetryServiceTweak -DisableServices $true | Out-Null; $totalOps++; $successOps++; & $appendLog "DiagTrack telemetry service disabled." }
        if ($chkHibernation.IsChecked) { Set-HibernationStorageTweak -DisableHibernation $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Hibernation disabled and storage reclaimed." }
        $progExecution.Value = 72

        # 6. System Extras
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

        # 7. AI Integration Suite
        if ($chkCopilotPolicy.IsChecked -or $chkCopilotAppx.IsChecked) {
            Set-CopilotAITweak -DisableCopilot ([bool]$chkCopilotPolicy.IsChecked) -RemoveAppxPackage ([bool]$chkCopilotAppx.IsChecked) | Out-Null
            $totalOps++; $successOps++; & $appendLog "Windows Copilot policies applied (AppX removal: $([bool]$chkCopilotAppx.IsChecked))."
        }
        if ($chkRecallAI.IsChecked) {
            Set-RecallAITweak -DisableRecall $true | Out-Null
            $totalOps++; $successOps++; & $appendLog "Windows Recall & AI screen analysis snapshots disabled."
        }
        if ($chkEdgeAI.IsChecked -or $chkPaintAI.IsChecked -or $chkNotepadAI.IsChecked) {
            Set-ApplicationAITweak -DisableEdgeAI ([bool]$chkEdgeAI.IsChecked) `
                                  -DisablePaintAI ([bool]$chkPaintAI.IsChecked) `
                                  -DisableNotepadAI ([bool]$chkNotepadAI.IsChecked) | Out-Null
            $totalOps++; $successOps++; & $appendLog "Integrated application AI features (Edge/Paint/Notepad) updated."
        }
        $progExecution.Value = 88

        # 8. Optional Windows Features
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
        $progExecution.Value = 93

        # 9. Selected Apps Removal
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
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        Restart-ShellExplorer
        [System.Windows.MessageBox]::Show("Windows Explorer has been restarted.", "NH Win Debloater", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    })

    $btnOpenLog.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        $logFile = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Logs\NHWinDebloater.log"
        if (Test-Path $logFile) {
            Start-Process notepad.exe $logFile
        } else {
            [System.Windows.MessageBox]::Show("Session log file not found.", "NH Win Debloater", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        }
    })

    if ($btnOpenBackups) {
        $btnOpenBackups.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $backupDir = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups"
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            Start-Process explorer.exe -ArgumentList "`"$backupDir`""
        })
    }

    $btnFinish.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        $window.Close()
    })

    # Initial view setup
    & $updateStageView 1

    # Show Modal Window
    $null = $window.ShowDialog()
}

if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Show-DebloaterWindow
}

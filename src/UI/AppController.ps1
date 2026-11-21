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
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
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
    $script:AppVersion = if (Test-Path $versionPath) { (Get-Content -Path $versionPath -Raw).Trim() } else { "0.5" }
    $logoDir = Join-Path $ProjectRoot "assets\logo"

    # 2. Import Core Modules
    Import-Module (Join-Path $corePath "AppManager.psm1") -Force
    Import-Module (Join-Path $corePath "PrivacySearch.psm1") -Force
    Import-Module (Join-Path $corePath "ShellCustomization.psm1") -Force
    Import-Module (Join-Path $corePath "SystemTweaks.psm1") -Force
    Import-Module (Join-Path $corePath "ExecutionLog.psm1") -Force

    Initialize-DebloatLogger -Version $script:AppVersion | Out-Null

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

    # Stage 1: Preset Cards & Scope Radios
    $cardPresetMinimal = $window.FindName("CardPresetMinimal")
    $cardPresetDefault = $window.FindName("CardPresetDefault")
    $cardPresetDeep = $window.FindName("CardPresetDeep")
    $radioPresetMinimal = $window.FindName("RadioPresetMinimal")
    $radioPresetDefault = $window.FindName("RadioPresetDefault")
    $radioPresetDeep = $window.FindName("RadioPresetDeep")
    $radioScopeCurrentUser = $window.FindName("RadioScopeCurrentUser")
    $radioScopeDefaultUser = $window.FindName("RadioScopeDefaultUser")

    # Stage 2 Header Live Counters & Badges
    $txtGlobalSelectionSummary = $window.FindName("TxtGlobalSelectionSummary")
    $badgeLiveImpact = $window.FindName("BadgeLiveImpact")
    $iconLiveImpact = $window.FindName("IconLiveImpact")
    $txtLiveImpact = $window.FindName("TxtLiveImpact")

    # Per-Tab Count Badges
    $txtTabAppsCount = $window.FindName("TxtTabAppsCount")
    $txtTabPrivacyCount = $window.FindName("TxtTabPrivacyCount")
    $txtTabShellCount = $window.FindName("TxtTabShellCount")
    $txtTabGamingCount = $window.FindName("TxtTabGamingCount")
    $txtTabExtrasCount = $window.FindName("TxtTabExtrasCount")
    $txtTabAICount = $window.FindName("TxtTabAICount")
    $txtTabFeaturesCount = $window.FindName("TxtTabFeaturesCount")

    # Tab 1: Apps & Multi-Select Category Filters
    $txtAppFilter = $window.FindName("TxtAppFilter")
    $toggleAppCategories = $window.FindName("ToggleAppCategories")
    $txtToggleAppCategoriesText = $window.FindName("TxtToggleAppCategoriesText")
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

    # Stage 2: TabControl
    $tabStage2Controls = $window.FindName("TabStage2Controls")

    # Tab 2: Privacy & Search
    $togglePrivacyPresets = $window.FindName("TogglePrivacyPresets")
    $txtTogglePrivacyText = $window.FindName("TxtTogglePrivacyText")
    $chkPrivTelemetry = $window.FindName("ChkPrivTelemetry")
    $chkPrivSearch = $window.FindName("ChkPrivSearch")
    $chkPrivActivity = $window.FindName("ChkPrivActivity")
    $chkPrivAds = $window.FindName("ChkPrivAds")
    $btnPrivSelectAll = $window.FindName("BtnPrivSelectAll")
    $btnPrivClear = $window.FindName("BtnPrivClear")
    $btnSelectAllPrivacy = $window.FindName("BtnSelectAllPrivacy")
    $btnDeselectAllPrivacy = $window.FindName("BtnDeselectAllPrivacy")
    $chkTelemetry = $window.FindName("ChkTelemetry")
    $chkBingSearch = $window.FindName("ChkBingSearch")
    $chkAdvertisingId = $window.FindName("ChkAdvertisingId")
    $chkActivityHistory = $window.FindName("ChkActivityHistory")
    $chkTailoredExp = $window.FindName("ChkTailoredExp")

    # Tab 3: UI & Shell
    $toggleShellPresets = $window.FindName("ToggleShellPresets")
    $txtToggleShellText = $window.FindName("TxtToggleShellText")
    $chkShellClean = $window.FindName("ChkShellClean")
    $chkShellPowerUser = $window.FindName("ChkShellPowerUser")
    $chkShellTaskbar = $window.FindName("ChkShellTaskbar")
    $btnShellSelectAll = $window.FindName("BtnShellSelectAll")
    $btnShellClear = $window.FindName("BtnShellClear")
    $btnSelectAllShell = $window.FindName("BtnSelectAllShell")
    $btnDeselectAllShell = $window.FindName("BtnDeselectAllShell")
    $chkShowExt = $window.FindName("ChkShowExt")
    $chkShowHidden = $window.FindName("ChkShowHidden")
    $chkLaunchToThisPC = $window.FindName("ChkLaunchToThisPC")
    if (-not $chkLaunchToThisPC) { $chkLaunchToThisPC = $window.FindName("ChkExplorerThisPC") }
    $chkClassicContextMenu = $window.FindName("ChkClassicContextMenu")
    $chkHideWidgets = $window.FindName("ChkHideWidgets")
    $chkHideChat = $window.FindName("ChkHideChat")
    $chkEndTask = $window.FindName("ChkEndTask")
    $chkAlignLeft = $window.FindName("ChkAlignLeft")
    $chkHideOneDriveNav = $window.FindName("ChkHideOneDriveNav")
    $chkHideGalleryNav = $window.FindName("ChkHideGalleryNav")
    $chkSearchHighlights = $window.FindName("ChkSearchHighlights")
    $chkStartRecommended = $window.FindName("ChkStartRecommended")
    $chkCompactExplorer = $window.FindName("ChkCompactExplorer")
    $chkMultitasking = $window.FindName("ChkMultitasking")
    $chkSnapFlyout = $window.FindName("ChkSnapFlyout")

    # Tab 4: Gaming & Performance
    $toggleGamingPresets = $window.FindName("ToggleGamingPresets")
    $txtToggleGamingText = $window.FindName("TxtToggleGamingText")
    $chkGamingDVR = $window.FindName("ChkGamingDVR")
    $chkGamingBackground = $window.FindName("ChkGamingBackground")
    $chkGamingOptimization = $window.FindName("ChkGamingOptimization")
    $chkGamingStorage = $window.FindName("ChkGamingStorage")
    $btnGamingSelectAll = $window.FindName("BtnGamingSelectAll")
    $btnGamingClear = $window.FindName("BtnGamingClear")
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
    $txtToggleExtrasText = $window.FindName("TxtToggleExtrasText")
    $chkExtrasPromos = $window.FindName("ChkExtrasPromos")
    $chkExtrasDesktop = $window.FindName("ChkExtrasDesktop")
    $chkExtrasAccessibility = $window.FindName("ChkExtrasAccessibility")
    $chkExtrasPower = $window.FindName("ChkExtrasPower")
    $btnExtrasSelectAll = $window.FindName("BtnExtrasSelectAll")
    $btnExtrasClear = $window.FindName("BtnExtrasClear")
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
    $chkSettingsHome = $window.FindName("ChkSettingsHome")

    # Tab 6: AI Integration (Dedicated Suite)
    $toggleAIPresets = $window.FindName("ToggleAIPresets")
    $txtToggleAIText = $window.FindName("TxtToggleAIText")
    $chkAISystem = $window.FindName("ChkAISystem")
    $chkAIEdge = $window.FindName("ChkAIEdge")
    $chkAIApps = $window.FindName("ChkAIApps")
    $btnAISelectAll = $window.FindName("BtnAISelectAll")
    $btnAIClear = $window.FindName("BtnAIClear")
    $btnSelectAllAI = $window.FindName("BtnSelectAllAI")
    $btnDeselectAllAI = $window.FindName("BtnDeselectAllAI")
    $chkCopilotPolicy = $window.FindName("ChkCopilotPolicy")
    $chkCopilotAppx = $window.FindName("ChkCopilotAppx")
    $chkRecallAI = $window.FindName("ChkRecallAI")
    $chkEdgeAI = $window.FindName("ChkEdgeAI")
    $chkPaintAI = $window.FindName("ChkPaintAI")
    $chkNotepadAI = $window.FindName("ChkNotepadAI")

    # Tab 7: Optional Features
    $toggleFeaturesPresets = $window.FindName("ToggleFeaturesPresets")
    $txtToggleFeaturesText = $window.FindName("TxtToggleFeaturesText")
    $chkFeatSandbox = $window.FindName("ChkFeatSandbox")
    $chkFeatWSL = $window.FindName("ChkFeatWSL")
    $btnFeatSelectAll = $window.FindName("BtnFeatSelectAll")
    $btnFeatClear = $window.FindName("BtnFeatClear")
    $btnSelectAllFeatures = $window.FindName("BtnSelectAllFeatures")
    $btnDeselectAllFeatures = $window.FindName("BtnDeselectAllFeatures")
    $chkWindowsSandbox = $window.FindName("ChkWindowsSandbox")
    $chkWSL = $window.FindName("ChkWSL")

    # Stage 3 Safety & Dry-Run
    $txtStage3Summary = $window.FindName("TxtStage3Summary")
    $badgeStage3Impact = $window.FindName("BadgeStage3Impact")
    $iconStage3Impact = $window.FindName("IconStage3Impact")
    $txtStage3Impact = $window.FindName("TxtStage3Impact")
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
    $btnStage5ReinstallApps = $window.FindName("BtnStage5ReinstallApps")
    $cboRegistrySnapshots = $window.FindName("CboRegistrySnapshots")
    $btnRefreshSnapshots = $window.FindName("BtnRefreshSnapshots")
    $btnPreviewSnapshot = $window.FindName("BtnPreviewSnapshot")
    $btnRestoreSnapshot = $window.FindName("BtnRestoreSnapshot")
    $txtRestoreStatus = $window.FindName("TxtRestoreStatus")

    # Header & Stage 1/2 Actions
    $btnHeaderReinstallApps = $window.FindName("BtnHeaderReinstallApps")
    $btnImportProfile = $window.FindName("BtnImportProfile")
    $btnExportProfile = $window.FindName("BtnExportProfile")

    # App Reinstall Modal
    $modalReinstallApps = $window.FindName("ModalReinstallApps")
    $btnCloseReinstallModal = $window.FindName("BtnCloseReinstallModal")
    $btnCloseReinstallModalBottom = $window.FindName("BtnCloseReinstallModalBottom")
    $chkReinstallStore = $window.FindName("ChkReinstallStore")
    $chkReinstallCalculator = $window.FindName("ChkReinstallCalculator")
    $chkReinstallNotepad = $window.FindName("ChkReinstallNotepad")
    $chkReinstallPaint = $window.FindName("ChkReinstallPaint")
    $chkReinstallPhotos = $window.FindName("ChkReinstallPhotos")
    $chkReinstallTerminal = $window.FindName("ChkReinstallTerminal")
    $chkReinstallDryRun = $window.FindName("ChkReinstallDryRun")
    $btnExecuteReinstallApps = $window.FindName("BtnExecuteReinstallApps")
    $txtReinstallLog = $window.FindName("TxtReinstallLog")

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
        $txtVersion.Text = "v0.5"
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

    # 7. Preset Cards Click-to-Select Wiring (Stage 1)
    if ($cardPresetMinimal) {
        $cardPresetMinimal.Add_MouseDown({
            param([object]$eventSource, [System.Windows.Input.MouseButtonEventArgs]$eventArgs)
            if ($radioPresetMinimal) { $radioPresetMinimal.IsChecked = $true }
        })
    }
    if ($cardPresetDefault) {
        $cardPresetDefault.Add_MouseDown({
            param([object]$eventSource, [System.Windows.Input.MouseButtonEventArgs]$eventArgs)
            if ($radioPresetDefault) { $radioPresetDefault.IsChecked = $true }
        })
    }
    if ($cardPresetDeep) {
        $cardPresetDeep.Add_MouseDown({
            param([object]$eventSource, [System.Windows.Input.MouseButtonEventArgs]$eventArgs)
            if ($radioPresetDeep) { $radioPresetDeep.IsChecked = $true }
        })
    }

    # 8. State Management & Fluid Animation Engine
    $script:CurrentStage = 1
    $script:AppCheckboxes = [System.Collections.Generic.List[System.Windows.Controls.CheckBox]]::new()
    $script:AppMetadata = @{}
    $script:InstalledAppMap = $null

    # Helper to smoothly reveal a target view with cubic ease slide + fade
    $revealStage = {
        param([System.Windows.FrameworkElement]$target)
        if (-not $target) { return }
        $target.Visibility = [System.Windows.Visibility]::Visible
        $target.Opacity = 0.0

        $tt = $null
        if ($target.RenderTransform -is [System.Windows.Media.TransformGroup]) {
            foreach ($t in $target.RenderTransform.Children) {
                if ($t -is [System.Windows.Media.TranslateTransform]) { $tt = $t; break }
            }
        } elseif ($target.RenderTransform -is [System.Windows.Media.TranslateTransform]) {
            $tt = $target.RenderTransform
        }

        if (-not $tt) {
            $tt = [System.Windows.Media.TranslateTransform]::new()
            $target.RenderTransform = $tt
        }

        try {
            $duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(220))
            $fadeAnim = [System.Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, $duration)
            $slideAnim = [System.Windows.Media.Animation.DoubleAnimation]::new(12.0, 0.0, $duration)
            $ease = [System.Windows.Media.Animation.CubicEase]::new()
            $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
            $fadeAnim.EasingFunction = $ease
            $slideAnim.EasingFunction = $ease

            $target.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeAnim)
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $slideAnim)
        } catch {
            $target.Opacity = 1.0
            Write-Verbose "Animation suppressed: $($_.Exception.Message)"
        }
    }

    # Smooth 220ms CubicEase slide-fade animation on tab switching
    if ($tabStage2Controls) {
        $tabStage2Controls.Add_SelectionChanged({
            param([object]$eventSource, [System.Windows.Controls.SelectionChangedEventArgs]$eventArgs)
            if ($eventArgs.Source -ne $tabStage2Controls) { return }
            $selectedItem = $tabStage2Controls.SelectedItem
            if ($selectedItem -and $selectedItem.Content -and ($selectedItem.Content -is [System.Windows.FrameworkElement])) {
                $content = $selectedItem.Content
                $tt = $null
                if ($content.RenderTransform -is [System.Windows.Media.TransformGroup]) {
                    foreach ($t in $content.RenderTransform.Children) {
                        if ($t -is [System.Windows.Media.TranslateTransform]) { $tt = $t; break }
                    }
                } elseif ($content.RenderTransform -is [System.Windows.Media.TranslateTransform]) {
                    $tt = $content.RenderTransform
                }
                if (-not $tt) {
                    $tt = [System.Windows.Media.TranslateTransform]::new()
                    $content.RenderTransform = $tt
                }
                try {
                    $duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(220))
                    $fadeAnim = [System.Windows.Media.Animation.DoubleAnimation]::new(0.3, 1.0, $duration)
                    $slideAnim = [System.Windows.Media.Animation.DoubleAnimation]::new(10.0, 0.0, $duration)
                    $ease = [System.Windows.Media.Animation.CubicEase]::new()
                    $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
                    $fadeAnim.EasingFunction = $ease
                    $slideAnim.EasingFunction = $ease

                    $content.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeAnim)
                    $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $slideAnim)
                } catch {
                    $content.Opacity = 1.0
                }
            }
        })
    }

    $getSnapshotFromItem = {
        param($item)
        if ($null -eq $item) { return $null }
        if ($item -is [System.Windows.Controls.ComboBoxItem]) {
            return $item.Tag
        }
        return $item
    }

    # Function to update stage views
    $refreshSnapshotsList = {
        if ($cboRegistrySnapshots) {
            $cboRegistrySnapshots.Items.Clear()
            $backups = Get-DebloatBackup
            if ($backups.Count -eq 0) {
                $noItem = [System.Windows.Controls.ComboBoxItem]::new()
                $noItem.Content = "No registry snapshots found"
                $noItem.Tag = $null
                $noItem.IsEnabled = $false
                $noItem.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
                $null = $cboRegistrySnapshots.Items.Add($noItem)
                $cboRegistrySnapshots.SelectedIndex = 0
                if ($btnRestoreSnapshot) { $btnRestoreSnapshot.IsEnabled = $false }
                if ($btnPreviewSnapshot) { $btnPreviewSnapshot.IsEnabled = $false }
            } else {
                foreach ($b in $backups) {
                    $cboItem = [System.Windows.Controls.ComboBoxItem]::new()
                    $cboItem.Content = "$($b.LastModified) — $($b.FileName) ($($b.SizeKb) KB)"
                    $cboItem.Tag = $b
                    $null = $cboRegistrySnapshots.Items.Add($cboItem)
                }
                $cboRegistrySnapshots.SelectedIndex = 0
                if ($btnRestoreSnapshot) { $btnRestoreSnapshot.IsEnabled = $true }
                if ($btnPreviewSnapshot) { $btnPreviewSnapshot.IsEnabled = $true }
            }
        }
    }

    $updateStageView = {
        param([int]$stage)
        $script:CurrentStage = $stage

        # Hide all stages
        $viewStage1.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage2.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage3.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage4.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage5.Visibility = [System.Windows.Visibility]::Collapsed

        # Stepper highlights
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
                & $updateLiveImpactSummary
            }
            3 {
                & $revealStage $viewStage3
                $stepTag3.Foreground = $stepColorActive; $stepTag3.FontWeight = [System.Windows.FontWeights]::Bold
                $btnBack.Visibility = [System.Windows.Visibility]::Visible
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Visible
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
                & $updateLiveImpactSummary
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
                & $refreshSnapshotsList
            }
        }
    }

    # 9. Dynamic Selection Counters & Live Safety/Impact Evaluator
    $updateLiveImpactSummary = {
        # 1. Count selected and visible apps
        $visibleCount = 0
        $selectedAppCount = 0
        foreach ($cb in $script:AppCheckboxes) {
            if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) {
                $visibleCount++
                if ($cb.IsChecked) { $selectedAppCount++ }
            }
        }

        if ($txtAppsSummary) {
            $txtAppsSummary.Text = "Showing $visibleCount apps ($selectedAppCount selected for removal)"
        }
        if ($txtTabAppsCount) {
            $txtTabAppsCount.Text = "$selectedAppCount"
        }

        # 2. Count per-tab tweak selections
        $privChecked = 0
        @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $privChecked++ } }
        if ($txtTabPrivacyCount) { $txtTabPrivacyCount.Text = "$privChecked/5" }

        $shellChecked = 0
        @($chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkHideGalleryNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking, $chkSnapFlyout) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $shellChecked++ } }
        if ($txtTabShellCount) { $txtTabShellCount.Text = "$shellChecked/15" }

        $gamingChecked = 0
        @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks, $chkTelemetryService, $chkHibernation) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $gamingChecked++ } }
        if ($txtTabGamingCount) { $txtTabGamingCount.Text = "$gamingChecked/6" }

        $extrasChecked = 0
        @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkFastStartup, $chkStorageSense, $chkPreventAutoReboot, $chkExcludeDrivers, $chkSettingsHome) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $extrasChecked++ } }
        if ($txtTabExtrasCount) { $txtTabExtrasCount.Text = "$extrasChecked/9" }

        $aiChecked = 0
        @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $aiChecked++ } }
        if ($txtTabAICount) { $txtTabAICount.Text = "$aiChecked/6" }

        $featuresChecked = 0
        @($chkWindowsSandbox, $chkWSL) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $featuresChecked++ } }
        if ($txtTabFeaturesCount) { $txtTabFeaturesCount.Text = "$featuresChecked/2" }

        # 3. Build TweakFlags hashtable for evaluation
        $tweakFlags = @{
            Telemetry           = [bool]($chkTelemetry -and $chkTelemetry.IsChecked)
            BingSearch          = [bool]($chkBingSearch -and $chkBingSearch.IsChecked)
            AdvertisingId       = [bool]($chkAdvertisingId -and $chkAdvertisingId.IsChecked)
            ActivityHistory     = [bool]($chkActivityHistory -and $chkActivityHistory.IsChecked)
            TailoredExp         = [bool]($chkTailoredExp -and $chkTailoredExp.IsChecked)
            ShowExt             = [bool]($chkShowExt -and $chkShowExt.IsChecked)
            ShowHidden          = [bool]($chkShowHidden -and $chkShowHidden.IsChecked)
            ExplorerThisPC      = [bool]($chkLaunchToThisPC -and $chkLaunchToThisPC.IsChecked)
            LaunchToThisPC      = [bool]($chkLaunchToThisPC -and $chkLaunchToThisPC.IsChecked)
            ClassicContextMenu  = [bool]($chkClassicContextMenu -and $chkClassicContextMenu.IsChecked)
            HideWidgets         = [bool]($chkHideWidgets -and $chkHideWidgets.IsChecked)
            HideChat            = [bool]($chkHideChat -and $chkHideChat.IsChecked)
            EndTask             = [bool]($chkEndTask -and $chkEndTask.IsChecked)
            AlignLeft           = [bool]($chkAlignLeft -and $chkAlignLeft.IsChecked)
            HideOneDriveNav     = [bool]($chkHideOneDriveNav -and $chkHideOneDriveNav.IsChecked)
            HideGalleryNav      = [bool]($chkHideGalleryNav -and $chkHideGalleryNav.IsChecked)
            SearchHighlights    = [bool]($chkSearchHighlights -and $chkSearchHighlights.IsChecked)
            StartRecommended    = [bool]($chkStartRecommended -and $chkStartRecommended.IsChecked)
            CompactExplorer     = [bool]($chkCompactExplorer -and $chkCompactExplorer.IsChecked)
            Multitasking        = [bool]($chkMultitasking -and $chkMultitasking.IsChecked)
            SnapFlyout          = [bool]($chkSnapFlyout -and $chkSnapFlyout.IsChecked)
            GameDVR             = [bool]($chkGameDVR -and $chkGameDVR.IsChecked)
            DeliveryOpt         = [bool]($chkDeliveryOpt -and $chkDeliveryOpt.IsChecked)
            EdgeBackground      = [bool]($chkEdgeBackground -and $chkEdgeBackground.IsChecked)
            ScheduledTasks      = [bool]($chkScheduledTasks -and $chkScheduledTasks.IsChecked)
            TelemetryService    = [bool]($chkTelemetryService -and $chkTelemetryService.IsChecked)
            Hibernation         = [bool]($chkHibernation -and $chkHibernation.IsChecked)
            ConsumerFeatures    = [bool]($chkConsumerFeatures -and $chkConsumerFeatures.IsChecked)
            LockScreenAds       = [bool]($chkLockScreenAds -and $chkLockScreenAds.IsChecked)
            MousePrecision      = [bool]($chkMousePrecision -and $chkMousePrecision.IsChecked)
            StickyKeys          = [bool]($chkStickyKeys -and $chkStickyKeys.IsChecked)
            FastStartup         = [bool]($chkFastStartup -and $chkFastStartup.IsChecked)
            StorageSense        = [bool]($chkStorageSense -and $chkStorageSense.IsChecked)
            PreventAutoReboot   = [bool]($chkPreventAutoReboot -and $chkPreventAutoReboot.IsChecked)
            ExcludeDrivers      = [bool]($chkExcludeDrivers -and $chkExcludeDrivers.IsChecked)
            SettingsHome        = [bool]($chkSettingsHome -and $chkSettingsHome.IsChecked)
            CopilotPolicy       = [bool]($chkCopilotPolicy -and $chkCopilotPolicy.IsChecked)
            CopilotAppx         = [bool]($chkCopilotAppx -and $chkCopilotAppx.IsChecked)
            RecallAI            = [bool]($chkRecallAI -and $chkRecallAI.IsChecked)
            EdgeAI              = [bool]($chkEdgeAI -and $chkEdgeAI.IsChecked)
            PaintAI             = [bool]($chkPaintAI -and $chkPaintAI.IsChecked)
            NotepadAI           = [bool]($chkNotepadAI -and $chkNotepadAI.IsChecked)
            WindowsSandbox      = [bool]($chkWindowsSandbox -and $chkWindowsSandbox.IsChecked)
            WSL                 = [bool]($chkWSL -and $chkWSL.IsChecked)
        }

        # 4. Compute Safety & Impact via pure engine function
        $impact = Get-DebloatSafetyImpact -AppCount $selectedAppCount -TweakFlags $tweakFlags

        # 5. Update UI Controls
        if ($txtGlobalSelectionSummary) {
            $txtGlobalSelectionSummary.Text = "$selectedAppCount Apps • $($impact.TweakCount) Tweaks selected"
        }

        $brushConv = [System.Windows.Media.BrushConverter]::new()
        $bgBrush = $brushConv.ConvertFromString($impact.BgColor)
        $borderBrush = $brushConv.ConvertFromString($impact.BorderColor)
        $fgBrush = $brushConv.ConvertFromString($impact.FgColor)

        if ($badgeLiveImpact) {
            $badgeLiveImpact.Background = $bgBrush
            $badgeLiveImpact.BorderBrush = $borderBrush
        }
        if ($txtLiveImpact) {
            $txtLiveImpact.Text = $impact.BadgeText
            $txtLiveImpact.Foreground = $fgBrush
        }
        if ($iconLiveImpact) {
            $iconLiveImpact.Data = $window.Resources[$impact.IconKey]
            $iconLiveImpact.Fill = $fgBrush
        }

        # Stage 3 Updates
        if ($txtStage3Summary) {
            $txtStage3Summary.Text = "$selectedAppCount Bloatware Apps • $($impact.TweakCount) System Tweaks Queued ($($impact.TotalCount) Operations)"
        }
        if ($badgeStage3Impact) {
            $badgeStage3Impact.Background = $bgBrush
            $badgeStage3Impact.BorderBrush = $borderBrush
        }
        if ($txtStage3Impact) {
            $txtStage3Impact.Text = "SAFETY RATING: $($impact.BadgeText)"
            $txtStage3Impact.Foreground = $fgBrush
        }
        if ($iconStage3Impact) {
            $iconStage3Impact.Data = $window.Resources[$impact.IconKey]
            $iconStage3Impact.Fill = $fgBrush
        }
    }

    # 10. Dynamic App Search & Installed Filter Engine
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

        & $updateLiveImpactSummary
    }

    # 11. Multi-Category Aggregation Engine for Bloatware Apps
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
        $catHeader = if ($selectedCatNames.Count -eq 0) {
            "Categories: None Selected (0 Apps)"
        } elseif ($selectedCatNames.Count -eq 6) {
            "Categories: All Selected ($($appMap.Count) Apps)"
        } else {
            "Categories: $($selectedCatNames -join ', ') ($($appMap.Count) Apps)"
        }

        if ($txtToggleAppCategoriesText) {
            $txtToggleAppCategoriesText.Text = $catHeader
        } elseif ($toggleAppCategories) {
            $toggleAppCategories.Content = "$catHeader ▼"
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
                & $updateLiveImpactSummary
            })
            $cb.Add_Unchecked({
                param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
                & $updateLiveImpactSummary
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
            & $updateLiveImpactSummary
        })
    }

    if ($btnDeselectAllApps) {
        $btnDeselectAllApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($cb in $script:AppCheckboxes) {
                if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = $false }
            }
            & $updateLiveImpactSummary
        })
    }

    if ($btnInvertSelection) {
        $btnInvertSelection.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            foreach ($cb in $script:AppCheckboxes) {
                if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = -not $cb.IsChecked }
            }
            & $updateLiveImpactSummary
        })
    }

    # 12. Wire All Tweak Checkboxes to Live Impact & Counter Evaluator
    $allTweakCheckboxes = @(
        $chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp,
        $chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkHideGalleryNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking, $chkSnapFlyout,
        $chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks, $chkTelemetryService, $chkHibernation,
        $chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkFastStartup, $chkStorageSense, $chkPreventAutoReboot, $chkExcludeDrivers, $chkSettingsHome,
        $chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI,
        $chkWindowsSandbox, $chkWSL
    )
    foreach ($chk in $allTweakCheckboxes) {
        if ($chk) {
            $chk.Add_Click({
                param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
                & $updateLiveImpactSummary
            })
        }
    }

    # Tab 2: Privacy Dropdown & Batch Selection Wiring
    $updatePrivacyDropdownHeader = {
        $sel = [System.Collections.Generic.List[string]]::new()
        if ($chkPrivTelemetry -and $chkPrivTelemetry.IsChecked) { $sel.Add("Telemetry") }
        if ($chkPrivSearch -and $chkPrivSearch.IsChecked) { $sel.Add("Search") }
        if ($chkPrivActivity -and $chkPrivActivity.IsChecked) { $sel.Add("Activity") }
        if ($chkPrivAds -and $chkPrivAds.IsChecked) { $sel.Add("Ads") }

        $hdr = if ($sel.Count -eq 0) {
            "Presets: None Selected (0/4)"
        } elseif ($sel.Count -eq 4) {
            "Presets: All Selected (4/4)"
        } else {
            "Presets: $($sel -join ', ') ($($sel.Count)/4)"
        }
        if ($txtTogglePrivacyText) { $txtTogglePrivacyText.Text = $hdr }
    }

    $syncPrivacyDropdownFromTweaks = {
        if ($chkPrivTelemetry) { $chkPrivTelemetry.IsChecked = [bool]($chkTelemetry -and $chkTelemetry.IsChecked) }
        if ($chkPrivSearch) { $chkPrivSearch.IsChecked = [bool]($chkBingSearch -and $chkBingSearch.IsChecked) }
        if ($chkPrivActivity) { $chkPrivActivity.IsChecked = [bool]($chkActivityHistory -and $chkActivityHistory.IsChecked) }
        if ($chkPrivAds) { $chkPrivAds.IsChecked = [bool]($chkAdvertisingId -and $chkAdvertisingId.IsChecked -and $chkTailoredExp -and $chkTailoredExp.IsChecked) }
        & $updatePrivacyDropdownHeader
    }

    if ($chkPrivTelemetry) {
        $chkPrivTelemetry.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkTelemetry) { $chkTelemetry.IsChecked = [bool]$chkPrivTelemetry.IsChecked }
            & $updateLiveImpactSummary
            & $updatePrivacyDropdownHeader
        })
    }
    if ($chkPrivSearch) {
        $chkPrivSearch.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkBingSearch) { $chkBingSearch.IsChecked = [bool]$chkPrivSearch.IsChecked }
            & $updateLiveImpactSummary
            & $updatePrivacyDropdownHeader
        })
    }
    if ($chkPrivActivity) {
        $chkPrivActivity.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkActivityHistory) { $chkActivityHistory.IsChecked = [bool]$chkPrivActivity.IsChecked }
            & $updateLiveImpactSummary
            & $updatePrivacyDropdownHeader
        })
    }
    if ($chkPrivAds) {
        $chkPrivAds.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkPrivAds.IsChecked
            if ($chkAdvertisingId) { $chkAdvertisingId.IsChecked = $st }
            if ($chkTailoredExp) { $chkTailoredExp.IsChecked = $st }
            & $updateLiveImpactSummary
            & $updatePrivacyDropdownHeader
        })
    }
    if ($btnPrivSelectAll) {
        $btnPrivSelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkPrivTelemetry, $chkPrivSearch, $chkPrivActivity, $chkPrivAds) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateLiveImpactSummary
            & $updatePrivacyDropdownHeader
        })
    }
    if ($btnPrivClear) {
        $btnPrivClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkPrivTelemetry, $chkPrivSearch, $chkPrivActivity, $chkPrivAds) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateLiveImpactSummary
            & $updatePrivacyDropdownHeader
        })
    }
    if ($btnSelectAllPrivacy) {
        $btnSelectAllPrivacy.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $syncPrivacyDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    if ($btnDeselectAllPrivacy) {
        $btnDeselectAllPrivacy.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $syncPrivacyDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    @($chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp) | ForEach-Object {
        if ($_) { $_.Add_Click({ & $syncPrivacyDropdownFromTweaks }) }
    }

    # Tab 3: UI & Shell Dropdown & Batch Selection Wiring
    $updateShellDropdownHeader = {
        $sel = [System.Collections.Generic.List[string]]::new()
        if ($chkShellClean -and $chkShellClean.IsChecked) { $sel.Add("Clean UI") }
        if ($chkShellPowerUser -and $chkShellPowerUser.IsChecked) { $sel.Add("Power-User") }
        if ($chkShellTaskbar -and $chkShellTaskbar.IsChecked) { $sel.Add("Taskbar/Snap") }

        $hdr = if ($sel.Count -eq 0) {
            "Presets: None Selected (0/3)"
        } elseif ($sel.Count -eq 3) {
            "Presets: All Selected (3/3)"
        } else {
            "Presets: $($sel -join ', ') ($($sel.Count)/3)"
        }
        if ($txtToggleShellText) { $txtToggleShellText.Text = $hdr }
    }

    $syncShellDropdownFromTweaks = {
        if ($chkShellClean) {
            $chkShellClean.IsChecked = [bool]($chkHideWidgets.IsChecked -and $chkHideChat.IsChecked -and $chkStartRecommended.IsChecked -and $chkSearchHighlights.IsChecked)
        }
        if ($chkShellPowerUser) {
            $chkShellPowerUser.IsChecked = [bool]($chkShowExt.IsChecked -and $chkShowHidden.IsChecked -and $chkLaunchToThisPC.IsChecked -and $chkClassicContextMenu.IsChecked)
        }
        if ($chkShellTaskbar) {
            $chkShellTaskbar.IsChecked = [bool]($chkAlignLeft.IsChecked -and $chkMultitasking.IsChecked -and $chkSnapFlyout.IsChecked)
        }
        & $updateShellDropdownHeader
    }

    if ($chkShellClean) {
        $chkShellClean.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkShellClean.IsChecked
            @($chkHideWidgets, $chkHideChat, $chkStartRecommended, $chkSearchHighlights, $chkHideOneDriveNav, $chkHideGalleryNav) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateShellDropdownHeader
        })
    }
    if ($chkShellPowerUser) {
        $chkShellPowerUser.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkShellPowerUser.IsChecked
            @($chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkEndTask, $chkCompactExplorer) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateShellDropdownHeader
        })
    }
    if ($chkShellTaskbar) {
        $chkShellTaskbar.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkShellTaskbar.IsChecked
            @($chkAlignLeft, $chkMultitasking, $chkSnapFlyout) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateShellDropdownHeader
        })
    }
    if ($btnShellSelectAll) {
        $btnShellSelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkShellClean, $chkShellPowerUser, $chkShellTaskbar) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            @($chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkHideGalleryNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking, $chkSnapFlyout) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateLiveImpactSummary
            & $updateShellDropdownHeader
        })
    }
    if ($btnShellClear) {
        $btnShellClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkShellClean, $chkShellPowerUser, $chkShellTaskbar) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            @($chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkHideGalleryNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking, $chkSnapFlyout) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateLiveImpactSummary
            & $updateShellDropdownHeader
        })
    }
    if ($btnSelectAllShell) {
        $btnSelectAllShell.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkHideGalleryNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking, $chkSnapFlyout) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $syncShellDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    if ($btnDeselectAllShell) {
        $btnDeselectAllShell.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkHideGalleryNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking, $chkSnapFlyout) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $syncShellDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    @($chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkHideGalleryNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking, $chkSnapFlyout) | ForEach-Object {
        if ($_) { $_.Add_Click({ & $syncShellDropdownFromTweaks }) }
    }

    # Tab 4: Gaming & Performance Dropdown & Batch Selection Wiring
    $updateGamingDropdownHeader = {
        $sel = [System.Collections.Generic.List[string]]::new()
        if ($chkGamingDVR -and $chkGamingDVR.IsChecked) { $sel.Add("Game DVR") }
        if ($chkGamingBackground -and $chkGamingBackground.IsChecked) { $sel.Add("Background") }
        if ($chkGamingOptimization -and $chkGamingOptimization.IsChecked) { $sel.Add("Services/Tasks") }
        if ($chkGamingStorage -and $chkGamingStorage.IsChecked) { $sel.Add("Storage") }

        $hdr = if ($sel.Count -eq 0) {
            "Presets: None Selected (0/4)"
        } elseif ($sel.Count -eq 4) {
            "Presets: All Selected (4/4)"
        } else {
            "Presets: $($sel -join ', ') ($($sel.Count)/4)"
        }
        if ($txtToggleGamingText) { $txtToggleGamingText.Text = $hdr }
    }

    $syncGamingDropdownFromTweaks = {
        if ($chkGamingDVR) { $chkGamingDVR.IsChecked = [bool]($chkGameDVR -and $chkGameDVR.IsChecked) }
        if ($chkGamingBackground) { $chkGamingBackground.IsChecked = [bool]($chkDeliveryOpt.IsChecked -and $chkEdgeBackground.IsChecked) }
        if ($chkGamingOptimization) { $chkGamingOptimization.IsChecked = [bool]($chkScheduledTasks.IsChecked -and $chkTelemetryService.IsChecked) }
        if ($chkGamingStorage) { $chkGamingStorage.IsChecked = [bool]($chkHibernation -and $chkHibernation.IsChecked) }
        & $updateGamingDropdownHeader
    }

    if ($chkGamingDVR) {
        $chkGamingDVR.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkGameDVR) { $chkGameDVR.IsChecked = [bool]$chkGamingDVR.IsChecked }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($chkGamingBackground) {
        $chkGamingBackground.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkGamingBackground.IsChecked
            @($chkDeliveryOpt, $chkEdgeBackground) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($chkGamingOptimization) {
        $chkGamingOptimization.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkGamingOptimization.IsChecked
            @($chkScheduledTasks, $chkTelemetryService) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($chkGamingStorage) {
        $chkGamingStorage.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkHibernation) { $chkHibernation.IsChecked = [bool]$chkGamingStorage.IsChecked }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($btnGamingSelectAll) {
        $btnGamingSelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkGamingDVR, $chkGamingBackground, $chkGamingOptimization, $chkGamingStorage) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks, $chkTelemetryService, $chkHibernation) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($btnGamingClear) {
        $btnGamingClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkGamingDVR, $chkGamingBackground, $chkGamingOptimization, $chkGamingStorage) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks, $chkTelemetryService, $chkHibernation) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($btnSelectAllGaming) {
        $btnSelectAllGaming.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks, $chkTelemetryService, $chkHibernation) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $syncGamingDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    if ($btnDeselectAllGaming) {
        $btnDeselectAllGaming.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks, $chkTelemetryService, $chkHibernation) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $syncGamingDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks, $chkTelemetryService, $chkHibernation) | ForEach-Object {
        if ($_) { $_.Add_Click({ & $syncGamingDropdownFromTweaks }) }
    }

    # Tab 5: System Extras Dropdown & Batch Selection Wiring
    $updateExtrasDropdownHeader = {
        $sel = [System.Collections.Generic.List[string]]::new()
        if ($chkExtrasPromos -and $chkExtrasPromos.IsChecked) { $sel.Add("Promos") }
        if ($chkExtrasDesktop -and $chkExtrasDesktop.IsChecked) { $sel.Add("Desktop") }
        if ($chkExtrasAccessibility -and $chkExtrasAccessibility.IsChecked) { $sel.Add("Accessibility") }
        if ($chkExtrasPower -and $chkExtrasPower.IsChecked) { $sel.Add("Power/Updates") }

        $hdr = if ($sel.Count -eq 0) {
            "Presets: None Selected (0/4)"
        } elseif ($sel.Count -eq 4) {
            "Presets: All Selected (4/4)"
        } else {
            "Presets: $($sel -join ', ') ($($sel.Count)/4)"
        }
        if ($txtToggleExtrasText) { $txtToggleExtrasText.Text = $hdr }
    }

    $syncExtrasDropdownFromTweaks = {
        if ($chkExtrasPromos) { $chkExtrasPromos.IsChecked = [bool]($chkConsumerFeatures.IsChecked -and $chkLockScreenAds.IsChecked -and $chkSettingsHome.IsChecked) }
        if ($chkExtrasDesktop) { $chkExtrasDesktop.IsChecked = [bool]($chkMousePrecision.IsChecked -and $chkStorageSense.IsChecked) }
        if ($chkExtrasAccessibility) { $chkExtrasAccessibility.IsChecked = [bool]($chkStickyKeys -and $chkStickyKeys.IsChecked) }
        if ($chkExtrasPower) { $chkExtrasPower.IsChecked = [bool]($chkFastStartup.IsChecked -and $chkPreventAutoReboot.IsChecked -and $chkExcludeDrivers.IsChecked) }
        & $updateExtrasDropdownHeader
    }

    if ($chkExtrasPromos) {
        $chkExtrasPromos.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkExtrasPromos.IsChecked
            @($chkConsumerFeatures, $chkLockScreenAds, $chkSettingsHome) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($chkExtrasDesktop) {
        $chkExtrasDesktop.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkExtrasDesktop.IsChecked
            @($chkMousePrecision, $chkStorageSense) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($chkExtrasAccessibility) {
        $chkExtrasAccessibility.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkStickyKeys) { $chkStickyKeys.IsChecked = [bool]$chkExtrasAccessibility.IsChecked }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($chkExtrasPower) {
        $chkExtrasPower.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkExtrasPower.IsChecked
            @($chkFastStartup, $chkPreventAutoReboot, $chkExcludeDrivers) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($btnExtrasSelectAll) {
        $btnExtrasSelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkExtrasPromos, $chkExtrasDesktop, $chkExtrasAccessibility, $chkExtrasPower) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkFastStartup, $chkStorageSense, $chkPreventAutoReboot, $chkExcludeDrivers, $chkSettingsHome) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($btnExtrasClear) {
        $btnExtrasClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkExtrasPromos, $chkExtrasDesktop, $chkExtrasAccessibility, $chkExtrasPower) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkFastStartup, $chkStorageSense, $chkPreventAutoReboot, $chkExcludeDrivers, $chkSettingsHome) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($btnSelectAllExtras) {
        $btnSelectAllExtras.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkFastStartup, $chkStorageSense, $chkPreventAutoReboot, $chkExcludeDrivers, $chkSettingsHome) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $syncExtrasDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    if ($btnDeselectAllExtras) {
        $btnDeselectAllExtras.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkFastStartup, $chkStorageSense, $chkPreventAutoReboot, $chkExcludeDrivers, $chkSettingsHome) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $syncExtrasDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkFastStartup, $chkStorageSense, $chkPreventAutoReboot, $chkExcludeDrivers, $chkSettingsHome) | ForEach-Object {
        if ($_) { $_.Add_Click({ & $syncExtrasDropdownFromTweaks }) }
    }

    # Tab 6: AI Integration Dropdown & Batch Selection Wiring
    $updateAIDropdownHeader = {
        $sel = [System.Collections.Generic.List[string]]::new()
        if ($chkAISystem -and $chkAISystem.IsChecked) { $sel.Add("System AI") }
        if ($chkAIEdge -and $chkAIEdge.IsChecked) { $sel.Add("Edge AI") }
        if ($chkAIApps -and $chkAIApps.IsChecked) { $sel.Add("Apps AI") }

        $hdr = if ($sel.Count -eq 0) {
            "Presets: None Selected (0/3)"
        } elseif ($sel.Count -eq 3) {
            "Presets: All Selected (3/3)"
        } else {
            "Presets: $($sel -join ', ') ($($sel.Count)/3)"
        }
        if ($txtToggleAIText) { $txtToggleAIText.Text = $hdr }
    }

    $syncAIDropdownFromTweaks = {
        if ($chkAISystem) { $chkAISystem.IsChecked = [bool]($chkCopilotPolicy.IsChecked -and $chkCopilotAppx.IsChecked -and $chkRecallAI.IsChecked) }
        if ($chkAIEdge) { $chkAIEdge.IsChecked = [bool]($chkEdgeAI -and $chkEdgeAI.IsChecked) }
        if ($chkAIApps) { $chkAIApps.IsChecked = [bool]($chkPaintAI.IsChecked -and $chkNotepadAI.IsChecked) }
        & $updateAIDropdownHeader
    }

    if ($chkAISystem) {
        $chkAISystem.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkAISystem.IsChecked
            @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateAIDropdownHeader
        })
    }
    if ($chkAIEdge) {
        $chkAIEdge.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkEdgeAI) { $chkEdgeAI.IsChecked = [bool]$chkAIEdge.IsChecked }
            & $updateLiveImpactSummary
            & $updateAIDropdownHeader
        })
    }
    if ($chkAIApps) {
        $chkAIApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $st = [bool]$chkAIApps.IsChecked
            @($chkPaintAI, $chkNotepadAI) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateAIDropdownHeader
        })
    }
    if ($btnAISelectAll) {
        $btnAISelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkAISystem, $chkAIEdge, $chkAIApps) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateLiveImpactSummary
            & $updateAIDropdownHeader
        })
    }
    if ($btnAIClear) {
        $btnAIClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkAISystem, $chkAIEdge, $chkAIApps) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateLiveImpactSummary
            & $updateAIDropdownHeader
        })
    }
    if ($btnSelectAllAI) {
        $btnSelectAllAI.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $syncAIDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    if ($btnDeselectAllAI) {
        $btnDeselectAllAI.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $syncAIDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI) | ForEach-Object {
        if ($_) { $_.Add_Click({ & $syncAIDropdownFromTweaks }) }
    }

    # Tab 7: Optional Features Dropdown & Batch Selection Wiring
    $updateFeaturesDropdownHeader = {
        $sel = [System.Collections.Generic.List[string]]::new()
        if ($chkFeatSandbox -and $chkFeatSandbox.IsChecked) { $sel.Add("Sandbox") }
        if ($chkFeatWSL -and $chkFeatWSL.IsChecked) { $sel.Add("WSL") }

        $hdr = if ($sel.Count -eq 0) {
            "Presets: None Selected (0/2)"
        } elseif ($sel.Count -eq 2) {
            "Presets: All Selected (2/2)"
        } else {
            "Presets: $($sel -join ', ') ($($sel.Count)/2)"
        }
        if ($txtToggleFeaturesText) { $txtToggleFeaturesText.Text = $hdr }
    }

    $syncFeaturesDropdownFromTweaks = {
        if ($chkFeatSandbox) { $chkFeatSandbox.IsChecked = [bool]($chkWindowsSandbox -and $chkWindowsSandbox.IsChecked) }
        if ($chkFeatWSL) { $chkFeatWSL.IsChecked = [bool]($chkWSL -and $chkWSL.IsChecked) }
        & $updateFeaturesDropdownHeader
    }

    if ($chkFeatSandbox) {
        $chkFeatSandbox.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkWindowsSandbox) { $chkWindowsSandbox.IsChecked = [bool]$chkFeatSandbox.IsChecked }
            & $updateLiveImpactSummary
            & $updateFeaturesDropdownHeader
        })
    }
    if ($chkFeatWSL) {
        $chkFeatWSL.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkWSL) { $chkWSL.IsChecked = [bool]$chkFeatWSL.IsChecked }
            & $updateLiveImpactSummary
            & $updateFeaturesDropdownHeader
        })
    }
    if ($btnFeatSelectAll) {
        $btnFeatSelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkFeatSandbox, $chkFeatWSL) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            @($chkWindowsSandbox, $chkWSL) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateLiveImpactSummary
            & $updateFeaturesDropdownHeader
        })
    }
    if ($btnFeatClear) {
        $btnFeatClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkFeatSandbox, $chkFeatWSL) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            @($chkWindowsSandbox, $chkWSL) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateLiveImpactSummary
            & $updateFeaturesDropdownHeader
        })
    }
    if ($btnSelectAllFeatures) {
        $btnSelectAllFeatures.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkWindowsSandbox) { $chkWindowsSandbox.IsChecked = $true }
            if ($chkWSL) { $chkWSL.IsChecked = $true }
            & $syncFeaturesDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    if ($btnDeselectAllFeatures) {
        $btnDeselectAllFeatures.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkWindowsSandbox) { $chkWindowsSandbox.IsChecked = $false }
            if ($chkWSL) { $chkWSL.IsChecked = $false }
            & $syncFeaturesDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    @($chkWindowsSandbox, $chkWSL) | ForEach-Object {
        if ($_) { $_.Add_Click({ & $syncFeaturesDropdownFromTweaks }) }
    }

    # Initialize all dropdown headers and states
    & $updatePrivacyDropdownHeader
    & $updateShellDropdownHeader
    & $updateGamingDropdownHeader
    & $updateExtrasDropdownHeader
    & $updateAIDropdownHeader
    & $updateFeaturesDropdownHeader

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
        if ($chkLaunchToThisPC -and $chkLaunchToThisPC.IsChecked) { $logBuilder.AppendLine("WhatIf: File Explorer set to open This PC.") | Out-Null }
        if ($chkClassicContextMenu -and $chkClassicContextMenu.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows 10 Classic Context Menu would be restored.") | Out-Null }
        if ($chkMultitasking -and $chkMultitasking.IsChecked) { $logBuilder.AppendLine("WhatIf: Snap Assist suggestions and Alt+Tab tab clutter would be disabled.") | Out-Null }
        if ($chkSnapFlyout -and $chkSnapFlyout.IsChecked) { $logBuilder.AppendLine("WhatIf: Snap Assist suggestions flyout would be disabled.") | Out-Null }
        if ($chkHideGalleryNav -and $chkHideGalleryNav.IsChecked) { $logBuilder.AppendLine("WhatIf: Gallery hidden from File Explorer navigation pane.") | Out-Null }
        if ($chkGameDVR -and $chkGameDVR.IsChecked) { $logBuilder.AppendLine("WhatIf: Game DVR background recording & Xbox Game Bar would be disabled.") | Out-Null }
        if ($chkDeliveryOpt -and $chkDeliveryOpt.IsChecked) { $logBuilder.AppendLine("WhatIf: Delivery Optimization P2P updates would be disabled.") | Out-Null }
        if ($chkEdgeBackground -and $chkEdgeBackground.IsChecked) { $logBuilder.AppendLine("WhatIf: Microsoft Edge background processes and Startup Boost would be disabled.") | Out-Null }
        if ($chkScheduledTasks -and $chkScheduledTasks.IsChecked) { $logBuilder.AppendLine("WhatIf: Telemetry scheduled tasks (Consolidator, Appraiser) would be disabled.") | Out-Null }
        if ($chkTelemetryService -and $chkTelemetryService.IsChecked) { $logBuilder.AppendLine("WhatIf: DiagTrack connected user experiences service would be disabled.") | Out-Null }
        if ($chkHibernation -and $chkHibernation.IsChecked) { $logBuilder.AppendLine("WhatIf: Hibernation storage would be reclaimed (powercfg /h off).") | Out-Null }
        if ($chkConsumerFeatures -and $chkConsumerFeatures.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows consumer features and promo preinstalls would be blocked.") | Out-Null }
        if ($chkSettingsHome -and $chkSettingsHome.IsChecked) { $logBuilder.AppendLine("WhatIf: Settings home page recommendations would be disabled.") | Out-Null }
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
            param(
                [string]$text,
                [string]$level = "INFO"
            )
            $txtLiveLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $text`r`n")
            $txtLiveLog.ScrollToEnd()
            [System.Windows.Forms.Application]::DoEvents()

            try {
                Write-DebloatLog -Message $text -Level $level -NoConsole
            } catch {
                # Fallback safeguard
            }
        }

        & $appendLog "Starting NH Win Debloater optimization pipeline..." "INFO"

        $targetScope = if ($radioScopeCurrentUser.IsChecked) { "CurrentUser" } elseif ($radioScopeDefaultUser.IsChecked) { "DefaultUser" } else { "AllUsers" }
        & $appendLog "Selected execution scope: $targetScope" "INFO"

        $totalOps = 0
        $successOps = 0
        $skippedOps = 0

        # 1. Restore Point
        if ($chkCreateRestorePoint.IsChecked) {
            & $appendLog "Creating Windows System Restore Point..." "INFO"
            $txtProgressStatus.Text = "Creating System Restore checkpoint..."
            $rp = New-DebloatRestorePoint -Description "NH Win Debloater Checkpoint"
            $totalOps++
            if ($rp.Status -eq "Success") { $successOps++; & $appendLog "System Restore Point created successfully." "SUCCESS" }
            else { $skippedOps++; & $appendLog "System Restore Point skipped/warning: $($rp.Message)" "WARN" }
        }
        $progExecution.Value = 20

        # 2. Registry Snapshot
        if ($chkRegistrySnapshot.IsChecked) {
            & $appendLog "Capturing pre-tweak registry snapshot..." "INFO"
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
            & $appendLog "Registry snapshot saved: $(Split-Path $snapFile -Leaf)" "SUCCESS"
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
        if ($chkLaunchToThisPC.IsChecked) { Set-ShellSetting -SettingId "ExplorerToThisPC" | Out-Null; $totalOps++; $successOps++; & $appendLog "File Explorer set to open This PC." }
        if ($chkClassicContextMenu.IsChecked) { Set-ClassicContextMenuTweak -EnableClassic $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Classic Windows 10 Context Menu restored." }
        if ($chkHideWidgets.IsChecked) { Set-ShellSetting -SettingId "HideWidgets" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar Widgets hidden." }
        if ($chkHideChat.IsChecked) { Set-ShellSetting -SettingId "HideChat" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar Chat hidden." }
        if ($chkEndTask.IsChecked) { Set-ShellSetting -SettingId "EnableEndTask" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar End Task enabled." }
        if ($chkAlignLeft.IsChecked) { Set-ShellSetting -SettingId "TaskbarAlignLeft" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar aligned to left." }
        if ($chkHideOneDriveNav.IsChecked) { Set-ShellSetting -SettingId "HideOneDriveNav" | Out-Null; $totalOps++; $successOps++; & $appendLog "OneDrive hidden from Explorer navigation pane." }
        if ($chkHideGalleryNav.IsChecked) { Set-ShellSetting -SettingId "HideGalleryNav" | Out-Null; $totalOps++; $successOps++; & $appendLog "Gallery hidden from Explorer navigation pane." }
        if ($chkSearchHighlights.IsChecked) { Set-ShellSetting -SettingId "HideSearchHighlights" | Out-Null; $totalOps++; $successOps++; & $appendLog "Taskbar search highlights disabled." }
        if ($chkStartRecommended.IsChecked) { Set-StartMenuRecommendedTweak -HideRecommended $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Start Menu Recommended clutter hidden." }
        if ($chkCompactExplorer.IsChecked) { Set-ShellSetting -SettingId "ShowCompactExplorer" | Out-Null; $totalOps++; $successOps++; & $appendLog "File Explorer compact view enabled." }
        if ($chkMultitasking.IsChecked) { Set-MultitaskingTweak -DisableSnapSuggestions $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Multitasking & Snap Assist suggestions disabled." }
        if ($chkSnapFlyout.IsChecked) { Set-ShellSetting -SettingId "DisableSnapFlyout" | Out-Null; $totalOps++; $successOps++; & $appendLog "Snap Assist suggestions flyout disabled." }
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
        if ($chkSettingsHome.IsChecked) { Set-SettingsHomeTweak -DisableHomeRecommendations $true | Out-Null; $totalOps++; $successOps++; & $appendLog "Settings home page recommendations disabled." }
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
            & $appendLog "Removing $($appsToRemove.Count) selected bloatware packages (Scope: $targetScope)..." "INFO"
            $txtProgressStatus.Text = "Removing selected packages..."
            $remResults = Remove-DebloatApp -AppIdList $appsToRemove.ToArray() -TargetScope $targetScope -PresetsPath $presetsPath
            foreach ($res in $remResults) {
                $totalOps++
                if ($res.Status -eq "Success" -or $res.Status -eq "Warning") {
                    $successOps++
                    & $appendLog "Removed package: $($res.AppId)" "SUCCESS"
                } elseif ($res.Status -eq "SkippedProtected") {
                    $skippedOps++
                    & $appendLog "Protected package skipped: $($res.AppId)" "WARN"
                } else {
                    $skippedOps++
                    & $appendLog "Package not found on system: $($res.AppId)" "INFO"
                }
            }
        }
        $progExecution.Value = 100

        & $appendLog "Pipeline execution finished successfully." "SUCCESS"
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

    # Custom Preset Profile: Export
    if ($btnExportProfile) {
        $btnExportProfile.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)

            $selectedApps = [System.Collections.Generic.List[string]]::new()
            foreach ($cb in $script:AppCheckboxes) {
                if ($cb.IsChecked) {
                    $selectedApps.Add([string]$cb.Tag)
                }
            }

            $selectedTweaks = @{
                Telemetry           = [bool]($chkTelemetry -and $chkTelemetry.IsChecked)
                BingSearch          = [bool]($chkBingSearch -and $chkBingSearch.IsChecked)
                AdvertisingId       = [bool]($chkAdvertisingId -and $chkAdvertisingId.IsChecked)
                ActivityHistory     = [bool]($chkActivityHistory -and $chkActivityHistory.IsChecked)
                TailoredExp         = [bool]($chkTailoredExp -and $chkTailoredExp.IsChecked)
                ShowExt             = [bool]($chkShowExt -and $chkShowExt.IsChecked)
                ShowHidden          = [bool]($chkShowHidden -and $chkShowHidden.IsChecked)
                ExplorerThisPC      = [bool]($chkLaunchToThisPC -and $chkLaunchToThisPC.IsChecked)
                LaunchToThisPC      = [bool]($chkLaunchToThisPC -and $chkLaunchToThisPC.IsChecked)
                ClassicContextMenu  = [bool]($chkClassicContextMenu -and $chkClassicContextMenu.IsChecked)
                HideWidgets         = [bool]($chkHideWidgets -and $chkHideWidgets.IsChecked)
                HideChat            = [bool]($chkHideChat -and $chkHideChat.IsChecked)
                EnableEndTask       = [bool]($chkEndTask -and $chkEndTask.IsChecked)
                AlignLeft           = [bool]($chkAlignLeft -and $chkAlignLeft.IsChecked)
                HideOneDriveNav     = [bool]($chkHideOneDriveNav -and $chkHideOneDriveNav.IsChecked)
                HideGalleryNav      = [bool]($chkHideGalleryNav -and $chkHideGalleryNav.IsChecked)
                SearchHighlights    = [bool]($chkSearchHighlights -and $chkSearchHighlights.IsChecked)
                StartRecommended    = [bool]($chkStartRecommended -and $chkStartRecommended.IsChecked)
                CompactExplorer     = [bool]($chkCompactExplorer -and $chkCompactExplorer.IsChecked)
                Multitasking        = [bool]($chkMultitasking -and $chkMultitasking.IsChecked)
                SnapFlyout          = [bool]($chkSnapFlyout -and $chkSnapFlyout.IsChecked)
                GameDVR             = [bool]($chkGameDVR -and $chkGameDVR.IsChecked)
                DeliveryOpt         = [bool]($chkDeliveryOpt -and $chkDeliveryOpt.IsChecked)
                EdgeBackground      = [bool]($chkEdgeBackground -and $chkEdgeBackground.IsChecked)
                ScheduledTasks      = [bool]($chkScheduledTasks -and $chkScheduledTasks.IsChecked)
                TelemetryService    = [bool]($chkTelemetryService -and $chkTelemetryService.IsChecked)
                Hibernation         = [bool]($chkHibernation -and $chkHibernation.IsChecked)
                ConsumerFeatures    = [bool]($chkConsumerFeatures -and $chkConsumerFeatures.IsChecked)
                LockScreenAds       = [bool]($chkLockScreenAds -and $chkLockScreenAds.IsChecked)
                MousePrecision      = [bool]($chkMousePrecision -and $chkMousePrecision.IsChecked)
                StickyKeys          = [bool]($chkStickyKeys -and $chkStickyKeys.IsChecked)
                FastStartup         = [bool]($chkFastStartup -and $chkFastStartup.IsChecked)
                StorageSense        = [bool]($chkStorageSense -and $chkStorageSense.IsChecked)
                PreventAutoReboot   = [bool]($chkPreventAutoReboot -and $chkPreventAutoReboot.IsChecked)
                ExcludeDrivers      = [bool]($chkExcludeDrivers -and $chkExcludeDrivers.IsChecked)
                SettingsHome        = [bool]($chkSettingsHome -and $chkSettingsHome.IsChecked)
                CopilotPolicy       = [bool]($chkCopilotPolicy -and $chkCopilotPolicy.IsChecked)
                CopilotAppx         = [bool]($chkCopilotAppx -and $chkCopilotAppx.IsChecked)
                RecallAI            = [bool]($chkRecallAI -and $chkRecallAI.IsChecked)
                EdgeAI              = [bool]($chkEdgeAI -and $chkEdgeAI.IsChecked)
                PaintAI             = [bool]($chkPaintAI -and $chkPaintAI.IsChecked)
                NotepadAI           = [bool]($chkNotepadAI -and $chkNotepadAI.IsChecked)
                WindowsSandbox      = [bool]($chkWindowsSandbox -and $chkWindowsSandbox.IsChecked)
                WSL                 = [bool]($chkWSL -and $chkWSL.IsChecked)
            }

            $sfd = [Microsoft.Win32.SaveFileDialog]::new()
            $sfd.Filter = "Debloat Preset Profile (*.json)|*.json"
            $sfd.FileName = "NHWinDebloater_CustomPreset.json"
            $sfd.Title = "Export Custom Debloat Preset Profile"

            if ($sfd.ShowDialog() -eq $true) {
                try {
                    Export-DebloatProfile -FilePath $sfd.FileName -ProfileName "Custom Preset Profile" -SelectedApps $selectedApps.ToArray() -SelectedTweaks $selectedTweaks -AppVersion $script:AppVersion | Out-Null
                    [System.Windows.MessageBox]::Show("Preset profile exported successfully to:`n$($sfd.FileName)", "NH Win Debloater", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                } catch {
                    [System.Windows.MessageBox]::Show("Failed to export preset profile:`n$($_.Exception.Message)", "Export Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
                }
            }
        })
    }

    # Custom Preset Profile: Import
    if ($btnImportProfile) {
        $btnImportProfile.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)

            $ofd = [Microsoft.Win32.OpenFileDialog]::new()
            $ofd.Filter = "Debloat Preset Profile (*.json)|*.json|All Files (*.*)|*.*"
            $ofd.Title = "Import Custom Debloat Preset Profile"

            if ($ofd.ShowDialog() -eq $true) {
                try {
                    $imported = Import-DebloatProfile -FilePath $ofd.FileName

                    # Update Apps Checkboxes
                    $appLookup = @{}
                    foreach ($app in $imported.SelectedApps) {
                        $appLookup[$app] = $true
                    }
                    foreach ($cb in $script:AppCheckboxes) {
                        $appId = [string]$cb.Tag
                        $cb.IsChecked = ($null -ne $appLookup[$appId])
                    }

                    # Update Tweaks Checkboxes
                    $t = $imported.SelectedTweaks
                    if ($t) {
                        if ($chkTelemetry -and $t.ContainsKey("Telemetry")) { $chkTelemetry.IsChecked = [bool]$t["Telemetry"] }
                        if ($chkBingSearch -and $t.ContainsKey("BingSearch")) { $chkBingSearch.IsChecked = [bool]$t["BingSearch"] }
                        if ($chkAdvertisingId -and $t.ContainsKey("AdvertisingId")) { $chkAdvertisingId.IsChecked = [bool]$t["AdvertisingId"] }
                        if ($chkActivityHistory -and $t.ContainsKey("ActivityHistory")) { $chkActivityHistory.IsChecked = [bool]$t["ActivityHistory"] }
                        if ($chkTailoredExp -and $t.ContainsKey("TailoredExp")) { $chkTailoredExp.IsChecked = [bool]$t["TailoredExp"] }
                        if ($chkShowExt -and $t.ContainsKey("ShowExt")) { $chkShowExt.IsChecked = [bool]$t["ShowExt"] }
                        if ($chkShowHidden -and $t.ContainsKey("ShowHidden")) { $chkShowHidden.IsChecked = [bool]$t["ShowHidden"] }
                        if ($chkLaunchToThisPC -and $t.ContainsKey("LaunchToThisPC")) { $chkLaunchToThisPC.IsChecked = [bool]$t["LaunchToThisPC"] }
                        elseif ($chkLaunchToThisPC -and $t.ContainsKey("ExplorerThisPC")) { $chkLaunchToThisPC.IsChecked = [bool]$t["ExplorerThisPC"] }
                        if ($chkClassicContextMenu -and $t.ContainsKey("ClassicContextMenu")) { $chkClassicContextMenu.IsChecked = [bool]$t["ClassicContextMenu"] }
                        if ($chkHideWidgets -and $t.ContainsKey("HideWidgets")) { $chkHideWidgets.IsChecked = [bool]$t["HideWidgets"] }
                        if ($chkHideChat -and $t.ContainsKey("HideChat")) { $chkHideChat.IsChecked = [bool]$t["HideChat"] }
                        if ($chkEndTask -and $t.ContainsKey("EnableEndTask")) { $chkEndTask.IsChecked = [bool]$t["EnableEndTask"] }
                        if ($chkAlignLeft -and $t.ContainsKey("AlignLeft")) { $chkAlignLeft.IsChecked = [bool]$t["AlignLeft"] }
                        if ($chkHideOneDriveNav -and $t.ContainsKey("HideOneDriveNav")) { $chkHideOneDriveNav.IsChecked = [bool]$t["HideOneDriveNav"] }
                        if ($chkHideGalleryNav -and $t.ContainsKey("HideGalleryNav")) { $chkHideGalleryNav.IsChecked = [bool]$t["HideGalleryNav"] }
                        if ($chkSearchHighlights -and $t.ContainsKey("SearchHighlights")) { $chkSearchHighlights.IsChecked = [bool]$t["SearchHighlights"] }
                        if ($chkStartRecommended -and $t.ContainsKey("StartRecommended")) { $chkStartRecommended.IsChecked = [bool]$t["StartRecommended"] }
                        if ($chkCompactExplorer -and $t.ContainsKey("CompactExplorer")) { $chkCompactExplorer.IsChecked = [bool]$t["CompactExplorer"] }
                        if ($chkMultitasking -and $t.ContainsKey("Multitasking")) { $chkMultitasking.IsChecked = [bool]$t["Multitasking"] }
                        if ($chkSnapFlyout -and $t.ContainsKey("SnapFlyout")) { $chkSnapFlyout.IsChecked = [bool]$t["SnapFlyout"] }
                        if ($chkGameDVR -and $t.ContainsKey("GameDVR")) { $chkGameDVR.IsChecked = [bool]$t["GameDVR"] }
                        if ($chkDeliveryOpt -and $t.ContainsKey("DeliveryOpt")) { $chkDeliveryOpt.IsChecked = [bool]$t["DeliveryOpt"] }
                        if ($chkEdgeBackground -and $t.ContainsKey("EdgeBackground")) { $chkEdgeBackground.IsChecked = [bool]$t["EdgeBackground"] }
                        if ($chkScheduledTasks -and $t.ContainsKey("ScheduledTasks")) { $chkScheduledTasks.IsChecked = [bool]$t["ScheduledTasks"] }
                        if ($chkTelemetryService -and $t.ContainsKey("TelemetryService")) { $chkTelemetryService.IsChecked = [bool]$t["TelemetryService"] }
                        if ($chkHibernation -and $t.ContainsKey("Hibernation")) { $chkHibernation.IsChecked = [bool]$t["Hibernation"] }
                        if ($chkConsumerFeatures -and $t.ContainsKey("ConsumerFeatures")) { $chkConsumerFeatures.IsChecked = [bool]$t["ConsumerFeatures"] }
                        if ($chkLockScreenAds -and $t.ContainsKey("LockScreenAds")) { $chkLockScreenAds.IsChecked = [bool]$t["LockScreenAds"] }
                        if ($chkMousePrecision -and $t.ContainsKey("MousePrecision")) { $chkMousePrecision.IsChecked = [bool]$t["MousePrecision"] }
                        if ($chkStickyKeys -and $t.ContainsKey("StickyKeys")) { $chkStickyKeys.IsChecked = [bool]$t["StickyKeys"] }
                        if ($chkFastStartup -and $t.ContainsKey("FastStartup")) { $chkFastStartup.IsChecked = [bool]$t["FastStartup"] }
                        if ($chkStorageSense -and $t.ContainsKey("StorageSense")) { $chkStorageSense.IsChecked = [bool]$t["StorageSense"] }
                        if ($chkPreventAutoReboot -and $t.ContainsKey("PreventAutoReboot")) { $chkPreventAutoReboot.IsChecked = [bool]$t["PreventAutoReboot"] }
                        if ($chkExcludeDrivers -and $t.ContainsKey("ExcludeDrivers")) { $chkExcludeDrivers.IsChecked = [bool]$t["ExcludeDrivers"] }
                        if ($chkSettingsHome -and $t.ContainsKey("SettingsHome")) { $chkSettingsHome.IsChecked = [bool]$t["SettingsHome"] }
                        if ($chkCopilotPolicy -and $t.ContainsKey("CopilotPolicy")) { $chkCopilotPolicy.IsChecked = [bool]$t["CopilotPolicy"] }
                        if ($chkCopilotAppx -and $t.ContainsKey("CopilotAppx")) { $chkCopilotAppx.IsChecked = [bool]$t["CopilotAppx"] }
                        if ($chkRecallAI -and $t.ContainsKey("RecallAI")) { $chkRecallAI.IsChecked = [bool]$t["RecallAI"] }
                        if ($chkEdgeAI -and $t.ContainsKey("EdgeAI")) { $chkEdgeAI.IsChecked = [bool]$t["EdgeAI"] }
                        if ($chkPaintAI -and $t.ContainsKey("PaintAI")) { $chkPaintAI.IsChecked = [bool]$t["PaintAI"] }
                        if ($chkNotepadAI -and $t.ContainsKey("NotepadAI")) { $chkNotepadAI.IsChecked = [bool]$t["NotepadAI"] }
                        if ($chkWindowsSandbox -and $t.ContainsKey("WindowsSandbox")) { $chkWindowsSandbox.IsChecked = [bool]$t["WindowsSandbox"] }
                        if ($chkWSL -and $t.ContainsKey("WSL")) { $chkWSL.IsChecked = [bool]$t["WSL"] }
                    }

                    & $syncPrivacyDropdownFromTweaks
                    & $syncShellDropdownFromTweaks
                    & $syncGamingDropdownFromTweaks
                    & $syncExtrasDropdownFromTweaks
                    & $syncAIDropdownFromTweaks
                    & $syncFeaturesDropdownFromTweaks
                    & $updateLiveImpactSummary
                    & $updateStageView 2

                    [System.Windows.MessageBox]::Show("Preset profile '$($imported.ProfileName)' loaded successfully!`n$($imported.SelectedApps.Count) Apps and $($imported.SelectedTweaks.Count) Tweaks configured.", "NH Win Debloater", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                } catch {
                    [System.Windows.MessageBox]::Show("Failed to import preset profile:`n$($_.Exception.Message)", "Import Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
                }
            }
        })
    }

    # Registry Snapshot Rollback Handlers
    if ($btnRefreshSnapshots) {
        $btnRefreshSnapshots.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $refreshSnapshotsList
        })
    }

    if ($btnPreviewSnapshot) {
        $btnPreviewSnapshot.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $selected = & $getSnapshotFromItem $cboRegistrySnapshots.SelectedItem
            if (-not $selected -or -not $selected.FilePath) {
                if ($txtRestoreStatus) { $txtRestoreStatus.Text = "Please select a valid snapshot to preview." }
                return
            }
            try {
                $results = Restore-RegistrySnapshot -SnapshotPath $selected.FilePath -WhatIf
                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = "Dry-Run Preview: $($results.Count) registry keys would be restored from $($selected.FileName)."
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::MediumAquamarine
                }
                Write-DebloatLog -Message "Dry-Run Preview: $($results.Count) registry keys would be restored from $($selected.FileName)" -Level "PREVIEW" -NoConsole
            } catch {
                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = "Preview Error: $($_.Exception.Message)"
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::Coral
                }
                Write-DebloatLog -Message "Preview Error for $($selected.FileName): $($_.Exception.Message)" -Level "ERROR" -NoConsole
            }
        })
    }

    if ($btnRestoreSnapshot) {
        $btnRestoreSnapshot.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $selected = & $getSnapshotFromItem $cboRegistrySnapshots.SelectedItem
            if (-not $selected -or -not $selected.FilePath) {
                if ($txtRestoreStatus) { $txtRestoreStatus.Text = "Please select a valid snapshot to restore." }
                return
            }

            $confirm = [System.Windows.MessageBox]::Show("Are you sure you want to restore registry snapshot:`n$($selected.FileName)?`n`nThis will overwrite current registry policies with the values saved in this backup.", "Confirm Registry Rollback", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
                try {
                    $results = Restore-RegistrySnapshot -SnapshotPath $selected.FilePath
                    if ($txtRestoreStatus) {
                        $txtRestoreStatus.Text = "Successfully restored $($results.Count) registry values from $($selected.FileName)."
                        $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::MediumAquamarine
                    }
                    Write-DebloatLog -Message "1-Click Rollback executed: restored $($results.Count) registry values from $($selected.FileName)" -Level "SUCCESS" -NoConsole
                    [System.Windows.MessageBox]::Show("Registry snapshot restored successfully ($($results.Count) entries updated).`nRestarting Explorer or rebooting your PC is recommended to apply changes.", "Rollback Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                } catch {
                    if ($txtRestoreStatus) {
                        $txtRestoreStatus.Text = "Restore Error: $($_.Exception.Message)"
                        $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::Coral
                    }
                    Write-DebloatLog -Message "Rollback Error for $($selected.FileName): $($_.Exception.Message)" -Level "ERROR" -NoConsole
                }
            }
        })
    }

    # App Reinstall Modal Open/Close & Execution
    $openReinstallModal = {
        if ($modalReinstallApps) {
            $modalReinstallApps.Visibility = [System.Windows.Visibility]::Visible
            if ($txtReinstallLog) {
                $txtReinstallLog.Text = "Ready. Select applications to reinstall and click 'Reinstall Selected'."
            }
        }
    }

    if ($btnHeaderReinstallApps) {
        $btnHeaderReinstallApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $openReinstallModal
        })
    }

    if ($btnStage5ReinstallApps) {
        $btnStage5ReinstallApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $openReinstallModal
        })
    }

    $closeReinstallModal = {
        if ($modalReinstallApps) {
            $modalReinstallApps.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }

    if ($btnCloseReinstallModal) {
        $btnCloseReinstallModal.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $closeReinstallModal
        })
    }

    if ($btnCloseReinstallModalBottom) {
        $btnCloseReinstallModalBottom.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $closeReinstallModal
        })
    }

    if ($btnExecuteReinstallApps) {
        $btnExecuteReinstallApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $appsToReinstall = [System.Collections.Generic.List[string]]::new()
            if ($chkReinstallStore -and $chkReinstallStore.IsChecked) { $appsToReinstall.Add("Store") }
            if ($chkReinstallCalculator -and $chkReinstallCalculator.IsChecked) { $appsToReinstall.Add("Calculator") }
            if ($chkReinstallNotepad -and $chkReinstallNotepad.IsChecked) { $appsToReinstall.Add("Notepad") }
            if ($chkReinstallPaint -and $chkReinstallPaint.IsChecked) { $appsToReinstall.Add("Paint") }
            if ($chkReinstallPhotos -and $chkReinstallPhotos.IsChecked) { $appsToReinstall.Add("Photos") }
            if ($chkReinstallTerminal -and $chkReinstallTerminal.IsChecked) { $appsToReinstall.Add("Terminal") }

            if ($appsToReinstall.Count -eq 0) {
                if ($txtReinstallLog) { $txtReinstallLog.Text = "No apps selected. Please tick at least one application." }
                return
            }

            $isDryRun = [bool]($chkReinstallDryRun -and $chkReinstallDryRun.IsChecked)
            $logBuilder = [System.Text.StringBuilder]::new()
            $modeTag = if ($isDryRun) { "[PREVIEW / DRY-RUN]" } else { "[INSTALLING]" }
            $logBuilder.AppendLine("$modeTag Starting reinstallation for $($appsToReinstall.Count) selected apps...") | Out-Null
            Write-DebloatLog -Message "$modeTag Starting reinstallation for $($appsToReinstall.Count) selected apps..." -Level (if ($isDryRun) { "PREVIEW" } else { "INFO" }) -NoConsole

            foreach ($appName in $appsToReinstall) {
                $logBuilder.AppendLine(" -> Processing: $appName...") | Out-Null
                if ($txtReinstallLog) { $txtReinstallLog.Text = $logBuilder.ToString() }

                $res = Install-CommonWindowsApp -AppName $appName -WhatIf:$isDryRun
                $logBuilder.AppendLine("    [$($res.Status)] $($res.DisplayName): $($res.Message)") | Out-Null
                $logLevel = if ($res.Status -eq "Success") { "SUCCESS" } elseif ($res.Status -eq "Warning" -or $res.Status -eq "Preview") { "PREVIEW" } else { "ERROR" }
                Write-DebloatLog -Message "[$($res.Status)] Reinstall $($res.DisplayName): $($res.Message)" -Level $logLevel -NoConsole
            }

            $logBuilder.AppendLine("Reinstallation task finished.") | Out-Null
            if ($txtReinstallLog) { $txtReinstallLog.Text = $logBuilder.ToString() }
            Write-DebloatLog -Message "App reinstallation task finished." -Level (if ($isDryRun) { "PREVIEW" } else { "SUCCESS" }) -NoConsole
        })
    }

    $btnFinish.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        $window.Close()
    })

    # Window Closed Handler: Ensure post-exit temp & session cleanup (preserving backups/logs)
    $window.Add_Closed({
        if (Get-Command Clear-DebloatTempSession -ErrorAction SilentlyContinue) {
            Clear-DebloatTempSession
        }
    })

    # Initial view setup
    & $updateStageView 1

    # Show Modal Window with guaranteed cleanup
    try {
        $null = $window.ShowDialog()
    }
    finally {
        if (Get-Command Clear-DebloatTempSession -ErrorAction SilentlyContinue) {
            Clear-DebloatTempSession
        }
    }
}

if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Show-DebloaterWindow
}

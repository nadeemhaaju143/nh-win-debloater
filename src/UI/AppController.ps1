<#
    .SYNOPSIS
        NH Win Debloater - UI Controller Engine
    .DESCRIPTION
        Orchestrates the WPF/XAML Guided Setup Assistant, manages stage transitions with
        fluid animations, populates application catalogs with dark Material multi-select
        category filters, executes dry-run previews, and triggers atomic debloat pipelines
        with dedicated AI integration, privacy, gaming, and system tweak controls.
    .MODULEVERSION
        1.3.1
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
        [string]$ProjectRoot,
        [switch]$DryRun
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    }

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms | Out-Null
    $script:GlobalDryRun = [bool]$DryRun

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
    Import-Module (Join-Path $corePath "PreflightValidator.psm1") -Force
    Import-Module (Join-Path $corePath "TransactionJournal.psm1") -Force
    Import-Module (Join-Path $corePath "RollbackEngine.psm1") -Force
    Import-Module (Join-Path $corePath "RegistryProvider.psm1") -Force
    Import-Module (Join-Path $corePath "ServiceProvider.psm1") -Force
    Import-Module (Join-Path $corePath "TaskProvider.psm1") -Force

    Initialize-DebloatLogger -Version $script:AppVersion | Out-Null

    # 3. Load XAML
    if (-not (Test-Path $xamlPath)) {
        Write-Error "MainWindow.xaml not found at: $xamlPath"
        return
    }

    $xaml = Get-Content -Path $xamlPath -Raw -Encoding UTF8
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
    $txtHardwareSpecs = $window.FindName("TxtHardwareSpecs")
    $txtOsCaption = $window.FindName("TxtOsCaption")
    $txtElevationStatus = $window.FindName("TxtElevationStatus")
    $dotElevationStatus = $window.FindName("DotElevationStatus")
    $btnActionReinstallApps = $window.FindName("BtnActionReinstallApps")
    $txtWelcomeHeading = $window.FindName("TxtWelcomeHeading")
    $txtWelcomeSubtitle = $window.FindName("TxtWelcomeSubtitle")
    $txtRecSetupTitle = $window.FindName("TxtRecSetupTitle")
    $txtRecSetupDesc = $window.FindName("TxtRecSetupDesc")
    $txtCustomTuningTitle = $window.FindName("TxtCustomTuningTitle")
    $txtCustomTuningDesc = $window.FindName("TxtCustomTuningDesc")
    $iconRecSetup = $window.FindName("IconRecSetup")
    $iconCustomTuning = $window.FindName("IconCustomTuning")

    $stepTag1 = $window.FindName("StepTag1")
    $stepTag2 = $window.FindName("StepTag2")
    $stepTag3 = $window.FindName("StepTag3")
    $stepTag4 = $window.FindName("StepTag4")
    $stepTag5 = $window.FindName("StepTag5")

    $pillStage1 = $window.FindName("PillStage1")
    $pillStage2 = $window.FindName("PillStage2")
    $pillStage3 = $window.FindName("PillStage3")
    $pillStage4 = $window.FindName("PillStage4")
    $pillStage5 = $window.FindName("PillStage5")

    $badgeStep1 = $window.FindName("BadgeStep1")
    $badgeStep2 = $window.FindName("BadgeStep2")
    $badgeStep3 = $window.FindName("BadgeStep3")
    $badgeStep4 = $window.FindName("BadgeStep4")
    $badgeStep5 = $window.FindName("BadgeStep5")

    $checkStep1 = $window.FindName("CheckStep1")
    $checkStep2 = $window.FindName("CheckStep2")
    $checkStep3 = $window.FindName("CheckStep3")
    $checkStep4 = $window.FindName("CheckStep4")
    $checkStep5 = $window.FindName("CheckStep5")

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
    $radioScopeAllUsers = $window.FindName("RadioScopeAllUsers")
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
    $btnGamingSelectAll = $window.FindName("BtnGamingSelectAll")
    $btnGamingClear = $window.FindName("BtnGamingClear")
    $btnSelectAllGaming = $window.FindName("BtnSelectAllGaming")
    $btnDeselectAllGaming = $window.FindName("BtnDeselectAllGaming")
    $chkGameDVR = $window.FindName("ChkGameDVR")
    $chkDeliveryOpt = $window.FindName("ChkDeliveryOpt")
    $chkEdgeBackground = $window.FindName("ChkEdgeBackground")
    $chkScheduledTasks = $window.FindName("ChkScheduledTasks")

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
    $chkStorageSense = $window.FindName("ChkStorageSense")
    $chkSettingsHome = $window.FindName("ChkSettingsHome")
    $chkDisableSpotlight = $window.FindName("ChkDisableSpotlight")

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

    # Stage 3 Safety & Dry-Run
    $txtStage3Summary = $window.FindName("TxtStage3Summary")
    $badgeStage3Impact = $window.FindName("BadgeStage3Impact")
    $iconStage3Impact = $window.FindName("IconStage3Impact")
    $txtStage3Impact = $window.FindName("TxtStage3Impact")
    $txtStage3Scope = $window.FindName("TxtStage3Scope")
    $txtStage3Mode = $window.FindName("TxtStage3Mode")
    $chkCreateRestorePoint = $window.FindName("ChkCreateRestorePoint")
    $chkRegistrySnapshot = $window.FindName("ChkRegistrySnapshot")
    $chkRestartExplorer = $window.FindName("ChkRestartExplorer")
    $chkDryRunStage3 = $window.FindName("ChkDryRunStage3")
    $btnRunDryRun = $window.FindName("BtnRunDryRun")
    $txtDryRunStatus = $window.FindName("TxtDryRunStatus")
    $txtDryRunLog = $window.FindName("TxtDryRunLog")
    $tabHeaderApps = $window.FindName("TabHeaderApps")
    $txtBtnApply = $window.FindName("TxtBtnApply")

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
    $btnRestoreSelective = $window.FindName("BtnRestoreSelective")
    $btnRestoreSnapshot = $window.FindName("BtnRestoreSnapshot")
    $txtRestoreStatus = $window.FindName("TxtRestoreStatus")
    $toggleSelectiveRestore = $window.FindName("ToggleSelectiveRestore")
    $txtToggleSelectiveRestoreText = $window.FindName("TxtToggleSelectiveRestoreText")
    $popupSelectiveRestore = $window.FindName("PopupSelectiveRestore")
    $chkRestoreScopeApps = $window.FindName("ChkRestoreScopeApps")
    $chkRestoreScopePrivacy = $window.FindName("ChkRestoreScopePrivacy")
    $chkRestoreScopeShell = $window.FindName("ChkRestoreScopeShell")
    $chkRestoreScopeGaming = $window.FindName("ChkRestoreScopeGaming")
    $chkRestoreScopeAI = $window.FindName("ChkRestoreScopeAI")
    $chkRestoreScopeExtras = $window.FindName("ChkRestoreScopeExtras")
    $btnRestoreScopeTweaksOnly = $window.FindName("BtnRestoreScopeTweaksOnly")
    $btnRestoreScopeAppsOnly = $window.FindName("BtnRestoreScopeAppsOnly")
    $btnRestoreScopeAll = $window.FindName("BtnRestoreScopeAll")
    $btnRestoreScopeClear = $window.FindName("BtnRestoreScopeClear")

    # Header & Stage 1/2 Actions
    $btnHeaderRestore = $window.FindName("BtnHeaderRestore")
    $btnStage1Restore = $window.FindName("BtnStage1Restore")
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
    $legendBottomBar = $window.FindName("LegendBottomBar")

    # 5. Populate Brand & System Info
    if (Test-Path $versionPath) {
        $v = (Get-Content -Path $versionPath -Raw).Trim()
        $txtVersion.Text = "v$v"
    } else {
        $txtVersion.Text = "v1.0.0"
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

    # Header Logo wiring (loads custom NH lion PNG logo, falling back to borderless vector lettermark)
    $logoCandidates = @(
        (Join-Path $logoDir "nh-lion-logo.png"),
        (Join-Path $logoDir "nhdigital-logo.png"),
        (Join-Path $logoDir "logo.png")
    )
    $foundLogo = $false
    foreach ($candidate in $logoCandidates) {
        if (Test-Path $candidate) {
            try {
                $img = [System.Windows.Media.Imaging.BitmapImage]::new()
                $img.BeginInit()
                $img.UriSource = [Uri]$candidate
                $img.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
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

    # Live PC Hardware Configuration & Platform Specs
    try {
        $cpuRaw = (Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0" -ErrorAction SilentlyContinue).ProcessorNameString
        $cpuClean = if ($cpuRaw) { ($cpuRaw -replace '\s+', ' ').Trim() } else { "Multi-Core CPU" }

        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $totalRamGb = if ($os -and $os.TotalVisibleMemorySize) {
            [math]::Round(($os.TotalVisibleMemorySize / 1024 / 1024), 0)
        } else {
            16
        }

        if ($txtHardwareSpecs) {
            $bullet = [char]0x2022
            $txtHardwareSpecs.Text = "$cpuClean $bullet ${totalRamGb} GB RAM"
        }

        $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).CurrentBuild
        $arch = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        $osCaptionText = if ($os -and $os.Caption) { "$($os.Caption) ($arch)" } else { "Windows 11 / 10 ($arch)" }
        if ($build) { $osCaptionText += " [Build $build]" }
        if ($txtOsCaption) {
            $txtOsCaption.Text = $osCaptionText
        }
    } catch {
        if ($txtHardwareSpecs) { $txtHardwareSpecs.Text = "PC Hardware Detected" }
        if ($txtOsCaption) { $txtOsCaption.Text = "Windows 11 / 10" }
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
                if ($btnRestoreSelective) { $btnRestoreSelective.IsEnabled = $false }
            } else {
                foreach ($b in $backups) {
                    $cboItem = [System.Windows.Controls.ComboBoxItem]::new()
                    $cboItem.Content = "$($b.LastModified) - $($b.FileName) ($($b.SizeKb) KB)"
                    $cboItem.Tag = $b
                    $null = $cboRegistrySnapshots.Items.Add($cboItem)
                }
                $cboRegistrySnapshots.SelectedIndex = 0
                if ($btnRestoreSnapshot) { $btnRestoreSnapshot.IsEnabled = $true }
                if ($btnPreviewSnapshot) { $btnPreviewSnapshot.IsEnabled = $true }
                if ($btnRestoreSelective) { $btnRestoreSelective.IsEnabled = $true }
            }
        }
    }

    $script:CameFromRestoreShortcut = $false

    $updateStageView = {
        param([int]$stage)
        $script:CurrentStage = $stage
        if ($stage -ne 5) {
            $script:CameFromRestoreShortcut = $false
        }

        # Hide all stages
        $viewStage1.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage2.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage3.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage4.Visibility = [System.Windows.Visibility]::Collapsed
        $viewStage5.Visibility = [System.Windows.Visibility]::Collapsed

        # Stepper highlights & Material Pill state synchronization
        $stepColorActive = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0EA5E9")
        $stepColorInactive = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
        $stepColorDone = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")

        $brushActivePillBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2234")
        $brushActiveBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0EA5E9")
        $brushDonePillBg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#131926")
        $brushDoneBorder   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981")
        $brushIdlePillBg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0B0F17")
        $brushIdleBorder   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#232D42")

        $brushActiveBadge  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0EA5E9")
        $brushIdleBadge    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222C42")

        $pills = @($pillStage1, $pillStage2, $pillStage3, $pillStage4, $pillStage5)
        $badges = @($badgeStep1, $badgeStep2, $badgeStep3, $badgeStep4, $badgeStep5)
        $checks = @($checkStep1, $checkStep2, $checkStep3, $checkStep4, $checkStep5)
        $stepTags = @($stepTag1, $stepTag2, $stepTag3, $stepTag4, $stepTag5)

        for ($i = 0; $i -lt 5; $i++) {
            $stepNum = $i + 1
            $pill = $pills[$i]
            $badge = $badges[$i]
            $chk = $checks[$i]
            $tag = $stepTags[$i]

            if ($stepNum -lt $stage) {
                # Completed
                if ($pill) { $pill.Background = $brushDonePillBg; $pill.BorderBrush = $brushDoneBorder }
                if ($badge) { $badge.Visibility = [System.Windows.Visibility]::Collapsed }
                if ($chk) { $chk.Visibility = [System.Windows.Visibility]::Visible }
                if ($tag) { $tag.Foreground = $stepColorDone; $tag.FontWeight = [System.Windows.FontWeights]::Normal }
            } elseif ($stepNum -eq $stage) {
                # Active
                if ($pill) { $pill.Background = $brushActivePillBg; $pill.BorderBrush = $brushActiveBorder }
                if ($badge) { $badge.Background = $brushActiveBadge; $badge.Visibility = [System.Windows.Visibility]::Visible }
                if ($chk) { $chk.Visibility = [System.Windows.Visibility]::Collapsed }
                if ($tag) { $tag.Foreground = $stepColorActive; $tag.FontWeight = [System.Windows.FontWeights]::Bold }
            } else {
                # Upcoming
                if ($pill) { $pill.Background = $brushIdlePillBg; $pill.BorderBrush = $brushIdleBorder }
                if ($badge) { $badge.Background = $brushIdleBadge; $badge.Visibility = [System.Windows.Visibility]::Visible }
                if ($chk) { $chk.Visibility = [System.Windows.Visibility]::Collapsed }
                if ($tag) { $tag.Foreground = $stepColorInactive; $tag.FontWeight = [System.Windows.FontWeights]::Normal }
            }
        }

        # Configure visible stage and buttons
        switch ($stage) {
            1 {
                & $revealStage $viewStage1
                $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                $btnNext.Visibility = [System.Windows.Visibility]::Visible
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            2 {
                & $revealStage $viewStage2
                $btnBack.Visibility = [System.Windows.Visibility]::Visible
                $btnNext.Visibility = [System.Windows.Visibility]::Visible
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
                & $updateLiveImpactSummary
            }
            3 {
                & $revealStage $viewStage3
                $btnBack.Visibility = [System.Windows.Visibility]::Visible
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Visible
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed

                $activeScopeText = if ($radioScopeDefaultUser -and $radioScopeDefaultUser.IsChecked) {
                    "Default User / Sysprep"
                } elseif ($radioScopeCurrentUser -and $radioScopeCurrentUser.IsChecked) {
                    "Current User Only"
                } else {
                    "All Users (Recommended)"
                }
                if ($txtStage3Scope) { $txtStage3Scope.Text = $activeScopeText }

                $isDry = [bool]($script:GlobalDryRun -or ($chkDryRunStage3 -and $chkDryRunStage3.IsChecked))
                if ($chkDryRunStage3) { $chkDryRunStage3.IsChecked = $isDry }
                if ($txtStage3Mode) {
                    $modeColor = if ($isDry) { "#F59E0B" } else { "#10B981" }
                    $txtStage3Mode.Text = if ($isDry) { "Dry-Run Simulation (WhatIf)" } else { "Live System Optimization" }
                    $txtStage3Mode.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($modeColor)
                }
                & $updateLiveImpactSummary
                if ($buildDryRunPreview) { & $buildDryRunPreview }
            }
            4 {
                & $revealStage $viewStage4
                $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Collapsed
            }
            5 {
                & $revealStage $viewStage5
                $stepTag5.Foreground = $stepColorActive; $stepTag5.FontWeight = [System.Windows.FontWeights]::Bold
                if ($script:CameFromRestoreShortcut) {
                    $btnBack.Visibility = [System.Windows.Visibility]::Visible
                } else {
                    $btnBack.Visibility = [System.Windows.Visibility]::Collapsed
                }
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $btnApply.Visibility = [System.Windows.Visibility]::Collapsed
                $btnFinish.Visibility = [System.Windows.Visibility]::Visible
                & $refreshSnapshotsList
            }
        }

        if ($legendBottomBar) {
            $legendBottomBar.Visibility = if ($stage -eq 2) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        }
    }

    # 9. Dynamic Selection Counters & Live Safety/Impact Evaluator
    $script:IsUpdatingAppBatch = $false
    $updateLiveImpactSummary = {
        if ($script:IsUpdatingAppBatch) { return }

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
        @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $gamingChecked++ } }
        if ($txtTabGamingCount) { $txtTabGamingCount.Text = "$gamingChecked/4" }

        $extrasChecked = 0
        $extrasAll = @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkStorageSense, $chkSettingsHome, $chkDisableSpotlight)
        $extrasAll | ForEach-Object { if ($_ -and $_.IsChecked) { $extrasChecked++ } }
        if ($txtTabExtrasCount) { $txtTabExtrasCount.Text = "$extrasChecked/$($extrasAll.Count)" }

        $aiChecked = 0
        @($chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $aiChecked++ } }
        if ($txtTabAICount) { $txtTabAICount.Text = "$aiChecked/6" }

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
            ConsumerFeatures    = [bool]($chkConsumerFeatures -and $chkConsumerFeatures.IsChecked)
            LockScreenAds       = [bool]($chkLockScreenAds -and $chkLockScreenAds.IsChecked)
            MousePrecision      = [bool]($chkMousePrecision -and $chkMousePrecision.IsChecked)
            StickyKeys          = [bool]($chkStickyKeys -and $chkStickyKeys.IsChecked)
            StorageSense        = [bool]($chkStorageSense -and $chkStorageSense.IsChecked)
            SettingsHome        = [bool]($chkSettingsHome -and $chkSettingsHome.IsChecked)
            DisableSpotlight    = [bool]($chkDisableSpotlight -and $chkDisableSpotlight.IsChecked)
            CopilotPolicy       = [bool]($chkCopilotPolicy -and $chkCopilotPolicy.IsChecked)
            CopilotAppx         = [bool]($chkCopilotAppx -and $chkCopilotAppx.IsChecked)
            RecallAI            = [bool]($chkRecallAI -and $chkRecallAI.IsChecked)
            EdgeAI              = [bool]($chkEdgeAI -and $chkEdgeAI.IsChecked)
            PaintAI             = [bool]($chkPaintAI -and $chkPaintAI.IsChecked)
            NotepadAI           = [bool]($chkNotepadAI -and $chkNotepadAI.IsChecked)
        }

        # 4. Compute Safety & Impact via pure engine function
        $impact = Get-DebloatSafetyImpact -AppCount $selectedAppCount -TweakFlags $tweakFlags

        # 5. Update UI Controls
        if ($txtGlobalSelectionSummary) {
            $bullet = [char]0x2022
            $txtGlobalSelectionSummary.Text = "$selectedAppCount Apps $bullet $($impact.TweakCount) Tweaks selected"
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
            $bullet = [char]0x2022
            $txtStage3Summary.Text = "$selectedAppCount Apps & Bloatware $bullet $($impact.TweakCount) System Tweaks Queued ($($impact.TotalCount) Operations)"
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
        $script:IsUpdatingAppBatch = $true
        try {
            # 1. Scan and cache installed packages once per session (excluding core system frameworks)
            if ($null -eq $script:InstalledAppMap) {
                try {
                    $scanned = Get-InstalledDebloatApp -PresetsPath $presetsPath -ExcludeCoreFrameworks
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
            $curatedRecommendedIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($recItem in (Get-DebloatPreset -PresetName "Default" -PresetsPath $presetsPath)) {
                if ($recItem.AppId) { [void]$curatedRecommendedIds.Add([string]$recItem.AppId) }
            }

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

            # Merge live installed/provisioned non-system apps not already in curated catalog (default unchecked)
            foreach ($instItem in $script:InstalledAppMap.Values) {
                if (-not $instItem -or $instItem.IsProtected -or $instItem.IsCoreFramework) { continue }
                if (-not $appMap.ContainsKey($instItem.AppId)) {
                    $appMap[$instItem.AppId] = [PSCustomObject]@{
                        AppId            = $instItem.AppId
                        Aliases          = @($instItem.AppId)
                        DisplayName      = $instItem.AppId
                        Recommendation   = "Optional"
                        RemovalMethod    = "Appx"
                        IsLiveDiscovered = $true
                    }
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
                $chevron = [char]0x25BC
                $toggleAppCategories.Content = "$catHeader $chevron"
            }

            $listAppsContainer.Items.Clear()
            $script:AppCheckboxes.Clear()
            $script:AppMetadata.Clear()

            $friendlyCatalog = @{
                "Clipchamp.Clipchamp"                    = @{ Name = "Clipchamp Video Editor"; Desc = "Web-based video editor and recorder" }
                "Microsoft.549981C3F5F10"                = @{ Name = "Cortana"; Desc = "Legacy voice assistant" }
                "Microsoft.BingNews"                     = @{ Name = "Microsoft News"; Desc = "MSN news headlines and live feeds" }
                "Microsoft.BingWeather"                  = @{ Name = "MSN Weather"; Desc = "Weather forecast and radar" }
                "Microsoft.BingFinance"                  = @{ Name = "MSN Money"; Desc = "Financial tracking and market news" }
                "Microsoft.BingSports"                   = @{ Name = "MSN Sports"; Desc = "Live sporting scores and updates" }
                "Microsoft.GetHelp"                      = @{ Name = "Get Help"; Desc = "Windows troubleshooter and help hub" }
                "Microsoft.Getstarted"                   = @{ Name = "Tips"; Desc = "Windows feature walkthroughs and tips" }
                "Microsoft.MicrosoftOfficeHub"           = @{ Name = "Microsoft 365 (Office)"; Desc = "Office cloud dashboard shortcut" }
                "Microsoft.MicrosoftSolitaireCollection" = @{ Name = "Solitaire Collection"; Desc = "Card games with sponsored ads" }
                "Microsoft.People"                       = @{ Name = "People"; Desc = "Windows contacts address book" }
                "Microsoft.Todos"                        = @{ Name = "Microsoft To Do"; Desc = "Task manager and checklist planner" }
                "Microsoft.WindowsFeedbackHub"           = @{ Name = "Feedback Hub"; Desc = "Feedback telemetry submission portal" }
                "Microsoft.WindowsMaps"                  = @{ Name = "Windows Maps"; Desc = "Offline maps and navigation" }
                "Microsoft.YourPhone"                    = @{ Name = "Phone Link"; Desc = "Phone sync and SMS mirroring" }
                "Microsoft.ZuneMusic"                    = @{ Name = "Media Player Legacy (Groove)"; Desc = "Legacy audio playback client" }
                "Microsoft.ZuneVideo"                    = @{ Name = "Movies & TV"; Desc = "Video playback and rentals hub" }
                "Microsoft.SkypeApp"                     = @{ Name = "Skype"; Desc = "Video calls and messaging" }
                "Microsoft.PowerAutomateDesktop"         = @{ Name = "Power Automate"; Desc = "Robotic desktop workflow automation" }
                "Microsoft.MicrosoftStickyNotes"         = @{ Name = "Sticky Notes"; Desc = "Desktop quick sticky notes utility" }
                "Microsoft.OutlookForWindows"            = @{ Name = "Outlook for Windows"; Desc = "Web-wrapper email client" }
                "Microsoft.GamingApp"                    = @{ Name = "Xbox App"; Desc = "Xbox PC gaming hub" }
                "Microsoft.XboxGamingOverlay"            = @{ Name = "Xbox Game Bar"; Desc = "In-game overlay widget" }
                "Microsoft.XboxSpeechToTextOverlay"      = @{ Name = "Xbox Speech Overlay"; Desc = "Voice-to-text gaming transcriptions" }
                "Microsoft.XboxIdentityProvider"         = @{ Name = "Xbox Identity Provider"; Desc = "Xbox Live authentication provider" }
                "Microsoft.MixedReality.Portal"          = @{ Name = "Mixed Reality Portal"; Desc = "VR and holographic environment launcher" }
                "Microsoft.WindowsSoundRecorder"         = @{ Name = "Sound Recorder"; Desc = "Audio capture utility" }
                "Microsoft.WindowsAlarms"                = @{ Name = "Clock & Alarms"; Desc = "Timers, stopwatches and alarms" }
                "Microsoft.WindowsCalculator"            = @{ Name = "Calculator"; Desc = "Standard system math calculator" }
                "Microsoft.WindowsCamera"                = @{ Name = "Camera"; Desc = "Webcam and video recording utility" }
                "Microsoft.Copilot"                      = @{ Name = "Microsoft Copilot"; Desc = "AI assistant app and taskbar integration" }
                "Microsoft.OneDrive"                     = @{ Name = "Microsoft OneDrive"; Desc = "Cloud storage sync and background client (Win32 + AppX)" }
                "Microsoft.Edge.GameAssist"              = @{ Name = "Microsoft Edge Game Assist"; Desc = "In-game browser overlay stub" }
                "MicrosoftWindows.CrossDevice"           = @{ Name = "Cross-Device Experience Host"; Desc = "Cross-device phone/PC sync background host" }
                "Microsoft.BingSearch"                   = @{ Name = "Bing Search"; Desc = "Windows Search web integration provider" }
                "Microsoft.Windows.DevHome"              = @{ Name = "Dev Home"; Desc = "Developer dashboard and widget host" }
                "MicrosoftCorporationII.MicrosoftFamily" = @{ Name = "Microsoft Family"; Desc = "Family safety and parental monitoring app" }
                "MicrosoftCorporationII.QuickAssist"     = @{ Name = "Quick Assist"; Desc = "Remote screen sharing support utility" }
                "MSTeams"                                = @{ Name = "Microsoft Teams"; Desc = "Work/personal chat and video meetings client" }
                "MicrosoftTeams"                         = @{ Name = "Microsoft Teams (Legacy)"; Desc = "Consumer Teams chat client" }
                "5319275A.WhatsAppDesktop"               = @{ Name = "WhatsApp Desktop"; Desc = "Promoted messaging stub" }
                "Facebook.InstagramBeta"                 = @{ Name = "Instagram"; Desc = "Promoted social media stub" }
                "7EE7776C.LinkedInforWindows"            = @{ Name = "LinkedIn"; Desc = "Promoted professional network stub" }
            }

            foreach ($app in $appMap.Values) {
                $isInst = $script:InstalledAppMap.ContainsKey($app.AppId.ToLower())
                if (-not $isInst -and $app.PSObject.Properties["Aliases"] -and $app.Aliases) {
                    foreach ($al in $app.Aliases) {
                        if ($script:InstalledAppMap.ContainsKey(([string]$al).ToLower())) {
                            $isInst = $true
                            break
                        }
                    }
                }

                $isProtected = Test-IsProtectedApp -AppId $app.AppId -PresetsPath $presetsPath
                if ($isProtected) {
                    continue # Exclude protected essential apps completely from bloatware list
                }

                $safetyTier = "Optional"
                $dotColor = "#F59E0B"
                $badgeBg = "#451A03"
                $badgeFg = "#F59E0B"

                $isLive = [bool]($app.PSObject.Properties["IsLiveDiscovered"] -and $app.IsLiveDiscovered)
                if (-not $isLive -and $curatedRecommendedIds.Contains($app.AppId) -and $app.AppId -notmatch "Xbox|Gaming|Zune|Media|Solitaire|Weather|News|Bing|Maps|People|Mail|Office|OneNote|Skype|Clipchamp|Copilot|OneDrive") {
                    $safetyTier = "Recommended"
                    $dotColor = "#10B981"
                    $badgeBg = "#064E3B"
                    $badgeFg = "#10B981"
                }

                $cleanName = $app.DisplayName
                $cleanDesc = $app.AppId
                if ($friendlyCatalog.ContainsKey($app.AppId)) {
                    $cleanName = $friendlyCatalog[$app.AppId].Name
                    $cleanDesc = $friendlyCatalog[$app.AppId].Desc
                } else {
                    $cleanName = Format-AppDisplayName -PackageName $cleanName
                }

                $cb = [System.Windows.Controls.CheckBox]::new()
                if ($window.Resources.Contains("ModernCheckBox")) {
                    $cb.Style = $window.Resources["ModernCheckBox"]
                }
                $cb.Tag = $app.AppId
                $isUncheckedByDefault = (
                    ($app.PSObject.Properties["IsLiveDiscovered"] -and $app.IsLiveDiscovered) -or
                    $app.AppId -eq "Microsoft.Copilot" -or
                    $app.AppId -eq "Microsoft.OneDrive" -or
                    $app.AppId -eq "Microsoft.OutlookForWindows" -or
                    $app.AppId -eq "MSTeams" -or
                    $app.AppId -eq "MicrosoftTeams" -or
                    $app.AppId -eq "Microsoft.YourPhone" -or
                    $app.AppId -eq "MicrosoftCorporationII.QuickAssist" -or
                    $app.AppId -eq "Microsoft.GamingApp" -or
                    $app.AppId -like "*Copilot*" -or
                    $app.AppId -like "*OneDrive*" -or
                    $app.AppId -like "*Xbox*"
                )
                $cb.IsChecked = if ($isUncheckedByDefault) { $false } else { $true }
                $cb.Margin = [System.Windows.Thickness]::new(4, 3, 4, 3)

                $sp = [System.Windows.Controls.StackPanel]::new()
                $sp.Orientation = [System.Windows.Controls.Orientation]::Horizontal
                $sp.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

                $dotShape = [System.Windows.Shapes.Ellipse]::new()
                $dotShape.Width = 8
                $dotShape.Height = 8
                $dotShape.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($dotColor)
                $dotShape.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
                $dotShape.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $sp.Children.Add($dotShape) | Out-Null

                $badge = [System.Windows.Controls.Border]::new()
                $badge.CornerRadius = [System.Windows.CornerRadius]::new(3)
                $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($badgeBg)
                $badge.Padding = [System.Windows.Thickness]::new(5, 1, 5, 1)
                $badge.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
                $badge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $badgeTxt = [System.Windows.Controls.TextBlock]::new()
                $badgeTxt.Text = $safetyTier
                $badgeTxt.FontSize = 10
                $badgeTxt.FontWeight = [System.Windows.FontWeights]::Bold
                $badgeTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($badgeFg)
                $badge.Child = $badgeTxt
                $sp.Children.Add($badge) | Out-Null

                $txtTitle = [System.Windows.Controls.TextBlock]::new()
                $txtTitle.Text = $cleanName
                $txtTitle.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $txtTitle.FontWeight = [System.Windows.FontWeights]::SemiBold
                $txtTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8FAFC")
                $txtTitle.FontSize = 12.5
                $txtTitle.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $sp.Children.Add($txtTitle) | Out-Null

                $txtDesc = [System.Windows.Controls.TextBlock]::new()
                $txtDesc.Text = " - $cleanDesc"
                $txtDesc.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $txtDesc.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CBD5E1")
                $txtDesc.FontSize = 11.5
                $txtDesc.Margin = [System.Windows.Thickness]::new(4, 0, 0, 0)
                $txtDesc.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $sp.Children.Add($txtDesc) | Out-Null

                $pkgBadge = [System.Windows.Controls.Border]::new()
                $pkgBadge.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $pkgBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
                $pkgBadge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
                $pkgBadge.BorderThickness = [System.Windows.Thickness]::new(1)
                $pkgBadge.Padding = [System.Windows.Thickness]::new(6, 1, 6, 1)
                $pkgBadge.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
                $pkgBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $pkgTxt = [System.Windows.Controls.TextBlock]::new()
                $pkgTxt.Text = $app.AppId
                $pkgTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $pkgTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
                $pkgTxt.FontSize = 9.5
                $pkgBadge.Child = $pkgTxt
                $sp.Children.Add($pkgBadge) | Out-Null

                if ($isInst) {
                    $instBadge = [System.Windows.Controls.Border]::new()
                    $instBadge.CornerRadius = [System.Windows.CornerRadius]::new(4)
                    $instBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0284C7")
                    $instBadge.Padding = [System.Windows.Thickness]::new(6, 1, 6, 1)
                    $instBadge.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
                    $instBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                    $instTxt = [System.Windows.Controls.TextBlock]::new()
                    $instTxt.Text = "INSTALLED"
                    $instTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                    $instTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
                    $instTxt.FontSize = 9.5
                    $instTxt.FontWeight = [System.Windows.FontWeights]::Bold
                    $instBadge.Child = $instTxt
                    $sp.Children.Add($instBadge) | Out-Null
                }

                $cb.Content = $sp

                $script:AppMetadata[$cb] = @{
                    AppId       = $app.AppId
                    DisplayName = $app.DisplayName
                    IsInstalled = $isInst
                    SafetyTier  = $safetyTier
                }

                $cb.Add_Checked({
                    param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
                    if (-not $script:IsUpdatingAppBatch) { & $updateLiveImpactSummary }
                })
                $cb.Add_Unchecked({
                    param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
                    if (-not $script:IsUpdatingAppBatch) { & $updateLiveImpactSummary }
                })

                $script:AppCheckboxes.Add($cb)
                $listAppsContainer.Items.Add($cb) | Out-Null
            }
        }
        finally {
            $script:IsUpdatingAppBatch = $false
            & $filterApps
            & $updateLiveImpactSummary
        }
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
            $script:IsUpdatingAppBatch = $true
            try {
                foreach ($cb in $script:AppCheckboxes) {
                    if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = $true }
                }
            } finally {
                $script:IsUpdatingAppBatch = $false
                & $updateLiveImpactSummary
            }
        })
    }

    if ($btnDeselectAllApps) {
        $btnDeselectAllApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $script:IsUpdatingAppBatch = $true
            try {
                foreach ($cb in $script:AppCheckboxes) {
                    if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = $false }
                }
            } finally {
                $script:IsUpdatingAppBatch = $false
                & $updateLiveImpactSummary
            }
        })
    }

    if ($btnInvertSelection) {
        $btnInvertSelection.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $script:IsUpdatingAppBatch = $true
            try {
                foreach ($cb in $script:AppCheckboxes) {
                    if ($cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = -not $cb.IsChecked }
                }
            } finally {
                $script:IsUpdatingAppBatch = $false
                & $updateLiveImpactSummary
            }
        })
    }

    # 12. Wire All Tweak Checkboxes to Live Impact & Counter Evaluator
    $allTweakCheckboxes = @(
        $chkTelemetry, $chkBingSearch, $chkAdvertisingId, $chkActivityHistory, $chkTailoredExp,
        $chkShowExt, $chkShowHidden, $chkLaunchToThisPC, $chkClassicContextMenu, $chkHideWidgets, $chkHideChat, $chkEndTask, $chkAlignLeft, $chkHideOneDriveNav, $chkHideGalleryNav, $chkSearchHighlights, $chkStartRecommended, $chkCompactExplorer, $chkMultitasking, $chkSnapFlyout,
        $chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks,
        $chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkStorageSense, $chkSettingsHome, $chkDisableSpotlight,
        $chkCopilotPolicy, $chkCopilotAppx, $chkRecallAI, $chkEdgeAI, $chkPaintAI, $chkNotepadAI
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

        $hdr = if ($sel.Count -eq 0) {
            "Presets: None Selected (0/3)"
        } elseif ($sel.Count -eq 3) {
            "Presets: All Selected (3/3)"
        } else {
            "Presets: $($sel -join ', ') ($($sel.Count)/3)"
        }
        if ($txtToggleGamingText) { $txtToggleGamingText.Text = $hdr }
    }

    $syncGamingDropdownFromTweaks = {
        if ($chkGamingDVR) { $chkGamingDVR.IsChecked = [bool]($chkGameDVR -and $chkGameDVR.IsChecked) }
        if ($chkGamingBackground) { $chkGamingBackground.IsChecked = [bool]($chkDeliveryOpt.IsChecked -and $chkEdgeBackground.IsChecked) }
        if ($chkGamingOptimization) { $chkGamingOptimization.IsChecked = [bool]($chkScheduledTasks -and $chkScheduledTasks.IsChecked) }
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
            if ($chkScheduledTasks) { $chkScheduledTasks.IsChecked = $st }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($btnGamingSelectAll) {
        $btnGamingSelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkGamingDVR, $chkGamingBackground, $chkGamingOptimization) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($btnGamingClear) {
        $btnGamingClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkGamingDVR, $chkGamingBackground, $chkGamingOptimization) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateLiveImpactSummary
            & $updateGamingDropdownHeader
        })
    }
    if ($btnSelectAllGaming) {
        $btnSelectAllGaming.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $syncGamingDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    if ($btnDeselectAllGaming) {
        $btnDeselectAllGaming.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $syncGamingDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    @($chkGameDVR, $chkDeliveryOpt, $chkEdgeBackground, $chkScheduledTasks) | ForEach-Object {
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
        if ($chkExtrasDesktop) { $chkExtrasDesktop.IsChecked = [bool]($chkMousePrecision -and $chkMousePrecision.IsChecked) }
        if ($chkExtrasAccessibility) { $chkExtrasAccessibility.IsChecked = [bool]($chkStickyKeys -and $chkStickyKeys.IsChecked) }
        if ($chkExtrasPower) { $chkExtrasPower.IsChecked = [bool]($chkStorageSense.IsChecked -and $chkDisableSpotlight.IsChecked) }
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
            @($chkStorageSense, $chkDisableSpotlight) | ForEach-Object { if ($_) { $_.IsChecked = $st } }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($btnExtrasSelectAll) {
        $btnExtrasSelectAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkExtrasPromos, $chkExtrasDesktop, $chkExtrasAccessibility, $chkExtrasPower) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkStorageSense, $chkSettingsHome, $chkDisableSpotlight) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($btnExtrasClear) {
        $btnExtrasClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkExtrasPromos, $chkExtrasDesktop, $chkExtrasAccessibility, $chkExtrasPower) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkStorageSense, $chkSettingsHome, $chkDisableSpotlight) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateLiveImpactSummary
            & $updateExtrasDropdownHeader
        })
    }
    if ($btnSelectAllExtras) {
        $btnSelectAllExtras.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkStorageSense, $chkSettingsHome, $chkDisableSpotlight) | ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $syncExtrasDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    if ($btnDeselectAllExtras) {
        $btnDeselectAllExtras.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkStorageSense, $chkSettingsHome, $chkDisableSpotlight) | ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $syncExtrasDropdownFromTweaks
            & $updateLiveImpactSummary
        })
    }
    @($chkConsumerFeatures, $chkLockScreenAds, $chkMousePrecision, $chkStickyKeys, $chkStorageSense, $chkSettingsHome, $chkDisableSpotlight) | ForEach-Object {
        if ($_) { $_.Add_Click({ & $syncExtrasDropdownFromTweaks; & $updateLiveImpactSummary }) }
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

    # Initialize all dropdown headers and states
    & $updatePrivacyDropdownHeader
    & $updateShellDropdownHeader
    & $updateGamingDropdownHeader
    & $updateExtrasDropdownHeader
    & $updateAIDropdownHeader

    # Dry-Run Preview Action (Auto-populated on Stage 3 entry & on Inspect/Dry-Run toggle)
    $buildDryRunPreview = {
        if (-not $txtDryRunLog) { return }
        if ($txtDryRunStatus) { $txtDryRunStatus.Text = "Simulating WhatIf dry-run changes..." }
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
        if ($chkConsumerFeatures -and $chkConsumerFeatures.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows consumer features and promo preinstalls would be blocked.") | Out-Null }
        if ($chkSettingsHome -and $chkSettingsHome.IsChecked) { $logBuilder.AppendLine("WhatIf: Settings home page recommendations and 365 ads would be disabled.") | Out-Null }
        if ($chkDisableSpotlight -and $chkDisableSpotlight.IsChecked) { $logBuilder.AppendLine("WhatIf: Windows Spotlight backgrounds and Action Center suggestions would be disabled.") | Out-Null }
        if ($chkMousePrecision -and $chkMousePrecision.IsChecked) { $logBuilder.AppendLine("WhatIf: Mouse pointer acceleration would be disabled (1:1 precision).") | Out-Null }
        if ($chkStickyKeys -and $chkStickyKeys.IsChecked) { $logBuilder.AppendLine("WhatIf: Sticky Keys 5x Shift shortcut prompt would be disabled.") | Out-Null }
        if ($chkStorageSense -and $chkStorageSense.IsChecked) { $logBuilder.AppendLine("WhatIf: Storage Sense automatic deletion policy would be disabled.") | Out-Null }
        if ($chkSearchHighlights -and $chkSearchHighlights.IsChecked) { $logBuilder.AppendLine("WhatIf: Taskbar search highlights and doodles would be disabled.") | Out-Null }
        if ($chkStartRecommended -and $chkStartRecommended.IsChecked) { $logBuilder.AppendLine("WhatIf: Start Menu Recommended clutter would be hidden.") | Out-Null }
        if ($chkCompactExplorer -and $chkCompactExplorer.IsChecked) { $logBuilder.AppendLine("WhatIf: File Explorer compact view would be enabled.") | Out-Null }

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
        if ($txtDryRunStatus) { $txtDryRunStatus.Text = "Queued preview ready: $selectedCount apps and selected tweaks simulated." }
    }

    if ($btnRunDryRun) {
        $btnRunDryRun.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $buildDryRunPreview
        })
    }

    if ($chkDryRunStage3) {
        $chkDryRunStage3.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $isDry = [bool]$chkDryRunStage3.IsChecked
            $script:GlobalDryRun = $isDry
            if ($txtStage3Mode) {
                $modeColor = if ($isDry) { "#F59E0B" } else { "#10B981" }
                $txtStage3Mode.Text = if ($isDry) { "Dry-Run Simulation (WhatIf)" } else { "Live System Optimization" }
                $txtStage3Mode.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($modeColor)
            }
            & $buildDryRunPreview
        })
    }

    # Step Navigation Buttons
    # Stage 1 Hero Buttons: Recommended Setup & Custom Tuning
    $btnRecommendedSetup = $window.FindName("BtnRecommendedSetup")
    $btnCustomTuning = $window.FindName("BtnCustomTuning")
    $script:WelcomeMode = "Recommended"

    $updateModeVisuals = {
        param([string]$mode)
        try {
            $script:WelcomeMode = $mode
            $brushConv = [System.Windows.Media.BrushConverter]::new()
            if ($mode -eq "Recommended") {
                if ($radioPresetDefault) { $radioPresetDefault.IsChecked = $true }
                if ($btnRecommendedSetup) {
                    $btnRecommendedSetup.Background = $brushConv.ConvertFromString("#0EA5E9")
                    $btnRecommendedSetup.BorderBrush = $brushConv.ConvertFromString("#38BDF8")
                    $btnRecommendedSetup.BorderThickness = [System.Windows.Thickness]::new(2)
                }
                if ($txtRecSetupTitle) { $txtRecSetupTitle.Foreground = $brushConv.ConvertFromString("#FFFFFF") }
                if ($txtRecSetupDesc) { $txtRecSetupDesc.Foreground = $brushConv.ConvertFromString("#E0F2FE") }
                if ($iconRecSetup) { $iconRecSetup.Fill = $brushConv.ConvertFromString("#FFFFFF") }

                if ($btnCustomTuning) {
                    $btnCustomTuning.Background = $brushConv.ConvertFromString("#131926")
                    $btnCustomTuning.BorderBrush = $brushConv.ConvertFromString("#232D42")
                    $btnCustomTuning.BorderThickness = [System.Windows.Thickness]::new(1)
                }
                if ($txtCustomTuningTitle) { $txtCustomTuningTitle.Foreground = $brushConv.ConvertFromString("#94A3B8") }
                if ($txtCustomTuningDesc) { $txtCustomTuningDesc.Foreground = $brushConv.ConvertFromString("#64748B") }
                if ($iconCustomTuning) { $iconCustomTuning.Fill = $brushConv.ConvertFromString("#64748B") }
            }
            else {
                if ($btnRecommendedSetup) {
                    $btnRecommendedSetup.Background = $brushConv.ConvertFromString("#131926")
                    $btnRecommendedSetup.BorderBrush = $brushConv.ConvertFromString("#232D42")
                    $btnRecommendedSetup.BorderThickness = [System.Windows.Thickness]::new(1)
                }
                if ($txtRecSetupTitle) { $txtRecSetupTitle.Foreground = $brushConv.ConvertFromString("#94A3B8") }
                if ($txtRecSetupDesc) { $txtRecSetupDesc.Foreground = $brushConv.ConvertFromString("#64748B") }
                if ($iconRecSetup) { $iconRecSetup.Fill = $brushConv.ConvertFromString("#64748B") }

                if ($btnCustomTuning) {
                    $btnCustomTuning.Background = $brushConv.ConvertFromString("#0EA5E9")
                    $btnCustomTuning.BorderBrush = $brushConv.ConvertFromString("#38BDF8")
                    $btnCustomTuning.BorderThickness = [System.Windows.Thickness]::new(2)
                }
                if ($txtCustomTuningTitle) { $txtCustomTuningTitle.Foreground = $brushConv.ConvertFromString("#FFFFFF") }
                if ($txtCustomTuningDesc) { $txtCustomTuningDesc.Foreground = $brushConv.ConvertFromString("#E0F2FE") }
                if ($iconCustomTuning) { $iconCustomTuning.Fill = $brushConv.ConvertFromString("#FFFFFF") }
            }
        } catch {
            Write-DebloatLog -Message "Exception updating mode visuals: $($_.Exception.Message)" -Level "WARN" -NoConsole
        }
    }

    if ($btnRecommendedSetup) {
        $btnRecommendedSetup.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            try {
                & $updateModeVisuals "Recommended"
            } catch {
                Write-DebloatLog -Message "Exception in BtnRecommendedSetup click: $($_.Exception.Message)" -Level "ERROR"
            }
        })
    }
    if ($btnCustomTuning) {
        $btnCustomTuning.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            try {
                & $updateModeVisuals "Custom"
            } catch {
                Write-DebloatLog -Message "Exception in BtnCustomTuning click: $($_.Exception.Message)" -Level "ERROR"
            }
        })
    }

    # Synchronize initial visual state on Stage 1
    & $updateModeVisuals "Recommended"

    # Apply Action Pipeline
    $applyOptimizationsAction = {
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

        $isDryRun = [bool]($script:GlobalDryRun -or ($chkDryRunStage3 -and $chkDryRunStage3.IsChecked))
        if ($isDryRun) {
            & $appendLog "DRY-RUN / WHATIF PREVIEW ACTIVE: System changes will be simulated without writing to disk." "WARN"
        }

        $targetScope = if ($radioScopeCurrentUser.IsChecked) { "CurrentUser" } elseif ($radioScopeDefaultUser.IsChecked) { "DefaultUser" } else { "AllUsers" }
        & $appendLog "Selected execution scope: $targetScope" "INFO"

        # Step 1: System Preflight (Read-Only)
        $preflight = Invoke-SystemPreflight -Scope $targetScope
        & $appendLog "Preflight: $($preflight.Edition) Build $($preflight.Build) ($($preflight.Architecture)), Admin=$($preflight.IsAdmin), FreeSpace=$($preflight.FreeDiskSpaceGB)GB" "INFO"
        foreach ($pw in $preflight.Warnings) {
            & $appendLog "Preflight Warning: $pw" "WARN"
        }

        # Step 6: Explicit Approval Gate for AllUsers / High-Impact changes (Live mode)
        $hasHighImpact = $false
        $approvalReq = Test-ApprovalRequirement -Scope $targetScope -HasHighImpact $hasHighImpact
        if (-not $isDryRun -and ($approvalReq.RequiresElevatedScopeConfirmation -or $approvalReq.RequiresHighImpactConfirmation)) {
            $confirmScope = [System.Windows.MessageBox]::Show(
                "$($approvalReq.PromptSummary)`n`nDo you explicitly approve applying these changes?",
                "NH Win Debloater - Explicit Confirmation Required",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($confirmScope -ne [System.Windows.MessageBoxResult]::Yes) {
                & $appendLog "Execution cancelled by user at explicit approval gate." "WARN"
                $txtProgressStatus.Text = "Cancelled before applying changes."
                & $updateStageView 3
                return
            }
        }

        $isDefaultUserScope = ($targetScope -eq "DefaultUser")
        $defaultUserMounted = $false
        if ($isDefaultUserScope -and -not $isDryRun) {
            & $appendLog "Mounting Windows Default User profile hive (C:\Users\Default\NTUSER.DAT) under HKLM\NHDefaultUser..." "INFO"
            $defaultUserMounted = Mount-DefaultUserHive
            if ($defaultUserMounted) {
                & $appendLog "Default User profile hive successfully mounted." "SUCCESS"
            } else {
                & $appendLog "Warning: Could not mount Default User hive. Applying to current user and machine policies." "WARN"
            }
        }

        $totalOps = 0
        $successOps = 0
        $skippedOps = 0
        $failedOps = 0

        # Step 2 & 3: Read-Only System Inventory & Mandatory Recovery Data Gate
        $txSession = New-TransactionSession
        & $appendLog "Initialized transaction session: $($txSession.SessionId)" "INFO"

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
            "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\48e6b7a6-50f5-4782-a5d4-53bb8f07e226",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings",
            "HKCU:\Software\Policies\Microsoft\Windows\CloudContent",
            "HKCU:\Software\Microsoft\GameBar",
            "HKCU:\System\GameConfigStore",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR",
            "HKLM:\SOFTWARE\Policies\Microsoft\Edge",
            "HKCU:\Software\Microsoft\Paint\Settings",
            "HKCU:\Software\Policies\Microsoft\Paint",
            "HKCU:\Software\Microsoft\Notepad",
            "HKCU:\Software\Policies\Microsoft\Notepad"
        )

        $inventory = Get-ReadOnlySystemInventory -RegistryPaths $regPaths
        $attemptRp = [bool]((-not $isDryRun) -and $chkCreateRestorePoint -and $chkCreateRestorePoint.IsChecked)
        if ($attemptRp) {
            & $appendLog "Creating Windows System Restore Point..." "INFO"
            $txtProgressStatus.Text = "Creating System Restore checkpoint..."
        }
        $recGate = Save-SessionRecoveryData -Session $txSession -BeforeStateData $inventory -AttemptRestorePoint $attemptRp
        if ($recGate.Halted) {
            $missingMsg = $recGate.MissingProtections -join "`n"
            & $appendLog "RECOVERY GATE HALTED: $missingMsg" "WARN"
            $overrideChoice = [System.Windows.MessageBox]::Show(
                "Mandatory recovery protection could not be completed:`n`n$missingMsg`n`nDo you want to override this safety gate and continue anyway?",
                "NH Win Debloater - Recovery Protection Warning",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($overrideChoice -ne [System.Windows.MessageBoxResult]::Yes) {
                & $appendLog "Execution halted cleanly because recovery protection was missing and not overridden." "WARN"
                $txtProgressStatus.Text = "Halted: Recovery protection required."
                & $updateStageView 3
                return
            }
            $null = Save-SessionRecoveryData -Session $txSession -BeforeStateData $inventory -AttemptRestorePoint $false -ForceOverride
            & $appendLog "User explicitly overrode missing recovery protection warning." "WARN"
        } elseif ($attemptRp) {
            $totalOps++; $successOps++
            & $appendLog "System Restore Point created successfully." "SUCCESS"
        }
        $progExecution.Value = 20

        # Legacy Registry Snapshot compatibility (preserved alongside session before-state.json)
        if ($chkRegistrySnapshot -and $chkRegistrySnapshot.IsChecked) {
            & $appendLog "Capturing pre-tweak registry snapshot..." "INFO"
            $snapFile = Export-RegistrySnapshot -RegistryPaths $regPaths
            $totalOps++
            $successOps++
            & $appendLog "Registry snapshot saved: $(Split-Path $snapFile -Leaf)" "SUCCESS"
        }
        $progExecution.Value = 35

        $env:NH_DEBLOAT_TARGET_SCOPE = $targetScope
        $recordTx = {
            param([string]$opId, [string]$cat, [string]$target, [object]$prev, [object]$req, [string]$resStr, [bool]$verified, [bool]$rollbackAvail, [string]$err = "")
            if (-not $isDryRun -and $txSession) {
                try {
                    Add-TransactionRecord -Session $txSession -OperationId $opId -Category $cat -Target $target -PreviousState $prev -RequestedState $req -Result $resStr -Verified $verified -RollbackAvailable $rollbackAvail -ErrorDetail $err | Out-Null
                } catch {}
            }
        }

        # 3. Privacy & Search Tweaks
        if ($chkTelemetry.IsChecked) { Set-PrivacySetting -SettingId "DisableTelemetry" -Enable $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Privacy.DisableTelemetry" "Privacy" "DisableTelemetry [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Telemetry diagnostics set to Security/Basic." }
        if ($chkBingSearch.IsChecked) { Set-PrivacySetting -SettingId "DisableBingSearch" -Enable $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Privacy.DisableBingSearch" "Privacy" "DisableBingSearch [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Bing Start Search suggestions disabled." }
        if ($chkAdvertisingId.IsChecked) { Set-PrivacySetting -SettingId "DisableAdvertisingId" -Enable $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Privacy.DisableAdvertisingId" "Privacy" "DisableAdvertisingId [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Advertising ID disabled." }
        if ($chkActivityHistory.IsChecked) { Set-PrivacySetting -SettingId "DisableActivityHistory" -Enable $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Privacy.DisableActivityHistory" "Privacy" "DisableActivityHistory [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Activity History feed disabled." }
        if ($chkTailoredExp.IsChecked) { Set-PrivacySetting -SettingId "DisableTailoredExperiences" -Enable $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Privacy.DisableTailoredExperiences" "Privacy" "DisableTailoredExperiences [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Tailored Experiences disabled." }
        $progExecution.Value = 48

        # 4. UI & Shell Tweaks
        if ($chkShowExt.IsChecked) { Set-ShellSetting -SettingId "ShowFileExtensions" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.ShowFileExtensions" "Shell" "ShowFileExtensions [$targetScope]" "Default" "Enabled" "Success" $true $true; & $appendLog "Show Known File Extensions enabled." }
        if ($chkShowHidden.IsChecked) { Set-ShellSetting -SettingId "ShowHiddenFiles" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.ShowHiddenFiles" "Shell" "ShowHiddenFiles [$targetScope]" "Default" "Enabled" "Success" $true $true; & $appendLog "Show Hidden Files enabled." }
        if ($chkLaunchToThisPC.IsChecked) { Set-ShellSetting -SettingId "ExplorerToThisPC" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.ExplorerToThisPC" "Shell" "ExplorerToThisPC [$targetScope]" "Default" "Enabled" "Success" $true $true; & $appendLog "File Explorer set to open This PC." }
        if ($chkClassicContextMenu.IsChecked) { Set-ClassicContextMenuTweak -EnableClassic $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.ClassicContextMenu" "Shell" "ClassicContextMenu [$targetScope]" "Default" "Classic" "Success" $true $true; & $appendLog "Classic Windows 10 Context Menu restored." }
        if ($chkHideWidgets.IsChecked) { Set-ShellSetting -SettingId "HideWidgets" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.HideWidgets" "Shell" "HideWidgets [$targetScope]" "Default" "Hidden" "Success" $true $true; & $appendLog "Taskbar Widgets hidden." }
        if ($chkHideChat.IsChecked) { Set-ShellSetting -SettingId "HideChat" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.HideChat" "Shell" "HideChat [$targetScope]" "Default" "Hidden" "Success" $true $true; & $appendLog "Taskbar Chat hidden." }
        if ($chkEndTask.IsChecked) { Set-ShellSetting -SettingId "EnableEndTask" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.EnableEndTask" "Shell" "EnableEndTask [$targetScope]" "Default" "Enabled" "Success" $true $true; & $appendLog "Taskbar End Task enabled." }
        if ($chkAlignLeft.IsChecked) { Set-ShellSetting -SettingId "TaskbarAlignLeft" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.TaskbarAlignLeft" "Shell" "TaskbarAlignLeft [$targetScope]" "Default" "Left" "Success" $true $true; & $appendLog "Taskbar aligned to left." }
        if ($chkHideOneDriveNav.IsChecked) { Set-ShellSetting -SettingId "HideOneDriveNav" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.HideOneDriveNav" "Shell" "HideOneDriveNav [$targetScope]" "Default" "Hidden" "Success" $true $true; & $appendLog "OneDrive hidden from Explorer navigation pane." }
        if ($chkHideGalleryNav.IsChecked) { Set-ShellSetting -SettingId "HideGalleryNav" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.HideGalleryNav" "Shell" "HideGalleryNav [$targetScope]" "Default" "Hidden" "Success" $true $true; & $appendLog "Gallery hidden from Explorer navigation pane." }
        if ($chkSearchHighlights.IsChecked) { Set-ShellSetting -SettingId "HideSearchHighlights" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.HideSearchHighlights" "Shell" "HideSearchHighlights [$targetScope]" "Default" "Hidden" "Success" $true $true; & $appendLog "Taskbar search highlights disabled." }
        if ($chkStartRecommended.IsChecked) { Set-StartMenuRecommendedTweak -HideRecommended $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.StartMenuRecommended" "Shell" "StartMenuRecommended [$targetScope]" "Default" "Hidden" "Success" $true $true; & $appendLog "Start Menu Recommended clutter hidden." }
        if ($chkCompactExplorer.IsChecked) { Set-ShellSetting -SettingId "ShowCompactExplorer" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.ShowCompactExplorer" "Shell" "ShowCompactExplorer [$targetScope]" "Default" "Enabled" "Success" $true $true; & $appendLog "File Explorer compact view enabled." }
        if ($chkMultitasking.IsChecked) { Set-MultitaskingTweak -DisableSnapSuggestions $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.Multitasking" "Shell" "Multitasking [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Multitasking & Snap Assist suggestions disabled." }
        if ($chkSnapFlyout.IsChecked) { Set-ShellSetting -SettingId "DisableSnapFlyout" -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Shell.DisableSnapFlyout" "Shell" "DisableSnapFlyout [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Snap Assist suggestions flyout disabled." }
        $progExecution.Value = 60

        # 5. Gaming & Performance Tweaks
        if ($chkGameDVR.IsChecked) { Set-GameDVRPlaybackTweak -DisableGameDVR $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Gaming.GameDVR" "Gaming" "GameDVR [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Game DVR background recording disabled." }
        if ($chkDeliveryOpt.IsChecked) { Set-DeliveryOptimizationTweak -DisableP2P $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Gaming.DeliveryOpt" "Gaming" "DeliveryOpt [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Delivery Optimization P2P disabled." }
        if ($chkEdgeBackground.IsChecked) { Set-EdgeBackgroundTweak -DisableEdgeBackground $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Gaming.EdgeBackground" "Gaming" "EdgeBackground [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Edge background mode and Startup Boost disabled." }
        if ($chkScheduledTasks.IsChecked) { Set-TelemetryScheduledTasksTweak -DisableTasks $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Gaming.ScheduledTasks" "Gaming" "ScheduledTasks [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Telemetry scheduled tasks disabled." }
        $progExecution.Value = 72

        # 6. System Extras
        if ($chkConsumerFeatures.IsChecked) { Set-ConsumerFeatureTweak -Disable $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Extras.ConsumerFeatures" "Extras" "ConsumerFeatures [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Windows consumer features disabled." }
        if ($chkLockScreenAds.IsChecked) { Set-LockScreenTweak -Disable $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Extras.LockScreenAds" "Extras" "LockScreenAds [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Lock screen promotional ads disabled." }
        if ($chkMousePrecision.IsChecked) { Set-MousePrecisionTweak -DisableAcceleration $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Extras.MousePrecision" "Extras" "MousePrecision [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Mouse pointer acceleration disabled (1:1 precision)." }
        if ($chkStickyKeys.IsChecked) { Set-StickyKeysTweak -DisableShortcut $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Extras.StickyKeys" "Extras" "StickyKeys [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Sticky Keys shortcut prompt disabled." }
        if ($chkStorageSense.IsChecked) { Set-StorageSenseTweak -DisableStorageSense $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Extras.StorageSense" "Extras" "StorageSense [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Storage Sense automatic deletion disabled." }
        if ($chkSettingsHome.IsChecked) { Set-SettingsHomeTweak -DisableHomeRecommendations $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Extras.SettingsHome" "Extras" "SettingsHome [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Settings home page recommendations & 365 ads disabled." }
        if ($chkDisableSpotlight -and $chkDisableSpotlight.IsChecked) { Set-WindowsSpotlightTweak -Disable $true -WhatIf:$isDryRun | Out-Null; $totalOps++; $successOps++; & $recordTx "Extras.DisableSpotlight" "Extras" "DisableSpotlight [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Windows Spotlight backgrounds & Action Center suggestions disabled." }
        $progExecution.Value = 80

        # 7. AI Integration Suite
        if ($chkCopilotPolicy.IsChecked -or $chkCopilotAppx.IsChecked) {
            Set-CopilotAITweak -DisableCopilot ([bool]$chkCopilotPolicy.IsChecked) -RemoveAppxPackage ([bool]$chkCopilotAppx.IsChecked) -WhatIf:$isDryRun | Out-Null
            $totalOps++; $successOps++; & $recordTx "AI.Copilot" "AI" "Copilot [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Windows Copilot policies applied (AppX removal: $([bool]$chkCopilotAppx.IsChecked))."
        }
        if ($chkRecallAI.IsChecked) {
            Set-RecallAITweak -DisableRecall $true -WhatIf:$isDryRun | Out-Null
            $totalOps++; $successOps++; & $recordTx "AI.Recall" "AI" "Recall [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Windows Recall & AI screen analysis snapshots disabled."
        }
        if ($chkEdgeAI.IsChecked -or $chkPaintAI.IsChecked -or $chkNotepadAI.IsChecked) {
            Set-ApplicationAITweak -DisableEdgeAI ([bool]$chkEdgeAI.IsChecked) `
                                  -DisablePaintAI ([bool]$chkPaintAI.IsChecked) `
                                  -DisableNotepadAI ([bool]$chkNotepadAI.IsChecked) -WhatIf:$isDryRun | Out-Null
            $totalOps++; $successOps++; & $recordTx "AI.AppFeatures" "AI" "Edge/Paint/Notepad AI [$targetScope]" "Default" "Disabled" "Success" $true $true; & $appendLog "Integrated application AI features (Edge/Paint/Notepad) updated."
        }
        $progExecution.Value = 88

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
            $remResults = Remove-DebloatApp -AppIdList $appsToRemove.ToArray() -TargetScope $targetScope -PresetsPath $presetsPath -WhatIf:$isDryRun
            foreach ($res in $remResults) {
                $totalOps++
                if ($res.Status -eq "Success" -or $res.Status -eq "Warning" -or $res.Status -eq "Preview") {
                    $successOps++
                    & $recordTx "App.$($res.AppId)" "Apps" "$($res.AppId) [$targetScope]" "Installed" "Removed" "Success" $true $true
                    & $appendLog "Removed package: $($res.AppId)" "SUCCESS"
                } elseif ($res.Status -eq "SkippedProtected") {
                    $skippedOps++
                    & $recordTx "App.$($res.AppId)" "Apps" "$($res.AppId) [$targetScope]" "Protected" "Skipped" "Skipped" $true $false
                    & $appendLog "Protected package skipped: $($res.AppId)" "WARN"
                } else {
                    $skippedOps++
                    & $recordTx "App.$($res.AppId)" "Apps" "$($res.AppId) [$targetScope]" "NotInstalled" "Skipped" "Skipped" $true $false
                    & $appendLog "Package not found on system: $($res.AppId)" "INFO"
                }
            }
        }
        Remove-Item Env:NH_DEBLOAT_TARGET_SCOPE -ErrorAction SilentlyContinue

        # 10. Default User Hive Synchronization & Clean Dismount
        if ($defaultUserMounted) {
            & $appendLog "Synchronizing configured policies and tweaks to Default User profile hive..." "INFO"
            $tweakHkcuPaths = @(
                "HKCU:\Software\Policies\Microsoft\Windows\Explorer",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo",
                "HKCU:\Software\Policies\Microsoft\Windows\CloudContent",
                "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot",
                "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\ClickToDo",
                "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32",
                "HKCU:\Control Panel\Mouse",
                "HKCU:\Control Panel\Accessibility\StickyKeys",
                "HKCU:\Software\Microsoft\Paint\Settings",
                "HKCU:\Software\Microsoft\Notepad"
            )
            foreach ($p in $tweakHkcuPaths) {
                try {
                    if (Test-Path -Path $p) {
                        $destPath = $p -replace "^HKCU:\\", "HKLM:\NHDefaultUser\"
                        if (-not (Test-Path -Path $destPath)) {
                            New-Item -Path $destPath -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                        $props = Get-ItemProperty -Path $p -ErrorAction SilentlyContinue
                        if ($props) {
                            foreach ($prop in $props.PSObject.Properties) {
                                if ($prop.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
                                    New-ItemProperty -Path $destPath -Name $prop.Name -Value $prop.Value -Force -ErrorAction SilentlyContinue | Out-Null
                                }
                            }
                        }
                    }
                } catch {}
            }
            & $appendLog "Default User profile hive successfully synchronized." "SUCCESS"

            & $appendLog "Dismounting Default User hive (releasing open handles)..." "INFO"
            $null = Dismount-DefaultUserHive
            & $appendLog "Default User profile hive dismounted cleanly." "SUCCESS"
        }

        # 11. Optional Explorer Restart
        if ($chkRestartExplorer -and $chkRestartExplorer.IsChecked -and -not $isDryRun) {
            & $appendLog "Restarting Windows Explorer to immediately refresh shell..." "INFO"
            try {
                Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 600
                if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
                    Start-Process "explorer.exe" -ErrorAction SilentlyContinue
                }
                & $appendLog "Windows Explorer restarted successfully." "SUCCESS"
            } catch {
                & $appendLog "Note: Explorer restart scheduled on next sign-in." "INFO"
            }
        }

        $progExecution.Value = 100

        $txReport = Get-TransactionReport -Session $txSession
        if ($failedOps -gt 0 -or ($txReport -and -not $txReport.OverallSuccess)) {
            & $appendLog "Pipeline completed with errors ($failedOps failed). Review session journal: $($txSession.SessionId)" "WARN"
            $txtProgressStatus.Text = "Completed with $failedOps failure(s)."
        } else {
            & $appendLog "Pipeline execution finished successfully (Session: $($txSession.SessionId))." "SUCCESS"
            $txtProgressStatus.Text = "Optimization complete."
        }

        # Update Summary Stats
        $txtStatTotal.Text = "$totalOps"
        $txtStatSuccess.Text = "$successOps"
        $txtStatSkipped.Text = "$skippedOps"

        Start-Sleep -Milliseconds 800
        & $updateStageView 5
    }

    $btnApply.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        & $applyOptimizationsAction
    })

    # Wizard Stepper Navigation Buttons (Next / Back)
    $btnNext.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        try {
            Write-DebloatLog -Message "Navigating from Stage $($script:CurrentStage) with mode $($script:WelcomeMode)..." -Level "INFO" -NoConsole
            if ($script:CurrentStage -eq 1) {
                if ($script:WelcomeMode -eq "Recommended") {
                    # 1. Preset Bloatware Apps: Recommended Safe Defaults
                    if ($chkCatRecommended) { $chkCatRecommended.IsChecked = $true }
                    if ($chkCatMinimal) { $chkCatMinimal.IsChecked = $false }
                    if ($chkCatDeep) { $chkCatDeep.IsChecked = $false }
                    if ($chkCatOem) { $chkCatOem.IsChecked = $false }
                    if ($chkCatXbox) { $chkCatXbox.IsChecked = $false }
                    if ($chkCatMedia) { $chkCatMedia.IsChecked = $false }
                    & $populateApps

                    # 2. Curated Safe Recommended System Tweaks
                    if ($chkTelemetry) { $chkTelemetry.IsChecked = $true }
                    if ($chkBingSearch) { $chkBingSearch.IsChecked = $true }
                    if ($chkAdvertisingId) { $chkAdvertisingId.IsChecked = $true }
                    if ($chkActivityHistory) { $chkActivityHistory.IsChecked = $true }
                    if ($chkTailoredExp) { $chkTailoredExp.IsChecked = $true }

                    if ($chkShowExt) { $chkShowExt.IsChecked = $true }
                    if ($chkShowHidden) { $chkShowHidden.IsChecked = $true }
                    if ($chkLaunchToThisPC) { $chkLaunchToThisPC.IsChecked = $true }
                    if ($chkClassicContextMenu) { $chkClassicContextMenu.IsChecked = $true }
                    if ($chkHideWidgets) { $chkHideWidgets.IsChecked = $true }
                    if ($chkHideChat) { $chkHideChat.IsChecked = $true }
                    if ($chkEndTask) { $chkEndTask.IsChecked = $true }
                    if ($chkAlignLeft) { $chkAlignLeft.IsChecked = $true }
                    if ($chkHideOneDriveNav) { $chkHideOneDriveNav.IsChecked = $true }
                    if ($chkSearchHighlights) { $chkSearchHighlights.IsChecked = $true }
                    if ($chkStartRecommended) { $chkStartRecommended.IsChecked = $true }

                    if ($chkGameDVR) { $chkGameDVR.IsChecked = $false }
                    if ($chkDeliveryOpt) { $chkDeliveryOpt.IsChecked = $true }
                    if ($chkEdgeBackground) { $chkEdgeBackground.IsChecked = $true }
                    if ($chkScheduledTasks) { $chkScheduledTasks.IsChecked = $true }

                    if ($chkConsumerFeatures) { $chkConsumerFeatures.IsChecked = $true }
                    if ($chkLockScreenAds) { $chkLockScreenAds.IsChecked = $true }
                    if ($chkSettingsHome) { $chkSettingsHome.IsChecked = $true }
                    if ($chkDisableSpotlight) { $chkDisableSpotlight.IsChecked = $false }

                    if ($chkCopilotPolicy) { $chkCopilotPolicy.IsChecked = $true }
                    if ($chkCopilotAppx) { $chkCopilotAppx.IsChecked = $false }
                    if ($chkRecallAI) { $chkRecallAI.IsChecked = $true }
                    if ($chkEdgeAI) { $chkEdgeAI.IsChecked = $true }
                    if ($chkPaintAI) { $chkPaintAI.IsChecked = $true }
                    if ($chkNotepadAI) { $chkNotepadAI.IsChecked = $true }

                    if ($chkCreateRestorePoint) { $chkCreateRestorePoint.IsChecked = $true }
                    if ($chkRegistrySnapshot) { $chkRegistrySnapshot.IsChecked = $true }

                    # 3. Route to Stage 3 Deployment / Pre-Apply Summary
                    & $updateLiveImpactSummary
                    & $updateStageView 3
                } else {
                    & $populateApps
                    & $updateStageView 2
                }
            } elseif ($script:CurrentStage -eq 2) {
                & $updateStageView 3
            } elseif ($script:CurrentStage -eq 3) {
                & $applyOptimizationsAction
            }
        } catch {
            Write-DebloatLog -Message "Exception in BtnNext click: $($_.Exception.Message)" -Level "ERROR"
        }
    })

    $btnBack.Add_Click({
        param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
        try {
            if ($script:CurrentStage -eq 5) {
                if ($script:CameFromRestoreShortcut) {
                    $script:CameFromRestoreShortcut = $false
                    & $updateStageView 1
                } elseif ($script:WelcomeMode -eq "Recommended") {
                    & $updateStageView 1
                } else {
                    & $updateStageView 2
                }
            } elseif ($script:CurrentStage -eq 3) {
                if ($script:WelcomeMode -eq "Recommended") {
                    & $updateStageView 1
                } else {
                    & $updateStageView 2
                }
            } elseif ($script:CurrentStage -gt 1) {
                & $updateStageView ($script:CurrentStage - 1)
            }
        } catch {
            Write-DebloatLog -Message "Exception in BtnBack click: $($_.Exception.Message)" -Level "ERROR"
        }
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
                ConsumerFeatures    = [bool]($chkConsumerFeatures -and $chkConsumerFeatures.IsChecked)
                LockScreenAds       = [bool]($chkLockScreenAds -and $chkLockScreenAds.IsChecked)
                MousePrecision      = [bool]($chkMousePrecision -and $chkMousePrecision.IsChecked)
                StickyKeys          = [bool]($chkStickyKeys -and $chkStickyKeys.IsChecked)
                StorageSense        = [bool]($chkStorageSense -and $chkStorageSense.IsChecked)
                SettingsHome        = [bool]($chkSettingsHome -and $chkSettingsHome.IsChecked)
                DisableSpotlight    = [bool]($chkDisableSpotlight -and $chkDisableSpotlight.IsChecked)
                CopilotPolicy       = [bool]($chkCopilotPolicy -and $chkCopilotPolicy.IsChecked)
                CopilotAppx         = [bool]($chkCopilotAppx -and $chkCopilotAppx.IsChecked)
                RecallAI            = [bool]($chkRecallAI -and $chkRecallAI.IsChecked)
                EdgeAI              = [bool]($chkEdgeAI -and $chkEdgeAI.IsChecked)
                PaintAI             = [bool]($chkPaintAI -and $chkPaintAI.IsChecked)
                NotepadAI           = [bool]($chkNotepadAI -and $chkNotepadAI.IsChecked)
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
                        if ($chkConsumerFeatures -and $t.ContainsKey("ConsumerFeatures")) { $chkConsumerFeatures.IsChecked = [bool]$t["ConsumerFeatures"] }
                        if ($chkLockScreenAds -and $t.ContainsKey("LockScreenAds")) { $chkLockScreenAds.IsChecked = [bool]$t["LockScreenAds"] }
                        if ($chkMousePrecision -and $t.ContainsKey("MousePrecision")) { $chkMousePrecision.IsChecked = [bool]$t["MousePrecision"] }
                        if ($chkStickyKeys -and $t.ContainsKey("StickyKeys")) { $chkStickyKeys.IsChecked = [bool]$t["StickyKeys"] }
                        if ($chkStorageSense -and $t.ContainsKey("StorageSense")) { $chkStorageSense.IsChecked = [bool]$t["StorageSense"] }
                        if ($chkSettingsHome -and $t.ContainsKey("SettingsHome")) { $chkSettingsHome.IsChecked = [bool]$t["SettingsHome"] }
                        if ($chkDisableSpotlight -and $t.ContainsKey("DisableSpotlight")) { $chkDisableSpotlight.IsChecked = [bool]$t["DisableSpotlight"] }
                        if ($chkCopilotPolicy -and $t.ContainsKey("CopilotPolicy")) { $chkCopilotPolicy.IsChecked = [bool]$t["CopilotPolicy"] }
                        if ($chkCopilotAppx -and $t.ContainsKey("CopilotAppx")) { $chkCopilotAppx.IsChecked = [bool]$t["CopilotAppx"] }
                        if ($chkRecallAI -and $t.ContainsKey("RecallAI")) { $chkRecallAI.IsChecked = [bool]$t["RecallAI"] }
                        if ($chkEdgeAI -and $t.ContainsKey("EdgeAI")) { $chkEdgeAI.IsChecked = [bool]$t["EdgeAI"] }
                        if ($chkPaintAI -and $t.ContainsKey("PaintAI")) { $chkPaintAI.IsChecked = [bool]$t["PaintAI"] }
                        if ($chkNotepadAI -and $t.ContainsKey("NotepadAI")) { $chkNotepadAI.IsChecked = [bool]$t["NotepadAI"] }
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

    # Shortcut Navigation to Stage 5 Restore Panel
    $jumpToRestore = {
        $script:CameFromRestoreShortcut = $true
        & $updateStageView 5
    }

    if ($btnHeaderRestore) {
        $btnHeaderRestore.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $jumpToRestore
        })
    }

    if ($btnStage1Restore) {
        $btnStage1Restore.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            & $jumpToRestore
        })
    }

    # Selective Scope Helpers & Handlers
    $getSelectedRestoreCategories = {
        $cats = [System.Collections.Generic.List[string]]::new()
        if ($chkRestoreScopePrivacy -and $chkRestoreScopePrivacy.IsChecked) { $cats.Add("Privacy") }
        if ($chkRestoreScopeShell -and $chkRestoreScopeShell.IsChecked) { $cats.Add("Shell") }
        if ($chkRestoreScopeGaming -and $chkRestoreScopeGaming.IsChecked) { $cats.Add("Gaming") }
        if ($chkRestoreScopeAI -and $chkRestoreScopeAI.IsChecked) { $cats.Add("AI") }
        if ($chkRestoreScopeExtras -and $chkRestoreScopeExtras.IsChecked) { $cats.Add("Extras") }
        return $cats.ToArray()
    }

    $updateSelectiveScopeSummary = {
        if (-not $txtToggleSelectiveRestoreText) { return }
        $tweakCount = 0
        @($chkRestoreScopePrivacy, $chkRestoreScopeShell, $chkRestoreScopeGaming, $chkRestoreScopeAI, $chkRestoreScopeExtras) |
            ForEach-Object { if ($_ -and $_.IsChecked) { $tweakCount++ } }
        $appsChecked = [bool]($chkRestoreScopeApps -and $chkRestoreScopeApps.IsChecked)

        if ($appsChecked -and $tweakCount -eq 5) {
            $txtToggleSelectiveRestoreText.Text = "Scope: All Tweaks & Apps"
        } elseif (-not $appsChecked -and $tweakCount -eq 5) {
            $txtToggleSelectiveRestoreText.Text = "Scope: Tweaks Only (5/5)"
        } elseif ($appsChecked -and $tweakCount -eq 0) {
            $txtToggleSelectiveRestoreText.Text = "Scope: Apps Only"
        } elseif (-not $appsChecked -and $tweakCount -eq 0) {
            $txtToggleSelectiveRestoreText.Text = "Scope: None Selected"
        } elseif ($appsChecked) {
            $txtToggleSelectiveRestoreText.Text = "Scope: Apps + $tweakCount Categories"
        } else {
            $txtToggleSelectiveRestoreText.Text = "Scope: $tweakCount Categories"
        }
    }

    @($chkRestoreScopeApps, $chkRestoreScopePrivacy, $chkRestoreScopeShell, $chkRestoreScopeGaming, $chkRestoreScopeAI, $chkRestoreScopeExtras) |
        ForEach-Object {
            if ($_) {
                $_.Add_Checked({ & $updateSelectiveScopeSummary })
                $_.Add_Unchecked({ & $updateSelectiveScopeSummary })
            }
        }

    if ($btnRestoreScopeTweaksOnly) {
        $btnRestoreScopeTweaksOnly.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkRestoreScopeApps) { $chkRestoreScopeApps.IsChecked = $false }
            if ($chkRestoreScopePrivacy) { $chkRestoreScopePrivacy.IsChecked = $true }
            if ($chkRestoreScopeShell) { $chkRestoreScopeShell.IsChecked = $true }
            if ($chkRestoreScopeGaming) { $chkRestoreScopeGaming.IsChecked = $true }
            if ($chkRestoreScopeAI) { $chkRestoreScopeAI.IsChecked = $true }
            if ($chkRestoreScopeExtras) { $chkRestoreScopeExtras.IsChecked = $true }
            & $updateSelectiveScopeSummary
        })
    }

    if ($btnRestoreScopeAppsOnly) {
        $btnRestoreScopeAppsOnly.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($chkRestoreScopeApps) { $chkRestoreScopeApps.IsChecked = $true }
            if ($chkRestoreScopePrivacy) { $chkRestoreScopePrivacy.IsChecked = $false }
            if ($chkRestoreScopeShell) { $chkRestoreScopeShell.IsChecked = $false }
            if ($chkRestoreScopeGaming) { $chkRestoreScopeGaming.IsChecked = $false }
            if ($chkRestoreScopeAI) { $chkRestoreScopeAI.IsChecked = $false }
            if ($chkRestoreScopeExtras) { $chkRestoreScopeExtras.IsChecked = $false }
            & $updateSelectiveScopeSummary
        })
    }

    if ($btnRestoreScopeAll) {
        $btnRestoreScopeAll.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkRestoreScopeApps, $chkRestoreScopePrivacy, $chkRestoreScopeShell, $chkRestoreScopeGaming, $chkRestoreScopeAI, $chkRestoreScopeExtras) |
                ForEach-Object { if ($_) { $_.IsChecked = $true } }
            & $updateSelectiveScopeSummary
        })
    }

    if ($btnRestoreScopeClear) {
        $btnRestoreScopeClear.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            @($chkRestoreScopeApps, $chkRestoreScopePrivacy, $chkRestoreScopeShell, $chkRestoreScopeGaming, $chkRestoreScopeAI, $chkRestoreScopeExtras) |
                ForEach-Object { if ($_) { $_.IsChecked = $false } }
            & $updateSelectiveScopeSummary
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
            $categories = & $getSelectedRestoreCategories
            $includeApps = [bool]($chkRestoreScopeApps -and $chkRestoreScopeApps.IsChecked)

            if ($categories.Count -eq 0 -and -not $includeApps) {
                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = "Please select at least one component in the restore scope."
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::Coral
                }
                return
            }

            if ($categories.Count -gt 0 -and (-not $selected -or -not $selected.FilePath)) {
                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = "Please select a valid snapshot to preview registry tweaks."
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::Coral
                }
                return
            }

            try {
                $regCount = 0
                if ($categories.Count -gt 0) {
                    $results = Restore-RegistrySnapshot -SnapshotPath $selected.FilePath -Categories $categories -WhatIf
                    $regCount = $results.Count
                }
                $appCount = if ($includeApps) { 6 } else { 0 }

                $msg = ""
                if ($regCount -gt 0 -and $appCount -gt 0) {
                    $msg = "Dry-Run Preview: $regCount registry keys ($($categories.Count) categories) and $appCount built-in apps eligible for restore."
                } elseif ($regCount -gt 0) {
                    $msg = "Dry-Run Preview: $regCount registry keys ($($categories.Count) categories) would be restored from $($selected.FileName)."
                } elseif ($appCount -gt 0) {
                    $msg = "Dry-Run Preview: $appCount built-in applications eligible for reinstallation (Store, Calculator, Notepad, Paint, Photos, Terminal)."
                } else {
                    $msg = "Dry-Run Preview: 0 matching keys found in $($selected.FileName) for selected categories."
                }

                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = $msg
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::MediumAquamarine
                }
                Write-DebloatLog -Message $msg -Level "PREVIEW" -NoConsole
            } catch {
                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = "Preview Error: $($_.Exception.Message)"
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::Coral
                }
                Write-DebloatLog -Message "Preview Error: $($_.Exception.Message)" -Level "ERROR" -NoConsole
            }
        })
    }

    if ($btnRestoreSelective) {
        $btnRestoreSelective.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $selected = & $getSnapshotFromItem $cboRegistrySnapshots.SelectedItem
            $categories = & $getSelectedRestoreCategories
            $includeApps = [bool]($chkRestoreScopeApps -and $chkRestoreScopeApps.IsChecked)

            if ($categories.Count -eq 0 -and -not $includeApps) {
                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = "Please select at least one component in the restore scope (Apps or Tweak Categories)."
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::Coral
                }
                return
            }

            if ($categories.Count -gt 0 -and (-not $selected -or -not $selected.FilePath)) {
                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = "Please select a valid snapshot to restore tweaks from."
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::Coral
                }
                return
            }

            $scopeSummary = [System.Collections.Generic.List[string]]::new()
            if ($categories.Count -gt 0) {
                $scopeSummary.Add("Registry Categories: $($categories -join ', ') (from $($selected.FileName))")
            }
            if ($includeApps) {
                $scopeSummary.Add("Built-in Applications (Store, Calculator, Notepad, Paint, Photos, Terminal)")
            }

            $confirmMsg = "Are you sure you want to run Selective Restore with the following scope?`n`n" +
                          ($scopeSummary | ForEach-Object { "- $_" } | Out-String).Trim() +
                          "`n`nThis will revert only the selected components."

            $confirm = [System.Windows.MessageBox]::Show($confirmMsg, "Confirm Selective Restore", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
                return
            }

            try {
                $regResultsCount = 0
                if ($categories.Count -gt 0) {
                    $results = Restore-RegistrySnapshot -SnapshotPath $selected.FilePath -Categories $categories
                    $regResultsCount = $results.Count
                }

                $appsInstalledCount = 0
                if ($includeApps) {
                    @("Store", "Calculator", "Notepad", "Paint", "Photos", "Terminal") | ForEach-Object {
                        $appRes = Install-CommonWindowsApp -AppName $_
                        if ($appRes.Status -eq "Success") { $appsInstalledCount++ }
                    }
                }

                $statusMsg = "Selective Restore Complete: Restored $regResultsCount registry keys"
                if ($includeApps) {
                    $statusMsg += " and processed built-in apps ($appsInstalledCount reinstalled)"
                }
                $statusMsg += "."

                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = $statusMsg
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::MediumAquamarine
                }
                Write-DebloatLog -Message $statusMsg -Level "SUCCESS" -NoConsole

                [System.Windows.MessageBox]::Show("$statusMsg`n`nRestarting Explorer or rebooting your PC is recommended to apply changes.", "Selective Restore Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            } catch {
                if ($txtRestoreStatus) {
                    $txtRestoreStatus.Text = "Restore Error: $($_.Exception.Message)"
                    $txtRestoreStatus.Foreground = [System.Windows.Media.Brushes]::Coral
                }
                Write-DebloatLog -Message "Selective Restore Error: $($_.Exception.Message)" -Level "ERROR" -NoConsole
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
    if ($btnActionReinstallApps) {
        $btnActionReinstallApps.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($popupQuickActions) { $popupQuickActions.IsOpen = $false }
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

    # Window Caption Controls (Minimize, Maximize / Restore, Close)
    $btnMin = $window.FindName("BtnMinimize")
    if ($btnMin) {
        $btnMin.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    }
    $btnMax = $window.FindName("BtnMaximize")
    if ($btnMax) {
        $btnMax.Add_Click({
            if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) {
                $window.WindowState = [System.Windows.WindowState]::Normal
            } else {
                $window.WindowState = [System.Windows.WindowState]::Maximized
            }
        })
    }
    $btnClose = $window.FindName("BtnClose")
    if ($btnClose) {
        $btnClose.Add_Click({ $window.Close() })
    }

    # Top Integrated Canvas Controls: Heart Support, Settings (Preferences), Quick Actions Menu, Close
    $btnSupport = $window.FindName("BtnSupport")
    $popupSupport = $window.FindName("PopupSupport")
    $btnSupportOneTime = $window.FindName("BtnSupportOneTime")
    $btnSupportMonthly = $window.FindName("BtnSupportMonthly")

    if ($btnSupport -and $popupSupport) {
        $btnSupport.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $popupSupport.IsOpen = -not $popupSupport.IsOpen
        })
    }
    if ($btnSupportOneTime) {
        $btnSupportOneTime.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            [System.Diagnostics.Process]::Start("https://rzp.io/rzp/nh-win-debloater") | Out-Null
            if ($popupSupport) { $popupSupport.IsOpen = $false }
        })
    }
    if ($btnSupportMonthly) {
        $btnSupportMonthly.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            [System.Diagnostics.Process]::Start("https://rzp.io/rzp/j9CGaaRR") | Out-Null
            if ($popupSupport) { $popupSupport.IsOpen = $false }
        })
    }

    # Preferences Modal & Theme Switcher
    $btnPreferences = $window.FindName("BtnPreferences")
    $modalPreferences = $window.FindName("ModalPreferences")
    $btnClosePreferencesX = $window.FindName("BtnClosePreferencesX")
    $btnClosePreferences = $window.FindName("BtnClosePreferences")
    $radioThemeAuto = $window.FindName("RadioThemeAuto")
    $radioThemeDark = $window.FindName("RadioThemeDark")
    $radioThemeLight = $window.FindName("RadioThemeLight")

    $applyTheme = {
        param([string]$ThemeMode)
        $isLight = $false
        if ($ThemeMode -eq "Auto") {
            try {
                $reg = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
                if ($reg -and $reg.AppsUseLightTheme -eq 1) { $isLight = $true }
            } catch {}
        } elseif ($ThemeMode -eq "Light") {
            $isLight = $true
        }

        $bc = [System.Windows.Media.BrushConverter]::new()
        if ($isLight) {
            $window.Resources["BgDark"] = $bc.ConvertFromString("#F8FAFC")
            $window.Resources["SurfaceCard"] = $bc.ConvertFromString("#FFFFFF")
            $window.Resources["SurfaceElevated"] = $bc.ConvertFromString("#F1F5F9")
            $window.Resources["CardBorder"] = $bc.ConvertFromString("#CBD5E1")
            $window.Resources["TextPrimary"] = $bc.ConvertFromString("#0F172A")
            $window.Resources["TextSecondary"] = $bc.ConvertFromString("#475569")
        } else {
            $window.Resources["BgDark"] = $bc.ConvertFromString("#0B0F17")
            $window.Resources["SurfaceCard"] = $bc.ConvertFromString("#131926")
            $window.Resources["SurfaceElevated"] = $bc.ConvertFromString("#1A2234")
            $window.Resources["CardBorder"] = $bc.ConvertFromString("#232D42")
            $window.Resources["TextPrimary"] = $bc.ConvertFromString("#F8FAFC")
            $window.Resources["TextSecondary"] = $bc.ConvertFromString("#94A3B8")
        }
    }

    if ($btnPreferences -and $modalPreferences) {
        $btnPreferences.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalPreferences.Visibility = [System.Windows.Visibility]::Visible
        })
    }
    if ($btnClosePreferencesX) {
        $btnClosePreferencesX.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalPreferences.Visibility = [System.Windows.Visibility]::Collapsed
        })
    }
    if ($btnClosePreferences) {
        $btnClosePreferences.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalPreferences.Visibility = [System.Windows.Visibility]::Collapsed
        })
    }
    if ($radioThemeAuto) { $radioThemeAuto.Add_Click({ & $applyTheme "Auto" }) }
    if ($radioThemeDark) { $radioThemeDark.Add_Click({ & $applyTheme "Dark" }) }
    if ($radioThemeLight) { $radioThemeLight.Add_Click({ & $applyTheme "Light" }) }

    # Multi-Language Engine Wiring
    $cmbLanguage = $window.FindName("CmbLanguage")
    $translationsPath = Join-Path $ProjectRoot "src\UI\Translations.json"
    $translationsObj = $null
    if (Test-Path $translationsPath) {
        try {
            $translationsJson = Get-Content -Path $translationsPath -Raw -Encoding UTF8
            $translationsObj = ConvertFrom-Json $translationsJson
        } catch {
            $translationsObj = $null
        }
    }

    $applyLanguage = {
        param([string]$langCode)

        $code = if ($langCode -eq "auto") {
            $sysLang = (Get-Culture).Name
            if ($translationsObj -and ($translationsObj.PSObject.Properties.Name -contains $sysLang)) { $sysLang } else { "en-US" }
        } else {
            $langCode
        }

        $t = $null
        if ($translationsObj -and ($translationsObj.PSObject.Properties.Name -contains $code)) {
            $t = $translationsObj.$code
        } elseif ($translationsObj -and ($translationsObj.PSObject.Properties.Name -contains "en-US")) {
            $t = $translationsObj.'en-US'
        }

        if (-not $t) { return }

        if ($txtWelcomeHeading) { $txtWelcomeHeading.Text = $t.Heading }
        if ($txtWelcomeSubtitle) { $txtWelcomeSubtitle.Text = $t.Sub }
        if ($txtRecSetupTitle) { $txtRecSetupTitle.Text = $t.RecTitle }
        if ($txtRecSetupDesc) { $txtRecSetupDesc.Text = $t.RecDesc }
        if ($txtCustomTuningTitle) { $txtCustomTuningTitle.Text = $t.CusTitle }
        if ($txtCustomTuningDesc) { $txtCustomTuningDesc.Text = $t.CusDesc }

        if ($radioScopeAllUsers) { $radioScopeAllUsers.Content = $t.ScopeAll }
        if ($radioScopeCurrentUser) { $radioScopeCurrentUser.Content = $t.ScopeCur }
        if ($radioScopeDefaultUser) { $radioScopeDefaultUser.Content = $t.ScopeDef }

        if ($btnBack -and $btnBack.Content -and $btnBack.Content.Children) {
            $tb = $btnBack.Content.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] }
            if ($tb) { $tb.Text = $t.Back }
        }
        if ($btnNext -and $btnNext.Content -and $btnNext.Content.Children) {
            $tb = $btnNext.Content.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] }
            if ($tb) { $tb.Text = $t.Next }
        }
        if ($btnApply -and $btnApply.Content -and $btnApply.Content.Children) {
            $tb = $btnApply.Content.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] }
            if ($tb) { $tb.Text = $t.Apply }
        }
        if ($txtBtnApply -and $t.Apply) { $txtBtnApply.Text = $t.Apply }
        if ($tabHeaderApps -and $t.TabApps) { $tabHeaderApps.Text = $t.TabApps }
        if ($btnFinish -and $btnFinish.Content -and $btnFinish.Content.Children) {
            $tb = $btnFinish.Content.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] }
            if ($tb) { $tb.Text = $t.Finish }
        }
    }

    if ($cmbLanguage) {
        $cmbLanguage.Add_SelectionChanged({
            param([object]$eventSource, [System.Windows.Controls.SelectionChangedEventArgs]$eventArgs)
            $selectedItem = $cmbLanguage.SelectedItem
            if ($selectedItem -and $selectedItem.Tag) {
                & $applyLanguage $selectedItem.Tag
            }
        })
    }

    # Quick Actions Menu
    $btnQuickActions = $window.FindName("BtnQuickActions")
    $popupQuickActions = $window.FindName("PopupQuickActions")
    $btnActionLoadProfile = $window.FindName("BtnActionLoadProfile")
    $btnActionSaveProfile = $window.FindName("BtnActionSaveProfile")
    $btnActionRecoveryRollback = $window.FindName("BtnActionRecoveryRollback")
    $btnActionWikiDocs = $window.FindName("BtnActionWikiDocs")
    $btnActionReportIssue = $window.FindName("BtnActionReportIssue")
    $btnActionOpenLogs = $window.FindName("BtnActionOpenLogs")
    $btnActionAbout = $window.FindName("BtnActionAbout")

    if ($btnQuickActions -and $popupQuickActions) {
        $btnQuickActions.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $popupQuickActions.IsOpen = -not $popupQuickActions.IsOpen
        })
    }
    if ($btnActionLoadProfile) {
        $btnActionLoadProfile.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($popupQuickActions) { $popupQuickActions.IsOpen = $false }
            if ($btnImportProfile) {
                $btnImportProfile.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
            }
        })
    }
    if ($btnActionSaveProfile) {
        $btnActionSaveProfile.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($popupQuickActions) { $popupQuickActions.IsOpen = $false }
            $mSave = $window.FindName("ModalSaveProfile")
            if ($mSave) { $mSave.Visibility = [System.Windows.Visibility]::Visible }
        })
    }
    if ($btnActionRecoveryRollback) {
        $btnActionRecoveryRollback.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($popupQuickActions) { $popupQuickActions.IsOpen = $false }
            $mRec = $window.FindName("ModalRecoveryRollback")
            if ($mRec) { $mRec.Visibility = [System.Windows.Visibility]::Visible }
        })
    }
    if ($btnActionWikiDocs) {
        $btnActionWikiDocs.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($popupQuickActions) { $popupQuickActions.IsOpen = $false }
            [System.Diagnostics.Process]::Start("https://github.com/nadeemhaaju143/nh-win-debloater/wiki") | Out-Null
        })
    }
    if ($btnActionReportIssue) {
        $btnActionReportIssue.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($popupQuickActions) { $popupQuickActions.IsOpen = $false }
            [System.Diagnostics.Process]::Start("https://github.com/nadeemhaaju143/nh-win-debloater/issues") | Out-Null
        })
    }
    if ($btnActionOpenLogs) {
        $btnActionOpenLogs.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($popupQuickActions) { $popupQuickActions.IsOpen = $false }
            $logDir = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Logs"
            if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
            [System.Diagnostics.Process]::Start("explorer.exe", $logDir) | Out-Null
        })
    }
    if ($btnActionAbout) {
        $btnActionAbout.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            if ($popupQuickActions) { $popupQuickActions.IsOpen = $false }
            $mAb = $window.FindName("ModalAbout")
            if ($mAb) { $mAb.Visibility = [System.Windows.Visibility]::Visible }
        })
    }

    # Save Profile Modal Wiring
    $modalSaveProfile = $window.FindName("ModalSaveProfile")
    $btnCloseSaveProfileX = $window.FindName("BtnCloseSaveProfileX")
    $btnCancelSaveProfile = $window.FindName("BtnCancelSaveProfile")
    $btnConfirmSaveProfile = $window.FindName("BtnConfirmSaveProfile")

    if ($btnCloseSaveProfileX) {
        $btnCloseSaveProfileX.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalSaveProfile.Visibility = [System.Windows.Visibility]::Collapsed
        })
    }
    if ($btnCancelSaveProfile) {
        $btnCancelSaveProfile.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalSaveProfile.Visibility = [System.Windows.Visibility]::Collapsed
        })
    }
    if ($btnConfirmSaveProfile) {
        $btnConfirmSaveProfile.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalSaveProfile.Visibility = [System.Windows.Visibility]::Collapsed
            if ($btnExportProfile) {
                $btnExportProfile.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
            }
        })
    }

    # Recovery & Rollback Modal Wiring
    $modalRecoveryRollback = $window.FindName("ModalRecoveryRollback")
    $btnCloseRecoveryModalX = $window.FindName("BtnCloseRecoveryModalX")
    $btnCloseRecoveryModal = $window.FindName("BtnCloseRecoveryModal")
    $btnActionFullRollback = $window.FindName("BtnActionFullRollback")
    $btnActionRegistryRollback = $window.FindName("BtnActionRegistryRollback")
    $btnActionStartMenuRollback = $window.FindName("BtnActionStartMenuRollback")

    if ($btnCloseRecoveryModalX) {
        $btnCloseRecoveryModalX.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalRecoveryRollback.Visibility = [System.Windows.Visibility]::Collapsed
        })
    }
    if ($btnCloseRecoveryModal) {
        $btnCloseRecoveryModal.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalRecoveryRollback.Visibility = [System.Windows.Visibility]::Collapsed
        })
    }
    if ($btnActionFullRollback) {
        $btnActionFullRollback.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalRecoveryRollback.Visibility = [System.Windows.Visibility]::Collapsed
            $backupDir = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups"
            if (Test-Path $backupDir) {
                $latestSnap = Get-ChildItem -Path $backupDir -Filter "RegistrySnapshot_*.json" -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($latestSnap -and (Get-Command Restore-RegistrySnapshot -ErrorAction SilentlyContinue)) {
                    Restore-RegistrySnapshot -SnapshotPath $latestSnap.FullName -ErrorAction SilentlyContinue | Out-Null
                }
            }
            if (Get-Command Restore-ServiceOptimization -ErrorAction SilentlyContinue) {
                Restore-ServiceOptimization -ErrorAction SilentlyContinue | Out-Null
            }
            if (Get-Command Restore-StartMenuLayout -ErrorAction SilentlyContinue) {
                Restore-StartMenuLayout -ErrorAction SilentlyContinue | Out-Null
            }
            [System.Windows.MessageBox]::Show("1-Click Full System Rollback completed successfully.`nRegistry tweaks, services, and Start Menu layout have been restored.", "Rollback Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        })
    }
    if ($btnActionRegistryRollback) {
        $btnActionRegistryRollback.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalRecoveryRollback.Visibility = [System.Windows.Visibility]::Collapsed
            & $updateStageView 5
        })
    }
    if ($btnActionStartMenuRollback) {
        $btnActionStartMenuRollback.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalRecoveryRollback.Visibility = [System.Windows.Visibility]::Collapsed
            if (Get-Command Restore-StartMenuLayout -ErrorAction SilentlyContinue) {
                $res = Restore-StartMenuLayout -ErrorAction SilentlyContinue
                if ($res) {
                    [System.Windows.MessageBox]::Show("Start Menu layout restored from backup.", "Start Menu Restored", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                } else {
                    [System.Windows.MessageBox]::Show("No Start Menu layout backup found to restore.", "Restore Skipped", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
                }
            }
        })
    }

    # About Modal Wiring
    $modalAbout = $window.FindName("ModalAbout")
    $btnCloseAboutModalX = $window.FindName("BtnCloseAboutModalX")
    $btnCloseAboutModal = $window.FindName("BtnCloseAboutModal")
    $btnAboutSupport = $window.FindName("BtnAboutSupport")

    if ($btnCloseAboutModalX) {
        $btnCloseAboutModalX.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalAbout.Visibility = [System.Windows.Visibility]::Collapsed
        })
    }
    if ($btnCloseAboutModal) {
        $btnCloseAboutModal.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            $modalAbout.Visibility = [System.Windows.Visibility]::Collapsed
        })
    }
    if ($btnAboutSupport) {
        $btnAboutSupport.Add_Click({
            param([object]$eventSource, [System.Windows.RoutedEventArgs]$eventArgs)
            [System.Diagnostics.Process]::Start("https://rzp.io/rzp/nh-win-debloater") | Out-Null
        })
    }

    # Minimize console host window on startup while keeping status mirrored
    $script:ConsoleHwnd = [System.IntPtr]::Zero
    try {
        if (-not ([System.Management.Automation.PSTypeName]'Win32Utils.Win32ShowWindowConsole').Type) {
            $null = Add-Type -MemberDefinition @"
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
"@ -Name "Win32ShowWindowConsole" -Namespace "Win32Utils" -PassThru -ErrorAction SilentlyContinue
        }
        $script:ConsoleHwnd = [Win32Utils.Win32ShowWindowConsole]::GetConsoleWindow()
        if (-not $script:ConsoleHwnd -or $script:ConsoleHwnd -eq [System.IntPtr]::Zero) {
            $script:ConsoleHwnd = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
        }
        if ($script:ConsoleHwnd -and $script:ConsoleHwnd -ne [System.IntPtr]::Zero) {
            # SW_SHOWMINIMIZED = 2
            [Win32Utils.Win32ShowWindowConsole]::ShowWindow($script:ConsoleHwnd, 2) | Out-Null
        }
    } catch {}

    # Window Closing & Closed Handlers: Guaranteed clean exit & temp purge
    $cleanTempAction = {
        try {
            if ($script:ConsoleHwnd -and $script:ConsoleHwnd -ne [System.IntPtr]::Zero) {
                # SW_RESTORE = 9
                [Win32Utils.Win32ShowWindowConsole]::ShowWindow($script:ConsoleHwnd, 9) | Out-Null
            }
            Write-Host "Cleaning temporary files..." -ForegroundColor Cyan
            Write-DebloatLog -Message "Cleaning temporary files on exit..." -Level "INFO" -NoConsole
            if (Get-Command Clear-DebloatTempSession -ErrorAction SilentlyContinue) {
                Clear-DebloatTempSession
            }
            $cleanPatterns = @("NHWinDebloater*", "nh-win-debloater*")
            foreach ($pat in $cleanPatterns) {
                Get-ChildItem -Path $env:TEMP -Filter $pat -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -notlike "*Backups*" -and $_.FullName -notlike "*Logs*" } |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-DebloatLog -Message "Exception during temp cleanup: $($_.Exception.Message)" -Level "WARN" -NoConsole
        }
    }

    $window.Add_Closing({
        param([object]$eventSource, [System.ComponentModel.CancelEventArgs]$eventArgs)
        try {
            Write-Host "Cleaning temporary files..." -ForegroundColor Cyan
            Write-DebloatLog -Message "Cleaning temporary files..." -Level "INFO" -NoConsole
        } catch {}
    })

    $window.Add_Closed({
        & $cleanTempAction
    })

    # Initial view setup
    & $updateStageView 1

    # Show Modal Window with guaranteed cleanup
    try {
        $null = $window.ShowDialog()
    }
    finally {
        & $cleanTempAction
    }
}

if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Show-DebloaterWindow
}

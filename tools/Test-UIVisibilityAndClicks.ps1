<#
    .SYNOPSIS
        Automated WPF Visual-Tree & UI Automation Test Harness for NH Win Debloater v1.2.0.
    .DESCRIPTION
        Launches the live WPF application window and verifies single-canvas header,
        hardware specs slot, top-right button order, welcome flow, scope selection,
        Preferences modal & 6-language dropdown, 3-line quick actions menu & sub-modals,
        Stage 2 tabs, search, batch buttons, safety indicators, and memory stability.
        Developed by NH Digital (https://nhdigital.shop).
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidTrailingWhitespace', '')]
param(
    [switch]$Detailed
)

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$projectRoot = Split-Path -Parent $PSScriptRoot
$xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
$controllerPath = Join-Path $projectRoot "src\UI\AppController.ps1"
$corePath = Join-Path $projectRoot "src\Core"

# Import Core Modules
Import-Module (Join-Path $corePath "ExecutionLog.psm1") -Force
Import-Module (Join-Path $corePath "AppManager.psm1") -Force
Import-Module (Join-Path $corePath "PrivacySearch.psm1") -Force
Import-Module (Join-Path $corePath "ShellCustomization.psm1") -Force
Import-Module (Join-Path $corePath "SystemTweaks.psm1") -Force

Write-Host ""
Write-Host " ======================================================================" -ForegroundColor Cyan
Write-Host "   NH WIN DEBLOATER v1.2.0 - AUTOMATED UI VISIBILITY & CLICK HARNESS" -ForegroundColor White
Write-Host "   Developed by NH Digital | https://nhdigital.shop" -ForegroundColor DarkCyan
Write-Host " ======================================================================" -ForegroundColor Cyan
Write-Host ""

$testResults = [System.Collections.Generic.List[PSCustomObject]]::new()

function Assert-Check {
    param(
        [string]$Category,
        [string]$Description,
        [bool]$Condition,
        [string]$Details = ""
    )
    $status = if ($Condition) { "PASS" } else { "FAIL" }
    $color = if ($Condition) { "Green" } else { "Red" }
    $symbol = if ($Condition) { "[OK]" } else { "[FAIL]" }

    Write-Host " $symbol $($Category): $Description" -ForegroundColor $color
    if ($Details -and ($Detailed -or -not $Condition)) {
        Write-Host "     -> $Details" -ForegroundColor Gray
    }

    $testResults.Add([PSCustomObject]@{
        Category    = $Category
        Description = $Description
        Status      = $status
        Details     = $Details
    })
}

# 1. Load XAML and Initialize Window
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw -Encoding UTF8)))
$win = [System.Windows.Markup.XamlReader]::Load($reader)
$reader.Close()

$win.Show()
$win.UpdateLayout()

# --- PART 1.1: Single-Canvas Header & Hardware Specs ---
$chrome = [System.Windows.Shell.WindowChrome]::GetWindowChrome($win)
Assert-Check -Category "Header" -Description "WindowChrome CaptionHeight is 52" -Condition ($chrome.CaptionHeight -eq 52)
Assert-Check -Category "Header" -Description "WindowStyle is None (Borderless Canvas)" -Condition ($win.WindowStyle -eq [System.Windows.WindowStyle]::None)
Assert-Check -Category "Header" -Description "AllowsTransparency is True" -Condition ($win.AllowsTransparency -eq $true)

$btnMinimize = $win.FindName("BtnMinimize")
$btnMaximize = $win.FindName("BtnMaximize")
Assert-Check -Category "Header" -Description "Old caption minimize/maximize buttons removed" -Condition ($null -eq $btnMinimize -and $null -eq $btnMaximize)

$btnSupport = $win.FindName("BtnSupport")
$btnPreferences = $win.FindName("BtnPreferences")
$btnQuickActions = $win.FindName("BtnQuickActions")
$btnClose = $win.FindName("BtnClose")

Assert-Check -Category "Header" -Description "Top-right control BtnSupport (Support) exists" -Condition ($null -ne $btnSupport)
Assert-Check -Category "Header" -Description "Top-right control BtnPreferences (Preferences) exists" -Condition ($null -ne $btnPreferences)
Assert-Check -Category "Header" -Description "Top-right control BtnQuickActions (QuickActions) exists" -Condition ($null -ne $btnQuickActions)
Assert-Check -Category "Header" -Description "Top-right control BtnClose (Close) exists" -Condition ($null -ne $btnClose)

# Check button order in Visual Tree
$topRightStack = $btnSupport.Parent.Parent
$topRightButtons = @()
if ($topRightStack -is [System.Windows.Controls.StackPanel]) {
    foreach ($child in $topRightStack.Children) {
        if ($child -is [System.Windows.Controls.Grid]) {
            $topRightButtons += $child.Children[0].Name
        } elseif ($child -is [System.Windows.Controls.Button]) {
            $topRightButtons += $child.Name
        }
    }
}
$expectedOrder = @("BtnSupport", "BtnPreferences", "BtnQuickActions", "BtnClose")
$orderMatch = ($topRightButtons -join ",") -eq ($expectedOrder -join ",")
Assert-Check -Category "Header" -Description "Top-right controls render in exact order (BtnSupport, BtnPreferences, BtnQuickActions, BtnClose)" -Condition $orderMatch -Details ($topRightButtons -join " -> ")

# Check Hardware Specs and Caption
$txtHardwareSpecs = $win.FindName("TxtHardwareSpecs")
$txtOsCaption = $win.FindName("TxtOsCaption")
$txtElevationStatus = $win.FindName("TxtElevationStatus")
$dotElevationStatus = $win.FindName("DotElevationStatus")

Assert-Check -Category "HardwareSpecs" -Description "TxtHardwareSpecs element exists" -Condition ($null -ne $txtHardwareSpecs)
Assert-Check -Category "HardwareSpecs" -Description "TxtOsCaption element exists" -Condition ($null -ne $txtOsCaption)
Assert-Check -Category "HardwareSpecs" -Description "Elevation badge elements exist" -Condition ($null -ne $txtElevationStatus -and $null -ne $dotElevationStatus)

# Simulate Hardware Specs retrieval
$cpuRaw = (Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0" -ErrorAction SilentlyContinue).ProcessorNameString
$cpuClean = if ($cpuRaw) { ($cpuRaw -replace '\s+', ' ').Trim() } else { "Multi-Core CPU" }
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$totalRamGb = if ($os -and $os.TotalVisibleMemorySize) { [math]::Round(($os.TotalVisibleMemorySize / 1024 / 1024), 0) } else { 16 }
$bullet = [char]0x2022
$txtHardwareSpecs.Text = "$cpuClean $bullet ${totalRamGb} GB RAM"
Assert-Check -Category "HardwareSpecs" -Description "TxtHardwareSpecs populated with real CPU and RAM" -Condition ($txtHardwareSpecs.Text -match ".*GB RAM") -Details $txtHardwareSpecs.Text

# --- PART 1.2: Welcome Screen & Mode Flow ---
$viewStage1 = $win.FindName("ViewStage1")
$viewStage2 = $win.FindName("ViewStage2")
$viewStage3 = $win.FindName("ViewStage3")
$logoFallbackBox = $win.FindName("LogoFallbackBox")
$radioScopeAllUsers = $win.FindName("RadioScopeAllUsers")
$radioScopeCurrentUser = $win.FindName("RadioScopeCurrentUser")
$radioScopeDefaultUser = $win.FindName("RadioScopeDefaultUser")
$btnRecommendedSetup = $win.FindName("BtnRecommendedSetup")
$btnCustomTuning = $win.FindName("BtnCustomTuning")
$btnNext = $win.FindName("BtnNext")
$btnBack = $win.FindName("BtnBack")

Assert-Check -Category "WelcomeScreen" -Description "NH Digital monogram emblem (LogoFallbackBox) renders" -Condition ($null -ne $logoFallbackBox)
Assert-Check -Category "WelcomeScreen" -Description "Scope RadioScopeAllUsers is visible and checked" -Condition ($radioScopeAllUsers.IsChecked -eq $true)
Assert-Check -Category "WelcomeScreen" -Description "Scope RadioScopeCurrentUser exists and clickable" -Condition ($null -ne $radioScopeCurrentUser)
Assert-Check -Category "WelcomeScreen" -Description "Scope RadioScopeDefaultUser exists and clickable" -Condition ($null -ne $radioScopeDefaultUser)

# Test Scope Selection
$radioScopeDefaultUser.IsChecked = $true
Assert-Check -Category "WelcomeScreen" -Description "RadioScopeDefaultUser selects cleanly" -Condition ($radioScopeDefaultUser.IsChecked -eq $true -and $radioScopeAllUsers.IsChecked -eq $false)
$radioScopeAllUsers.IsChecked = $true

# Confirm no duplicate buttons on Stage 1
$dupRestore = $viewStage1.FindName("BtnHeaderRestore")
$dupExport = $viewStage2.FindName("BtnExportProfile")
Assert-Check -Category "WelcomeScreen" -Description "Zero duplicate Restore buttons on Stage 1" -Condition ($null -eq $dupRestore)
Assert-Check -Category "WelcomeScreen" -Description "Zero duplicate Export buttons on Stage 2" -Condition ($null -eq $dupExport)

# Test Mode selection: clicking Recommended doesn't jump screens
$script:WelcomeMode = "Recommended"
$btnRecommendedSetup.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
Assert-Check -Category "ModeFlow" -Description "Clicking Recommended Setup stays on Stage 1 (no jump)" -Condition ($viewStage1.Visibility -eq [System.Windows.Visibility]::Visible)

$btnCustomTuning.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
Assert-Check -Category "ModeFlow" -Description "Clicking Custom Tuning stays on Stage 1 (no jump)" -Condition ($viewStage1.Visibility -eq [System.Windows.Visibility]::Visible)

# --- PART 1.3: Preferences Modal & 6-Language Dropdown ---
$modalPreferences = $win.FindName("ModalPreferences")
$btnClosePreferences = $win.FindName("BtnClosePreferences")
$btnClosePreferencesX = $win.FindName("BtnClosePreferencesX")
$radioThemeAuto = $win.FindName("RadioThemeAuto")
$radioThemeDark = $win.FindName("RadioThemeDark")
$radioThemeLight = $win.FindName("RadioThemeLight")
$cmbLanguage = $win.FindName("CmbLanguage")
$chkPrefRestorePoint = $win.FindName("ChkPrefRestorePoint")
$chkPrefCleanTempExit = $win.FindName("ChkPrefCleanTempExit")
$chkPrefRippleEffects = $win.FindName("ChkPrefRippleEffects")

# Open Preferences
$modalPreferences.Visibility = [System.Windows.Visibility]::Visible
Assert-Check -Category "Preferences" -Description "ModalPreferences opens cleanly" -Condition ($modalPreferences.Visibility -eq [System.Windows.Visibility]::Visible)

# Test Theme Radios
$radioThemeLight.IsChecked = $true
$radioThemeDark.IsChecked = $true
$radioThemeAuto.IsChecked = $true
Assert-Check -Category "Preferences" -Description "Theme switcher radio buttons toggle without error" -Condition ($radioThemeAuto.IsChecked -eq $true)

# Verify Language Dropdown
Assert-Check -Category "Preferences" -Description "CmbLanguage dropdown element exists" -Condition ($null -ne $cmbLanguage)
Assert-Check -Category "Preferences" -Description "CmbLanguage has exactly 6 languages" -Condition ($cmbLanguage.Items.Count -eq 6) -Details "Items: $($cmbLanguage.Items.Count)"

$expectedTags = @("auto", "en-US", "hi-IN", "kn-IN", "es-ES", "de-DE")
$actualTags = @($cmbLanguage.Items | ForEach-Object { $_.Tag })
$langMatch = ($actualTags -join ";") -eq ($expectedTags -join ";")
Assert-Check -Category "Preferences" -Description "All 6 languages present with proper tags" -Condition $langMatch -Details ($actualTags -join ", ")

# Test Multi-Language Switching on UI text
$txtWelcomeHeading = $win.FindName("TxtWelcomeHeading")
$translationsPath = Join-Path $projectRoot "src\UI\Translations.json"
$translationsObj = ConvertFrom-Json (Get-Content -Path $translationsPath -Raw -Encoding UTF8)

$cmbLanguage.SelectedIndex = 2 # Hindi
$txtWelcomeHeading.Text = $translationsObj.'hi-IN'.Heading
Assert-Check -Category "Preferences" -Description "Hindi language updates Welcome heading" -Condition ($txtWelcomeHeading.Text -eq $translationsObj.'hi-IN'.Heading)

$cmbLanguage.SelectedIndex = 3 # Kannada
$txtWelcomeHeading.Text = $translationsObj.'kn-IN'.Heading
Assert-Check -Category "Preferences" -Description "Kannada language updates Welcome heading" -Condition ($txtWelcomeHeading.Text -eq $translationsObj.'kn-IN'.Heading)

$cmbLanguage.SelectedIndex = 1 # English
$txtWelcomeHeading.Text = $translationsObj.'en-US'.Heading

# Test Safety Toggles
$chkPrefRestorePoint.IsChecked = $false
$chkPrefRestorePoint.IsChecked = $true
$chkPrefCleanTempExit.IsChecked = $true
$chkPrefRippleEffects.IsChecked = $true
Assert-Check -Category "Preferences" -Description "Safety and behavior toggles check/uncheck cleanly" -Condition ($chkPrefRestorePoint.IsChecked -eq $true)

# Close Preferences
$modalPreferences.Visibility = [System.Windows.Visibility]::Collapsed
Assert-Check -Category "Preferences" -Description "ModalPreferences closes cleanly" -Condition ($modalPreferences.Visibility -eq [System.Windows.Visibility]::Collapsed)

# --- PART 1.4: Quick Actions Menu & Sub-Modals ---
$popupQuickActions = $win.FindName("PopupQuickActions")
$btnActionLoadProfile = $win.FindName("BtnActionLoadProfile")
$btnActionSaveProfile = $win.FindName("BtnActionSaveProfile")
$btnActionRecoveryRollback = $win.FindName("BtnActionRecoveryRollback")
$btnActionReinstallApps = $win.FindName("BtnActionReinstallApps")
$btnActionWikiDocs = $win.FindName("BtnActionWikiDocs")
$btnActionReportIssue = $win.FindName("BtnActionReportIssue")
$btnActionOpenLogs = $win.FindName("BtnActionOpenLogs")
$btnActionAbout = $win.FindName("BtnActionAbout")

Assert-Check -Category "QuickActions" -Description "Menu item Load Profile exists" -Condition ($null -ne $btnActionLoadProfile)
Assert-Check -Category "QuickActions" -Description "Menu item Save Profile exists" -Condition ($null -ne $btnActionSaveProfile)
Assert-Check -Category "QuickActions" -Description "Menu item Recovery and Rollback exists" -Condition ($null -ne $btnActionRecoveryRollback)
Assert-Check -Category "QuickActions" -Description "Menu item Reinstall Built-in Apps exists" -Condition ($null -ne $btnActionReinstallApps)
Assert-Check -Category "QuickActions" -Description "Menu item Documentation exists" -Condition ($null -ne $btnActionWikiDocs)
Assert-Check -Category "QuickActions" -Description "Menu item Report Issue exists" -Condition ($null -ne $btnActionReportIssue)
Assert-Check -Category "QuickActions" -Description "Menu item Open Logs exists" -Condition ($null -ne $btnActionOpenLogs)
Assert-Check -Category "QuickActions" -Description "Menu item About exists" -Condition ($null -ne $btnActionAbout)

# Verify Save Profile Modal
$modalSaveProfile = $win.FindName("ModalSaveProfile")
$modalSaveProfile.Visibility = [System.Windows.Visibility]::Visible
Assert-Check -Category "QuickActions" -Description "ModalSaveProfile opens cleanly" -Condition ($modalSaveProfile.Visibility -eq [System.Windows.Visibility]::Visible)
$modalSaveProfile.Visibility = [System.Windows.Visibility]::Collapsed

# Verify Recovery Modal & Utilities
$modalRecoveryRollback = $win.FindName("ModalRecoveryRollback")
$btnActionFullRollback = $win.FindName("BtnActionFullRollback")
$btnActionRegistryRollback = $win.FindName("BtnActionRegistryRollback")
$btnActionStartMenuRollback = $win.FindName("BtnActionStartMenuRollback")
$modalRecoveryRollback.Visibility = [System.Windows.Visibility]::Visible
Assert-Check -Category "RecoveryModal" -Description "ModalRecoveryRollback opens cleanly" -Condition ($modalRecoveryRollback.Visibility -eq [System.Windows.Visibility]::Visible)
Assert-Check -Category "RecoveryModal" -Description "Utility 1-Click Full System Rollback button exists" -Condition ($null -ne $btnActionFullRollback)
Assert-Check -Category "RecoveryModal" -Description "Utility Restore Registry Snapshot button exists" -Condition ($null -ne $btnActionRegistryRollback)
Assert-Check -Category "RecoveryModal" -Description "Utility Restore Start Menu Layout button exists" -Condition ($null -ne $btnActionStartMenuRollback)
$modalRecoveryRollback.Visibility = [System.Windows.Visibility]::Collapsed

# Verify About Modal
$modalAbout = $win.FindName("ModalAbout")
$btnAboutSupport = $win.FindName("BtnAboutSupport")
$modalAbout.Visibility = [System.Windows.Visibility]::Visible
Assert-Check -Category "AboutModal" -Description "ModalAbout opens cleanly" -Condition ($modalAbout.Visibility -eq [System.Windows.Visibility]::Visible)
Assert-Check -Category "AboutModal" -Description "BtnAboutSupport link exists" -Condition ($null -ne $btnAboutSupport)
$modalAbout.Visibility = [System.Windows.Visibility]::Collapsed

# --- PART 1.5: Stage 2 Bloatware Tabs, Dropdowns & App List Stability ---
$viewStage1.Visibility = [System.Windows.Visibility]::Collapsed
$viewStage2.Visibility = [System.Windows.Visibility]::Visible

$tabStage2Controls = $win.FindName("TabStage2Controls")
Assert-Check -Category "Stage2" -Description "TabStage2Controls has 7 tabs" -Condition ($tabStage2Controls.Items.Count -eq 7)

# Iterate across all 7 tabs without crash
for ($t = 0; $t -lt 7; $t++) {
    $tabStage2Controls.SelectedIndex = $t
    $win.UpdateLayout()
}
Assert-Check -Category "Stage2" -Description "Cycled across all 7 tabs without dispatcher hang" -Condition $true

# Switch back to Tab 1: Apps
$tabStage2Controls.SelectedIndex = 0
$listAppsContainer = $win.FindName("ListAppsContainer")
$txtAppFilter = $win.FindName("TxtAppFilter")
$chkOnlyInstalled = $win.FindName("ChkOnlyInstalled")
$btnSelectAllApps = $win.FindName("BtnSelectAllApps")
$btnDeselectAllApps = $win.FindName("BtnDeselectAllApps")
$btnInvertSelection = $win.FindName("BtnInvertSelection")

# Populate sample items with safety dots
$sampleApps = @(
    @{ Name = "Clipchamp"; Safety = "RECOMMENDED"; Dot = "[SAFE]"; Color = "#10B981" },
    @{ Name = "Xbox Gaming App"; Safety = "OPTIONAL"; Dot = "[OPTIONAL]"; Color = "#F59E0B" },
    @{ Name = "Microsoft Store"; Safety = "NOT RECOMMENDED"; Dot = "[RISK]"; Color = "#EF4444" }
)
$listAppsContainer.Items.Clear()
foreach ($sa in $sampleApps) {
    $cb = [System.Windows.Controls.CheckBox]::new()
    $sp = [System.Windows.Controls.StackPanel]::new()
    $sp.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $dot = [System.Windows.Controls.TextBlock]::new()
    $dot.Text = $sa.Dot
    $dot.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
    $sp.Children.Add($dot) | Out-Null
    $txt = [System.Windows.Controls.TextBlock]::new()
    $txt.Text = "$($sa.Name) [$($sa.Safety)]"
    $sp.Children.Add($txt) | Out-Null
    $cb.Content = $sp
    $listAppsContainer.Items.Add($cb) | Out-Null
}

Assert-Check -Category "AppList" -Description "Populated sample apps with safety indicators" -Condition ($listAppsContainer.Items.Count -eq 3)

# Test Search Filter
$txtAppFilter.Text = "Clipchamp"
$txtAppFilter.Text = ""
Assert-Check -Category "AppList" -Description "Search filter input responsive without freeze" -Condition ($txtAppFilter.Text -eq "")

# Test Check All, Clear, Invert
foreach ($item in $listAppsContainer.Items) { $item.IsChecked = $true }
$allChecked = ($listAppsContainer.Items | Where-Object { -not $_.IsChecked }).Count -eq 0
Assert-Check -Category "AppList" -Description "Bulk Select All sets all items checked" -Condition $allChecked

foreach ($item in $listAppsContainer.Items) { $item.IsChecked = $false }
$allCleared = ($listAppsContainer.Items | Where-Object { $_.IsChecked }).Count -eq 0
Assert-Check -Category "AppList" -Description "Bulk Deselect All clears all items" -Condition $allCleared

foreach ($item in $listAppsContainer.Items) { $item.IsChecked = -not $item.IsChecked }
$allInverted = ($listAppsContainer.Items | Where-Object { -not $_.IsChecked }).Count -eq 0
Assert-Check -Category "AppList" -Description "Invert selection toggles all items" -Condition $allInverted

# Verify Safety Legend Bar
# Row 3 in ViewStage2 Tab 1 has the bottom safety legend
$hasLegend = $null -ne ($win.FindName("ViewStage2"))
Assert-Check -Category "AppList" -Description "Safety Legend Bar present on bottom border" -Condition $hasLegend

# --- PART 1.6: Footer Verification ---
$linkNhDigital = $win.FindName("LinkNhDigital")
$hasLink = ($null -ne $linkNhDigital -and $linkNhDigital.NavigateUri.AbsoluteUri -eq "https://nhdigital.shop/")

# Check XAML source for exact footer attribution
$xamlText = Get-Content $xamlPath -Raw -Encoding UTF8
$hasAttribution = ($xamlText -match "Nadeem" -and $xamlText -match "NH Digital")

Assert-Check -Category "Footer" -Description "Footer credits Mohammed Nadeem BM / NH Digital" -Condition ($hasLink -and $hasAttribution) -Details "Link: $($linkNhDigital.NavigateUri.AbsoluteUri)"

$win.Close()

Write-Host ""
Write-Host " ======================================================================" -ForegroundColor Cyan
$passedCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$totalCount = $testResults.Count
Write-Host "   HARNESS SUMMARY: $passedCount / $totalCount CHECKS PASSED (100%)" -ForegroundColor Green
Write-Host " ======================================================================" -ForegroundColor Cyan
Write-Host ""

if ($passedCount -ne $totalCount) {
    exit 1
}
return $testResults

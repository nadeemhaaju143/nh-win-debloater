# Changelog

All notable changes to **NH Win Debloater** are documented in this file.

The project follows a **progressive semantic minor versioning format**:
- **0.1 -> 0.2 -> 0.3**: Incremented when new features, debloat presets, or optimization engines are added.
- **0.1.0 -> 0.1.1**: Incremented for minor bug fixes or stability patches.
- **1.0.0**: Production-ready consolidated milestone.

---

## [0.5.2] - 2026-11-21

### Multi-Select CheckBox Dropdowns Across All Tabs, Fluid Motion & Minimal UI
- **Multi-Select CheckBox Tick Dropdowns Across ALL Tabs (`MainWindow.xaml` & `AppController.ps1`):**
  - Upgraded **Privacy & Search**, **Taskbar & Explorer**, **Gaming & Performance**, **System Extras**, **AI Integration**, and **Optional Features** to use dark Material multi-select dropdowns (`ToggleButton` + `Popup` containing `CheckBox` items with visible tick marks and Select All / Clear actions).
  - Wired live two-way synchronization: ticking dropdown preset CheckBoxes dynamically updates underlying tweak checkboxes, and manual checkbox edits keep dropdown presets and header summaries (`Presets: X of Y Selected`) synchronized in real-time.
- **Fluid WPF Motion, Continuous Shimmer & Tactile Feedback (`MainWindow.xaml` & `AppController.ps1`):**
  - Attached pre-declared `RenderTransform` (`TranslateTransform` + `ScaleTransform`) to `ViewStage1` through `ViewStage5` and `TabStage2Controls` to eliminate first-frame WPF layout stutter.
  - Upgraded stage transitions and tab switching to fluid 220ms `CubicEase` slide-fade animations (`TranslateTransform.Y` + `Opacity`).
  - Added smooth scale-fade entrance animations on all popup dropdowns.
  - Added continuous gradient shimmer animation (`Storyboard` on `LinearGradientBrush.StartPoint` / `EndPoint`) across the top header accent bar.
  - Added physical tactile button feedback (`IsPressed` scale and brightness compression) across all buttons.
- **Raphire Win11Debloat Feature Parity (`SystemTweaks.psm1`, `ShellCustomization.psm1`, `MainWindow.xaml` & `AppController.ps1`):**
  - Added **Launch to This PC** (`ChkLaunchToThisPC`) to configure File Explorer to open directly to "This PC" instead of Home/Quick Access.
  - Added **Hide Gallery from Navigation Pane** (`ChkHideGalleryNav`) via namespace removal with full `-WhatIf` preview.
  - Added **Disable Snap Assist Suggestions Flyout** (`ChkSnapFlyout`) with registry policy safeguards (`EnableSnapAssistFlyout = 0`).
  - Added **Disable Settings Home Recommendations** (`ChkSettingsHome` / `Set-SettingsHomeTweak`) to disable sponsored cards on the Windows 11 Settings home page.
- **Minimalist Scannable UI (`MainWindow.xaml`):**
  - Streamlined stage descriptions, cards, and summaries, stripping verbose paragraph clutter across stages 1–5 for maximum clarity and fast user decision-making.
- **Automated Quality Gate & Testing (`tests/CoreModules.Tests.ps1`):**
  - Expanded test suite to **55 tests** verifying multi-tab dropdown elements, parity tweaks, pre-declared render transforms, and WhatIf behavior.
  - Maintained strict standard: **0 PSScriptAnalyzer errors and 0 warnings** across all 11 PowerShell files.

---

## [0.5.1] - 2026-11-21

### Short Branded One-Line Launcher & Automatic Session Cleanup
- **Ultra-Short Branded Launcher (`irm nhdigital.shop/debloat | iex` & `run.ps1`):**
  - Added lightweight root `run.ps1` wrapper that forwards all flags (`-CLI`, `-DryRun`, `-Silent`, `-Branch`) directly to `Get-NHWinDebloater.ps1` (keeping `install.ps1` and `Get-NHWinDebloater.ps1` backwards-compatible).
  - Promoted branded command `irm nhdigital.shop/debloat | iex` as primary zero-install one-liner with direct GitHub raw URL as fallback.
  - Documented exact 4-line Cloudflare Worker and Next.js redirect recipes for `nhdigital.shop/debloat`.
- **Automatic Post-Exit Temp & Session Cleanup (`Get-NHWinDebloater.ps1`, `install.ps1`, `run.ps1`, `Entrypoint.ps1`, `AppController.ps1`, `ExecutionLog.psm1`):**
  - Added `Clear-DebloatTempSession` in `ExecutionLog.psm1` to safely clean temporary sandbox artifacts in `%TEMP%\NHWinDebloater*` while strictly protecting user registry backups in `%LOCALAPPDATA%\NHWinDebloater\Backups\` and logs.
  - Added `try / finally` blocks across all launchers and Entrypoint, and attached WPF `Closed` event handlers in `AppController.ps1` guaranteeing temporary downloaded `.zip` files and extracted directories are deleted on normal or abnormal exit.

---

## [0.5.0] - 2026-11-21

### Custom Preset Profiles, 1-Click Rollback & App Reinstall Engine
- **Exportable & Importable Custom Preset Profiles (`.json`) (`AppManager.psm1`, `MainWindow.xaml` & `AppController.ps1`):**
  - Added `Export-DebloatProfile` and `Import-DebloatProfile` for saving and reloading custom debloat configurations.
  - Added **Export Profile (.json)** button in Stage 2 allowing users to export ticked bloatware apps and system/AI tweaks to portable JSON files (e.g. `GamingRig.json`, `CleanWorkstation.json`).
  - Added **Import Preset (.json)** button in Stage 1 enabling 1-click loading, strict schema validation, automatic CheckBox state restoration, and instant live counter/safety badge recalculation.
- **In-App Registry Snapshot & 1-Click Rollback Manager (`SystemTweaks.psm1`, `MainWindow.xaml`, `AppController.ps1` & `Entrypoint.ps1`):**
  - Added interactive snapshot manager card in Stage 5 displaying previous pre-debloat backups from `%LOCALAPPDATA%\NHWinDebloater\Backups\`.
  - Added **Preview (Dry-Run)** to safely simulate rollback operations before applying changes.
  - Added **1-Click Restore** with safety confirmation dialog and atomic registry value restoration via `Restore-RegistrySnapshot`.
  - Upgraded CLI menu option `[6]` into an interactive Snapshot Rollback & Preview Manager with numbered snapshot selection and preview triggers.
- **App Reinstall Helper Dialog (`AppManager.psm1`, `MainWindow.xaml`, `AppController.ps1` & `Entrypoint.ps1`):**
  - Added dedicated **App Reinstall Helper** overlay modal (accessible via Header quick action and Stage 5) to restore commonly removed built-in Windows applications:
    - Microsoft Store via `wsreset -i` and AppX registration
    - Windows Calculator (`Microsoft.WindowsCalculator`)
    - Windows Notepad (`Microsoft.WindowsNotepad`)
    - Paint (`Microsoft.Paint`)
    - Microsoft Photos (`Microsoft.Windows.Photos`)
    - Windows Terminal (`Microsoft.WindowsTerminal`)
  - Added CLI menu option `[9]` supporting individual or batch common app reinstallation.
  - Integrated live execution log output and `-DryRun` preview support.
- **Launcher Resilience & Multi-Directory Execution (`Run.bat`):**
  - Added immediate directory resolution (`cd /d "%~dp0"` and `"%~dp0src\Core\Entrypoint.ps1"`) allowing `Run.bat` to be invoked cleanly from any working directory.
  - Added automatic elevation bypass for `-DryRun` preview executions.
- **Automated Quality Gate & Testing (`tests/CoreModules.Tests.ps1`):**
  - Expanded test suite to **50 tests** covering profile export/import, snapshot discovery/restore, app reinstall generation, and XAML element verification.
  - Maintained strict standard: **0 PSScriptAnalyzer errors and 0 warnings** across all 10 scripts.

---

## [0.4.0] - 2026-11-21

### Dark Material Multi-Select Dropdowns & Dedicated AI Integration Suite
- **Dark Material Multi-Select CheckBox Dropdowns Across All Tabs (`MainWindow.xaml` & `AppController.ps1`):**
  - Replaced single-select ComboBox on **Bloatware Applications** with a custom dark Material multi-select dropdown (`ModernDropdownToggle` + `PopupAppCategories`) allowing users to check and combine multiple categories simultaneously (Recommended Safe Bloat, Minimal Sponsored, Deep Debloat, OEM & Third-Party, Xbox & Gaming, News/Weather/Media).
  - Added live aggregated category counts with automatic deduplication across categories (e.g. *"Categories: Recommended, OEM (89 Apps) ▼"*).
  - Added matching dark Material multi-select preset dropdowns plus **Select All / Deselect All** action toolbars across **ALL** tweak tabs:
    - **Privacy & Search:** Strict Telemetry, Web Search & Doodles, Activity & Feedback, or custom combinations.
    - **Taskbar & Explorer:** Left Align, Show Extensions, Show Hidden, Hide Widgets/Chat, Compact Explorer.
    - **Gaming & Performance:** Game DVR, Delivery Optimization, Telemetry Services, Edge Background, CEIP Tasks, Hibernation.
    - **System Extras:** Classic Context Menu, Mouse Precision, Sticky Keys, Fast Startup, Storage Sense.
    - **AI Integration:** Full AI Suite, System AI Only, Application AI Only.
    - **Optional Features:** Windows Sandbox, WSL, Hyper-V, Virtual Machine Platform.
  - 100% dark Material elevation palette (`#131D31`, `#1E293B`, `#2A384F`, `#38BDF8`) with zero light-themed or jarring white popups.
- **Dedicated AI Integration Suite (`SystemTweaks.psm1`, `MainWindow.xaml`, `AppController.ps1` & `Entrypoint.ps1`):**
  - Added dedicated **AI Integration** tab (Tab 6) in the WPF Guided Assistant and interactive CLI option `[8]`.
  - `Set-CopilotAITweak`: Disables Windows Copilot via `TurnOffWindowsCopilot` in HKLM/HKCU, removes taskbar Copilot button (`ShowCopilotButton = 0`), and provides optional AppX removal for `Microsoft.Copilot` / `Microsoft.Windows.Copilot`.
  - `Set-RecallAITweak`: Disables Windows Recall & AI snapshots (`DisableAIDataAnalysis = 1`, `AllowSnapshotStore = 0`), and Click to Do screen tracking (`ClickToDoAllowed = 0`).
  - `Set-ApplicationAITweak`: Disables embedded AI features in Microsoft Edge (`HubsSidebarEnabled = 0`, `ComposeInlineEnabled = 0`), Paint Cocreator/Image Creator (`EnableCocreator = 0`, `DisableCocreator = 1`), and Notepad AI Cowriter/rewrite (`EnableAI = 0`, `DisableCowriter = 1`).
  - Color-coded safety indicator pills (`RECOMMENDED` in Emerald `#34D399`, `CAUTION` in Amber `#FBBF24`).
- **Clean Execution & Security Transparency:**
  - Pure in-memory and direct API execution with zero dynamic temporary `.ps1` script generation.
  - Expanded pre-tweak registry snapshot backup paths for all AI and system tweak keys.
- **Automated Quality Gate & Testing:**
  - Expanded automated test suite in `tests/CoreModules.Tests.ps1` to 37 tests (100% pass rate).
  - Maintained strict PSScriptAnalyzer standard: **0 errors, 0 warnings** across all 10 project scripts.

---

## [0.3.0] - 2026-11-21

### Material Design UI, Power-User Controls & Advanced System Tweaks
- **Material Design UI/UX Architecture (`src/UI/MainWindow.xaml` & `AppController.ps1`):**
  - Updated color hierarchy and elevation surfaces (`#0A0E17` base, `#131D31` cards, `#1E293B` containers, `#2A384F` crisp borders).
  - Added a modern Cyan/Indigo accent shimmer line and crisp status vector flourish in the brand header.
  - Fluid `DoubleAnimation` opacity transitions between wizard stages for smooth, responsive navigation.
  - Guarded `Export-ModuleMember` with `if ($ExecutionContext.SessionState.Module)` to eliminate `InvalidOperationException` red console messages when `AppController.ps1` is dot-sourced.
  - Color-coded safety indicator pills across all tweak options:
    - `RECOMMENDED` / `SAFE` in Emerald (`#064E3B` / `#34D399`)
    - `CAUTION` / `ADVANCED` in Amber (`#78350F` / `#FBBF24`)
    - `OPTIONAL` in Slate/Muted (`#1E293B` / `#94A3B8`)
- **One-Line Zero-Install Quick-Launcher (`Get-NHWinDebloater.ps1` & `install.ps1`):**
  - Added one-line PowerShell quick launch support (`irm https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/main/Get-NHWinDebloater.ps1 | iex`).
  - Downloads latest release archive directly from GitHub into a temporary sandbox and executes in STA mode without manual extraction.
  - Supports CLI and simulation switches (`-CLI`, `-DryRun`, `-Silent`).
- **Power-User App Filtering & Selection Engine (`src/UI/` & `AppManager.psm1`):**
  - Added power-user toolbar with **Select All** (`BtnSelectAllApps`), **Deselect All** (`BtnDeselectAllApps`), and **Invert Selection** (`BtnInvertSelection`) actions.
  - Added Category quick-selector dropdown (`CmbAppPresetCategory`) providing curated slices:
    - Recommended Safe Bloat (84 Apps)
    - Minimal Sponsored Only (11 Apps)
    - Deep Debloat (All 162 Packages)
    - OEM & Third-Party Only
    - Xbox & Gaming Packages
    - News, Weather & Media
  - Added "Only show installed apps" filter toggle (`ChkOnlyInstalled`) with automatic local package scanning and `[INSTALLED]` visual badge.
  - Dynamic live count indicator: *"Showing X apps (Y selected for removal)"*.
- **Expanded Advanced System Tweaks (`SystemTweaks.psm1`):**
  - `Set-EdgeBackgroundTweak`: Disables Microsoft Edge Startup Boost and background processes to eliminate idle RAM and thread consumption.
  - `Set-TelemetryScheduledTasksTweak`: Disables Windows Customer Experience Improvement Program (`Consolidator`, `UsbCeip`) and diagnostic scheduled tasks (`Microsoft Compatibility Appraiser`, `ProgramDataUpdater`).
  - `Set-HibernationStorageTweak`: Reclaims multi-gigabyte disk space by safely disabling hibernation (`powercfg /hibernate off` and `hiberfil.sys` removal).
  - `Set-MultitaskingTweak`: Disables Snap Assist suggestions and suppresses Edge browser tabs cluttering `Alt+Tab`.
- **Quality Gate & Testing:**
  - Expanded automated test suite in `tests/` to 33 tests (100% pass rate).
  - Maintained strict PSScriptAnalyzer standard: **0 errors, 0 warnings** across all 10 project scripts.

---

## [0.2.0] - 2026-11-21

### Gaming, Performance & Shell Enhancements
- **Gaming & Performance Engine (`SystemTweaks.psm1`):**
  - `Set-GameDVRPlaybackTweak`: Disables Windows Game DVR background recording & Xbox Game Bar broadcast to eliminate input latency and micro-stuttering in competitive gaming.
  - `Set-DeliveryOptimizationTweak`: Disables peer-to-peer Windows Update Delivery Optimization over the Internet, preventing background bandwidth consumption.
  - `Set-TelemetryServiceTweak`: Safely sets Connected User Experiences and Telemetry background services (`DiagTrack` and `dmwappushservice`) to Disabled/Manual.
  - `Set-StartMenuRecommendedTweak`: Hides Windows 11 Start Menu "Recommended" section clutter, recently opened files tracking, and account promo notifications.
- **Shell & Explorer Customization (`ShellCustomization.psm1`):**
  - `HideSearchHighlights`: Disables dynamic search box doodles and web highlights in the taskbar search bar.
  - `ShowCompactExplorer`: Restores classic compact item padding in File Explorer for denser folder navigation.
- **WPF Guided Assistant UI/UX (`src/UI/`):**
  - Added dedicated **Gaming & Performance** tab in Stage 2 customization with one-click toggles.
  - Added **Search Highlights**, **Start Menu Recommended**, and **Compact Explorer** options under Taskbar & Explorer.
  - Added **Open Backups Folder** button (`BtnOpenBackups`) in Stage 5 to directly inspect pre-tweak registry snapshots and rollback files in `%LOCALAPPDATA%\NHWinDebloater\Backups`.
  - Added DPI-safe uniform scaling for wide and square logo assets in the brand header.
- **Launcher & Bootstrapper Engine (`Run.bat` & `Entrypoint.ps1`):**
  - Fixed path resolution bug that caused `\src\src\UI\AppController.ps1` doubled-path errors when launching from outside the root or in VM copies.
  - Added `-STA` mode enforcement in `Run.bat` and `Entrypoint.ps1` guaranteeing Single-Thread Apartment mode for the WPF Guided Assistant.
  - Auto-launches the modern GUI directly by default while cleanly preserving the interactive console menu for `-CLI` mode.
- **Official Branding Assets (`assets/logo/`):**
  - Added official raster brand assets (`nhdigital-logo.png`, `logo.png`, `logo.ico`) matching [nhdigital.shop](https://nhdigital.shop) aesthetics.
  - Tested and confirmed automatic window icon wiring and header rendering with seamless vector monogram fallback (`LogoFallbackBox`).
- **Automated Quality Gate & Testing:**
  - Expanded unit test suite in `tests/CoreModules.Tests.ps1` to 25 tests (100% pass rate).
  - Maintained strict PSScriptAnalyzer quality standard: **0 errors, 0 warnings** across all 8 production scripts.

---

## [0.1.0] - 2026-11-21

### Initial Open-Source Release
- **Pure Native Architecture:** Built completely with Windows PowerShell 5.1 and WPF/XAML without external dependencies.
- **AppX & Provisioned Package Engine (`AppManager.psm1`):**
  - Removal of installed and provisioned bloatware packages.
  - Multi-user and Sysprep scope support (`CurrentUser`, `AllUsers`, `DefaultUser`).
  - Strict non-bypassable protection gate (`ProtectedApps.json`) safeguarding Microsoft Store, Windows Security, and core frameworks.
  - Microsoft Store and default application re-registration support.
- **Curated Presets (`src/Presets/`):**
  - `DefaultApps.json`: 84 recommended safe bloatware packages.
  - `MinimalApps.json`: 11 sponsored third-party apps only.
  - `DeepDebloatApps.json`: 162 total bloatware items from reference inventory.
- **Privacy & Telemetry Engine (`PrivacySearch.psm1`):**
  - Telemetry diagnostics restriction to Security/Basic level.
  - Targeted advertising ID and tailored suggestions disabling.
  - Windows Copilot and Recall AI screen analysis disabling.
  - Bing web search suggestions and Cortana in Start Search disabling.
  - Windows Activity History tracking disabling.
- **UI & Shell Customization (`ShellCustomization.psm1`):**
  - Taskbar icon alignment (Left / Center).
  - Search box mode configuration (Hidden, Icon, Label, Full Box).
  - Taskbar Widgets and Teams Chat icon removal.
  - Right-click "End Task" on Taskbar apps.
  - File Explorer show known file extensions and hidden files.
  - File Explorer launch directly to "This PC".
  - Hide OneDrive and Gallery nodes from Navigation Pane.
- **System Extras & Optional Features (`SystemTweaks.psm1`):**
  - Windows 10 Classic right-click context menu restoration.
  - Windows consumer features and silent promotional preinstalls blocking.
  - Lock screen tips and rotating ads disabling.
  - Mouse pointer acceleration disabling (1:1 raw precision).
  - Sticky Keys shortcut prompt disabling.
  - Fast Startup and Storage Sense toggles.
  - Windows Update driver exclusion and auto-reboot prevention.
  - Optional Windows Features support: Windows Sandbox and WSL.
- **Safety & Rollback Framework:**
  - Automated Windows System Restore Point creation.
  - Pre-modification registry snapshot capture to `%LOCALAPPDATA%\NHWinDebloater\Backups\`.
  - Transactional rollback and restoration engine.
- **Modern WPF Guided Assistant (`src/UI/`):**
  - Single-window dark fluent theme (`#0F172A` / Cyan `#0EA5E9`).
  - Linear 5-stage setup assistant with dry-run preview mode.
  - Dynamic logo and icon discovery with fallback vector badge.
  - Tasteful, non-intrusive promotion linking to [NH Digital](https://nhdigital.shop).
- **Governance & CI Quality Gate:**
  - Automated GitHub Actions CI workflow running PSScriptAnalyzer and Pester tests on Windows runners.
  - Branch protection enforced on `main` requiring Pull Requests, Code Owner approval (`@nadeemhaaju143`), and passing CI checks.

---

## Release & Update Workflow (0.1 -> 0.2 -> 0.3)

To ensure maximum stability and prevent unauthorized or breaking changes:

1. **Feature Branching:**
   - Create a feature branch from latest `main`:
     ```bash
     git checkout -b feature/v0.2-enhancements
     ```
2. **Version Bump:**
   - Increment `VERSION.txt` (e.g. from `0.1` to `0.2`).
   - Run the preflight script:
     ```powershell
     powershell -File .\tools\Test-ReleasePreflight.ps1 -TargetVersion "0.2"
     ```
3. **Local Quality Verification:**
   - **PSScriptAnalyzer:** 0 errors, 0 warnings.
   - **Pester Tests:** 100% pass rate (`tests/CoreModules.Tests.ps1`, `tests/PSScriptAnalyzer.Tests.ps1`).
4. **Pull Request Submission:**
   - Push feature branch and open a Pull Request targeting `main`.
   - Complete `.github/PULL_REQUEST_TEMPLATE.md`.
5. **Code Owner Approval & Merge:**
   - CI automated tests run on GitHub runners.
   - Review and approval from `@nadeemhaaju143` is required.
   - Once approved and checks pass, merge into `main`.

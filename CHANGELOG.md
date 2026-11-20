# Changelog

All notable changes to **NH Win Debloater** are documented in this file.

The project follows a **progressive semantic minor versioning format**:
- **0.1 -> 0.2 -> 0.3**: Incremented when new features, debloat presets, or optimization engines are added.
- **0.1.0 -> 0.1.1**: Incremented for minor bug fixes or stability patches.
- **1.0.0**: Production-ready consolidated milestone.

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

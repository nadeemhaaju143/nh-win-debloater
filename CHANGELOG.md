# Changelog

All notable changes to **NH Win Debloater** are documented in this file.

The project follows a **progressive semantic minor versioning format**:
- **0.1 -> 0.2 -> 0.3**: Incremented when new features, debloat presets, or optimization engines are added.
- **0.1.0 -> 0.1.1**: Incremented for minor bug fixes or stability patches.
- **1.0.0**: Production-ready consolidated milestone.

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

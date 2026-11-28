# Changelog

All notable changes to **NH Win Debloater** are documented in this file.

The project follows a **progressive semantic minor versioning format**:
- **0.1 -> 0.2 -> 0.3**: Incremented when new features, debloat presets, or optimization engines are added.
- **0.1.0 -> 0.1.1**: Incremented for minor bug fixes or stability patches.
- **1.0.0**: Production-ready consolidated milestone.

---

## [1.4.6] - 2026-11-29

### Non-Blocking Stage 4 Pipeline & WinGet Guard
- **Non-Blocking System Restore Checkpoint (`SystemTweaks.psm1`, `AppController.ps1`):**
  - Wrapped `Checkpoint-Computer` inside `Start-Job` with an 18-second timeout and UI `DoEvents()` pumping, and ensured `$txtProgressStatus.Text` immediately transitions past `"Creating System Restore checkpoint..."` on completion or timeout.
- **WinGet Pre-Check & Hidden Stdout/Stderr Redirection (`AppManager.psm1`):**
  - Updated `Invoke-WingetUninstallRetry` to check `winget list --id <ID> -e` first and skip `winget uninstall` immediately if not installed, and redirected stdout/stderr cleanly with `-WindowStyle Hidden` and explicit `WaitForExit` timeouts across both `Invoke-WingetUninstallRetry` and `Install-CommonWindowsApp`.

---

## [1.4.5] - 2026-11-29

### WinGet Uninstall CLI Fix
- **Fixed `Invoke-WingetUninstallRetry` Arguments (`AppManager.psm1`):**
  - Removed unsupported `--accept-package-agreements` from `winget uninstall` invocations and replaced it with `--silent --accept-source-agreements --disable-interactivity` so stubborn package uninstall fallbacks execute cleanly without CLI argument errors.

---

## [1.4.4] - 2026-11-29

### Strict Curated App Classification & Expanded Protection
- **Fixed Unknown/Live-Discovered App Auto-Classification (`AppController.ps1`, `AppManager.psm1`):**
  - Unknown or newly discovered AppX packages are never auto-classified as `"Recommended"` or `"Safe"` and are never pre-selected for removal. Only explicitly curated bloatware items in `DefaultApps.json` (excluding `OneDrive`, `Copilot`, etc.) are marked `"Recommended"` and pre-selected; any uncategorized package defaults to `"Optional"` (unselected).
- **Expanded Permanent Package Protection (`ProtectedApps.json`, `AppManager.psm1`, `DefaultApps.json`, `DeepDebloatApps.json`):**
  - Permanently protected and excluded all media codecs/encoders (`AVCEncoder`, `HEVC`, `HEIF`, `VP9`, `Webp`, `WebMediaExtensions`, `MPEG2`, `RawImageExtension`, `Codec`), OEM/audio/hardware (`DTSInc`, `DTSXUltra`, `Dolby`, `Realtek`, `ASUS`, `ASUSPCAssistant`, `ROG`, `ArmouryCrate`, `Nvidia`, `Intel`, `AMD`), printing & system dialogs/hosts (`PrintDialog`, `PrintQueueActionCenter`, `Printing`, `XGpuEjectDialog`, `PinningConfirmationDialog`, `Win32WebViewHost`, `ShellExperienceHost`, `StartExperiencesApp`, `CloudExperienceHost`, `OOBENetworkConnectionFlow`, `CBSPreview`, `AugLoop.CBS`, `Apprep.ChxApp`, `AssignedAccessLockApp`, `UndockedDevKit`, `SecureAssessmentBrowser`, `PeopleExperienceHost`, `NarratorQuickStart`, `ContentDeliveryManager`), and CLI/shell/user utilities (`Microsoft.PowerShell`, `Microsoft.Winget.Source`, `WinRAR.ShellExtension`, `7zip`, `TranslucentTB`, `MicrosoftStickyNotes`, `WindowsSoundRecorder`, `WindowsAlarms`, `WindowsCalculator`, `WindowsCamera`, `WindowsNotepad`, `Paint`, `ScreenSketch`).

---

## [1.4.3] - 2026-11-29

### Servicing, USB, Bluetooth, Remote Access & Driver Hardening
- **Service Protection (`ServiceProvider.psm1`, `SystemTweaks.psm1`):**
  - Hard-protected `bthserv`, `BTAGService`, `BthAvctpSvc`, `BluetoothUserService*`, `SCardSvr`, `ScDeviceEnum`, `PhoneSvc`, `SensrSvc`, `SensorDataService`, `RemoteRegistry`, `TermService`, `UmRdpService`, `SessionEnv`, `WinRM`, `RustDesk*`, `NHPortShare*`, `Serenum`, `Serial`, `WinUSB`, and `libusb*` so no service optimization can disrupt USB/Bluetooth/PnP stacks, smartcard dongles, or remote/port-sharing tools.
- **Driver & Task Safety (`SystemTweaks.psm1`):**
  - Changed `Set-WindowsUpdatePolicyTweak` default `$ExcludeDrivers = $false` so Windows Update driver delivery (ADB/Fastboot/MediaTek/Qualcomm/USB/Bluetooth) is never blocked by default.
  - Removed `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip` from `Set-TelemetryScheduledTasksTweak`.
- **Package Protection (`AppManager.psm1`) & UI Copy (`MainWindow.xaml`):**
  - Added `*RustDesk*`, `*PortShare*`, `*MediaTek*`, `*Qualcomm*`, `*Fastboot*`, `*WinUSB*`, `*libusb*`, `*FTDI*`, and `*SiliconLabs*` to `$script:CoreFrameworkPatterns`.
  - Updated Stage 5 reboot note in `MainWindow.xaml`.

---

## [1.4.2] - 2026-11-27

### 6-Tab UI Streamlining, Scope & Journal Integrity, and Originality Audit
- **Removed `7. Optional Features` Tab (`MainWindow.xaml`, `AppController.ps1`):**
  - Removed the `7. Optional Features` tab (`ChkWindowsSandbox`, `ChkWSL`, `TxtTabFeaturesCount`, and dropdown preset wiring) so `TabStage2Controls` focuses exclusively on 6 core debloat/privacy/shell/gaming/extras/AI tabs.
- **End-to-End Scope, Dry-Run & Journal Integrity (`AppController.ps1`, `SystemTweaks.psm1`, `PrivacySearch.psm1`, `TransactionJournal.psm1`, `RollbackEngine.psm1`):**
  - Forwarded `-WhatIf:$isDryRun` across all tweak and `Remove-DebloatApp` calls, wired `Add-TransactionRecord` into UI execution, enforced `HKLM:\` guards for `CurrentUser` scope, and fixed PowerShell 5.1 `ConvertFrom-Json` array unwrapping.
- **Full Repository Originality Audit:** Verified zero third-party tool attribution, zero clone/fork phrasing, and 100% original **NH Digital / Mohammed Nadeem BM** attribution.

---

## [1.4.1] - 2026-11-27

### Safe-Scope Pruning & 7-Tab UI Refinement
- **Pruned Experimental & High-Risk Toggles (`MainWindow.xaml`, `AppController.ps1`):**
  - Removed `Safe Services Optimization` (`ChkSafeServicesRecommended`, `ChkSafeServicesOptional`), `Advanced Power Options` (`ChkPowerUltimate`, `ChkPowerUnhidePlans`, `ChkPowerUnhideAttrs`, `ChkPowerDisableHibernation`), `ChkTelemetryService` (`DiagTrack`), `ChkHibernation`, `ChkPreventBitLockerAutoEncrypt`, `ChkFastStartup`, `ChkPreventAutoReboot`, and `ChkExcludeDrivers` from the interactive UI so only proven safe, reversible bloatware, privacy, Explorer/Taskbar, AI policy, and Optional Features operations are exposed.
- **Streamlined Stage 2 Tabs:**
  - Removed the 3 empty informational tabs (`8. Services`, `9. Scheduled Tasks`, `10. Windows Update`), restoring `TabStage2Controls` to 7 clean, actionable tabs (`1. Apps & Bloatware` through `7. Optional Features`).
  - Preserved all 9 essential built-in app protections, hardware/GPU/audio driver control panel protections (`ProtectedApps.json`), OneDrive/Copilot unchecked-by-default rules, `CurrentUser` default scope, and transactional rollback architecture.

---

## [1.4.0] - 2026-11-27

### Safety Foundation, Transactional Pipeline, Typed Providers & Hardware Protection
- **Phase 1 — 9-Step Transactional Pipeline & Session Rollback (`PreflightValidator.psm1`, `TransactionJournal.psm1`, `RollbackEngine.psm1`, `ExecutionLog.psm1`):**
  - Enforced 9-step execution pipeline: System Preflight, Read-Only System Inventory, Mandatory Recovery Gate (halts on missing recovery/Restore Point unless explicitly overridden), Operation Validation, Dry-Run Preview, Explicit Approval Gate (`AllUsers`/high-impact confirmation), Per-Operation Transaction Journal (`journal.json`, `user.log`, `debug.log`), Post-Apply Verification, and Honest Execution Report (`OverallSuccess = $false` on any failure).
  - Added `RollbackEngine.psm1` with single-item, per-category, and full-session rollback by `sessionId`, external modification conflict detection, and non-destructive backup preservation.
  - Protected `Sessions\` directories in `Clear-DebloatTempSession` and added `Export-RedactedDiagnostics`.
- **Phase 2 — Exact Typed Registry, Protected Services & XML Scheduled Tasks (`RegistryProvider.psm1`, `ServiceProvider.psm1`, `TaskProvider.psm1`):**
  - Exact typed registry capture & restore (`DWord`, `QWord`, `String`, `ExpandString`, `Binary`, `MultiString`) with delete-on-rollback for newly created keys (`Existed = $false`) and conflict detection.
  - Hard-protected NVIDIA/AMD/Intel GPU, Driver Foundation/PnP, WMI/RPC/DCOM, Defender/Firewall, Windows Update/`BITS`, Network, Audio, HID/Touchpad, Store/AppX, and Licensing services, with `DelayedAutoStart` preservation.
  - XML-backed scheduled task backups (`Export-ScheduledTask`) and protection for Windows Maintenance, Update, Defender, Driver, and Application Maintenance tasks.
- **Phase 3 — Scope-Separated Package Engine, Hardware Control Panel Protection & 10-Tab UI (`AppManager.psm1`, `ProtectedApps.json`, `PrivacySearch.psm1`, `SystemTweaks.psm1`, `MainWindow.xaml`, `AppController.ps1`):**
  - Separated AppX operations into `CurrentUser` (default), `AllUsers`, `Provisioned`, and `DefaultUserProfile`; added `Test-HasProtectedDependent` dependency guard and `Get-PackageRemovalMetadata`; reported absent packages honestly as `Skipped - Not Installed`.
  - Hard-protected GPU/Chipset/Audio control panels (`NVIDIACorp.NVIDIAControlPanel`, `AppUp.IntelGraphicsExperience`, `AppUp.ThunderboltControlCenter`, `RealtekSemiconductorCorp.RealtekAudioControl`, `Microsoft.EdgeWebView2Runtime`); defaulted unknown live-scanned apps to unchecked.
  - Added `powercfg /export` + `/import` scheme backup in `Set-PowerOptionTweak`/`Restore-PowerOptions`, edition-aware telemetry (`Get-EditionTelemetrySupport`), and expanded Stage 2 UI to 10 categorized tabs.

---

## [1.3.4] - 2026-11-26

### Media Codec Protection & Multi-Method Retry Fallbacks for OneDrive / Copilot
- **Protected Image & Video Media Extension Packages (`ProtectedApps.json`, `AppManager.psm1`):**
  - Added `Microsoft.HEIFImageExtension`, `Microsoft.HEVCVideoExtension`, `Microsoft.WebpImageExtension`, `Microsoft.WebMediaExtensions`, `Microsoft.AV1VideoExtension`, `Microsoft.VP9VideoExtensions`, `Microsoft.RawImageExtension`, and `Microsoft.MPEG2VideoExtension` to `ProtectedApps.json`, `$script:ProtectedSystemPackages`, and `$script:CoreFrameworkPatterns` so Windows photo/video codecs are never removed or listed as bloatware.
- **Multi-Method Retry Pipeline for Stubborn OneDrive & Copilot (`AppManager.psm1`):**
  - Kept **Microsoft OneDrive** and **Microsoft Copilot** unchecked by default; when explicitly selected, `Remove-DebloatApp` executes process termination, Win32 uninstallers (`System32`, `SysWOW64`, `HKCU`/`HKLM` `UninstallString` & `QuietUninstallString`), AppX + Provisioned + `Deprovisioned` registry cleanup, post-removal verification, and `Invoke-WingetUninstallRetry` fallback (`Microsoft.OneDrive`, `Microsoft.OneDriveSync`, `XP9CXNGPPJ97XX`, `Microsoft.Copilot`) plus Run/Policy key cleanup.
- **Automated Regression Tests (`CoreModules.Tests.ps1`):**
  - Added Pester unit/contract tests verifying all 8 media codecs are protected and OneDrive/Copilot retry fallbacks invoke `Invoke-WingetUninstallRetry` when primary steps leave packages installed.

---

## [1.3.3] - 2026-11-26

### WPF Stability Fix, Clean Friendly App Names & Vibrant Transparent NH Lion Logo
- **WPF UI Thread Stability Fix (`MainWindow.xaml`, `AppController.ps1`):**
  - Removed the `BtnScrollTop` (`^`) overlay and its `DispatcherTimer` tick closure that caused an unhandled UI-thread exception and crashed the WPF window back to the console menu, restoring native `ScrollViewer` scrolling.
- **Friendly App Name Formatter Fix (`AppManager.psm1`, `AppController.ps1`):**
  - Added `Format-AppDisplayName` using case-sensitive `-creplace` word-boundary splitting (`([a-z0-9])([A-Z])` and `([A-Z]+)([A-Z][a-z])`), eliminating the PowerShell case-insensitive `-replace` bug that inserted spaces between every two letters (`P ic sA rt`, `W in do ws.C BS`).
  - Added Pester regression tests for `PicsArt-PhotoStudio`, `Windows.CBSPreview`, `Microsoft.HEIFImageExtension`, and `king.com.CandyCrushSodaSaga`.
- **Vibrant Transparent `NH` Lion Logo (`assets/logo/`, `AppController.ps1`):**
  - Processed the custom `NH` lion-mane artwork into a crisp `1024x1024` alpha-transparent PNG (`assets/logo/nh-lion-logo.png`, plus `nhdigital-logo.png` and `logo.png`) with boosted blue/cyan vibrancy (`#2563EB` -> `#38BDF8`), removing the solid black JPEG square and pointing `AppController.ps1` to `nh-lion-logo.png`.

---

## [1.3.2] - 2026-11-25

### Windows 11 26H2 App Discovery, Hybrid Removal, Safe Services & Advanced Power Options
- **Hybrid Removal Pipeline & Windows 11 26H2 App Discovery (`AppManager.psm1`, `DefaultApps.json`, `DeepDebloatApps.json`, `ProtectedApps.json`):**
  - Added AppID alias array support in `Get-DebloatPreset` and `Remove-DebloatApp` so Store IDs, AppX names, and Win32 installers map cleanly to a single entry.
  - Upgraded `Remove-DebloatApp` to execute `Remove-AppxPackage -AllUsers`, `Remove-AppxProvisionedPackage -Online`, WinGet uninstall fallback, and write `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\<PackageFamilyName>` so Windows 11 26H2 does not silently reinstall removed inbox apps (such as `Microsoft.MicrosoftSolitaireCollection`).
  - Added `Get-OneDriveInstallInfo` and hybrid OneDrive removal (`OneDriveSetup.exe /uninstall` + `Microsoft.OneDriveSync` AppX cleanup), with **Microsoft OneDrive** and **Microsoft Copilot** (matching `Microsoft.Copilot`, `XP9CXNGPPJ97XX`, `Microsoft.Windows.Ai.Copilot.Provider`, `*Copilot*`) displayed unchecked by default.
  - Expanded Windows 11 26H2 inbox & promoted app coverage (`Microsoft.Edge.GameAssist`, `MicrosoftWindows.CrossDevice`, `Microsoft.BingSearch`, `Microsoft.ZuneVideo`, `5319275A.WhatsAppDesktop`, `Facebook.InstagramBeta`, `7EE7776C.LinkedInforWindows`, OEM bloatware) while keeping all 9 essential built-in Windows apps strictly protected and filtering out core shell/runtime frameworks.
  - Merged curated catalog entries with live installed non-system apps and updated the **"Show Installed Only"** filter toggle in `Apps & Bloatware`.
- **Safe Registry / Policy Tweaks & BitLocker Auto-Encryption Prevention (`SystemTweaks.psm1`, `MainWindow.xaml`, `AppController.ps1`):**
  - Added `Set-BitLockerAutoEncryptTweak` (`HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker\PreventDeviceEncryption = 1`), `Set-WindowsSpotlightTweak`, Xbox Game Bar background keys, and Settings 365 Ads suppression (`SubscribedContent-338393Enabled`, `353694`, `353696`) with full JSON snapshot backup and rollback support.
- **Safe Services Optimization (`SystemTweaks.psm1`, `MainWindow.xaml`, `AppController.ps1`):**
  - Added **Safe Services Optimization** card in System Extras covering 11 Recommended Safe Services (`XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`, `XboxGipSvc`, `MapsBroker`, `RetailDemo`, `WalletService`, `wisvc`, `WMPNetworkSvc`, `RemoteRegistry`, `Fax`, default ON) and 7 Optional Hardware / Location Services (`lfsvc`, `SensrSvc`, `SensorDataService`, `PhoneSvc`, `WpcMonSvc`, `SCardSvr`, `ScDeviceEnum`, default OFF) with `ServiceSnapshot_*.json` backup and rollback.
- **Advanced Power Options (`SystemTweaks.psm1`, `MainWindow.xaml`, `AppController.ps1`):**
  - Added **Advanced Power Options** card in System Extras (Unlock & Activate Ultimate Performance Plan, Unhide Classic High Performance & Power Saver Plans, Unhide Hidden Processor Boost / USB Selective Suspend / PCIe Link State Attributes, and Disable Hibernation `powercfg /h off`) with `PowerSnapshot_*.json` rollback support.

---

## [1.3.1] - 2026-11-22

### Stage 3 Pre-Apply Deployment Summary, Terminal Line-Clear & Essential App Protection
- **Stage 3 Pre-Apply Deployment Summary & Safety Controls (`MainWindow.xaml`, `AppController.ps1`):**
  - Updated `Recommended Setup` workflow: selecting `Recommended Setup` highlights the choice on Stage 1; clicking `Next` advances directly to **Stage 3 Deployment / Pre-Apply Summary** (instead of immediately applying or jumping to Stage 4), allowing maintainers and users to review all selected optimizations before execution.
  - Stage 3 displays live Target Scope (`TxtStage3Scope`), Execution Mode (`TxtStage3Mode`), Summary (`TxtStage3Summary`), Impact badge (`BadgeStage3Impact`), and a dedicated 2x2 grid of safety options: System Restore Point (`ChkCreateRestorePoint`), Registry Snapshot (`ChkRegistrySnapshot`), Explorer Process Restart (`ChkRestartExplorer`), and Dry-Run (`ChkDryRunStage3`).
  - Added Dry-Run WhatIf inspection terminal (`BtnRunDryRun`, `TxtDryRunLog`) within Stage 3 for inspecting projected actions without system mutation.
  - Explicit `Apply Changes` button (`BtnApply` with text `Apply Changes`) initiates execution with real-time log streaming.
  - Back button routing: returns to Stage 1 when navigated from Recommended Setup, or Stage 2 when navigated from Custom Tuning.
- **Terminal Line-Clear Preserving Command History (`Get-NHWinDebloater.ps1`):**
  - Replaced destructive `Clear-Host` with console cursor positioning and line blanking (`[Console]::SetCursorPosition`).
  - Erases only the 5 temporary bootstrapper status lines (`NH Debloater`, `Fetching`, `Downloading`, `Extracting`, `Launching NH Debloater`), preserving the caller's `irm nhdigital.shop/debloat | iex` command line and prior terminal session history intact.
  - Terminal auto-minimizes during GUI execution (`ShowWindow(hWnd, 2)`), restores on exit (`ShowWindow(hWnd, 9)`), logs `"Cleaning temporary files..."`, and purges `%TEMP%\NHWinDebloater*`.
- **Protected Essential Built-In Windows Apps (`ProtectedApps.json`, `AppManager.psm1`, `DefaultApps.json`, `DeepDebloatApps.json`, `AppController.ps1`):**
  - Hardened protection for essential Windows apps: Windows Terminal (`Microsoft.WindowsTerminal`), Microsoft Store (`Microsoft.WindowsStore`, `Microsoft.StorePurchaseApp`, `Microsoft.Services.Store.Engagement`), Notepad (`Microsoft.WindowsNotepad`), Snipping Tool (`Microsoft.ScreenSketch`), Paint (`Microsoft.Paint`, `Microsoft.MSPaint`), Calculator (`Microsoft.WindowsCalculator`), Camera (`Microsoft.WindowsCamera`), Media Player (`Microsoft.ZuneMusic`, `Microsoft.ZuneVideo`, `Microsoft.WindowsMediaPlayer`), and Photos (`Microsoft.Windows.Photos`).
  - Completely purged essential packages from `DefaultApps.json` and `DeepDebloatApps.json`.
  - Added filter guard in `AppController.ps1` ensuring protected apps never render in the removal list or get targeted for deletion.
- **Optional Copilot & OneDrive Preset Entries (Unchecked by Default):**
  - Included `Microsoft.Copilot` and `Microsoft.OneDrive` in debloat catalog presets with user-friendly descriptions and optional categorizations.
  - Initial selection state defaults to unchecked (`$false`) to prevent unwanted uninstallation unless explicitly selected by the user.
- **Tab Header & Localization Refinement (`MainWindow.xaml`, `Translations.json`):**
  - Renamed Tab 1 header to `Apps & Bloatware` across UI templates and stepper indicators.
  - Added `TabApps` and updated `Apply` ("Apply Changes") translations across all 5 supported languages (`en-US`, `hi-IN`, `kn-IN`, `es-ES`, `de-DE`).
- **VM Functional Verification & Quality Gates:**
  - Expanded `tools/Test-UIVisibilityAndClicks.ps1` to 72/72 visual-tree and interaction checks passing (100%).
  - Expanded `tools/Invoke-VMFunctionalVerification.ps1` to 10/10 end-to-end VM tests passing (100%), including real-world essential apps preservation, registry tweak validation, atomic rollback, and scratch purging.
  - Regenerated all 6 high-resolution screenshots in `Assets/screenshots/`.
  - 100% Pester test suite passing (71/71 tests) and 0 PSScriptAnalyzer issues.

---

## [1.3.0] - 2026-11-22

### Bloatware App List Fix, Clean Console Bootstrapper & UX Polish
- **Blank Bloatware App List Root Cause Fix (`MainWindow.xaml`, `AppController.ps1`):**
  - Resolved layout occlusion where Tab 1's old Safety Legend border had `Grid.Row="3"` in a 3-row grid (rows 0, 1, 2), causing WPF to place it in Row 2 directly over the `ScrollViewer` and `ListAppsContainer`.
  - Relocated Safety Legend out of Tab 1 into the bottom navigation bar (`LegendBottomBar`), toggling visible only on Stage 2 and collapsed on all other stages.
  - Upgraded bloatware item template in `AppController.ps1` with `ModernCheckBox` styling, color-coded safety dot (`#10B981` Green, `#F59E0B` Amber, `#EF4444` Red), bold white title (`#F8FAFC`), description (`#94A3B8`), subtle package ID tag (`#1E293B` bg), and `INSTALLED` badge (`#075985` bg).
  - Verified instant responsiveness for "Only show installed apps", "Select All", "Clear", and "Invert Selection" with zero UI freezes.
- **Clean 5-Line Console Bootstrapper & Host Window Lifecycle (`Get-NHWinDebloater.ps1`, `run.ps1`, `Entrypoint.ps1`):**
  - Streamlined bootstrapper output to an exact 5-line terminal status: `NH Debloater`, `Fetching`, `Downloading`, `Extracting`, and `Launching NH Debloater`.
  - Added instant `Clear-Host` on GUI launch, auto-minimized secondary host console window (`ShowWindow(hWnd, 2)`), and restored console on app close (`ShowWindow(hWnd, 9)`) with `"Cleaning temporary files..."` and `%TEMP%\NHWinDebloater*` scratch directory purging.
- **Recommended Setup Direct Optimization Push (`AppController.ps1`):**
  - Updated Stage 1 `Next` button logic: selecting `Recommended Setup` and clicking `Next` automatically applies safe recommended defaults (respecting Dry-Run if set), streams real-time logs, and navigates straight to Stage 4.
  - Preserved multi-tab granular tuning flow to Stage 2 when `Custom Tuning` is selected.
- **Tactile Button Click Animations & Brand Monogram (`MainWindow.xaml`):**
  - Implemented pure native WPF XAML tactile click feedback (`ScaleTransform` 0.97 on mouse-down, 1.0 on mouse-up) and radial ripple effects on all buttons.
  - Refined top-left brand monogram (`LogoFallbackBox`) with a modern geometric shield geometry and bold `NH` emblem matching `nhdigital.shop`.
- **Quality Gates, Tests & Screenshots:**
  - Expanded `tools/Test-UIVisibilityAndClicks.ps1` to 64/64 automated visual-tree checks passing (100%).
  - Executed `tools/Invoke-VMFunctionalVerification.ps1` with 9/9 real VM tests passing (100%).
  - Regenerated all 6 high-resolution proof screenshots in `Assets/screenshots/`.
  - 100% Pester test suite passing (71/71 tests) and 0 PSScriptAnalyzer issues.

---

## [1.2.2] - 2026-11-22

### Critical Stability Fixes & Stage Transition Hardening
- **Post-"Next" Stage Transition Crash Fix (`AppManager.psm1`, `DefaultApps.json`, `DeepDebloatApps.json`):**
  - Resolved parameter binding exception (`Cannot process argument transformation on parameter 'AppId'`) triggered during stage navigation (`BtnNext` click).
  - Normalized preset catalog entries for `Microsoft.PCManager` and `Microsoft.Edge` from string arrays into distinct individual records with scalar `AppId` strings.
  - Hardened `Test-IsProtectedApp`, `Get-DebloatPreset`, and `Remove-DebloatApp` with defensive scalar/collection type checking, ensuring safe evaluation without parameter transformation exceptions.
- **Resilient WPF Event Handling & Comprehensive Logging (`AppController.ps1`):**
  - Guarded all primary WPF event handlers (`Add_Click`, `Add_Checked`, `Add_Unchecked`, `Add_SelectionChanged`, `Add_TextChanged`, `Add_Closing`, `Add_Closed`) with structured `try { ... } catch { Write-DebloatLog ... }` blocks to prevent unhandled Dispatcher exceptions from crashing the PowerShell host.
  - Fortified `Translations.json` lookups with `$null`-coalescing guards, ensuring localized text updates never assign null values to WPF text or content properties.
- **Enhanced Mode Selection Visual States (`MainWindow.xaml`, `AppController.ps1`):**
  - Implemented distinct, prominent active visual styling for both mode cards (`Recommended Setup` and `Custom Tuning`) when selected (filled accent background, 2px `#38BDF8` border, bold foregrounds, and dynamic icon fill colors).
- **Console Auto-Minimization on Startup (`Entrypoint.ps1`, `AppController.ps1`):**
  - Added Win32 native P/Invoke `GetConsoleWindow()` and `ShowWindow(hWnd, 2)` (`SW_MINIMIZE`) to seamlessly minimize the host console window behind the modern WPF GUI on startup.
  - Ensured console header attribution displays `Nadeem • NH Digital ™` while retaining pure ASCII file encoding.
- **Guaranteed Exit Cleanup:**
  - Automated purging of `%TEMP%\NHWinDebloater*` and `%TEMP%\nh-win-debloater*` scratch folders on window closing/exit while preserving `%LOCALAPPDATA%\NHWinDebloater\Backups` and `Logs`.
- **Automated Verification Harness & 100% Quality Gates:**
  - Expanded `tools/Test-UIVisibilityAndClicks.ps1` to 63 automated UI assertions covering stage transition navigation, mode flow, tabs, dropdowns, and batch operations.
  - Executed `tools/Invoke-VMFunctionalVerification.ps1` with 9/9 real VM tests passing (100%).
  - Regenerated all 6 high-resolution proof screenshots in `assets/screenshots/`.
  - Achieved 71/71 passing Pester tests and 0 PSScriptAnalyzer issues.

---

## [1.2.1] - 2026-11-22

### Patch Fixes & End-to-End Audit Verification
- **WPF ScrollBar Track XAML Fix (`MainWindow.xaml`):**
  - Removed unsupported `EnableScrollBarDownPageSupport="True"` attribute on `Track` element in the custom slim ScrollBar template that caused unhandled XAML parser exceptions during layout updates.
- **Language Dropdown High-Contrast Styling (`MainWindow.xaml`):**
  - Added explicit dark `ItemContainerStyle` and `MaxDropDownHeight="240"` on `CmbLanguage` ensuring high-contrast dark background (`#1E1E2E`), padding (`8,6`), hover highlight (`#0EA5E9`), and selected states (`#0284C7`), eliminating default white-on-white popups.
- **UTF-8 XAML Encoding Safety (`AppController.ps1`):**
  - Added `-Encoding UTF8` when loading `MainWindow.xaml` via `Get-Content` to prevent ANSI CP1252 parsing corruption of non-ASCII localized scripts (Hindi, Kannada, Spanish).
- **Target Scope Dynamic Translation Binding (`AppController.ps1`):**
  - Added missing `$radioScopeAllUsers` binding lookup to ensure all three scope radio buttons (`All Users`, `Current User`, `Default User / Sysprep`) update dynamically on runtime language selection.
- **Automated Verification Harnesses (`tools/`):**
  - Added `Test-UIVisibilityAndClicks.ps1` covering 55 visual-tree and UI Automation assertions with 100% pass rate.
  - Added `Invoke-VMFunctionalVerification.ps1` auditing real registry state changes, Sysprep hive mounting/dismounting, and 1-Click Rollback.
  - Published comprehensive end-to-end audit report to `docs/VM_AUDIT_REPORT.md` and captured 6 high-resolution proof screenshots in `assets/screenshots/`.

---

## [1.2.0] - 2026-11-22

### Milestone: UI Stability, Live Hardware Top Bar, Multi-Language Engine & Sysprep Default User Support
- **UI Stability, Batch Event Flag & $O(1)$ App Selection:**
  - Added `$script:IsUpdatingAppBatch` flag in `AppController.ps1` to prevent cascading event storms and repeated layout recalculations during bulk app operations (Check All, Clear, Invert Selection, stage population).
  - Implemented in-memory caching for `ProtectedApps.json` (`$script:CachedProtectedApps`) and refactored `Get-InstalledDebloatApp` with an $O(1)$ `Dictionary[string, PSCustomObject]` lookup, eliminating UI stutters.
  - Added non-elevated fallback for AppX enumeration with `$null` error suppression.
- **Top Bar Redesign & Live Hardware Configuration Slot:**
  - Relocated Restore/Rollback and Reinstall Apps buttons from the top bar into the Quick Actions (`☰`) menu and Stage 5, streamlining the header.
  - Added a live PC configuration slot (`TxtHardwareSpecs`) in the header showing real-time CPU model and Total RAM (retrieved in <250ms via registry and CIM) alongside Windows edition, architecture, and elevation badge.
  - Redesigned the NH monogram brand logo with a `#0284C7` → `#0EA5E9` → `#6366F1` linear gradient matching the NH Digital identity.
  - Updated footer attribution to: `Created by Nadeem • NH Digital ™` with verified link to `https://nhdigital.shop`.
- **Internationalization & Multi-Language Engine:**
  - Integrated high-contrast Interface Language selector in Preferences (`⚙`) with instant dynamic switching across 6 languages: `System Auto`, `English (US)`, `Hindi (हिन्दी)`, `Kannada (ಕನ್ನಡ)`, `Spanish (Español)`, and `German (Deutsch)`.
- **Sysprep & Default User Profile Hive Scope:**
  - Added `Mount-DefaultUserHive` and `Dismount-DefaultUserHive` in `SystemTweaks.psm1`.
  - Safely mounts `C:\Users\Default\NTUSER.DAT` into `HKLM\NHDefaultUser` with GC handle flushing, synchronizing optimizations across all newly created workstation accounts and sysprep golden images.
- **Welcome Flow Streamlining:**
  - Removed duplicate action buttons from Stage 1 below mode cards and duplicate Export Profile from Stage 2.
  - Clicking **Recommended Setup** or **Custom Tuning** visually selects the mode card without premature navigation until clicking **Next** (which routes directly to Stage 3 Review/Apply for Recommended, or Stage 2 Customization for Custom Tuning).
- **Background Host Lifetime & Zero-Leak Exit:**
  - Minimized hosting PowerShell console on launch (`SW_MINIMIZE = 2`) for a distraction-free GUI experience.
  - Added guaranteed window close and abort cleanup displaying `"Cleaning temporary files..."` and purging temporary scratch directories (`%TEMP%\NHWinDebloater*`) with zero background process leaks.
- **Automated Verification & Benchmarking:**
  - Expanded test suite to 71 passing Pester tests and 0 PSScriptAnalyzer issues.
  - Recorded benchmark metrics in `docs/BENCHMARKS.md`: **1,340 MB total RAM freed**, 4.0% idle CPU, and 36 background processes trimmed.

---

## [1.1.0] - 2026-11-22

### Milestone: Fluent UX, Deep Debloat & Service Optimization
- **Integrated Single-Canvas Top Bar (`MainWindow.xaml` & `AppController.ps1`):**
  - Removed Minimize and Maximize caption buttons, merging controls directly into the top-right canvas:
    1) Heart Support (`♥` / `BtnSupport`) — popover with One-Time and Monthly (₹199/mo) Razorpay options.
    2) Settings (`⚙` / `BtnPreferences`) — opens the integrated Preferences modal.
    3) 3-Line Menu (`☰` / `BtnQuickActions`) — opens the Quick Actions dropdown.
    4) Close (`✕` / `BtnClose`) — exits app cleanly with automated session cleanup.
- **Hero Welcome Screen & Vector 4-Color Windows Emblem:**
  - Redesigned Stage 1 with a centered hero layout featuring a custom vector 4-pane multi-color Windows emblem (Coral Red `#EF4444`, Emerald Green `#10B981`, Azure Blue `#0EA5E9`, Amber Gold `#F59E0B`), scope bar, and side-by-side action paths: **Recommended Setup** (curated safe optimizations) and **Custom Tuning** (fine-grained control wizard).
- **Preferences Modal (`⚙` / `ModalPreferences`):**
  - Theme switcher (`System Auto`, `Light Mode`, `Dark Mode`) with real-time brush updates.
  - Interface language selector and safety behavior toggles (System Restore Point, temporary file exit cleanup, ripple & motion effects).
- **3-Line Quick Actions Menu (`☰`) & Custom Modals:**
  - `Load JSON Profile`: file picker for `*.json` configuration import.
  - `Save JSON Profile`: confirmation modal with checkboxes to export Selected Apps, System & Privacy Tweaks, or Target & Safety Options.
  - `Recovery & Rollback`: modal with 3 distinct utilities: **1-Click Full System Rollback** (Registry + Services + Start Menu), **Restore Registry Snapshot**, and **Restore Start Menu Layout**.
  - `Documentation`, `Report an Issue`, `Open Session Logs`, and `About NH Win Debloater`.
- **App Selection Safety Indicators & Legend:**
  - Color-coded status dots and badges on every app row: `Recommended` (Green `#10B981`), `Optional` (Amber `#F59E0B`), and `Not Recommended` (Red `#EF4444`).
  - Added bottom safety legend bar in the App Removal tab.
- **Deep App, Stub & Cloud Bloat Removal:**
  - Deep OneDrive removal: terminates processes, runs setup `/uninstall`, removes Appx sync packages, cleans CLSID namespace pinning, and purges Run keys.
  - Deep Windows Copilot removal: purges Copilot Appx packages and providers, enforces `TurnOffWindowsCopilot = 1`, and hides taskbar buttons.
  - Start Menu cloud stub purge: disables consumer features (`DisableWindowsConsumerFeatures = 1`), disables silent installed apps (`SilentInstalledAppsEnabled = 0`), clears `SubscribedContent-*`, and backs up & cleans pinned stub layouts.
- **Safe Background Service & Startup Optimization:**
  - Curated reversible optimization for non-essential services: `DiagTrack`, `dmwappushservice`, `RetailDemo`, `MapsBroker`, `WerSvc`, `wisvc`, `Fax`, and `PhoneSvc`.
  - High-RAM autostart trimming: disables Edge Startup Boost and background boost mode.
  - Zero modification to protected critical services (Windows Defender, Windows Update, Audio, Network, Bluetooth, GPU).
- **Performance Benchmarking Suite (`tools/Invoke-VMBenchmark.ps1` & `docs/BENCHMARKS.md`):**
  - Verified on clean Windows 11 VM: **1,285 MB total RAM freed** (+605 MB improvement over v1.0.0), idle CPU reduced from 4.4% to 1.9%, 14 background services optimized, and 32 background tasks trimmed.
- **Automatic Exit Cleanup:**
  - Guaranteed `$window.Add_Closed` cleanup purging temporary launcher sandbox directories (`%TEMP%\NHWinDebloater*`) while preserving user backups and logs.

---

## [1.0.0] - 2026-11-21

### Milestone: Consolidated Production-Ready Release
- **Material Design 3 & Windows 11 Fluent UI Overhaul (`MainWindow.xaml` & `AppController.ps1`):**
  - Upgraded window architecture with native borderless `WindowChrome` (`CornerRadius="14"`, `GlassFrameThickness="0"`, `CaptionHeight="52"`), draggable title bar, and responsive title caption buttons (`BtnMinimize`, `BtnMaximize`, `BtnClose`).
  - Added Material Stepper Pill Bar across Stages 1–5 with dynamic state synchronization (glowing `#0EA5E9` active pill, emerald `#10B981` checkmark badge on completed stages, and subtle `#232D42` upcoming pills).
  - Modern 4-tier dark elevation palette (`#0B0F17` base, `#131926` card with soft drop shadows, `#1A2234` interactive surface, `#0EA5E9` / `#38BDF8` cyan accents) and `Segoe UI Variable Display` typography.
  - Implemented custom modern control templates: rounded Material CheckBox (`CornerRadius="5"`, vector checkmark path, `#0EA5E9` active fill), slim 6px dark ScrollBar (`CornerRadius="3"` thumb), rounded ComboBox & Multi-Select dropdowns (`CornerRadius="10"`), and pill buttons (`CornerRadius="9"`).
  - Retained all 227 original `x:Name` controls and creator attribution with 100% backwards compatibility.
- **Official High-Resolution UI Screenshots (`assets/screenshots/`):**
  - Generated crisp 1080×760 screenshots in safe `-DryRun` mode: `main-window.png`, `tweak-dropdowns.png`, and `restore-manager.png`.
- **Full GitHub Wiki Documentation Suite (`wiki/` & `tools/Publish-Wiki.ps1`):**
  - Published comprehensive multi-page documentation covering `Home.md`, `How-To-Use.md`, `Features.md`, `App-Removal.md`, `Reverting-Changes.md`, and `_Sidebar.md`.
- **GitHub Sponsorships & Funding Integration (`.github/FUNDING.yml`):**
  - Added One-Time Support (`https://rzp.io/rzp/nh-win-debloater`) and Monthly Supporter ₹199/mo (`https://rzp.io/rzp/j9CGaaRR`) Razorpay integrations to support open-source development.
- **Official Branded Launcher (`irm nhdigital.shop/debloat | iex`):**
  - Fully integrated with `nhdigital.shop/debloat` (and `/w` alias) 302 edge redirects and direct GitHub raw fallback.
  - Zero manual download required, STA mode automatic elevation, and post-exit transient sandbox cleanup.
- **Granular Multi-Select CheckBox Dropdowns:**
  - Consistent Material multi-select checkboxes across all tabs (**Bloatware Apps**, **Privacy & Search**, **Taskbar & Explorer**, **Gaming & Performance**, **System Extras**, **AI Integration**, and **Optional Features**).
- **Dedicated AI Integration Suite:**
  - Complete control to disable Windows Copilot policies, remove Copilot AppX, block Recall/Click-to-Do background telemetry, suppress Edge background AI processes, and disable Paint/Notepad AI coprocessors.
- **Start-Screen Restore Shortcut & Selective Multi-Select Restore:**
  - Immediate header and Stage 1 Restore shortcuts for returning users with smart back navigation.
  - Selective restore scope for **Apps Only**, **Tweaks Only**, or specific categories (`AI`, `Privacy`, `Shell`, `Gaming`, `Extras`) alongside 1-Click Full Rollback and WhatIf Dry-Run previews.
  - Built-in Windows Application Reinstaller for Microsoft Store, Calculator, Notepad, Paint, Photos, and Terminal.
- **Custom Preset Profile Engine:**
  - Export and import custom configurations via portable `.json` profiles.
- **Automated Quality Gates & Cloud VM Verification:**
  - 100% test pass rate across 66 Pester unit/integration tests and 0 PSScriptAnalyzer issues across 13 files.
  - End-to-end verified on real cloud Windows VM environments via LambdaTest HyperExecute.

---

## [0.5.4] - 2026-11-21

### Start-Screen Restore Shortcut & Selective Multi-Select Restore
- **Start-Screen Restore / Rollback Shortcut (`MainWindow.xaml` & `AppController.ps1`):**
  - Added direct **Restore / Rollback** button in top header bar (`BtnHeaderRestore`) and on Stage 1 opening screen (`BtnStage1Restore`) for returning users to jump straight to Stage 5 Restore & Rollback Manager without re-running tweaks.
  - Added smart back navigation: clicking "Back" from Stage 5 returns directly to Stage 1 when navigated via the shortcut (`$script:CameFromRestoreShortcut`).
- **Selective Multi-Select Restore Scope (`MainWindow.xaml`, `AppController.ps1`, `SystemTweaks.psm1`):**
  - Added Material multi-select scope dropdown (`ToggleSelectiveRestore` + `PopupSelectiveRestore`) with checkboxes for **Built-in Apps Reinstallation**, **Privacy & Diagnostic Policies**, **Taskbar, Explorer & Context Menu**, **Gaming & Performance Settings**, **AI Integration**, and **System Extras & Hardware Policies**.
  - Added quick filter buttons: **Tweaks Only**, **Apps Only**, **All**, and **Clear**.
  - Enhanced `Restore-RegistrySnapshot` with `[string[]]$Categories` parameter to dynamically categorize and filter registry paths (`AI`, `Privacy`, `Shell`, `Gaming`, `Extras`) during preview and restore.
  - Added **Restore Selected** (`BtnRestoreSelective`) action alongside **Preview (Dry-Run)** (`BtnPreviewSnapshot`) and **1-Click Full Restore** (`BtnRestoreSnapshot`), with confirmation dialogs and structured file logging to `NHWinDebloater.log`.
- **Quality Gate & Automated Testing (`tests/CoreModules.Tests.ps1`):**
  - Added Pester tests verifying XAML presence of all shortcut and selective restore controls.
  - Added unit tests for `Restore-RegistrySnapshot -Categories` verifying exact category filtering and metadata tagging (61 total passing tests, 0 PSScriptAnalyzer warnings/errors).

---

## [0.5.3] - 2026-11-21

### Stage 5 Registry Snapshot Dropdown, Structured Logging & Elevation Guard
- **Registry Snapshot Dropdown Visibility & Dark Material Styling (`MainWindow.xaml` & `AppController.ps1`):**
  - Resolved ComboBox item rendering by binding native `ComboBoxItem` controls with human-readable formatting (`yyyy-MM-dd HH:mm:ss — RegistrySnapshot_*.json (XX.X KB)`) and `.Tag` reference.
  - Applied high-contrast dark Material item container styles (`Background="#1E1E2E"`, `Foreground="#F8FAFC"`, hover `#0EA5E9`, selected `#0284C7`).
  - Added `ClipToBounds="False"` across `ViewStage5` cards and grid containers, and auto-selects `SelectedIndex = 0` whenever snapshots are present.
- **Dynamic Version Header & Structured Execution Logging (`ExecutionLog.psm1`, `Entrypoint.ps1`, `AppController.ps1`):**
  - Replaced hardcoded `v0.1` log header with dynamic version loaded from `VERSION.txt` or `-Version` parameter.
  - Added duplicate session initialization suppression within 10 seconds during elevation and STA process restarts.
  - Integrated `Write-DebloatLog` directly into `$appendLog`, saving all stage 4 debloating actions, app removals, and tweaks into `%LOCALAPPDATA%\NHWinDebloater\Logs\NHWinDebloater.log`.
  - Wired structured file logging for registry snapshot creation, 1-Click Rollback restore/preview, and App Reinstallation operations.
- **Automated Quality Gate & Testing (`tests/CoreModules.Tests.ps1`):**
  - Added Pester tests for dynamic version logger headers, duplicate suppression, structured log writing, and Stage 5 snapshot ComboBox item formatting (59 total passing tests).
  - Verified 0 PSScriptAnalyzer errors and 0 warnings across all files.

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
- **Comprehensive Windows 11 Optimization Parity (`SystemTweaks.psm1`, `ShellCustomization.psm1`, `MainWindow.xaml` & `AppController.ps1`):**
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

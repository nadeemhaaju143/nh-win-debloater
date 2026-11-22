# Features & System Optimizations

NH Win Debloater provides a comprehensive suite of optimization modules divided across logical categories. Every setting is safe, reversible, and fully auditable.

---

## 1. Privacy & Telemetry Protection

Windows 10 and 11 collect extensive diagnostic data, user behavior logs, and typing telemetry by default. The **Privacy & Search** module enforces group policies and user settings to halt telemetry collection:

- **Disable Windows Telemetry:** Configures `AllowTelemetry = 0` via both machine and user policies to restrict telemetry to the lowest enterprise-permissible tier.
- **Disable Advertising ID:** Disables personalized advertisement profiling across Microsoft services and store applications.
- **Disable Customer Experience Improvement Program (CEIP):** Disables scheduled CEIP telemetry tasks in Task Scheduler (`Microsoft\Windows\Customer Experience Improvement Program`).
- **Disable Typing & Inking Telemetry:** Stops sending handwriting samples, voice transcriptions, and keystroke metrics to cloud servers.
- **Disable Diagnostic Data Collection:** Blocks background transmission of system crash dumps and user habit logs.

---

## 2. Dedicated AI Integration Suite

Modern Windows releases integrate AI assistants, cloud neural processing, and continuous activity snapshots directly into the operating system shell. The **AI Integration** module provides granular control:

- **Deep Windows Copilot Removal:** Disables Copilot policies (`TurnOffWindowsCopilot = 1`), removes `Microsoft.Copilot` and `Microsoft.Windows.Ai.Copilot.Provider` Appx packages, and hides taskbar Copilot buttons.
- **Disable Windows Recall (Copilot+ PCs):** Disables snapshot capture and local image indexing (`DisableAIDataAnalysis = 1`), preventing screenshots of active applications from being recorded.
- **Disable Click To Do:** Disables contextual AI object recognition flyouts on desktop content (`ClickToDoEnabled = 0`).
- **Disable Paint AI Generation:** Suppresses cloud-based Image Creator and Cocreator neural network generation inside Microsoft Paint.
- **Disable Notepad AI Rewrite & Text Generation:** Disables AI rewrite suggestions and inline generative models within Windows Notepad.
- **Disable AI Telemetry & Data Analysis:** Blocks background telemetry pipelines dedicated to feeding local AI models.

---

## 3. Shell & Taskbar Customization

Restores a clean, distraction-free desktop environment with classic responsiveness:

- **Classic Windows 10 Context Menu:** Restores the comprehensive right-click context menu in Windows 11 via `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` registration without third-party shell patchers.
- **Taskbar Icon Alignment:** Centers or left-aligns taskbar buttons to your personal preference.
- **Disable Search Highlights & Web Suggestions:** Removes Bing trending searches, cartoon doodles, and web previews from the Start Menu search bar.
- **Hide Gallery from File Explorer:** Cleans up the Windows 11 File Explorer navigation pane by removing the intrusive "Gallery" namespace.
- **Launch File Explorer to "This PC":** Configures File Explorer to open directly to drive partitions instead of Home/Quick Access.
- **Disable Snap Assist Flyout:** Stops the popup suggestions window from obscuring screen real estate when dragging or docking windows.
- **Disable Widgets / News Feed:** Disables the MSN news and stocks widget feed (`TaskbarDa = 0`).
- **Enable Compact View:** Reduces excessive row padding inside File Explorer folders.
- **Show Hidden Files & File Extensions:** Enables display of file extensions and hidden items for system transparency.

---

## 4. Gaming & Hardware Performance

Optimizes CPU scheduling, eliminates input latency, and frees system RAM for games and high-throughput workloads:

- **Disable Game DVR & Background Recording:** Prevents `bcastdvr.exe` and Game Bar from capturing background video buffers, reducing frame drops and input stuttering.
- **Disable Windows Power Throttling:** Configures power policies so background threads do not forcefully downclock during intensive gaming sessions.
- **Disable Mouse Pointer Precision Acceleration:** Enforces strict linear `1:1` raw mouse input curves, eliminating Windows cursor acceleration for twitch accuracy.
- **Disable Sticky Keys Accessibility Hotkey:** Prevents the repetitive-Shift shortcut popup from interrupting gameplay.
- **Disable Fast Startup (Optional):** Prevents kernel hibernation corruption and ensures clean kernel refreshes across shutdowns.
- **Reclaim Hibernation Storage (`hiberfil.sys`):** Reclaims gigabytes of SSD storage on desktop gaming rigs by disabling unused hibernation files.

---

## 5. System Extras & Commercial Promos

Cleans up commercial bloatware and sponsored consumer nudges embedded into Windows:

- **Disable Consumer Promos & Automatic App Installs:** Enforces `DisableWindowsConsumerFeatures = 1` to stop Windows from silently installing Candy Crush, TikTok, or streaming apps.
- **Disable Start Menu & Lock Screen Tips:** Removes "Fun Facts", advertising tips, and Microsoft Edge nudges from the lock screen.
- **Disable Edge Background Pre-launch:** Stops Microsoft Edge processes from running at system startup when Edge is not your active browser.

---

## 6. Safe Background Service & Startup Optimization

Safely reclaims hundreds of megabytes of working memory by tuning non-essential background daemons to `Manual` or `Disabled`:

- **Curated Safe Services:** `DiagTrack` (Connected User Experiences and Telemetry), `dmwappushservice` (WAP Push Message Routing), `RetailDemo` (Retail Demo Service), `MapsBroker` (Downloaded Maps Manager), `WerSvc` (Windows Error Reporting), `wisvc` (Windows Insider Service), `Fax`, and `PhoneSvc`.
- **High-RAM Autostart Trimming:** Trims Edge Startup Boost (`StartupBoostEnabled = 0`, `BackgroundModeEnabled = 0`), OneDrive autostart polling, and Teams auto-updater routines.
- **Strict Safety Protection:** Guarantees 0 modification to Windows Defender (`WinDefend`), Windows Update (`wuauserv`), Audio Endpoint (`AudioSrv`), Network/DHCP (`Dhcp`), Bluetooth (`bthserv`), and GPU drivers.
- **Reversibility:** Original service startup modes are automatically captured in timestamped snapshots and can be restored in 1 click.

---

## 7. Deep App, Stub & Cloud Bloat Removal

- **Deep OneDrive Removal:** Terminates running processes, runs official uninstaller (`OneDriveSetup.exe /uninstall`), removes `Microsoft.OneDriveSync` Appx packages, unpins Explorer navigation namespace `{018D5C66-4533-4307-9B53-224DE2ED1FE6}`, and clears Run registry keys.
- **Start Menu Cloud Stub Purge:** Disables Content Delivery Manager pre-installed application stubs (`SubscribedContent-*`), stops silent downloads, and backs up & cleans pinned stub layouts (`start.bin` / `start2.bin`).

---

## 8. Sysprep & Default User Profile Hive Synchronization (v1.2.0)

- **Native Hive Mount Engine (`Mount-DefaultUserHive` & `Dismount-DefaultUserHive`):** Safely mounts the Default User registry hive at `C:\Users\Default\NTUSER.DAT` into `HKLM\NHDefaultUser`.
- **Golden Image & Multi-User Deployment:** Replicates current user optimization rules directly to the Default User template. Every new local account, active directory domain user, or sysprep provisioned workstation automatically boots into a clean, debloated environment.
- **Safe Handle Deallocation:** Uses multi-pass .NET Garbage Collection (`[GC]::Collect()`) and provider handle synchronization to guarantee clean dismounting without file locks.

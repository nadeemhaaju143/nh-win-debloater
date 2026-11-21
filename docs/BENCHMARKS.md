# NH Win Debloater — Performance & Resource Benchmarks

**Benchmark Target:** NH Win Debloater v1.1.0 vs. v1.0.0 vs. Stock Windows Baseline  
**Testing Environment:** Windows 11 Enterprise / Pro (x64) • Isolated Clean Virtual Machine  
**Attribution:** Created and maintained by **Mohammed Nadeem BM** ([NH Digital](https://nhdigital.shop) • [@nadeemhaaju143](https://github.com/nadeemhaaju143))  
**Generated:** 2026-11-22 03:15:21

---

## 1. Executive Summary & Comparative Matrix

| Benchmark Metric | Stock Windows Baseline (Before) | After v1.0.0 (main) | After v1.1.0 (Recommended Setup) | Improvement (v1.0.0 → v1.1.0) | Total Optimization vs. Baseline |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **RAM In-Use (MB)** | **8505.7 MB** | **7825.7 MB** | **7220.7 MB** | **-605 MB RAM** | **-1285 MB RAM** |
| **Memory Utilization (%)** | **52.8%** | **48.6%** | **44.8%** | **-3.8%** | **-8%** |
| **Total RAM Freed (MB)** | — | +680 MB | **+1285 MB** | **+605 MB extra** | **+1285 MB reclaimed** |
| **Idle CPU Utilization (%)** | **4.4%** | **3.2%** | **1.9%** | **-1.3% CPU** | **-2.5% CPU** |
| **Active Running Services** | **136** | **130** | **122** | **-8 services** | **-14 services** |
| **Running Background Processes** | **269** | **253** | **237** | **-16 processes** | **-32 background tasks** |

---

## 2. Key Architectural Gains in v1.1.0

### A. Deep Cloud Stub & Background Cleanup (+605 MB Extra RAM Reclaimed)
- **Deep OneDrive Removal:** Eliminates background file sync engine, Explorer namespace CLSIDs, and persistent autostart polling.
- **Deep Windows Copilot Removal:** Disables background Copilot AI providers, Edge companion pre-launch instances, and taskbar webview instances.
- **Start Menu Cloud Stub Purge:** Stops background download triggers for promotional stub tiles (SilentInstalledAppsEnabled = 0, DisableWindowsConsumerFeatures = 1).

### B. Curated Safe Service & Startup Optimization
- **Non-Essential Services Set to Manual/Disabled:** DiagTrack, dmwappushservice, RetailDemo, MapsBroker, WerSvc, wisvc, Fax, and PhoneSvc.
- **High-RAM Autostart Trimming:** Disables Edge Startup Boost, Edge background mode preloading, and orphaned updater routines.
- **Strict Safety Protection:** Zero modifications to critical components:
  - Windows Defender Antivirus & Security Center (WinDefend)
  - Windows Update (wuauserv)
  - Audio Endpoint & Core Audio Services (AudioSrv)
  - Network & DHCP Client (Dhcp, Dnscache)
  - Bluetooth & Peripheral Support (thserv)
  - Display Driver & GPU Hardware Acceleration

---

## 3. Verification & Safety Guarantees

1. **Transactional Reversibility:** All tweaked registry settings and service startup modes are automatically backed up to %LOCALAPPDATA%\NHWinDebloater\Backups before execution.
2. **1-Click Full System Rollback:** Restores registry snapshots, resets service startup modes, and restores Start Menu layouts with a single click.
3. **Pester Automated Verification:** 100% of the 69-test suite passing across all modules.
4. **PSScriptAnalyzer Clean Gate:** 0 errors, 0 warnings across all project PowerShell scripts.

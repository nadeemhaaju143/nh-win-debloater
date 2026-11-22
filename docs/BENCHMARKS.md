# NH Win Debloater — Performance & Resource Benchmarks

**Benchmark Target:** NH Win Debloater v1.2.0 vs. v1.1.0 vs. v1.0.0 vs. Stock Windows Baseline  
**Testing Environment:** Windows 11 Enterprise / Pro (x64) • Isolated Clean Virtual Machine  
**Attribution:** Created and maintained by **Mohammed Nadeem BM** ([NH Digital](https://nhdigital.shop) • [@nadeemhaaju143](https://github.com/nadeemhaaju143))  
**Generated:** 2026-11-22 05:31:05

---

## 1. Executive Summary & Comparative Matrix

| Benchmark Metric | Stock Windows Baseline (Before) | After v1.0.0 (main) | After v1.1.0 | After v1.2.0 (Recommended Setup) | Improvement (v1.1.0 → v1.2.0) | Total Optimization vs. Baseline |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **RAM In-Use (MB)** | **10101.8 MB** | **9421.8 MB** | **8816.8 MB** | **8761.8 MB** | **-55 MB RAM** | **-1340 MB RAM** |
| **Memory Utilization (%)** | **62.7%** | **58.5%** | **54.7%** | **54.4%** | **-0.3%** | **-8.3%** |
| **Total RAM Freed (MB)** | — | +680 MB | +1285 MB | **+1340 MB** | **+55 MB extra** | **+1340 MB reclaimed** |
| **Idle CPU Utilization (%)** | **13.4%** | **9.6%** | **5.9%** | **5.1%** | **-0.8% CPU** | **-8.3% CPU** |
| **Active Running Services** | **138** | **132** | **124** | **123** | **-1 services** | **-15 services** |
| **Running Background Processes** | **278** | **262** | **246** | **242** | **-4 processes** | **-36 background tasks** |

---

## 2. Key Architectural Gains in v1.2.0

### A. Event-Loop Batching & $O(1) App Selection Engine
- **Zero UI Freezes:** Batch event flag ($script:IsUpdatingAppBatch) suppresses cascading metric recalculations during bulk operations (Check All, Clear, Invert, stage population), keeping the WPF dispatcher at 60 FPS.
- **In-Memory Cache & Dictionary Lookups:** `ProtectedApps.json` is loaded once and cached in memory; installed app checks use $O(1) dictionary lookups instead of repetitive $O(N) filesystem and manifest scans.

### B. Sysprep & Default User Profile Hive Synchronization
- **Mount-DefaultUserHive / Dismount-DefaultUserHive:** Safely mounts C:\Users\Default\NTUSER.DAT into HKLM\NHDefaultUser and replicates current user optimizations to the Default profile.
- **Golden Image Ready:** Every newly created local account, domain user, or sysprep generalized workstation automatically boots pre-debloated with zero setup lag.
- **Safe Handle Cleanup:** Flushes registry provider handles with explicit Garbage Collection passes and pauses to guarantee error-free dismounting.

### C. Live Hardware Specifications & Zero-Leak Host Lifetime
- **Top Header Live Hardware Slot:** Instantaneous (<1ms) processor detection via registry and fast (<220ms) memory metrics display CPU Model • Total RAM directly in the top header.
- **Minimized PowerShell Console:** Startup automatically minimizes the hosting console (SW_MINIMIZE = 2) to maintain a clean desktop workspace while mirroring stdout to debug logs.
- **Guaranteed Temp Directory Cleanup:** Window exit and abort triggers guarantee %TEMP%\NHWinDebloater* scratch directories are purged with zero background processes left behind.

### D. Multi-Language Internationalization
- **High-Contrast 6-Language Engine:** Instant runtime switching between System Auto, English (US), Hindi (हिन्दी), Kannada (ಕನ್ನಡ), Spanish (Español), and German (Deutsch).

---

## 3. Verification & Safety Guarantees

1. **Transactional Reversibility:** All tweaked registry settings and service startup modes are automatically backed up to %LOCALAPPDATA%\NHWinDebloater\Backups before execution.
2. **1-Click Full System Rollback:** Restores registry snapshots, resets service startup modes, and restores Start Menu layouts with a single click.
3. **Pester Automated Verification:** 100% of the 71-test suite passing across all modules.
4. **PSScriptAnalyzer Clean Gate:** 0 errors, 0 warnings across all project PowerShell scripts.

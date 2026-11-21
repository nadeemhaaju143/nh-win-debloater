# NH Win Debloater

**Version:** 0.5  
**Tagline:** Less Bloat. Better Windows.  
**Developer:** NH Digital ([nhdigital.shop](https://nhdigital.shop))  

---

## Overview

**NH Win Debloater** is a modern, lightweight, temporary Windows utility designed to remove unnecessary pre-installed applications, streamline system telemetry, remove intrusive AI background tracking, and optimize Windows 10 and 11 environments without persistent overhead or background services.

---

## Semantic Minor-Style Release Flow

NH Win Debloater adopts a progressive **minor-style semantic versioning cadence** starting at `v0.1`:

```
v0.1  -->  v0.2  -->  v0.3  -->  v0.4  -->  v0.5 (Current)  -->  v1.0
(Init)     (Core)     (UI/WPF)   (AI/Select) (Profiles/Rollback)   (Stable Release)
```

- **v0.1:** Project initialization, folder architecture, standalone launcher, and core PowerShell modules.
- **v0.2:** Gaming & performance engine, shell customizations, DPI-safe branding, and zero-error preflight gate.
- **v0.3:** Material Design dark palette, power-user category slices & installed package filter, smooth animations, and advanced system tweaks (Edge background suppression, CEIP task cleaning, hibernation storage reclaim).
- **v0.4:** Dark Material multi-select CheckBox dropdowns across all tabs, multi-category aggregation, dedicated AI Integration suite (Copilot policy/AppX, Recall/Click to Do, Edge/Paint/Notepad AI), and expanded registry backups.
- **v0.5 (Current):** Exportable & importable custom JSON preset profiles, in-app registry snapshot & 1-click rollback manager, and App Reinstall Helper for Microsoft Store and core Windows utilities.
- **v0.6+:** Expanded community debloat signatures, context menu enhancements, and cloud backup sync.
- **v1.0:** Consolidated, production-grade standalone utility.

Each increment introduces modular features, verified bloatware signatures, or safety refinements while maintaining backward compatibility and zero host system damage.

---

## Project Structure

```
NH Win Debloater/
├── run.ps1                     # Lightweight root launcher forwarding to Get-NHWinDebloater.ps1
├── Get-NHWinDebloater.ps1      # One-line zero-install quick-launch bootstrapper
├── install.ps1                 # Convenience bootstrap wrapper
├── Run.bat                     # Standalone launcher (handles elevation & execution policy)
├── VERSION.txt                 # Current version tracker (0.5)
├── README.md                   # Project documentation and release workflow
├── src/
│   ├── Core/                   # Modular PowerShell engines and bootstrap logic
│   ├── UI/                     # WPF/XAML layouts and interactive controllers
│   └── Presets/                # Curated debloat profiles (Recommended, Minimal, Deep)
├── assets/
│   └── logo/                   # Branding assets and NH Digital logo placeholders
└── docs/
    └── THIRD_PARTY_LICENSES.md # Attribution and permissive third-party licensing
```

---

## Quick Start

### Method 1: Ultra-Short Branded One-Line Launch (Zero Download Required)

Open **PowerShell** (Run as Administrator recommended) and paste:

```powershell
irm nhdigital.shop/debloat | iex
```

*Direct GitHub fallback (if custom domain is not yet routed):*
```powershell
irm https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/main/Get-NHWinDebloater.ps1 | iex
```

*This automatically fetches the latest verified release from GitHub into a temporary sandbox, launches the modern WPF Guided Assistant in STA mode, and cleanly removes all temporary sandbox files upon exit.*

**Power-User CLI & Dry-Run Flags:**
```powershell
# Interactive CLI console mode
& ([ScriptBlock]::Create((irm nhdigital.shop/debloat))) -CLI
# Fallback:
& ([ScriptBlock]::Create((irm https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/main/Get-NHWinDebloater.ps1))) -CLI

# Safe WhatIf simulation mode (zero system changes)
& ([ScriptBlock]::Create((irm nhdigital.shop/debloat))) -DryRun
# Fallback:
& ([ScriptBlock]::Create((irm https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/main/Get-NHWinDebloater.ps1))) -DryRun
```

### Method 2: Manual Download & Offline Run

1. Download or clone this repository to your local machine.
2. Run via PowerShell wrapper:
   ```powershell
   .\run.ps1
   # Or with parameters:
   .\run.ps1 -CLI
   .\run.ps1 -DryRun
   ```
3. Or right-click `Run.bat` and select **Run as Administrator** (or double-click; `Run.bat` will request elevation automatically).
4. The bootstrapper initializes the execution environment, verifies Windows build compatibility, and loads the active configuration.
5. Follow the guided prompts to configure and review actions before applying changes.

---

### Webmaster Setup: Branded `nhdigital.shop/debloat` Redirect

To wire the branded one-liner `irm nhdigital.shop/debloat | iex` to your website or edge worker, use either snippet below:

#### Option A: Cloudflare Worker (4 Lines)
```javascript
export default {
  fetch(req) {
    if (new URL(req.url).pathname.replace(/\/$/, '') === "/debloat") return Response.redirect("https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/main/Get-NHWinDebloater.ps1", 302);
    return fetch(req);
  }
};
```

#### Option B: Next.js (`next.config.js`)
```javascript
module.exports = {
  async redirects() {
    return [{ source: '/debloat', destination: 'https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/main/Get-NHWinDebloater.ps1', permanent: false }];
  },
};
```

## Safety & Invariants

- **Zero Persistent Overhead:** Does not install permanent services, scheduled tasks, or startup entries.
- **Explicit Authorization:** No modifications occur without explicit user confirmation.
- **System Safeguards:** Core system components (Windows Store, Windows Security, Essential Frameworks) are protected against removal.
- **Pre-Tweak Registry Snapshots:** Automatic `.reg` backup snapshots generated before applying modifications with one-click folder inspection.
- **Automatic Sandbox & Session Cleanup:** Downloaded release archives and extracted temporary files in `%TEMP%\NHWinDebloater*` are automatically purged upon GUI or CLI exit, while user backups in `%LOCALAPPDATA%\NHWinDebloater\Backups` and session logs in `%LOCALAPPDATA%\NHWinDebloater\Logs` are strictly preserved.

---

## Windows SmartScreen, Defender & Execution Policy Transparency

When downloading scripts or tools directly from GitHub, Windows may display a **Windows SmartScreen** prompt (*"Windows protected your PC"*) or PowerShell may restrict script execution (`ExecutionPolicy`). Here is why this happens and how to handle it safely:

### 1. Why Does SmartScreen or Defender Prompt?
- **Mark-of-the-Web (MOTW):** Files downloaded via browsers or web streams receive an alternate data stream identifier (`Zone.Identifier`) marking them as coming from the internet. Windows displays SmartScreen prompts for any unsigned script or executable that has not yet accumulated millions of global download reputation signals.
- **100% Open Source & Zero Binaries:** NH Win Debloater contains **zero compiled binaries (.exe/.dll)**, **zero obfuscated code**, and **zero hidden telemetry**. Every line of PowerShell (`.ps1`, `.psm1`) and XAML is open, readable, and auditable directly in this repository.

### 2. How to Run Unrestricted:
- **SmartScreen Prompt:** Click **More info** -> **Run anyway**.
- **PowerShell Execution Policy:** To permit local script execution in your PowerShell session:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
- **Unblocking Downloaded Files (GUI / CLI):**
  - *GUI:* Right-click the downloaded `.zip` or folder -> **Properties** -> Check **Unblock** -> Click **Apply**.
  - *PowerShell:*
    ```powershell
    Get-ChildItem -Path "C:\Path\To\NH Win Debloater" -Recurse | Unblock-File
    ```
- **Windows Defender Local Folder Exclusion (Optional for Developers):**
  If you regularly run debloat or administrative scripts, you can optionally exclude your development directory:
  ```powershell
  # Run in elevated Administrator PowerShell if desired:
  Add-MpPreference -ExclusionPath "C:\Users\<YourUser>\Projects\NH Win Debloater"
  ```

---

## About NH Digital

> **Crafted with care by NH Digital**  
> We build high-performance utilities, digital templates, and automation tools designed to make your workflow faster and cleaner.  
> 
> Explore our full catalog of software tools, presets, and digital resources at:  
> **[nhdigital.shop](https://nhdigital.shop)**

---

## License & Attribution

- Built and maintained by **NH Digital**.
- Third-party registry discoveries and package definitions are credited under the MIT License in [THIRD_PARTY_LICENSES.md](docs/THIRD_PARTY_LICENSES.md).

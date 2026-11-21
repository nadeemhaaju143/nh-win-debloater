# How To Use NH Win Debloater

This guide covers running NH Win Debloater via the branded one-line launcher, command-line arguments, offline standalone execution, and managing portable JSON preset profiles.

---

## Method 1: Ultra-Short Branded One-Line Launcher (Recommended)

You can launch NH Win Debloater directly in PowerShell without downloading archives or extracting files.

1. Open **Windows PowerShell** (Run as Administrator recommended for system tweaks).
2. Execute the primary command:

```powershell
irm nhdigital.shop/debloat | iex
```

*Short alias:*
```powershell
irm nhdigital.shop/w | iex
```

*Direct GitHub raw fallback:*
```powershell
irm https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/main/Get-NHWinDebloater.ps1 | iex
```

### What happens behind the scenes?
- Connects securely to the GitHub repository to retrieve the verified stable release package.
- Extracts files into an isolated transient folder (`%TEMP%\NHWinDebloater_*`).
- Launches the modern Material 3 WPF Guided Assistant in an STA execution thread.
- Upon closing the application, all transient temp files are automatically deleted, preserving your backups in `%LOCALAPPDATA%\NHWinDebloater\Backups` and logs in `%LOCALAPPDATA%\NHWinDebloater\Logs`.

---

## Power-User CLI & Simulation Flags

All command-line parameters can be passed directly to the one-line launcher:

### 1. Interactive CLI Mode (`-CLI`)
For remote terminal environments, SSH sessions, or headless administrative deployment:

```powershell
& ([ScriptBlock]::Create((irm nhdigital.shop/debloat))) -CLI
```

### 2. Safe Dry-Run Simulation Mode (`-DryRun`)
Simulates execution without modifying registry keys, services, or installed packages:

```powershell
& ([ScriptBlock]::Create((irm nhdigital.shop/debloat))) -DryRun
```

### 3. Automated Silent Mode (`-Silent`)
Applies the baseline Recommended profile without interactive confirmation:

```powershell
& ([ScriptBlock]::Create((irm nhdigital.shop/debloat))) -Silent
```

---

## Method 2: Manual Download & Offline Execution

If your target workstation is air-gapped or has restricted network access:

1. Download the latest release `.zip` from [GitHub Releases](https://github.com/nadeemhaaju143/nh-win-debloater/releases).
2. Extract the archive to a local folder (e.g., `C:\Tools\NH-Win-Debloater`).
3. Run via PowerShell:
   ```powershell
   Set-Location "C:\Tools\NH-Win-Debloater"
   .\run.ps1
   ```
4. Or double-click `Run.bat`, which will handle elevation and launch the assistant automatically.

---

## Custom Preset Profiles (`.json`)

NH Win Debloater allows exporting and importing tailored configurations so power users, system administrators, and IT teams can deploy uniform setups across multiple machines.

### Exporting a Profile:
1. In the WPF Assistant, navigate to **Stage 2 (Refine Packages & System Tweaks)**.
2. Select or customize your exact bloatware packages, privacy policies, shell customizations, and AI toggles.
3. Click the **Export Profile (.json)** button in the top right.
4. Choose a file location (e.g., `CleanWorkstation.json` or `GamingRig.json`).

### Importing a Profile:
1. Open NH Win Debloater on any machine.
2. On **Stage 1 (Opening Screen)**, click **Import Preset (.json)**.
3. Select your exported `.json` file.
4. The assistant validates the schema, verifies all keys and package identifiers, and ticks the exact configuration ready for execution.

---

## Troubleshooting & Execution Policies

If PowerShell restricts script execution with `ExecutionPolicy` errors:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
This enables script execution strictly for your active terminal window without altering system-wide security settings.

# App Removal & Package Management

NH Win Debloater categorizes removable UWP, Provisioned, and Microsoft Store packages into distinct risk and utility tiers. It ensures that essential system functionality remains completely untouched while eliminating sponsored and unwanted bloat.

---

## 1. Protected Core System Applications

To prevent operating system instability, accidental loss of system security, or breaking the Windows servicing engine, NH Win Debloater strictly safeguards core packages. These protected packages **cannot** be removed:

| Protected Package Identifier | Component Name | Why It Is Protected |
| :--- | :--- | :--- |
| `Microsoft.WindowsStore` | **Microsoft Store** | Required for installing, updating, and servicing legitimate software |
| `Microsoft.SecHealthUI` | **Windows Security** | Core antivirus, firewall, and device security management dashboard |
| `Microsoft.DesktopAppInstaller` | **App Installer (WinGet)** | Required for package management and CLI winget deployments |
| `Microsoft.VCLibs.*` | **VC++ Runtimes** | Core C++ shared libraries required by desktop applications |
| `Microsoft.UI.Xaml.*` | **WinUI Framework** | Required for modern Windows UI rendering |
| `Microsoft.NET.Native.*` | **.NET Native Framework** | Critical runtime engine for UWP applications |

---

## 2. Removable Bloatware Categories

Removable applications are organized into granular categories with multi-select checkboxes:

### Category: Recommended Bloatware (80+ Packages)
Pre-installed consumer apps that do not affect core system features:
- **Sponsored Games & Promos:** Solitaire Collection, Candy Crush, Bubble Witch, Disney+, Spotify, Netflix, TikTok.
- **Third-Party Trials:** McAfee/Norton pre-loaders, Amazon apps, Adobe promo stubs.
- **Consumer Nudges:** Feedback Hub, Tips, Get Help, Microsoft News, MSN Weather, Mixed Reality Portal.

### Category: Minimal Debloat
Lightweight preset for cautious users:
- Removes sponsored promotional apps while leaving all built-in utility tools, media players, and Xbox tools completely untouched.

### Category: Deep Debloat
Aggressive preset for workstations and benchmark rigs:
- Removes all non-essential consumer packages including built-in media players (Zune Music/Video, Movies & TV), Voice Recorder, Sticky Notes, and Mail/Calendar.

### Category: Xbox & Gaming Integration
For workstations that do not play Xbox games:
- `Microsoft.XboxApp`, `Microsoft.XboxGamingOverlay`, `Microsoft.XboxIdentityProvider`, `Microsoft.XboxSpeechToTextOverlay`.
*(Note: If you play Xbox Game Pass titles, leave this category unchecked.)*

### Category: OEM Pre-Installs
Manufacturer-specific pre-installed bloat:
- Dell, HP, Lenovo, ASUS, and Acer consumer support utilities that consume background CPU cycles.

---

## 3. App Selection Safety Indicators & Legend

In v1.2.0, every application in the catalog features a high-contrast safety indicator and badge:

- 🟢 **Recommended (Green `#10B981`):** Safe bloatware packages universally recommended for removal without affecting workflow.
- 🟡 **Optional (Amber `#F59E0B`):** User preference applications such as Xbox services, built-in media tools, or office viewers.
- 🔴 **Not Recommended (Red `#EF4444`):** Protected system components and frameworks that must remain intact.

A persistent **Safety Legend Bar** is displayed along the bottom of the App Removal view for quick reference.

---

## 4. Windows Built-in App Reinstall Helper

If you ever need to restore a default Windows utility (such as Calculator or Notepad) or re-register the Microsoft Store:

1. Click the **Reinstall Apps** button in the header bar or in Stage 5.
2. The **Windows Built-in App Reinstall Helper** modal appears.
3. Select the applications you wish to reinstall:
   - **Microsoft Store** (`wsreset -i`)
   - **Windows Calculator**
   - **Windows Notepad**
   - **Microsoft Paint**
   - **Microsoft Photos**
   - **Windows Terminal**
4. Optional: Tick **Dry-Run Preview Only** to simulate the re-registration without altering packages.
5. Click **Reinstall Selected**. The engine executes native PowerShell package manifests and live-logs progress directly into the dialog.

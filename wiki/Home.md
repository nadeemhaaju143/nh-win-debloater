# Welcome to NH Win Debloater Documentation

**NH Win Debloater** is an advanced, lightweight, temporary Windows optimization utility designed to safely remove pre-installed bloatware applications, disable invasive system telemetry, suppress background AI surveillance services, and optimize Windows 10 and Windows 11 performance without persistent overhead or background processes.

---

## Quick Navigation

| Document | Description |
| :--- | :--- |
| **[[How-To-Use\|How To Use]]** | 1-line launcher, CLI flags, offline ZIP execution, and custom JSON profiles |
| **[[Features\|Features]]** | In-depth breakdown of Privacy, AI, Shell, Gaming, and System Tweaks |
| **[[App-Removal\|App Removal]]** | Removable UWP/Store packages, protected core apps, and Reinstall Helper |
| **[[Reverting-Changes\|Reverting Changes]]** | 1-Click snapshot rollback, Selective Multi-Select Restore, and safety checkpoints |

---

## Core Philosophy & Design Principles

1. **Zero Persistent Overhead:** Unlike heavy tuning utilities, NH Win Debloater does not install background services, scheduled polling tasks, or startup agents. It runs strictly on-demand and cleans up its temporary execution files upon exit.
2. **Explicit User Consent & Transparency:** Every removal and registry adjustment is presented with clear descriptions, category filters, and safety impact ratings. No changes occur without explicit user confirmation.
3. **Multi-Tiered Safety Architecture:**
   - **Automatic Pre-Tweak Registry Snapshots:** A complete `.reg` backup is captured to `%LOCALAPPDATA%\NHWinDebloater\Backups` prior to applying any system modifications.
   - **Windows System Restore Checkpoint:** Initiates native Windows System Restore checkpoints.
   - **Selective Multi-Select Rollback:** Allows restoring specific tweak categories (Privacy, Shell, Gaming, AI, Extras) or reinstalling removed apps without reverting desired settings.
   - **Protected System Packages:** Essential system components like Microsoft Store, Windows Security (`Microsoft.SecHealthUI`), and core runtime frameworks are strictly safeguarded and prevented from accidental deletion.
4. **Pure Native PowerShell & WPF:** Built using 100% native PowerShell 5.1/7+ and Windows Presentation Foundation (WPF) with zero third-party compiled binaries or external DLLs.

---

## Frequently Asked Questions (FAQ)

### Is NH Win Debloater safe for daily productivity and work PCs?
Yes. The default **Recommended Debloat** profile is intentionally curated to remove sponsored consumer bloatware (games, promotional apps, targeted ads) while keeping essential productivity tools, Microsoft Store, Windows Security, Xbox gaming services, and system frameworks completely intact.

### Will running NH Win Debloater break Windows Updates?
No. NH Win Debloater does not disable core Windows Update services or tamper with security patch distribution. It disables consumer content delivery and search suggestions, leaving update mechanisms fully operational.

### Can I revert changes if I change my mind?
Yes! NH Win Debloater includes a dedicated **Restore & Rollback Manager**:
- **1-Click Full Restore:** Re-applies your original pre-tweak registry snapshot.
- **Selective Restore:** Ticked multi-select checkboxes allow reinstalling apps only, restoring registry tweaks only, or restoring specific categories (e.g., re-enabling Copilot without restoring other bloatware).
- **App Reinstall Helper:** Re-registers built-in Windows applications (Calculator, Notepad, Paint, Photos, Terminal, Microsoft Store) with a single click.

---

## Creator & Open-Source Maintainer

**NH Win Debloater** is conceived, architected, and maintained by **Mohammed Nadeem BM** under **NH Digital**.

- **Lead Developer:** **Mohammed Nadeem BM**
- **Brand / Studio:** **NH Digital** ([https://nhdigital.shop](https://nhdigital.shop))
- **GitHub:** [@nadeemhaaju143](https://github.com/nadeemhaaju143)
- **Repository:** [https://github.com/nadeemhaaju143/nh-win-debloater](https://github.com/nadeemhaaju143/nh-win-debloater)

---

## Support Open-Source Development

If NH Win Debloater saved you time, reclaimed system memory, or improved your PC's responsiveness, consider supporting ongoing open-source engineering, cloud testing, and maintenance:

- **[One-Time Support Tip (Razorpay)](https://rzp.io/rzp/nh-win-debloater)** — Support continuous feature development and preflight test infrastructure.
- **[Monthly Supporter ₹199/mo (Razorpay)](https://rzp.io/rzp/j9CGaaRR)** — Sponsor monthly optimization research, Windows 11 update testing, and community support.

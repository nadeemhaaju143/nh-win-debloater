# NH Win Debloater

**Version:** 0.1  
**Tagline:** Less Bloat. Better Windows.  
**Developer:** NH Digital ([nhdigital.shop](https://nhdigital.shop))  

---

## Overview

**NH Win Debloater** is a modern, lightweight, temporary Windows utility designed to remove unnecessary pre-installed applications, streamline system telemetry, and optimize Windows 10 and 11 environments without persistent overhead or background services.

---

## Semantic Minor-Style Release Flow

NH Win Debloater adopts a progressive **minor-style semantic versioning cadence** starting at `v0.1`:

```
v0.1  -->  v0.2  -->  v0.3  -->  v0.4  --> ... -->  v1.0
(Init)     (Core)     (UI/WPF)   (Presets)         (Stable Release)
```

- **v0.1 (Current):** Project initialization, folder architecture, standalone launcher, and environment bootstrapper.
- **v0.2:** Core engine integration (AppX removal, WinGet support, atomic registry tweaks, and baseline backup snapshots).
- **v0.3:** Modern single-window WPF Guided Assistant interface with real-time progress reporting.
- **v0.4+:** Expanded debloat presets, community package signatures, and advanced Windows 11 feature configurations.
- **v1.0:** Consolidated, production-grade standalone utility.

Each increment introduces modular features, verified bloatware signatures, or safety refinements while maintaining backward compatibility and zero host system damage.

---

## Project Structure

```
NH Win Debloater/
├── Run.bat                     # Standalone launcher (handles elevation & execution policy)
├── VERSION.txt                 # Current version tracker (0.1)
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

1. Right-click `Run.bat` and select **Run as Administrator** (or double-click; `Run.bat` will request elevation automatically).
2. The bootstrapper initializes the execution environment, verifies Windows build compatibility, and loads the active configuration.
3. Follow the guided prompts to configure and review actions before applying changes.

---

## Safety & Invariants

- **Zero Persistent Overhead:** Does not install permanent services, scheduled tasks, or startup entries.
- **Explicit Authorization:** No modifications occur without explicit user confirmation.
- **System Safeguards:** Core system components (Windows Store, Windows Security, Essential Frameworks) are protected against removal.

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

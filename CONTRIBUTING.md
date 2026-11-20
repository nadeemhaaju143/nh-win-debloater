# Contributing to NH Win Debloater

Thank you for your interest in contributing to **NH Win Debloater**!

---

## 1. Governance & Strict Review Policy

To preserve the stability and safety of our users' Windows environments:
- **Pull Requests Required:** Direct pushes to the `main` branch are strictly prohibited.
- **Maintainer Approval:** All modifications require explicit review and approval by repository code owners (`@nadeemhaaju143`).
- **No Auto-Merging:** Unreviewed, automated, or bypass merges are blocked.
- **CI Status Checks:** Continuous Integration workflows must pass with 0 PSScriptAnalyzer issues and 100% test pass rates before any merge.

---

## 2. Quality & Safety Standards

1. **Pure Native PowerShell 5.1:** All scripts and modules must run natively on Windows PowerShell 5.1 without requiring third-party runtime dependencies (no Python, Node.js, C#, or external packages).
2. **Zero Analyzer Warnings:** All PowerShell source files must pass `Invoke-ScriptAnalyzer` with **0 errors and 0 warnings**.
3. **Protected Core Packages:** Essential Windows components (such as Microsoft Store, Windows Security / Defender, and Desktop App Installer) must remain strictly protected and non-removable.
4. **Reversible Modifications:** Any system or registry modifications must be accompanied by rollback and dry-run preview support.

---

## 3. Pull Request Process

1. Fork the repository and create a descriptive feature branch (`feature/your-feature-name` or `fix/your-fix-name`).
2. Implement your changes adhering to existing naming conventions and modular boundaries.
3. Validate locally:
   ```powershell
   Invoke-ScriptAnalyzer -Path .\src
   Invoke-Pester -Path .\tests
   ```
4. Submit a Pull Request targeting the `main` branch with the completed PR template.
5. Await code owner review and CI verification.

# Reverting Changes & Rollback Manager

NH Win Debloater provides a multi-layered recovery architecture designed to ensure peace of mind. Every modification made to system policies, registry values, or installed packages can be audited, rolled back, or selectively re-enabled.

---

## 1. Start-Screen Restore Shortcut

Returning users who have already run optimizations do not need to step through the entire wizard to restore their settings:

- A dedicated **Restore / Rollback** button is located in the **top header bar** and on **Stage 1 (Start Screen)**.
- Clicking this shortcut jumps directly to the **Stage 5 Restore Manager** without reapplying tweaks.
- A **Back** button is available in the footer if you navigated to the Restore Manager via the shortcut.

---

## 2. 1-Click Full Registry Rollback

Before applying optimizations, NH Win Debloater automatically captures a complete pre-tweak registry snapshot in JSON and `.reg` format, saved securely to:
```
%LOCALAPPDATA%\NHWinDebloater\Backups\RegistrySnapshot_<Timestamp>.json
```

### To execute a full 1-click restore:
1. Open NH Win Debloater and navigate to **Restore / Rollback**.
2. Under **1-Click Registry Snapshot & Rollback**, choose your snapshot from the dropdown list. Snapshots display date, filename, and file size (e.g., `2026-11-21 16:37:09 — RegistrySnapshot_20261121_163709.json (46.6 KB)`).
3. Click **Preview Snapshot** to inspect all previously captured registry values and their original states.
4. Click **1-Click Full Restore**. The rollback engine restores every original value and confirms completion.

---

## 3. Selective Multi-Select Restore

If you only want to reverse specific tweaks (for example, re-enabling Windows Copilot or reinstalling removed bloatware apps while keeping your gaming and shell optimizations active):

1. Open the **Restore / Rollback** view.
2. Under **Selective Restore**, click the **Restore Scope: Selective** dropdown.
3. Use the multi-select checkboxes to choose exactly what to restore:
   - **Apps Only:** Reinstall all or selected removed bloatware applications.
   - **Privacy Only:** Restore telemetry and advertising policy keys.
   - **Shell Only:** Revert taskbar alignment, File Explorer view, and context menus.
   - **Gaming Only:** Restore Game DVR, mouse acceleration, or power throttling settings.
   - **AI Only:** Re-enable Windows Copilot, Recall, and AI generation features.
   - **System Extras Only:** Restore lock screen suggestions and consumer features.
4. Use quick-action buttons: **Tweaks Only**, **Apps Only**, **Select All**, or **Clear**.
5. Click **Restore Selected Scope**. Only the ticked categories are reverted, leaving your other tweaks 100% untouched.

---

## 4. Windows System Restore Checkpoints

During Stage 3 (Safety & Dry-Run Preview), NH Win Debloater can automatically trigger a native Windows System Restore checkpoint:
- Creates a named restore point: `NH Win Debloater Pre-Optimization Checkpoint`.
- Can be restored at any time via Windows native recovery (`rstrui.exe`) or Windows Advanced Startup Options.

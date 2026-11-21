# Reverting Changes & Recovery Manager

NH Win Debloater provides a multi-layered recovery architecture designed to ensure total peace of mind. Every modification made to system policies, registry values, service configurations, or installed packages can be audited, rolled back, or selectively re-enabled.

---

## 1. Quick Access via Top Canvas & Start Screen

Returning users who have already run optimizations do not need to step through the entire wizard to restore their settings:

- A dedicated **Recovery & Rollback** entry is available from the **3-Line Menu (`☰`)** in the top right canvas.
- An immediate **Restore & Rollback Manager** shortcut button is located on **Stage 1 (Opening Screen)**.
- A **Restore / Rollback** button remains pinned in the header bar.
- Clicking any shortcut opens the **Recovery & Rollback Actions** modal or navigates directly to the **Stage 5 Restore Manager** without reapplying tweaks.

---

## 2. 1-Click Full System Rollback (v1.1.0)

For instant recovery of your workstation's original baseline state, NH Win Debloater v1.1.0 provides an atomic **1-Click Full System Rollback**:

1. Open the **Recovery & Rollback Actions** dialog from the 3-Line Menu (`☰`) or Stage 1.
2. Click **Execute Full Rollback** under **1-Click Full System Rollback**.
3. In a single click, the rollback engine:
   - Reverts all captured registry keys to their pre-tweak values.
   - Restores all background services (`DiagTrack`, `dmwappushservice`, `RetailDemo`, `MapsBroker`, `WerSvc`, `wisvc`, `Fax`, `PhoneSvc`) to their original startup types (`Automatic` / `Manual`).
   - Restores the original Start Menu pinned application layout from backup and refreshes the shell.
4. A confirmation dialog confirms successful rollback completion.

---

## 3. Restore Registry Snapshot

Before applying optimizations, NH Win Debloater automatically captures a complete pre-tweak registry snapshot in JSON format, saved securely to:
```
%LOCALAPPDATA%\NHWinDebloater\Backups\RegistrySnapshot_<Timestamp>.json
```

### To execute a registry restore:
1. Open NH Win Debloater and navigate to **Restore / Rollback** (Stage 5).
2. Under **1-Click Registry Snapshot & Rollback**, choose your snapshot from the dropdown list. Snapshots display date, filename, and file size (e.g., `2026-11-21 16:37:09 — RegistrySnapshot_20261121_163709.json (46.6 KB)`).
3. Click **Preview Snapshot** to inspect all previously captured registry values and their original states.
4. Click **1-Click Full Restore**. The rollback engine restores every original value and confirms completion.

---

## 4. Restore Start Menu Layout

When Start Menu cloud stubs are cleared, NH Win Debloater automatically creates a backup of the pinned layout files (`start.bin` and `start2.bin`) in:
```
%LOCALAPPDATA%\NHWinDebloater\Backups\StartMenu\
```

To restore your pinned icons:
1. Open the **Recovery & Rollback Actions** dialog.
2. Click **Restore Layout** under **Restore Start Menu Layout**.
3. The original pinned layout files are restored and `StartMenuExperienceHost` is safely restarted to refresh the Start Menu immediately.

---

## 5. Selective Multi-Select Restore

If you only want to reverse specific tweaks (for example, re-enabling Windows Copilot or reinstalling removed bloatware apps while keeping your gaming and shell optimizations active):

1. Open the **Restore / Rollback** view (Stage 5).
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

## 6. Windows System Restore Checkpoints

Before applying modifications, NH Win Debloater calls the native Windows System Restore engine to create an official System Restore Point named `NHWinDebloater_PreDebloat_<Timestamp>`.

If you ever encounter an issue that cannot be resolved via registry rollback, you can restore your system using native Windows System Restore:
1. Press `Win + R`, type `rstrui.exe`, and hit Enter.
2. Select your `NHWinDebloater_PreDebloat` restore point.
3. Follow the Windows wizard to revert the workstation state.

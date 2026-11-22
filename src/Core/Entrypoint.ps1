<#
    .SYNOPSIS
        NH Win Debloater - Main Entrypoint & Bootstrapper
    .DESCRIPTION
        Temporary, zero-install Windows debloating and optimization assistant.
        Supports both modern WPF Guided Assistant GUI and standalone CLI modes.
        Built by NH Digital (https://nhdigital.shop)
    .VERSION
        0.4
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
param(
    [switch]$DryRun,
    [switch]$Silent,
    [switch]$CLI
)

# 1. Robust Path Resolution (Guaranteed <ProjectRoot>\src\UI regardless of working directory or VM placement)
$CoreDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$SrcDirectory = Split-Path -Parent $CoreDirectory
$ProjectRootDirectory = Split-Path -Parent $SrcDirectory
$PresetsDirectory = Join-Path $SrcDirectory "Presets"
$UiDirectory = Join-Path $SrcDirectory "UI"
$AppControllerScript = Join-Path $UiDirectory "AppController.ps1"

$versionFile = Join-Path $ProjectRootDirectory "VERSION.txt"
$script:AppVersion = if (Test-Path $versionFile) { (Get-Content -Path $versionFile -Raw).Trim() } else { "0.5" }

if ($Host -and $Host.UI -and $Host.UI.RawUI) {
    $Host.UI.RawUI.WindowTitle = "NH Win Debloater v$($script:AppVersion) - NH Digital"
}

# 2. Import Core Modules
Import-Module (Join-Path $CoreDirectory "AppManager.psm1") -Force
Import-Module (Join-Path $CoreDirectory "PrivacySearch.psm1") -Force
Import-Module (Join-Path $CoreDirectory "ShellCustomization.psm1") -Force
Import-Module (Join-Path $CoreDirectory "SystemTweaks.psm1") -Force
Import-Module (Join-Path $CoreDirectory "ExecutionLog.psm1") -Force

# Initialize Logging
Initialize-DebloatLogger -Version $script:AppVersion | Out-Null

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host " ======================================================================" -ForegroundColor Cyan
    Write-Host "   NH WIN DEBLOATER v$($script:AppVersion)" -ForegroundColor White
    Write-Host "   Less Bloat. Better Windows." -ForegroundColor Gray
    Write-Host "   Developed by Mohammed Nadeem BM - NH Digital | https://nhdigital.shop" -ForegroundColor DarkCyan
    Write-Host " ======================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# 3. Platform Detection
$os = Get-CimInstance Win32_OperatingSystem
$buildNumber = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

try {
    # 4. Dry-Run Mode
if ($DryRun) {
    Show-Header
    Write-Host " [+] Operating System : $($os.Caption) (Build $buildNumber)" -ForegroundColor Green
    Write-Host " [+] PowerShell Ver   : $($PSVersionTable.PSVersion.ToString())" -ForegroundColor Green
    Write-Host ""
    Write-Host "Executing in DryRun preview mode..." -ForegroundColor Cyan
    Invoke-DebloatAction -ActionName "Disable Telemetry" -DryRun -ScriptBlock { Set-PrivacySetting -SettingId "DisableTelemetry" -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Copilot" -DryRun -ScriptBlock { Set-PrivacySetting -SettingId "DisableCopilot" -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Windows Copilot AI Suite" -DryRun -ScriptBlock { Set-CopilotAITweak -DisableCopilot $true -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Windows Recall & Snapshots" -DryRun -ScriptBlock { Set-RecallAITweak -DisableRecall $true -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Edge, Paint & Notepad AI" -DryRun -ScriptBlock { Set-ApplicationAITweak -DisableEdgeAI $true -DisablePaintAI $true -DisableNotepadAI $true -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Show File Extensions" -DryRun -ScriptBlock { Set-ShellSetting -SettingId "ShowFileExtensions" -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Game DVR" -DryRun -ScriptBlock { Set-GameDVRPlaybackTweak -DisableGameDVR $true -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Delivery Optimization P2P" -DryRun -ScriptBlock { Set-DeliveryOptimizationTweak -DisableP2P $true -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Edge Background Mode" -DryRun -ScriptBlock { Set-EdgeBackgroundTweak -DisableEdgeBackground $true -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Telemetry Scheduled Tasks" -DryRun -ScriptBlock { Set-TelemetryScheduledTasksTweak -DisableTasks $true -WhatIf } | Out-Null
    Invoke-DebloatAction -ActionName "Disable Multitasking Snap Suggestions" -DryRun -ScriptBlock { Set-MultitaskingTweak -DisableSnapSuggestions $true -WhatIf } | Out-Null
    exit 0
}

# 5. Silent Mode
if ($Silent) {
    Set-PrivacySetting -SettingId "All" -Enable $true | Out-Null
    Set-ConsumerFeatureTweak -Disable $true | Out-Null
    Set-LockScreenTweak -Disable $true | Out-Null
    Set-GameDVRPlaybackTweak -DisableGameDVR $true | Out-Null
    Set-DeliveryOptimizationTweak -DisableP2P $true | Out-Null
    Set-EdgeBackgroundTweak -DisableEdgeBackground $true | Out-Null
    Set-TelemetryScheduledTasksTweak -DisableTasks $true | Out-Null
    Set-MultitaskingTweak -DisableSnapSuggestions $true | Out-Null
    exit 0
}

# 6. GUI Launch Mode (Default when not explicitly in CLI)
if (-not $CLI) {
    # Ensure Single-Thread Apartment (STA) mode required for WPF
    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
        Write-Verbose "Single-Thread Apartment (STA) mode required for WPF. Launching STA process..."
        $entrypointFile = Join-Path $CoreDirectory "Entrypoint.ps1"
        $psArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-STA", "-File", $entrypointFile)
        $proc = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -PassThru -Wait
        exit $proc.ExitCode
    }

    try {
        if (-not (Test-Path $AppControllerScript)) {
            throw "UI Controller script not found at expected location: '$AppControllerScript'."
        }

        Import-Module $AppControllerScript -Force
        Show-DebloaterWindow -ProjectRoot $ProjectRootDirectory
        exit 0
    }
    catch {
        Write-Warning "Could not start Graphical Interface: $($_.Exception.Message)"
        Write-Host "Falling back to interactive CLI console..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
}

# 7. Interactive CLI Console
Show-Header

Write-Host " [+] Operating System : " -NoNewline -ForegroundColor Gray
Write-Host "$($os.Caption) (Build $buildNumber)" -ForegroundColor Green

Write-Host " [+] PowerShell Ver   : " -NoNewline -ForegroundColor Gray
Write-Host "$($PSVersionTable.PSVersion.ToString())" -ForegroundColor Green

Write-Host " [+] Elevated (Admin) : " -NoNewline -ForegroundColor Gray
if ($isAdmin) {
    Write-Host "Yes (Full Privileges)" -ForegroundColor Green
} else {
    Write-Host "No (Restricted - Run as Administrator recommended)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host " [i] Status: v$($script:AppVersion) Core Debloat Modules & UI Controller Loaded." -ForegroundColor Cyan
Write-Host ""

Write-Host "Select an action to perform:" -ForegroundColor White
Write-Host " [G] Launch Graphical Setup Assistant (WPF)" -ForegroundColor Cyan
Write-Host " [1] Preview Recommended Debloat Actions (Dry-Run Mode)" -ForegroundColor White
Write-Host " [2] Apply Privacy & Telemetry Optimizations" -ForegroundColor White
Write-Host " [3] Apply UI & File Explorer Optimizations" -ForegroundColor White
Write-Host " [4] Apply System & Gaming Tweaks (Game DVR, Delivery Optimization, Lock Screen)" -ForegroundColor White
Write-Host " [5] Scan Installed Bloatware Packages" -ForegroundColor White
Write-Host " [6] Registry Snapshot & Rollback Manager (Restore / Preview)" -ForegroundColor White
Write-Host " [7] Re-register Default Windows Store Apps" -ForegroundColor White
Write-Host " [8] Apply AI Integration Debloat (Copilot, Recall, Edge/Paint/Notepad AI)" -ForegroundColor White
Write-Host " [9] Reinstall Common Built-in Windows Apps (Store, Calculator, Notepad, Paint, Photos, Terminal)" -ForegroundColor White
Write-Host " [Q] Exit" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host " Enter choice (G, 1-9, Q)"

switch ($choice) {
    "G" {
        if (Test-Path $AppControllerScript) {
            Import-Module $AppControllerScript -Force
            Show-DebloaterWindow -ProjectRoot $ProjectRootDirectory
        } else {
            Write-Error "UI Controller not found at: '$AppControllerScript'"
        }
    }
    "1" {
        Write-Host "`n--- DRY-RUN PREVIEW OF RECOMMENDED ACTIONS ---" -ForegroundColor Cyan
        Invoke-DebloatAction -ActionName "Disable Telemetry & Diagnostics" -DryRun -ScriptBlock {
            Set-PrivacySetting -SettingId "DisableTelemetry" -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Copilot & Recall" -DryRun -ScriptBlock {
            Set-PrivacySetting -SettingId "DisableCopilot" -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Windows Copilot AI Suite" -DryRun -ScriptBlock {
            Set-CopilotAITweak -DisableCopilot $true -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Windows Recall & Snapshots" -DryRun -ScriptBlock {
            Set-RecallAITweak -DisableRecall $true -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable App AI (Edge, Paint, Notepad)" -DryRun -ScriptBlock {
            Set-ApplicationAITweak -DisableEdgeAI $true -DisablePaintAI $true -DisableNotepadAI $true -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Bing Search in Start" -DryRun -ScriptBlock {
            Set-PrivacySetting -SettingId "DisableBingSearch" -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Show File Extensions" -DryRun -ScriptBlock {
            Set-ShellSetting -SettingId "ShowFileExtensions" -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Consumer Features" -DryRun -ScriptBlock {
            Set-ConsumerFeatureTweak -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Game DVR Background Recording" -DryRun -ScriptBlock {
            Set-GameDVRPlaybackTweak -DisableGameDVR $true -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Delivery Optimization P2P" -DryRun -ScriptBlock {
            Set-DeliveryOptimizationTweak -DisableP2P $true -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Edge Background Mode" -DryRun -ScriptBlock {
            Set-EdgeBackgroundTweak -DisableEdgeBackground $true -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Telemetry Scheduled Tasks" -DryRun -ScriptBlock {
            Set-TelemetryScheduledTasksTweak -DisableTasks $true -WhatIf
        } | Out-Null
        Invoke-DebloatAction -ActionName "Disable Multitasking Snap Suggestions" -DryRun -ScriptBlock {
            Set-MultitaskingTweak -DisableSnapSuggestions $true -WhatIf
        } | Out-Null
        Write-Host "`nDry-run preview completed. No system changes were made." -ForegroundColor Green
    }
    "2" {
        Write-Host "`nApplying Privacy & Telemetry Optimizations..." -ForegroundColor Yellow
        $privResults = Set-PrivacySetting -SettingId "All" -Enable $true
        $privResults | Format-Table Path, Name, Value, Status -AutoSize
    }
    "3" {
        Write-Host "`nApplying UI & File Explorer Optimizations..." -ForegroundColor Yellow
        Set-ShellSetting -SettingId "ShowFileExtensions" | Out-Null
        Set-ShellSetting -SettingId "ShowHiddenFiles" | Out-Null
        Set-ShellSetting -SettingId "HideWidgets" | Out-Null
        Set-ShellSetting -SettingId "HideChat" | Out-Null
        Set-ShellSetting -SettingId "EnableEndTask" | Out-Null
        Write-Host "UI Optimizations applied. Restarting Explorer..." -ForegroundColor Green
        Restart-ShellExplorer
    }
    "4" {
        Write-Host "`nApplying System & Gaming Extras..." -ForegroundColor Yellow
        Set-ConsumerFeatureTweak -Disable $true | Format-Table Path, Name, Status -AutoSize
        Set-LockScreenTweak -Disable $true | Format-Table Path, Name, Status -AutoSize
        Set-GameDVRPlaybackTweak -DisableGameDVR $true | Format-Table Path, Name, Status -AutoSize
        Set-DeliveryOptimizationTweak -DisableP2P $true | Format-Table Path, Name, Status -AutoSize
        Set-EdgeBackgroundTweak -DisableEdgeBackground $true | Format-Table Path, Name, Status -AutoSize
        Set-TelemetryScheduledTasksTweak -DisableTasks $true | Format-Table Path, Name, Status -AutoSize
        Set-MultitaskingTweak -DisableSnapSuggestions $true | Format-Table Path, Name, Status -AutoSize
    }
    "5" {
        Write-Host "`nScanning installed AppX packages..." -ForegroundColor Yellow
        $installed = Get-InstalledDebloatApp -PresetsPath $PresetsDirectory
        $bloatCount = ($installed | Where-Object { -not $_.IsProtected }).Count
        Write-Host "Found $($installed.Count) total packages ($bloatCount non-protected)." -ForegroundColor Green
        $installed | Select-Object -First 20 AppId, IsProvisioned, IsProtected | Format-Table -AutoSize
    }
    "6" {
        Write-Host "`n=== REGISTRY SNAPSHOT & ROLLBACK MANAGER ===" -ForegroundColor Cyan
        $backups = Get-DebloatBackup
        if ($backups.Count -eq 0) {
            Write-Host "No registry snapshots found in local backup store." -ForegroundColor Gray
        } else {
            Write-Host "Available Registry Snapshots:" -ForegroundColor White
            for ($i = 0; $i -lt $backups.Count; $i++) {
                $b = $backups[$i]
                Write-Host " [$($i + 1)] $($b.FileName) ($($b.LastModified) - $($b.SizeKb) KB)" -ForegroundColor Yellow
            }
            Write-Host ""
            $snapChoice = Read-Host " Enter snapshot number to restore (e.g. 1), or prefix 'P' for dry-run preview (e.g. P1), or press Enter to cancel"
            if (-not [string]::IsNullOrWhiteSpace($snapChoice)) {
                $isPreview = $snapChoice -match "^[Pp]"
                $idxStr = $snapChoice -replace "^[Pp]", ""
                $idx = 0
                if ([int]::TryParse($idxStr, [ref]$idx) -and $idx -ge 1 -and $idx -le $backups.Count) {
                    $targetBackup = $backups[$idx - 1]
                    if ($isPreview) {
                        Write-Host "`nPreviewing rollback for $($targetBackup.FileName)..." -ForegroundColor Cyan
                        $res = Restore-RegistrySnapshot -SnapshotPath $targetBackup.FilePath -WhatIf
                        Write-Host "Preview complete: $($res.Count) registry keys would be restored." -ForegroundColor Green
                    } else {
                        $confirm = Read-Host " Confirm restore of snapshot '$($targetBackup.FileName)'? (Y/N)"
                        if ($confirm -eq "Y" -or $confirm -eq "y") {
                            Write-Host "`nRestoring registry values from $($targetBackup.FileName)..." -ForegroundColor Yellow
                            $res = Restore-RegistrySnapshot -SnapshotPath $targetBackup.FilePath
                            Write-Host "Rollback complete: $($res.Count) registry values restored successfully." -ForegroundColor Green
                        } else {
                            Write-Host "Restore cancelled." -ForegroundColor Gray
                        }
                    }
                } else {
                    Write-Host "Invalid snapshot selection." -ForegroundColor Red
                }
            }
        }
    }
    "7" {
        Write-Host "`nRe-registering default apps from WindowsApps store..." -ForegroundColor Yellow
        Restore-DefaultApp -AppId "All" | Select-Object -First 10 AppId, Status, Message | Format-Table -AutoSize
    }
    "8" {
        Write-Host "`nApplying AI Integration Debloat..." -ForegroundColor Yellow
        $aiResults = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($item in (Set-CopilotAITweak -DisableCopilot $true)) { $aiResults.Add($item) }
        foreach ($item in (Set-RecallAITweak -DisableRecall $true)) { $aiResults.Add($item) }
        foreach ($item in (Set-ApplicationAITweak -DisableEdgeAI $true -DisablePaintAI $true -DisableNotepadAI $true)) { $aiResults.Add($item) }
        $aiResults | Format-Table Path, Name, Status -AutoSize
    }
    "9" {
        Write-Host "`n=== REINSTALL COMMON BUILT-IN WINDOWS APPS ===" -ForegroundColor Cyan
        Write-Host " [1] Microsoft Store (wsreset -i)" -ForegroundColor White
        Write-Host " [2] Windows Calculator" -ForegroundColor White
        Write-Host " [3] Windows Notepad" -ForegroundColor White
        Write-Host " [4] Paint" -ForegroundColor White
        Write-Host " [5] Microsoft Photos" -ForegroundColor White
        Write-Host " [6] Windows Terminal" -ForegroundColor White
        Write-Host " [A] Reinstall All Common Apps" -ForegroundColor Yellow
        Write-Host ""
        $appChoice = Read-Host " Enter app number (1-6, A) or press Enter to cancel"
        $appsToInstall = @()
        switch ($appChoice) {
            "1" { $appsToInstall = @("Store") }
            "2" { $appsToInstall = @("Calculator") }
            "3" { $appsToInstall = @("Notepad") }
            "4" { $appsToInstall = @("Paint") }
            "5" { $appsToInstall = @("Photos") }
            "6" { $appsToInstall = @("Terminal") }
            "A" { $appsToInstall = @("Store", "Calculator", "Notepad", "Paint", "Photos", "Terminal") }
        }
        if ($appsToInstall.Count -gt 0) {
            $dryConfirm = Read-Host " Run in Dry-Run preview mode first? (Y/N)"
            $isDry = ($dryConfirm -eq "Y" -or $dryConfirm -eq "y")
            foreach ($app in $appsToInstall) {
                Write-Host " -> Processing: $app..." -ForegroundColor Cyan
                $res = Install-CommonWindowsApp -AppName $app -WhatIf:$isDry
                Write-Host "    [$($res.Status)] $($res.DisplayName): $($res.Message)" -ForegroundColor Green
            }
        }
    }
    Default {
        Write-Host "Exiting NH Win Debloater." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host " Explore more digital tools and updates at:" -ForegroundColor DarkGray
Write-Host " https://nhdigital.shop" -ForegroundColor Cyan
Write-Host ""
Write-Host " Press any key to finish..." -ForegroundColor Gray
    try {
        if ([System.Environment]::UserInteractive -and -not [System.Console]::IsInputRedirected) {
            $null = [System.Console]::ReadKey()
        }
    } catch {
        Write-Verbose "Non-interactive or redirected console session: $($_.Exception.Message)"
    }
}
finally {
    # Post-Exit Temp & Session Cleanup (Preserving Backups in %LOCALAPPDATA%\NHWinDebloater\Backups)
    if (Get-Command Clear-DebloatTempSession -ErrorAction SilentlyContinue) {
        Clear-DebloatTempSession
    }
}

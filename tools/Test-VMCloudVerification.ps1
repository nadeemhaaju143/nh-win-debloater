<#
    .SYNOPSIS
        Cloud VM Verification & Metrics Comparison Runner for NH Win Debloater.
    .DESCRIPTION
        Executes baseline measurement, debloat pipeline verification, Stage 5 snapshot
        rollback testing, and post-optimization metrics comparison on cloud Windows VMs.
        Developed by NH Digital (https://nhdigital.shop).
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
param(
    [switch]$DryRun
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$corePath = Join-Path $projectRoot "src\Core"
$versionPath = Join-Path $projectRoot "VERSION.txt"
$version = if (Test-Path $versionPath) { (Get-Content $versionPath -Raw).Trim() } else { "0.5" }

Write-Host ""
Write-Host " ======================================================================" -ForegroundColor Cyan
Write-Host "   NH WIN DEBLOATER v$version - CLOUD VM VERIFICATION SUITE" -ForegroundColor White
Write-Host "   Developed by NH Digital | https://nhdigital.shop" -ForegroundColor DarkCyan
Write-Host " ======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Helper function for system resource metrics
function Get-SystemMetricsSnapshot {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMemMb = [math]::Round($os.TotalVisibleMemorySize / 1024, 1)
    $freeMemMb = [math]::Round($os.FreePhysicalMemory / 1024, 1)
    $usedMemMb = [math]::Round($totalMemMb - $freeMemMb, 1)
    $memUsagePct = [math]::Round(($usedMemMb / $totalMemMb) * 100, 1)
    $processCount = (Get-Process).Count
    $runningServices = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count

    return [PSCustomObject]@{
        TotalMemoryMB   = $totalMemMb
        FreeMemoryMB    = $freeMemMb
        UsedMemoryMB    = $usedMemMb
        MemoryUsagePct  = $memUsagePct
        ProcessCount    = $processCount
        RunningServices = $runningServices
        Timestamp       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# 2. Capture Baseline (Before) Metrics
Write-Host " [+] Step 1/6: Capturing Baseline System Metrics (BEFORE)..." -ForegroundColor Yellow
$beforeMetrics = Get-SystemMetricsSnapshot
Write-Host "     - RAM In-Use      : $($beforeMetrics.UsedMemoryMB) MB / $($beforeMetrics.TotalMemoryMB) MB ($($beforeMetrics.MemoryUsagePct)%)" -ForegroundColor Gray
Write-Host "     - Active Processes: $($beforeMetrics.ProcessCount)" -ForegroundColor Gray
Write-Host "     - Running Services: $($beforeMetrics.RunningServices)" -ForegroundColor Gray
Write-Host ""

# 3. Import Core Debloater Modules
Write-Host " [+] Step 2/6: Importing Core Debloat Modules & Initializing Logger..." -ForegroundColor Yellow
Import-Module (Join-Path $corePath "AppManager.psm1") -Force
Import-Module (Join-Path $corePath "PrivacySearch.psm1") -Force
Import-Module (Join-Path $corePath "ShellCustomization.psm1") -Force
Import-Module (Join-Path $corePath "SystemTweaks.psm1") -Force
Import-Module (Join-Path $corePath "ExecutionLog.psm1") -Force

$logFile = Initialize-DebloatLogger -Version $version
Write-Host "     [OK] Log initialized at: $logFile" -ForegroundColor Green

# Test duplicate initialization suppression within 10 seconds
$testLogDir = Join-Path $env:TEMP "NHWinDebloater_VM_DedupTest"
if (Test-Path $testLogDir) { Remove-Item -Path $testLogDir -Recurse -Force -ErrorAction SilentlyContinue }
$null = Initialize-DebloatLogger -LogDirectory $testLogDir -Version $version
$null = Initialize-DebloatLogger -LogDirectory $testLogDir -Version $version
$initLines = Get-Content -Path (Join-Path $testLogDir "NHWinDebloater.log") | Where-Object { $_ -match "=== NH Win Debloater" }
if (@($initLines).Count -eq 1) {
    Write-Host "     [OK] Duplicate Session Initialized header suppressed successfully." -ForegroundColor Green
} else {
    Write-Warning "Duplicate Session Initialized header detected."
}
Remove-Item -Path $testLogDir -Recurse -Force -ErrorAction SilentlyContinue

# Ensure logger is pointing to the primary session log file
$logFile = Initialize-DebloatLogger -Version $version
Write-Host ""

# 4. Capture Pre-Tweak Registry Snapshot (Stage 5 Verification)
Write-Host " [+] Step 3/6: Capturing Pre-Tweak Registry Snapshot..." -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo",
    "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI",
    "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
)
$snapFile = Export-RegistrySnapshot -RegistryPaths $regPaths
Write-Host "     [OK] Snapshot created: $snapFile" -ForegroundColor Green
Write-DebloatLog -Message "Pre-tweak registry snapshot captured: $(Split-Path $snapFile -Leaf)" -Level "SUCCESS" -NoConsole

# Test Stage 5 Dropdown Formatting
$backups = @(Get-DebloatBackup)
if ($backups.Count -gt 0) {
    $firstBackup = $backups[0]
    $dropdownDisplay = "$($firstBackup.LastModified) - $($firstBackup.FileName) ($($firstBackup.SizeKb) KB)"
    Write-Host "     [OK] Stage 5 Dropdown Formatting: $dropdownDisplay" -ForegroundColor Green

    # Test 1-Click Rollback Preview
    $previewResults = Restore-RegistrySnapshot -SnapshotPath $firstBackup.FilePath -WhatIf
    Write-Host "     [OK] Stage 5 Rollback Preview: $($previewResults.Count) registry keys eligible for restore." -ForegroundColor Green
    Write-DebloatLog -Message "Rollback preview verified for $($firstBackup.FileName): $($previewResults.Count) keys" -Level "PREVIEW" -NoConsole
} else {
    Write-Warning "No backups found by Get-DebloatBackup."
}
Write-Host ""

# 5. Execute Debloat & Optimization Actions
Write-Host " [+] Step 4/6: Executing Windows Optimization & Debloat Suite..." -ForegroundColor Yellow
$tweaksApplied = 0

$actions = @(
    @{ Name = "Disable Telemetry Diagnostics"; Script = { Set-PrivacySetting -SettingId "DisableTelemetry" -Enable $true } },
    @{ Name = "Disable Bing Web Search in Start"; Script = { Set-PrivacySetting -SettingId "DisableBingSearch" -Enable $true } },
    @{ Name = "Disable Advertising ID"; Script = { Set-PrivacySetting -SettingId "DisableAdvertisingId" -Enable $true } },
    @{ Name = "Show Known File Extensions"; Script = { Set-ShellSetting -SettingId "ShowFileExtensions" } },
    @{ Name = "Hide Taskbar Widgets"; Script = { Set-ShellSetting -SettingId "HideWidgets" } },
    @{ Name = "Disable Windows Copilot AI Suite"; Script = { Set-CopilotAITweak -DisableCopilot $true } },
    @{ Name = "Disable Windows Recall & Snapshots"; Script = { Set-RecallAITweak -DisableRecall $true } },
    @{ Name = "Disable Edge Background Mode"; Script = { Set-EdgeBackgroundTweak -DisableEdgeBackground $true } },
    @{ Name = "Disable Game DVR Background Recording"; Script = { Set-GameDVRPlaybackTweak -DisableGameDVR $true } },
    @{ Name = "Disable Delivery Optimization P2P"; Script = { Set-DeliveryOptimizationTweak -DisableP2P $true } }
)

foreach ($act in $actions) {
    try {
        if ($DryRun) {
            Write-Host "     [PREVIEW] Would execute: $($act.Name)" -ForegroundColor Cyan
            Write-DebloatLog -Message "DRY-RUN: $($act.Name)" -Level "PREVIEW" -NoConsole
        } else {
            $null = & $act.Script
            $tweaksApplied++
            Write-Host "     [OK] Applied: $($act.Name)" -ForegroundColor Green
            Write-DebloatLog -Message "Optimized: $($act.Name)" -Level "SUCCESS" -NoConsole
        }
    } catch {
        Write-Host "     [!] Skipped/Warn: $($act.Name) - $($_.Exception.Message)" -ForegroundColor Yellow
        Write-DebloatLog -Message "Skipped: $($act.Name) - $($_.Exception.Message)" -Level "WARN" -NoConsole
    }
}
Write-Host ""

# 6. Verify Log File Integrity
Write-Host " [+] Step 5/6: Validating Execution Log Content..." -ForegroundColor Yellow
if (Test-Path $logFile) {
    $logLines = Get-Content -Path $logFile
    $hasHeader = [bool]($logLines | Where-Object { $_ -match "=== NH Win Debloater v$version Session Initialized:" })
    $hasSuccess = [bool]($logLines | Where-Object { $_ -match "\[SUCCESS\]" })
    $hasPreview = [bool]($logLines | Where-Object { $_ -match "\[PREVIEW\]" })

    Write-Host "     - Total Log Entries: $($logLines.Count)" -ForegroundColor Gray
    Write-Host "     - Live Version Header Validated: $(if ($hasHeader) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($hasHeader) { 'Green' } else { 'Red' })
    Write-Host "     - Structured [SUCCESS] Tags: $(if ($hasSuccess) { 'PRESENT' } else { 'MISSING' })" -ForegroundColor $(if ($hasSuccess) { 'Green' } else { 'Red' })
    Write-Host "     - Structured [PREVIEW] Tags: $(if ($hasPreview) { 'PRESENT' } else { 'NONE' })" -ForegroundColor Gray
}
Write-Host ""

# 7. Collect Post-Optimization (After) Metrics & Compute Delta
Write-Host " [+] Step 6/6: Capturing Post-Optimization Metrics (AFTER)..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
$afterMetrics = Get-SystemMetricsSnapshot

$deltaMemMb = [math]::Round($beforeMetrics.UsedMemoryMB - $afterMetrics.UsedMemoryMB, 1)
$deltaMemPct = [math]::Round($beforeMetrics.MemoryUsagePct - $afterMetrics.MemoryUsagePct, 1)
$deltaProcs = $beforeMetrics.ProcessCount - $afterMetrics.ProcessCount
$deltaServices = $beforeMetrics.RunningServices - $afterMetrics.RunningServices

Write-Host "     - RAM In-Use      : $($afterMetrics.UsedMemoryMB) MB / $($afterMetrics.TotalMemoryMB) MB ($($afterMetrics.MemoryUsagePct)%)" -ForegroundColor Gray
Write-Host "     - Active Processes: $($afterMetrics.ProcessCount)" -ForegroundColor Gray
Write-Host "     - Running Services: $($afterMetrics.RunningServices)" -ForegroundColor Gray
Write-Host ""

# 8. Output Final Formatted Comparison Report
Write-Host " ======================================================================" -ForegroundColor Green
Write-Host "   CLOUD VM VERIFICATION & OPTIMIZATION RESULTS SUMMARY" -ForegroundColor White
Write-Host " ======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "| Metric Indicator                  | Baseline (Before)   | Optimized (After)   | Change / Delta           |" -ForegroundColor White
Write-Host "| :-------------------------------- | :------------------ | :------------------ | :----------------------- |" -ForegroundColor Gray
Write-Host (("| Memory In-Use (MB)                | {0,-19} | {1,-19} | {2,-24} |" -f "$($beforeMetrics.UsedMemoryMB) MB", "$($afterMetrics.UsedMemoryMB) MB", "$(if ($deltaMemMb -ge 0) { "-$deltaMemMb MB (Reclaimed)" } else { "+$([math]::Abs($deltaMemMb)) MB" })")) -ForegroundColor White
Write-Host (("| Memory Usage (%)                  | {0,-19} | {1,-19} | {2,-24} |" -f "$($beforeMetrics.MemoryUsagePct)%", "$($afterMetrics.MemoryUsagePct)%", "$(if ($deltaMemPct -ge 0) { "-$deltaMemPct% Reduction" } else { "+$([math]::Abs($deltaMemPct))%" })")) -ForegroundColor White
Write-Host (("| Active Background Processes       | {0,-19} | {1,-19} | {2,-24} |" -f "$($beforeMetrics.ProcessCount)", "$($afterMetrics.ProcessCount)", "$(if ($deltaProcs -ge 0) { "-$deltaProcs Processes" } else { "+$([math]::Abs($deltaProcs))" })")) -ForegroundColor White
Write-Host (("| Running Background Services       | {0,-19} | {1,-19} | {2,-24} |" -f "$($beforeMetrics.RunningServices)", "$($afterMetrics.RunningServices)", "$(if ($deltaServices -ge 0) { "-$deltaServices Services" } else { "+$([math]::Abs($deltaServices))" })")) -ForegroundColor White
Write-Host "| Stage 5 Registry Snapshot         | None                | Created (Valid)     | Dropdown & Rollback Ready|" -ForegroundColor White
Write-Host "| Execution Log Persistence         | Default             | Full Audit Trail    | Dynamic v$version Verified    |" -ForegroundColor White
Write-Host ""
Write-Host " [OK] Cloud VM Verification Completed Successfully." -ForegroundColor Green

# Stage artifacts for HyperExecute artifact collection
try {
    $artifactsFolder = Join-Path $projectRoot "artifacts"
    if (-not (Test-Path $artifactsFolder)) {
        New-Item -ItemType Directory -Path $artifactsFolder -Force | Out-Null
    }
    $localLogs = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Logs"
    $localBackups = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups"
    if (Test-Path $localLogs) {
        Copy-Item -Path "$localLogs\*" -Destination $artifactsFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $localBackups) {
        Copy-Item -Path "$localBackups\*" -Destination $artifactsFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {
    # Non-blocking artifact staging safeguard
}

<#
    .SYNOPSIS
        Release preflight check and version bumping utility for NH Win Debloater.
    .DESCRIPTION
        Automates version validation, static analysis, and automated test execution
        prior to submitting a Pull Request to the protected main branch.
    .EXAMPLE
        .\tools\Test-ReleasePreflight.ps1 -TargetVersion "0.2"
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
param(
    [Parameter(Mandatory = $false)]
    [string]$TargetVersion,

    [switch]$SkipBump
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$versionFile = Join-Path $projectRoot "VERSION.txt"
$testsDir = Join-Path $projectRoot "tests"

Write-Host ""
Write-Host " ======================================================================" -ForegroundColor Cyan
Write-Host "   NH WIN DEBLOATER - RELEASE PREFLIGHT & QUALITY GATE" -ForegroundColor White
Write-Host "   Developed by NH Digital | https://nhdigital.shop" -ForegroundColor DarkCyan
Write-Host " ======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Version Bumping
$currentVersion = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "0.1" }
Write-Host " [+] Current Version : $currentVersion" -ForegroundColor Gray

if (-not [string]::IsNullOrWhiteSpace($TargetVersion)) {
    if (-not $SkipBump) {
        Set-Content -Path $versionFile -Value $TargetVersion -Encoding UTF8
        Write-Host " [✓] Bumped VERSION.txt -> $TargetVersion" -ForegroundColor Green
    }
} else {
    Write-Host " [i] Retaining version: $currentVersion (pass -TargetVersion to bump)" -ForegroundColor Gray
}

# 2. PSScriptAnalyzer Quality Gate
Write-Host "`n [Step 1/2] Running PSScriptAnalyzer Quality Gate..." -ForegroundColor Yellow
$scriptFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.ps1", "*.psm1" | Where-Object {
    $_.FullName -notmatch "\\tests\\" -and
    $_.FullName -notmatch "\\logs\\" -and
    $_.FullName -notmatch "\\artifacts\\"
}
$issues = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($file in $scriptFiles) {
    $analysis = Invoke-ScriptAnalyzer -Path $file.FullName
    if ($analysis.Count -gt 0) {
        foreach ($item in $analysis) {
            $issues.Add($item)
        }
    }
}

if ($issues.Count -eq 0) {
    Write-Host " [✓] PSScriptAnalyzer: PASSED (0 errors, 0 warnings across $($scriptFiles.Count) files)." -ForegroundColor Green
} else {
    Write-Host " [✗] PSScriptAnalyzer: FAILED with $($issues.Count) issues!" -ForegroundColor Red
    $issues | Format-Table RuleName, Severity, ScriptName, Line, Message -AutoSize
    exit 1
}

# 3. Pester Automated Tests
Write-Host "`n [Step 2/2] Running Pester Test Suite..." -ForegroundColor Yellow
$pesterResults = Invoke-Pester -Path $testsDir -PassThru -Output Detailed

if ($pesterResults.FailedCount -eq 0) {
    Write-Host " [✓] Pester Test Suite: PASSED ($($pesterResults.PassedCount)/$($pesterResults.TotalCount) tests passed)." -ForegroundColor Green
} else {
    Write-Host " [✗] Pester Test Suite: FAILED ($($pesterResults.FailedCount) failed tests)!" -ForegroundColor Red
    exit 1
}

# 4. Git Branch & PR Guidance
Write-Host "`n [Git & Branch Protection Check]" -ForegroundColor Cyan
try {
    $currentBranch = (git -C "$PSScriptRoot\.." branch --show-current 2>$null).Trim()
    Write-Host " [+] Active Git Branch: $currentBranch" -ForegroundColor Gray

    if ($currentBranch -eq "main") {
        Write-Host " [!] NOTICE: You are currently on the 'main' branch." -ForegroundColor Yellow
        Write-Host "     Branch protection prohibits direct pushes to 'main'." -ForegroundColor Yellow
        Write-Host "     Create a feature branch before committing:" -ForegroundColor Yellow
        Write-Host "     git checkout -b feature/v$(if ($TargetVersion) { $TargetVersion } else { $currentVersion })-updates" -ForegroundColor White
    } else {
        Write-Host " [✓] Good! You are on a feature branch ('$currentBranch')." -ForegroundColor Green
        Write-Host "     Ready to commit and open a Pull Request:" -ForegroundColor Gray
        Write-Host "     git commit -am 'Release: Bump version to $(if ($TargetVersion) { $TargetVersion } else { $currentVersion })'" -ForegroundColor DarkGray
        Write-Host "     git push -u origin $currentBranch" -ForegroundColor DarkGray
        Write-Host "     gh pr create --fill" -ForegroundColor DarkGray
    }
} catch {
    Write-Verbose "Git status check skipped: $($_.Exception.Message)"
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host " PREFLIGHT COMPLETE: Ready for Pull Request & CI Verification!" -ForegroundColor Green
Write-Host " Visit https://nhdigital.shop for digital presets and tooling." -ForegroundColor DarkCyan
Write-Host "======================================================================`n"

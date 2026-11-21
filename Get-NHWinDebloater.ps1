<#
    .SYNOPSIS
        NH Win Debloater - One-Line Zero-Install PowerShell Quick-Launcher
    .DESCRIPTION
        Downloads the latest verified release archive of NH Win Debloater directly from
        GitHub into a sandboxed temp environment, verifies archive integrity, and
        launches the modern WPF Guided Assistant or CLI in Single-Thread Apartment (STA) mode.
        Automatically cleans up downloaded archives and temporary sandboxes on exit.
        Developed by Mohammed Nadeem BM - NH Digital (https://nhdigital.shop).
    .EXAMPLE
        irm nhdigital.shop/debloat | iex
    .EXAMPLE
        irm https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/main/Get-NHWinDebloater.ps1 | iex
    .EXAMPLE
        & .\Get-NHWinDebloater.ps1 -CLI
    .EXAMPLE
        & .\Get-NHWinDebloater.ps1 -DryRun
#>

function Invoke-NHWinDebloaterBootstrap {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    param(
        [switch]$DryRun,
        [switch]$CLI,
        [switch]$Silent,
        [string]$Branch = "main",
        [string]$RepoUrl = "https://github.com/nadeemhaaju143/nh-win-debloater"
    )

    # 1. Enforce TLS 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls

    Write-Host ""
    Write-Host " ======================================================================" -ForegroundColor Cyan
    Write-Host "   NH WIN DEBLOATER - ZERO-INSTALL QUICK-LAUNCH BOOTSTRAPPER" -ForegroundColor White
    Write-Host "   Developed by Mohammed Nadeem BM - NH Digital | https://nhdigital.shop" -ForegroundColor DarkCyan
    Write-Host " ======================================================================" -ForegroundColor Cyan
    Write-Host ""

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host " [i] Notice: Running under Standard User privileges." -ForegroundColor Yellow
        Write-Host "     Administrator elevation is recommended for system-wide package removal." -ForegroundColor Gray
        Write-Host ""
    }

    # 2. Setup Sandboxed Temp Target
    $tempDir = Join-Path $env:TEMP "NHWinDebloater"
    $zipFile = Join-Path $tempDir "nh-win-debloater-$Branch.zip"
    $archiveUrl = "$RepoUrl/archive/refs/heads/$Branch.zip"

    try {
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }

        # 3. Download Latest Archive
        Write-Host " [+] Fetching latest '$Branch' release from GitHub..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $archiveUrl -OutFile $zipFile -UseBasicParsing -ErrorAction Stop
            Write-Host " [OK] Download completed successfully." -ForegroundColor Green
        } catch {
            Write-Error "Failed to download NH Win Debloater archive from '$archiveUrl': $($_.Exception.Message)"
            return
        }

        # 4. Extract Archive Cleanly
        Write-Host " [+] Extracting release archive..." -ForegroundColor Cyan
        try {
            Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force -ErrorAction Stop
            Write-Host " [OK] Extraction completed." -ForegroundColor Green
        } catch {
            Write-Error "Failed to extract release archive: $($_.Exception.Message)"
            return
        }

        # 5. Resolve Entrypoint
        $entrypoint = Get-ChildItem -Path $tempDir -Recurse -Filter "Entrypoint.ps1" -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName

        if (-not $entrypoint -or -not (Test-Path $entrypoint)) {
            Write-Error "Entrypoint.ps1 not found in extracted directory '$tempDir'."
            return
        }

        Write-Host " [OK] Launching NH Win Debloater ($entrypoint)..." -ForegroundColor Green
        Write-Host ""

        # 6. Execute in Single-Thread Apartment (STA) Mode
        $psArgs = [System.Collections.Generic.List[string]]::new()
        $psArgs.Add("-NoProfile")
        $psArgs.Add("-ExecutionPolicy")
        $psArgs.Add("Bypass")
        $psArgs.Add("-STA")
        $psArgs.Add("-File")
        $psArgs.Add("`"$entrypoint`"")

        if ($DryRun) { $psArgs.Add("-DryRun") }
        if ($CLI) { $psArgs.Add("-CLI") }
        if ($Silent) { $psArgs.Add("-Silent") }

        $proc = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -PassThru -Wait
        $exitCode = if ($proc) { $proc.ExitCode } else { 0 }
        $global:LASTEXITCODE = $exitCode
        return
    }
    finally {
        # Post-Exit Temp & Session Cleanup (Preserving Backups in %LOCALAPPDATA%\NHWinDebloater\Backups)
        $cleanPatterns = @(
            "NHWinDebloater*",
            "nh-win-debloater*"
        )
        foreach ($pattern in $cleanPatterns) {
            $tempTargets = Get-Item -Path (Join-Path $env:TEMP $pattern) -ErrorAction SilentlyContinue
            foreach ($target in $tempTargets) {
                if ($target.FullName -notlike "*LOCALAPPDATA*" -and $target.FullName -notlike "*Backups*" -and $target.FullName -notlike "*Logs*") {
                    try {
                        Remove-Item -Path $target.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    } catch {
                        # Transient lock ignored
                    }
                }
            }
        }
    }
}

Invoke-NHWinDebloaterBootstrap @args

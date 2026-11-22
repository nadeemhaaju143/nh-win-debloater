<#
    .SYNOPSIS
        NH Win Debloater - Root PowerShell Launcher Wrapper
    .DESCRIPTION
        Lightweight root launcher that forwards parameters (-CLI, -DryRun, -Silent, -Branch)
        directly to Get-NHWinDebloater.ps1 with post-exit session cleanup.
        Developed by Nadeem - NH Digital (https://nhdigital.shop).
    .EXAMPLE
        .\run.ps1
    .EXAMPLE
        .\run.ps1 -CLI
    .EXAMPLE
        .\run.ps1 -DryRun
#>

function Invoke-NHWinDebloaterRun {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    param(
        [switch]$DryRun,
        [switch]$CLI,
        [switch]$Silent,
        [string]$Branch = "main"
    )

    $targetScript = Join-Path $PSScriptRoot "Get-NHWinDebloater.ps1"
    try {
        if (Test-Path $targetScript) {
            & $targetScript -DryRun:$DryRun -CLI:$CLI -Silent:$Silent -Branch $Branch
        } else {
            $remoteUrl = "https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/$Branch/Get-NHWinDebloater.ps1"
            $remoteScript = Invoke-RestMethod -Uri $remoteUrl -UseBasicParsing
            & ([ScriptBlock]::Create($remoteScript)) -DryRun:$DryRun -CLI:$CLI -Silent:$Silent -Branch $Branch
        }
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

Invoke-NHWinDebloaterRun @args

<#
    .SYNOPSIS
        NH Win Debloater - Quick-Launch Bootstrap Wrapper
    .DESCRIPTION
        Convenience wrapper executing Get-NHWinDebloater.ps1 for zero-install execution with post-exit cleanup.
#>

function Invoke-NHWinDebloaterInstall {
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
            $remoteScript = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/$Branch/Get-NHWinDebloater.ps1" -UseBasicParsing
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
                        Write-Verbose "Could not remove '$($target.FullName)': $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}

Invoke-NHWinDebloaterInstall @args

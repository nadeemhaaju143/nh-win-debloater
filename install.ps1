<#
    .SYNOPSIS
        NH Win Debloater - Quick-Launch Bootstrap Wrapper
    .DESCRIPTION
        Convenience wrapper executing Get-NHWinDebloater.ps1 for zero-install execution.
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
param(
    [switch]$DryRun,
    [switch]$CLI,
    [switch]$Silent,
    [string]$Branch = "main"
)

$targetScript = Join-Path $PSScriptRoot "Get-NHWinDebloater.ps1"
if (Test-Path $targetScript) {
    & $targetScript -DryRun:$DryRun -CLI:$CLI -Silent:$Silent -Branch $Branch
} else {
    $remoteScript = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/nadeemhaaju143/nh-win-debloater/$Branch/Get-NHWinDebloater.ps1" -UseBasicParsing
    & ([ScriptBlock]::Create($remoteScript)) -DryRun:$DryRun -CLI:$CLI -Silent:$Silent -Branch $Branch
}

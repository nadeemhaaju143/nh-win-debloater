[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $scriptFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.ps1", "*.psm1" | Where-Object { $_.FullName -notmatch "\\tests\\" }
}

Describe "PSScriptAnalyzer Zero Warnings / Zero Errors Gate" {
    It "Verifies that all project PowerShell scripts pass analyzer with 0 issues" {
        $issues = @()
        foreach ($file in $scriptFiles) {
            $analysis = Invoke-ScriptAnalyzer -Path $file.FullName
            if ($analysis.Count -gt 0) {
                $issues += $analysis
            }
        }

        $issues.Count | Should -Be 0
    }
}

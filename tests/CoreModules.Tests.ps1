[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $corePath = Join-Path $projectRoot "src\Core"
    $presetsPath = Join-Path $projectRoot "src\Presets"

    Import-Module (Join-Path $corePath "AppManager.psm1") -Force
    Import-Module (Join-Path $corePath "PrivacySearch.psm1") -Force
    Import-Module (Join-Path $corePath "ShellCustomization.psm1") -Force
    Import-Module (Join-Path $corePath "SystemTweaks.psm1") -Force
    Import-Module (Join-Path $corePath "ExecutionLog.psm1") -Force
}

Describe "AppManager Module" {
    It "Loads protected system apps list" {
        $protected = Get-ProtectedApp -PresetsPath $presetsPath
        $protected.Count | Should -BeGreaterThan 0
        $protected | Should -Contain "Microsoft.WindowsStore"
    }

    It "Correctly identifies protected vs non-protected apps" {
        (Test-IsProtectedApp -AppId "Microsoft.WindowsStore" -PresetsPath $presetsPath) | Should -BeTrue
        (Test-IsProtectedApp -AppId "Microsoft.SecHealthUI" -PresetsPath $presetsPath) | Should -BeTrue
        (Test-IsProtectedApp -AppId "Clipchamp.Clipchamp" -PresetsPath $presetsPath) | Should -BeFalse
    }

    It "Loads presets cleanly" {
        $defaultPreset = Get-DebloatPreset -PresetName "Default" -PresetsPath $presetsPath
        $defaultPreset.Count | Should -Be 84

        $minimalPreset = Get-DebloatPreset -PresetName "Minimal" -PresetsPath $presetsPath
        $minimalPreset.Count | Should -BeGreaterThan 0

        $deepPreset = Get-DebloatPreset -PresetName "Deep" -PresetsPath $presetsPath
        $deepPreset.Count | Should -BeGreaterThan 100
    }

    It "Skips protected packages during removal" {
        $result = Remove-DebloatApp -AppIdList @("Microsoft.WindowsStore") -PresetsPath $presetsPath
        $result.Status | Should -Be "SkippedProtected"
    }
}

Describe "PrivacySearch Module" {
    It "Retrieves privacy status correctly" {
        $settings = Get-PrivacySetting
        $settings.Count | Should -Be 6
        $settings.Id | Should -Contain "DisableTelemetry"
        $settings.Id | Should -Contain "DisableCopilot"
    }

    It "Executes WhatIf preview safely" {
        $res = Set-PrivacySetting -SettingId "DisableTelemetry" -WhatIf
        $res.Count | Should -BeGreaterThan 0
        $res[0].Status | Should -Be "Preview"
    }
}

Describe "ShellCustomization Module" {
    It "Retrieves shell settings accurately" {
        $shell = Get-ShellSetting
        $shell.Count | Should -BeGreaterThan 5
        $shell.Id | Should -Contain "TaskbarAlignment"
        $shell.Id | Should -Contain "ShowFileExtensions"
    }

    It "Executes shell setting WhatIf preview safely" {
        $res = Set-ShellSetting -SettingId "ShowFileExtensions" -WhatIf
        $res[0].Status | Should -Be "Preview"
    }
}

Describe "SystemTweaks Module" {
    It "Executes consumer features WhatIf safely" {
        $res = Set-ConsumerFeatureTweak -Disable $true -WhatIf
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes classic context menu WhatIf safely" {
        $res = Set-ClassicContextMenuTweak -EnableClassic $true -WhatIf
        $res.Status | Should -Be "Preview"
    }

    It "Executes mouse precision WhatIf safely" {
        $res = Set-MousePrecisionTweak -DisableAcceleration $true -WhatIf
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes sticky keys WhatIf safely" {
        $res = Set-StickyKeysTweak -DisableShortcut $true -WhatIf
        $res.Status | Should -Be "Preview"
    }

    It "Executes fast startup WhatIf safely" {
        $res = Set-FastStartupTweak -DisableFastStartup $true -WhatIf
        $res.Status | Should -Be "Preview"
    }

    It "Executes storage sense WhatIf safely" {
        $res = Set-StorageSenseTweak -DisableStorageSense $true -WhatIf
        $res.Status | Should -Be "Preview"
    }

    It "Executes optional feature WhatIf safely" {
        $resSandbox = Set-OptionalFeatureState -FeatureId "WindowsSandbox" -Enable $true -WhatIf
        $resSandbox.Status | Should -Be "Preview"

        $resWSL = Set-OptionalFeatureState -FeatureId "WSL" -Enable $true -WhatIf
        $resWSL.Status | Should -Be "Preview"
    }
}

Describe "ExecutionLog Module" {
    It "Initializes log file without error" {
        $logPath = Initialize-DebloatLogger
        (Test-Path $logPath) | Should -BeTrue
    }

    It "Executes DryRun without running script block" {
        $res = Invoke-DebloatAction -ActionName "Test Action" -DryRun -ScriptBlock { throw "Should not run" }
        $res.Status | Should -Be "Preview"
    }
}

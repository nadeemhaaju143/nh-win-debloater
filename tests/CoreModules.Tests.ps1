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

        # Category Slices for Power-User Selection
        $oemApps = @($deepPreset | Where-Object { -not ($_.AppId -like "Microsoft.*") })
        $oemApps.Count | Should -BeGreaterThan 0

        $xboxApps = @($deepPreset | Where-Object { $_.AppId -like "*Xbox*" -or $_.AppId -like "*Gaming*" })
        $xboxApps.Count | Should -BeGreaterThan 0

        $mediaApps = @($deepPreset | Where-Object { $_.AppId -like "*BingNews*" -or $_.AppId -like "*Clipchamp*" -or $_.AppId -like "*Photos*" })
        $mediaApps.Count | Should -BeGreaterThan 0
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

        $resHighlights = Set-ShellSetting -SettingId "HideSearchHighlights" -WhatIf
        $resHighlights[0].Status | Should -Be "Preview"

        $resCompact = Set-ShellSetting -SettingId "ShowCompactExplorer" -WhatIf
        $resCompact[0].Status | Should -Be "Preview"
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

    It "Executes GameDVR WhatIf safely" {
        $res = Set-GameDVRPlaybackTweak -DisableGameDVR $true -WhatIf
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes DeliveryOptimization WhatIf safely" {
        $res = Set-DeliveryOptimizationTweak -DisableP2P $true -WhatIf
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes TelemetryService WhatIf safely" {
        $res = Set-TelemetryServiceTweak -DisableServices $true -WhatIf
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes StartMenuRecommended WhatIf safely" {
        $res = Set-StartMenuRecommendedTweak -HideRecommended $true -WhatIf
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes EdgeBackground WhatIf safely" {
        $res = Set-EdgeBackgroundTweak -DisableEdgeBackground $true -WhatIf
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes TelemetryScheduledTasks WhatIf safely" {
        $res = Set-TelemetryScheduledTasksTweak -DisableTasks $true -WhatIf
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes HibernationStorage WhatIf safely" {
        $res = Set-HibernationStorageTweak -DisableHibernation $true -WhatIf
        $res.Status | Should -Be "Preview"
    }

    It "Executes Multitasking WhatIf safely" {
        $res = Set-MultitaskingTweak -DisableSnapSuggestions $true -WhatIf
        $res[0].Status | Should -Be "Preview"
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

Describe "Entrypoint Bootstrapper & Path Resolution" {
    It "Resolves AppController path to src\UI without path doubling" {
        $coreDir = Join-Path $projectRoot "src\Core"
        $srcDir = Split-Path -Parent $coreDir
        $resolvedProjectRoot = Split-Path -Parent $srcDir
        $uiDir = Join-Path $srcDir "UI"
        $appController = Join-Path $uiDir "AppController.ps1"

        $appController | Should -Not -Match "\\src\\src\\UI"
        $resolvedProjectRoot | Should -Be $projectRoot
        (Test-Path $appController) | Should -BeTrue
    }

    It "Ensures Run.bat contains -STA flag for WPF compatibility" {
        $runBatPath = Join-Path $projectRoot "Run.bat"
        (Test-Path $runBatPath) | Should -BeTrue
        $batContent = Get-Content $runBatPath -Raw
        $batContent | Should -Match "-STA"
    }

    It "Executes Entrypoint in -DryRun mode cleanly" {
        $entrypointPath = Join-Path $projectRoot "src\Core\Entrypoint.ps1"
        (Test-Path $entrypointPath) | Should -BeTrue
        $res = powershell -NoProfile -ExecutionPolicy Bypass -File $entrypointPath -DryRun
        $LASTEXITCODE | Should -Be 0
    }

    It "Executes Entrypoint in -CLI mode cleanly" {
        $entrypointPath = Join-Path $projectRoot "src\Core\Entrypoint.ps1"
        (Test-Path $entrypointPath) | Should -BeTrue
        "Q" | powershell -NoProfile -ExecutionPolicy Bypass -File $entrypointPath -CLI
        $LASTEXITCODE | Should -Be 0
    }
}

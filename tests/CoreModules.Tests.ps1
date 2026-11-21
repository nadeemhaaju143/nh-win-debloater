[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $corePath = Join-Path $projectRoot "src\Core"
    $presetsPath = Join-Path $projectRoot "src\Presets"

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

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

    It "Combines multi-select categories into deduplicated AppId collection" {
        $recPreset = Get-DebloatPreset -PresetName "Default" -PresetsPath $presetsPath
        $minPreset = Get-DebloatPreset -PresetName "Minimal" -PresetsPath $presetsPath
        $deepPreset = Get-DebloatPreset -PresetName "Deep" -PresetsPath $presetsPath

        $combinedMap = @{}
        foreach ($app in $recPreset) { $combinedMap[$app.AppId] = $app }
        foreach ($app in $minPreset) { $combinedMap[$app.AppId] = $app }
        foreach ($app in $deepPreset) { $combinedMap[$app.AppId] = $app }

        $combinedMap.Keys.Count | Should -BeGreaterOrEqual $recPreset.Count
        $combinedMap.ContainsKey("Microsoft.BingNews") | Should -BeTrue
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

    It "Executes Copilot AI WhatIf safely" {
        $res = Set-CopilotAITweak -DisableCopilot $true -WhatIf
        $res.Count | Should -BeGreaterThan 0
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes Windows Recall & Snapshots WhatIf safely" {
        $res = Set-RecallAITweak -DisableRecall $true -WhatIf
        $res.Count | Should -BeGreaterThan 0
        $res[0].Status | Should -Be "Preview"
    }

    It "Executes App AI (Edge, Paint, Notepad) WhatIf safely" {
        $res = Set-ApplicationAITweak -DisableEdgeAI $true -DisablePaintAI $true -DisableNotepadAI $true -WhatIf
        $res.Count | Should -BeGreaterThan 0
        $res[0].Status | Should -Be "Preview"
    }

    It "Evaluates LOW / SAFE impact when only safe tweaks are selected" {
        $impact = Get-DebloatSafetyImpact -AppCount 84 -TweakFlags @{ Telemetry = $true; ClassicContextMenu = $true; GameDVR = $true }
        $impact.Rating | Should -Be "LOW / SAFE"
        $impact.Level | Should -Be "Safe"
        $impact.TotalCount | Should -Be 87
    }

    It "Evaluates MODERATE / CAUTION impact when caution tweaks are selected" {
        $impact = Get-DebloatSafetyImpact -AppCount 84 -TweakFlags @{ Telemetry = $true; Hibernation = $true }
        $impact.Rating | Should -Be "MODERATE / CAUTION"
        $impact.Level | Should -Be "Moderate"
    }

    It "Evaluates HIGH IMPACT when system virtualization tweaks are selected" {
        $impact = Get-DebloatSafetyImpact -AppCount 84 -TweakFlags @{ Telemetry = $true; WindowsSandbox = $true }
        $impact.Rating | Should -Be "HIGH IMPACT"
        $impact.Level | Should -Be "High"
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

    It "Dot-sources AppController.ps1 cleanly without InvalidOperationException" {
        $appController = Join-Path $projectRoot "src\UI\AppController.ps1"
        (Test-Path $appController) | Should -BeTrue
        $res = powershell -NoProfile -Command ". '$appController'; if (Get-Command Show-DebloaterWindow -ErrorAction SilentlyContinue) { 'Loaded' }"
        $res | Should -Match "Loaded"
        $LASTEXITCODE | Should -Be 0
    }

    It "Validates Get-NHWinDebloater.ps1 syntax and parameter signature" {
        $bootstrapperPath = Join-Path $projectRoot "Get-NHWinDebloater.ps1"
        (Test-Path $bootstrapperPath) | Should -BeTrue
        $content = Get-Content $bootstrapperPath -Raw
        $content | Should -Match '\[switch\]\$DryRun'
        $content | Should -Match '\[switch\]\$CLI'
        $content | Should -Match '\[switch\]\$Silent'
        $content | Should -Match '-STA'
    }

    It "Validates install.ps1 wrapper syntax and parameters" {
        $installPath = Join-Path $projectRoot "install.ps1"
        (Test-Path $installPath) | Should -BeTrue
        $content = Get-Content $installPath -Raw
        $content | Should -Match "Get-NHWinDebloater\.ps1"
    }
}

Describe "UI Motion & Vector Icon Architecture" {
    It "Loads MainWindow.xaml with all crisp vector icon geometries" {
        $xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
        (Test-Path $xamlPath) | Should -BeTrue
        $xamlContent = Get-Content $xamlPath -Raw
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
        $win = $null
        try {
            $win = [System.Windows.Markup.XamlReader]::Load($reader)
        } finally {
            $reader.Close()
        }
        $win | Should -Not -BeNullOrEmpty
        $win.Resources.Contains("IconAppGrid") | Should -BeTrue
        $win.Resources.Contains("IconShieldLock") | Should -BeTrue
        $win.Resources.Contains("IconDesktopExplorer") | Should -BeTrue
        $win.Resources.Contains("IconGamepadGaming") | Should -BeTrue
        $win.Resources.Contains("IconSettingsExtras") | Should -BeTrue
        $win.Resources.Contains("IconSparklesAI") | Should -BeTrue
        $win.Resources.Contains("IconLayersFeatures") | Should -BeTrue
        $win.Resources.Contains("IconCheckCircle") | Should -BeTrue
        $win.Resources.Contains("IconAlertTriangle") | Should -BeTrue
        $win.Resources.Contains("IconAlertOctagon") | Should -BeTrue
    }

    It "Verifies presence of dynamic counter and live impact badge elements in XAML" {
        $xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
        $xamlContent = Get-Content $xamlPath -Raw
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
        $win = $null
        try {
            $win = [System.Windows.Markup.XamlReader]::Load($reader)
        } finally {
            $reader.Close()
        }
        $win.FindName("TxtGlobalSelectionSummary") | Should -Not -BeNullOrEmpty
        $win.FindName("BadgeLiveImpact") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtStage3Summary") | Should -Not -BeNullOrEmpty
        $win.FindName("BadgeStage3Impact") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtTabAppsCount") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtTabPrivacyCount") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtTabShellCount") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtTabGamingCount") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtTabExtrasCount") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtTabAICount") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtTabFeaturesCount") | Should -Not -BeNullOrEmpty
    }
}

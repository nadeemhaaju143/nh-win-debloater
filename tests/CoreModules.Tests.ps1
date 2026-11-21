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

        $resSnap = Set-ShellSetting -SettingId "DisableSnapFlyout" -WhatIf
        $resSnap[0].Status | Should -Be "Preview"

        $resGallery = Set-ShellSetting -SettingId "HideGalleryNav" -WhatIf
        $resGallery[0].Status | Should -Be "Preview"
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

    It "Executes SettingsHome WhatIf safely" {
        $res = Set-SettingsHomeTweak -DisableHomeRecommendations $true -WhatIf
        $res.Status | Should -Be "Preview"
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

    It "Initializes log file with dynamic version header" {
        $testLogDir = Join-Path $env:TEMP "NHWinDebloater_LogTest"
        if (Test-Path $testLogDir) { Remove-Item -Path $testLogDir -Recurse -Force }
        $logPath = Initialize-DebloatLogger -LogDirectory $testLogDir -Version "0.5.3"
        (Test-Path $logPath) | Should -BeTrue
        $content = Get-Content -Path $logPath -Raw
        $content | Should -Match "=== NH Win Debloater v0.5.3 Session Initialized:"
        Remove-Item -Path $testLogDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Suppresses duplicate Session Initialized lines within 10 seconds" {
        $testLogDir = Join-Path $env:TEMP "NHWinDebloater_LogDedupTest"
        if (Test-Path $testLogDir) { Remove-Item -Path $testLogDir -Recurse -Force }
        $logPath = Initialize-DebloatLogger -LogDirectory $testLogDir -Version "0.5.3"
        $null = Initialize-DebloatLogger -LogDirectory $testLogDir -Version "0.5.3"
        $lines = Get-Content -Path $logPath | Where-Object { $_ -match "=== NH Win Debloater" }
        @($lines).Count | Should -Be 1
        Remove-Item -Path $testLogDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Persists structured log entries to file via Write-DebloatLog" {
        $testLogDir = Join-Path $env:TEMP "NHWinDebloater_WriteLogTest"
        if (Test-Path $testLogDir) { Remove-Item -Path $testLogDir -Recurse -Force }
        $null = Initialize-DebloatLogger -LogDirectory $testLogDir -Version "0.5.3"
        Write-DebloatLog -Message "Test Information Event" -Level "INFO" -NoConsole
        Write-DebloatLog -Message "Test Success Event" -Level "SUCCESS" -NoConsole
        Write-DebloatLog -Message "Test Warning Event" -Level "WARN" -NoConsole
        Write-DebloatLog -Message "Test Error Event" -Level "ERROR" -NoConsole
        Write-DebloatLog -Message "Test Preview Event" -Level "PREVIEW" -NoConsole

        $logPath = Join-Path $testLogDir "NHWinDebloater.log"
        $content = Get-Content -Path $logPath -Raw
        $content | Should -Match "\[INFO\] Test Information Event"
        $content | Should -Match "\[SUCCESS\] Test Success Event"
        $content | Should -Match "\[WARN\] Test Warning Event"
        $content | Should -Match "\[ERROR\] Test Error Event"
        $content | Should -Match "\[PREVIEW\] Test Preview Event"
        Remove-Item -Path $testLogDir -Recurse -Force -ErrorAction SilentlyContinue
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
        $content | Should -Match "finally"
    }

    It "Validates run.ps1 root launcher syntax and parameter forwarding" {
        $runPath = Join-Path $projectRoot "run.ps1"
        (Test-Path $runPath) | Should -BeTrue
        $content = Get-Content $runPath -Raw
        $content | Should -Match '\[switch\]\$DryRun'
        $content | Should -Match '\[switch\]\$CLI'
        $content | Should -Match '\[switch\]\$Silent'
        $content | Should -Match "Get-NHWinDebloater\.ps1"
        $content | Should -Match "finally"
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

    It "Verifies presence of v0.5 profile export/import, snapshot rollback, and reinstall modal controls" {
        $xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
        $xamlContent = Get-Content $xamlPath -Raw
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
        $win = $null
        try {
            $win = [System.Windows.Markup.XamlReader]::Load($reader)
        } finally {
            $reader.Close()
        }
        $win.FindName("BtnImportProfile") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnExportProfile") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnHeaderReinstallApps") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnStage5ReinstallApps") | Should -Not -BeNullOrEmpty
        $win.FindName("CboRegistrySnapshots") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnPreviewSnapshot") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnRestoreSnapshot") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtRestoreStatus") | Should -Not -BeNullOrEmpty
        $win.FindName("ModalReinstallApps") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnExecuteReinstallApps") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtReinstallLog") | Should -Not -BeNullOrEmpty
    }

    It "Verifies presence of multi-select CheckBox dropdowns and Raphire parity tweaks across all tabs in XAML" {
        $xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
        $xamlContent = Get-Content $xamlPath -Raw
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
        $win = $null
        try {
            $win = [System.Windows.Markup.XamlReader]::Load($reader)
        } finally {
            $reader.Close()
        }
        # Dropdown ToggleButtons
        $win.FindName("ToggleAppCategories") | Should -Not -BeNullOrEmpty
        $win.FindName("TogglePrivacyPresets") | Should -Not -BeNullOrEmpty
        $win.FindName("ToggleShellPresets") | Should -Not -BeNullOrEmpty
        $win.FindName("ToggleGamingPresets") | Should -Not -BeNullOrEmpty
        $win.FindName("ToggleExtrasPresets") | Should -Not -BeNullOrEmpty
        $win.FindName("ToggleAIPresets") | Should -Not -BeNullOrEmpty
        $win.FindName("ToggleFeaturesPresets") | Should -Not -BeNullOrEmpty

        # Dropdown Preset CheckBoxes
        $win.FindName("ChkPrivTelemetry") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkShellClean") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkGamingDVR") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkExtrasPromos") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkAISystem") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkFeatSandbox") | Should -Not -BeNullOrEmpty

        # Raphire Parity Tweaks
        $win.FindName("ChkLaunchToThisPC") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkHideGalleryNav") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkSnapFlyout") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkSettingsHome") | Should -Not -BeNullOrEmpty

        # Pre-declared RenderTransform on Stages and TabStage2Controls
        $win.FindName("ViewStage1").RenderTransform | Should -Not -BeNullOrEmpty
        $win.FindName("ViewStage2").RenderTransform | Should -Not -BeNullOrEmpty
        $win.FindName("ViewStage3").RenderTransform | Should -Not -BeNullOrEmpty
        $win.FindName("ViewStage4").RenderTransform | Should -Not -BeNullOrEmpty
        $win.FindName("ViewStage5").RenderTransform | Should -Not -BeNullOrEmpty
        $win.FindName("TabStage2Controls").RenderTransform | Should -Not -BeNullOrEmpty
    }

    It "Verifies presence of Start-Screen Restore shortcut and Selective Restore controls in XAML" {
        $xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
        $xamlContent = Get-Content $xamlPath -Raw
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
        $win = $null
        try {
            $win = [System.Windows.Markup.XamlReader]::Load($reader)
        } finally {
            $reader.Close()
        }

        # Header and Stage 1 shortcuts
        $win.FindName("BtnHeaderRestore") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnStage1Restore") | Should -Not -BeNullOrEmpty

        # Selective restore dropdown and controls
        $win.FindName("ToggleSelectiveRestore") | Should -Not -BeNullOrEmpty
        $win.FindName("TxtToggleSelectiveRestoreText") | Should -Not -BeNullOrEmpty
        $win.FindName("PopupSelectiveRestore") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkRestoreScopeApps") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkRestoreScopePrivacy") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkRestoreScopeShell") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkRestoreScopeGaming") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkRestoreScopeAI") | Should -Not -BeNullOrEmpty
        $win.FindName("ChkRestoreScopeExtras") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnRestoreScopeTweaksOnly") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnRestoreScopeAppsOnly") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnRestoreScopeAll") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnRestoreScopeClear") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnRestoreSelective") | Should -Not -BeNullOrEmpty
        $win.FindName("BtnRestoreSnapshot") | Should -Not -BeNullOrEmpty
    }
}

Describe "Custom Preset Profiles Export/Import" {
    BeforeAll {
        $tempProfilePath = Join-Path $env:TEMP "TestDebloatProfile.json"
    }

    AfterAll {
        if ($tempProfilePath -and (Test-Path $tempProfilePath)) {
            Remove-Item -Path $tempProfilePath -Force -ErrorAction SilentlyContinue
        }
    }

    It "Exports custom preset profile to JSON cleanly" {
        $apps = @("Microsoft.BingNews", "Microsoft.GetHelp", "Microsoft.ZuneVideo")
        $tweaks = @{
            Telemetry          = $true
            ClassicContextMenu = $true
            DisableCopilot     = $true
        }
        $res = Export-DebloatProfile -FilePath $tempProfilePath -ProfileName "Gaming Profile" -SelectedApps $apps -SelectedTweaks $tweaks -AppVersion "0.5"
        (Test-Path $res) | Should -BeTrue

        $jsonContent = Get-Content -Path $res -Raw | ConvertFrom-Json
        $jsonContent.ProfileName | Should -Be "Gaming Profile"
        $jsonContent.AppVersion | Should -Be "0.5"
        $jsonContent.SelectedApps.Count | Should -Be 3
        $jsonContent.SelectedTweaks.Telemetry | Should -BeTrue
    }

    It "Imports and validates custom preset profile safely" {
        $imported = Import-DebloatProfile -FilePath $tempProfilePath
        $imported.ProfileName | Should -Be "Gaming Profile"
        $imported.AppVersion | Should -Be "0.5"
        $imported.SelectedApps | Should -Contain "Microsoft.BingNews"
        $imported.SelectedTweaks["ClassicContextMenu"] | Should -BeTrue
    }

    It "Throws expected error on non-existent profile file" {
        { Import-DebloatProfile -FilePath "C:\NonExistent\Profile.json" } | Should -Throw
    }
}

Describe "Registry Snapshot & Rollback Engine" {
    BeforeAll {
        $tempBackupDir = Join-Path $env:TEMP "NHWinDebloaterTestBackups"
        if (-not (Test-Path $tempBackupDir)) {
            New-Item -Path $tempBackupDir -ItemType Directory -Force | Out-Null
        }
        $tempSnapshotPath = Join-Path $tempBackupDir "RegistrySnapshot_20261121_120000.json"
        $sampleSnapshot = @(
            @{ Path = "HKCU:\Software\NHWinDebloaterTest"; Name = "TestTweak"; Value = 1 }
        )
        $sampleSnapshot | ConvertTo-Json | Set-Content -Path $tempSnapshotPath -Encoding UTF8
    }

    AfterAll {
        if ($tempBackupDir -and (Test-Path $tempBackupDir)) {
            Remove-Item -Path $tempBackupDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Discovers existing registry backup snapshots" {
        $backups = @(Get-DebloatBackup -BackupDirectory $tempBackupDir)
        $backups | Should -Not -BeNullOrEmpty
        $backups.Count | Should -BeGreaterOrEqual 1
    }

    It "Executes Restore-RegistrySnapshot in WhatIf preview mode safely" {
        $results = @(Restore-RegistrySnapshot -SnapshotPath $tempSnapshotPath -WhatIf)
        $results.Count | Should -Be 1
        $results[0].Status | Should -Be "Preview"
    }

    It "Verifies Stage 5 ComboBox item formatting with date, filename, and size" {
        $backups = @(Get-DebloatBackup -BackupDirectory $tempBackupDir)
        $backups.Count | Should -BeGreaterOrEqual 1
        $b = $backups[0]
        $formatted = "$($b.LastModified) — $($b.FileName) ($($b.SizeKb) KB)"
        $formatted | Should -Match "RegistrySnapshot_.*\.json"
        $formatted | Should -Match "KB\)"

        $cboItem = [System.Windows.Controls.ComboBoxItem]::new()
        $cboItem.Content = $formatted
        $cboItem.Tag = $b
        $cboItem.Content | Should -Be $formatted
        $cboItem.Tag.FileName | Should -Be $b.FileName
    }

    It "Filters snapshot restoration accurately by category" {
        $multiCatSnapshotPath = Join-Path $tempBackupDir "MultiCatSnapshot.json"
        $multiData = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 1 }
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "HideFileExt"; Value = 1 }
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"; Name = "AppCaptureEnabled"; Value = 1 }
            @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableAIDataAnalysis"; Value = 0 }
            @{ Path = "HKCU:\Control Panel\Accessibility\StickyKeys"; Name = "Flags"; Value = "510" }
        )
        $multiData | ConvertTo-Json | Set-Content -Path $multiCatSnapshotPath -Encoding UTF8

        # Test Privacy only
        $privResults = @(Restore-RegistrySnapshot -SnapshotPath $multiCatSnapshotPath -Categories @("Privacy") -WhatIf)
        $privResults.Count | Should -Be 1
        $privResults[0].Category | Should -Be "Privacy"

        # Test Shell and Gaming
        $shellGamingResults = @(Restore-RegistrySnapshot -SnapshotPath $multiCatSnapshotPath -Categories @("Shell", "Gaming") -WhatIf)
        $shellGamingResults.Count | Should -Be 2
        ($shellGamingResults.Category) | Should -Contain "Shell"
        ($shellGamingResults.Category) | Should -Contain "Gaming"

        # Test AI only
        $aiResults = @(Restore-RegistrySnapshot -SnapshotPath $multiCatSnapshotPath -Categories @("AI") -WhatIf)
        $aiResults.Count | Should -Be 1
        $aiResults[0].Category | Should -Be "AI"

        # Test All or Omitted categories
        $allResults = @(Restore-RegistrySnapshot -SnapshotPath $multiCatSnapshotPath -WhatIf)
        $allResults.Count | Should -Be 5
    }
}

Describe "App Reinstall Helper Engine" {
    It "Generates WhatIf preview for Microsoft Store" {
        $res = Install-CommonWindowsApp -AppName "Store" -WhatIf
        $res.AppName | Should -Be "Store"
        $res.Status | Should -Be "Preview"
    }

    It "Generates WhatIf preview for Calculator, Notepad, Paint, Photos, Terminal" {
        $apps = @("Calculator", "Notepad", "Paint", "Photos", "Terminal")
        foreach ($app in $apps) {
            $res = Install-CommonWindowsApp -AppName $app -WhatIf
            $res.AppName | Should -Be $app
            $res.Status | Should -Be "Preview"
        }
    }
}

Describe "Post-Exit Temp & Session Cleanup" {
    BeforeAll {
        $testTempSandbox = Join-Path $env:TEMP "NHWinDebloater_UnitTest_Sandbox"
        if (-not (Test-Path $testTempSandbox)) {
            New-Item -Path $testTempSandbox -ItemType Directory -Force | Out-Null
        }
        $dummyFile = Join-Path $testTempSandbox "dummy_payload.tmp"
        Set-Content -Path $dummyFile -Value "Test temporary artifact" -Encoding UTF8

        # Create simulated protected backup directory
        $testProtectedBackups = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups"
        if (-not (Test-Path $testProtectedBackups)) {
            New-Item -Path $testProtectedBackups -ItemType Directory -Force | Out-Null
        }
        $testSnapshotFile = Join-Path $testProtectedBackups "RegistrySnapshot_KeepMe.json"
        Set-Content -Path $testSnapshotFile -Value "{}" -Encoding UTF8
    }

    AfterAll {
        $testTempSandbox = Join-Path $env:TEMP "NHWinDebloater_UnitTest_Sandbox"
        if ($testTempSandbox -and (Test-Path $testTempSandbox)) {
            Remove-Item -Path $testTempSandbox -Recurse -Force -ErrorAction SilentlyContinue
        }
        $testProtectedBackups = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups"
        $testSnapshotFile = Join-Path $testProtectedBackups "RegistrySnapshot_KeepMe.json"
        if (Test-Path $testSnapshotFile) {
            Remove-Item -Path $testSnapshotFile -Force -ErrorAction SilentlyContinue
        }
    }

    It "Cleans up transient sandbox folder in temporary directory" {
        $testTempSandbox = Join-Path $env:TEMP "NHWinDebloater_UnitTest_Sandbox"
        (Test-Path $testTempSandbox) | Should -BeTrue
        $removed = Clear-DebloatTempSession -TempRoot $env:TEMP
        (Test-Path $testTempSandbox) | Should -BeFalse
    }

    It "Strictly preserves %LOCALAPPDATA%\NHWinDebloater\Backups during cleanup" {
        $testProtectedBackups = Join-Path $env:LOCALAPPDATA "NHWinDebloater\Backups"
        $testSnapshotFile = Join-Path $testProtectedBackups "RegistrySnapshot_KeepMe.json"
        (Test-Path $testProtectedBackups) | Should -BeTrue
        (Test-Path $testSnapshotFile) | Should -BeTrue

        # Run cleanup again
        $null = Clear-DebloatTempSession -TempRoot $env:TEMP

        # Ensure backup folder and snapshot file are 100% untouched
        (Test-Path $testProtectedBackups) | Should -BeTrue
        (Test-Path $testSnapshotFile) | Should -BeTrue
    }
}

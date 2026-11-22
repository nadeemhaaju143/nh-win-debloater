[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param()

# tools/Capture-HighResScreenshots.ps1
# Captures high-resolution, pixel-perfect UI screenshots in safe DryRun mode

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$projectRoot = "C:\Users\nadee\Projects\NH Win Debloater"
$xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
$outDir = Join-Path $projectRoot "Assets\screenshots"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$brushActivePillBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2234")
$brushActiveBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0EA5E9")
$brushDonePillBg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#131926")
$brushDoneBorder   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981")
$brushIdlePillBg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0B0F17")
$brushIdleBorder   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#232D42")

$brushActiveBadge  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0EA5E9")
$brushIdleBadge    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222C42")

$stepColorActive   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0EA5E9")
$stepColorInactive = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
$stepColorDone     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")

function Update-StepperState {
    param($win, [int]$stage)
    $pills = @(
        $win.FindName("PillStage1"),
        $win.FindName("PillStage2"),
        $win.FindName("PillStage3"),
        $win.FindName("PillStage4"),
        $win.FindName("PillStage5")
    )
    $badges = @(
        $win.FindName("BadgeStep1"),
        $win.FindName("BadgeStep2"),
        $win.FindName("BadgeStep3"),
        $win.FindName("BadgeStep4"),
        $win.FindName("BadgeStep5")
    )
    $checks = @(
        $win.FindName("CheckStep1"),
        $win.FindName("CheckStep2"),
        $win.FindName("CheckStep3"),
        $win.FindName("CheckStep4"),
        $win.FindName("CheckStep5")
    )
    $tags = @(
        $win.FindName("StepTag1"),
        $win.FindName("StepTag2"),
        $win.FindName("StepTag3"),
        $win.FindName("StepTag4"),
        $win.FindName("StepTag5")
    )

    for ($i = 0; $i -lt 5; $i++) {
        $stepNum = $i + 1
        $p = $pills[$i]
        $b = $badges[$i]
        $c = $checks[$i]
        $t = $tags[$i]

        if ($stepNum -lt $stage) {
            if ($p) { $p.Background = $brushDonePillBg; $p.BorderBrush = $brushDoneBorder }
            if ($b) { $b.Visibility = [System.Windows.Visibility]::Collapsed }
            if ($c) { $c.Visibility = [System.Windows.Visibility]::Visible }
            if ($t) { $t.Foreground = $stepColorDone; $t.FontWeight = [System.Windows.FontWeights]::Normal }
        } elseif ($stepNum -eq $stage) {
            if ($p) { $p.Background = $brushActivePillBg; $p.BorderBrush = $brushActiveBorder }
            if ($b) { $b.Background = $brushActiveBadge; $b.Visibility = [System.Windows.Visibility]::Visible }
            if ($c) { $c.Visibility = [System.Windows.Visibility]::Collapsed }
            if ($t) { $t.Foreground = $stepColorActive; $t.FontWeight = [System.Windows.FontWeights]::Bold }
        } else {
            if ($p) { $p.Background = $brushIdlePillBg; $p.BorderBrush = $brushIdleBorder }
            if ($b) { $b.Background = $brushIdleBadge; $b.Visibility = [System.Windows.Visibility]::Visible }
            if ($c) { $c.Visibility = [System.Windows.Visibility]::Collapsed }
            if ($t) { $t.Foreground = $stepColorInactive; $t.FontWeight = [System.Windows.FontWeights]::Normal }
        }
    }
}

function Save-VisualToPng {
    param($visual, $width, $height, $filePath, $childVisual = $null, $childRect = $null)
    $dv = [System.Windows.Media.DrawingVisual]::new()
    $dc = $dv.RenderOpen()
    $dc.DrawRectangle([System.Windows.Media.VisualBrush]::new($visual), $null, [System.Windows.Rect]::new(0, 0, $width, $height))
    if ($childVisual -and $childRect) {
        $dc.DrawRectangle([System.Windows.Media.VisualBrush]::new($childVisual), $null, $childRect)
    }
    $dc.Close()

    $rtb = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($width, $height, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $rtb.Render($dv)

    $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
    $stream = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Create)
    $encoder.Save($stream)
    $stream.Close()

    $fi = Get-Item $filePath
    Write-Host " [+] Generated $($fi.Name) ($([math]::Round($fi.Length / 1024, 1)) KB)"
}

# --- 1. Capture Stage 1: main-window.png ---
$reader1 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw)))
$win1 = [System.Windows.Markup.XamlReader]::Load($reader1)
$reader1.Close()

Update-StepperState -win $win1 -stage 1

$hw1 = $win1.FindName("TxtHardwareSpecs")
if ($hw1) { $hw1.Text = "AMD Ryzen 9 5900X • 32.0 GB RAM" }

$win1.FindName("ViewStage1").Visibility = [System.Windows.Visibility]::Visible
$win1.FindName("ViewStage2").Visibility = [System.Windows.Visibility]::Collapsed
$win1.FindName("ViewStage3").Visibility = [System.Windows.Visibility]::Collapsed
$win1.FindName("ViewStage4").Visibility = [System.Windows.Visibility]::Collapsed
$win1.FindName("ViewStage5").Visibility = [System.Windows.Visibility]::Collapsed

$win1.FindName("BtnBack").Visibility = [System.Windows.Visibility]::Collapsed
$win1.FindName("BtnNext").Visibility = [System.Windows.Visibility]::Visible
$win1.FindName("BtnApply").Visibility = [System.Windows.Visibility]::Collapsed
$win1.FindName("BtnFinish").Visibility = [System.Windows.Visibility]::Collapsed

$win1.Show()

$frame1 = [System.Windows.Threading.DispatcherFrame]::new()
[System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
    [System.Windows.Threading.DispatcherPriority]::Loaded,
    [System.Action]{
        param()
        $outPath1 = Join-Path $outDir "main-window.png"
        Save-VisualToPng -visual $win1 -width 1080 -height 760 -filePath $outPath1
        $win1.Close()
        $frame1.Continue = $false
    }
)
[System.Windows.Threading.Dispatcher]::PushFrame($frame1)

# --- 2. Capture Stage 2: tweak-dropdowns.png (AI Integration tab + Dropdown) ---
$reader2 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw)))
$win2 = [System.Windows.Markup.XamlReader]::Load($reader2)
$reader2.Close()

Update-StepperState -win $win2 -stage 2

$hw2 = $win2.FindName("TxtHardwareSpecs")
if ($hw2) { $hw2.Text = "AMD Ryzen 9 5900X • 32.0 GB RAM" }

$win2.FindName("ViewStage1").Visibility = [System.Windows.Visibility]::Collapsed
$win2.FindName("ViewStage2").Visibility = [System.Windows.Visibility]::Visible
$win2.FindName("ViewStage3").Visibility = [System.Windows.Visibility]::Collapsed
$win2.FindName("ViewStage4").Visibility = [System.Windows.Visibility]::Collapsed
$win2.FindName("ViewStage5").Visibility = [System.Windows.Visibility]::Collapsed

$win2.FindName("BtnBack").Visibility = [System.Windows.Visibility]::Visible
$win2.FindName("BtnNext").Visibility = [System.Windows.Visibility]::Visible
$win2.FindName("BtnApply").Visibility = [System.Windows.Visibility]::Collapsed
$win2.FindName("BtnFinish").Visibility = [System.Windows.Visibility]::Collapsed

$tabCtrl = $win2.FindName("TabStage2Controls")
# Select Tab 6: AI Integration (index 5)
$tabCtrl.SelectedIndex = 5

$toggleAI = $win2.FindName("ToggleAIPresets")
if ($toggleAI) { $toggleAI.IsChecked = $true }

$popupAI = $win2.FindName("PopupAIPresets")

$win2.Show()

$frame2 = [System.Windows.Threading.DispatcherFrame]::new()
[System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
    [System.Windows.Threading.DispatcherPriority]::Loaded,
    [System.Action]{
        param()
        $outPath2 = Join-Path $outDir "tweak-dropdowns.png"

        # Position of ToggleAIPresets relative to Window
        $pt = $toggleAI.TransformToAncestor($win2).Transform([System.Windows.Point]::new(0, 0))
        $child = $popupAI.Child
        $child.Measure([System.Windows.Size]::new(280, 240))
        $child.Arrange([System.Windows.Rect]::new(0, 0, 280, 240))
        $child.UpdateLayout()

        $popupRect = [System.Windows.Rect]::new($pt.X, $pt.Y + $toggleAI.ActualHeight + 4, 280, 240)
        Save-VisualToPng -visual $win2 -width 1080 -height 760 -filePath $outPath2 -childVisual $child -childRect $popupRect
        $win2.Close()
        $frame2.Continue = $false
    }
)
[System.Windows.Threading.Dispatcher]::PushFrame($frame2)

# --- 3. Capture Stage 5: restore-manager.png (Snapshot Dropdown + Selective Restore) ---
$reader3 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw)))
$win3 = [System.Windows.Markup.XamlReader]::Load($reader3)
$reader3.Close()

Update-StepperState -win $win3 -stage 5

$hw3 = $win3.FindName("TxtHardwareSpecs")
if ($hw3) { $hw3.Text = "AMD Ryzen 9 5900X • 32.0 GB RAM" }

$win3.FindName("ViewStage1").Visibility = [System.Windows.Visibility]::Collapsed
$win3.FindName("ViewStage2").Visibility = [System.Windows.Visibility]::Collapsed
$win3.FindName("ViewStage3").Visibility = [System.Windows.Visibility]::Collapsed
$win3.FindName("ViewStage4").Visibility = [System.Windows.Visibility]::Collapsed
$win3.FindName("ViewStage5").Visibility = [System.Windows.Visibility]::Visible

$win3.FindName("BtnBack").Visibility = [System.Windows.Visibility]::Collapsed
$win3.FindName("BtnNext").Visibility = [System.Windows.Visibility]::Collapsed
$win3.FindName("BtnApply").Visibility = [System.Windows.Visibility]::Collapsed
$win3.FindName("BtnFinish").Visibility = [System.Windows.Visibility]::Visible

$win3.FindName("TxtStatTotal").Text = "102"
$win3.FindName("TxtStatSuccess").Text = "98"
$win3.FindName("TxtStatSkipped").Text = "4"

# Populate snapshots ComboBox
$cboSnap = $win3.FindName("CboRegistrySnapshots")
if ($cboSnap) {
    $cboSnap.Items.Clear()
    $item1 = [System.Windows.Controls.ComboBoxItem]::new()
    $item1.Content = "2026-11-21 16:37:09 — RegistrySnapshot_20261121_163709.json (46.6 KB)"
    $null = $cboSnap.Items.Add($item1)

    $item2 = [System.Windows.Controls.ComboBoxItem]::new()
    $item2.Content = "2026-11-20 09:12:44 — RegistrySnapshot_20261120_091244.json (45.2 KB)"
    $null = $cboSnap.Items.Add($item2)

    $cboSnap.SelectedIndex = 0
}

$toggleRestore = $win3.FindName("ToggleSelectiveRestore")
if ($toggleRestore) { $toggleRestore.IsChecked = $true }
$popupRestore = $win3.FindName("PopupSelectiveRestore")

$win3.Show()

$frame3 = [System.Windows.Threading.DispatcherFrame]::new()
[System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
    [System.Windows.Threading.DispatcherPriority]::Loaded,
    [System.Action]{
        param()
        $outPath3 = Join-Path $outDir "restore-manager.png"

        $pt = $toggleRestore.TransformToAncestor($win3).Transform([System.Windows.Point]::new(0, 0))
        $child = $popupRestore.Child
        $child.Measure([System.Windows.Size]::new(280, 260))
        $child.Arrange([System.Windows.Rect]::new(0, 0, 280, 260))
        $child.UpdateLayout()

        $popupRect = [System.Windows.Rect]::new($pt.X, $pt.Y + $toggleRestore.ActualHeight + 4, 280, 260)
        Save-VisualToPng -visual $win3 -width 1080 -height 760 -filePath $outPath3 -childVisual $child -childRect $popupRect
        $win3.Close()
        $frame3.Continue = $false
    }
)
[System.Windows.Threading.Dispatcher]::PushFrame($frame3)

Write-Host "`nAll 3 high-resolution screenshots generated successfully in $outDir"

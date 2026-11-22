[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidTrailingWhitespace', '')]
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
$reader1 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw -Encoding UTF8)))
$win1 = [System.Windows.Markup.XamlReader]::Load($reader1)
$reader1.Close()

Update-StepperState -win $win1 -stage 1
$hw1 = $win1.FindName("TxtHardwareSpecs")
if ($hw1) { $hw1.Text = "AMD Ryzen 9 5900X - 32.0 GB RAM" }

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
$reader2 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw -Encoding UTF8)))
$win2 = [System.Windows.Markup.XamlReader]::Load($reader2)
$reader2.Close()

Update-StepperState -win $win2 -stage 2
$hw2 = $win2.FindName("TxtHardwareSpecs")
if ($hw2) { $hw2.Text = "AMD Ryzen 9 5900X - 32.0 GB RAM" }

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
$reader3 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw -Encoding UTF8)))
$win3 = [System.Windows.Markup.XamlReader]::Load($reader3)
$reader3.Close()

Update-StepperState -win $win3 -stage 5
$hw3 = $win3.FindName("TxtHardwareSpecs")
if ($hw3) { $hw3.Text = "AMD Ryzen 9 5900X - 32.0 GB RAM" }

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
    $item1.Content = "2026-11-21 16:37:09 - RegistrySnapshot_20261121_163709.json (46.6 KB)"
    $null = $cboSnap.Items.Add($item1)

    $item2 = [System.Windows.Controls.ComboBoxItem]::new()
    $item2.Content = "2026-11-20 09:12:44 - RegistrySnapshot_20261120_091244.json (45.2 KB)"
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

# --- 4. Capture Preferences Modal: preferences-modal.png (6-Language Dropdown & Theme) ---
$reader4 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw -Encoding UTF8)))
$win4 = [System.Windows.Markup.XamlReader]::Load($reader4)
$reader4.Close()

Update-StepperState -win $win4 -stage 1
$hw4 = $win4.FindName("TxtHardwareSpecs")
if ($hw4) { $hw4.Text = "AMD Ryzen 9 5900X - 32.0 GB RAM" }

$modalPref = $win4.FindName("ModalPreferences")
if ($modalPref) { $modalPref.Visibility = [System.Windows.Visibility]::Visible }

$win4.Show()

$frame4 = [System.Windows.Threading.DispatcherFrame]::new()
[System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
    [System.Windows.Threading.DispatcherPriority]::Loaded,
    [System.Action]{
        param()
        $outPath4 = Join-Path $outDir "preferences-modal.png"
        Save-VisualToPng -visual $win4 -width 1080 -height 760 -filePath $outPath4
        $win4.Close()
        $frame4.Continue = $false
    }
)
[System.Windows.Threading.Dispatcher]::PushFrame($frame4)

# --- 5. Capture Stage 2 App List: stage2-app-selection.png (Safety Indicators & Legend) ---
$reader5 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw -Encoding UTF8)))
$win5 = [System.Windows.Markup.XamlReader]::Load($reader5)
$reader5.Close()

Update-StepperState -win $win5 -stage 2
$hw5 = $win5.FindName("TxtHardwareSpecs")
if ($hw5) { $hw5.Text = "AMD Ryzen 9 5900X - 32.0 GB RAM" }

$win5.FindName("ViewStage1").Visibility = [System.Windows.Visibility]::Collapsed
$win5.FindName("ViewStage2").Visibility = [System.Windows.Visibility]::Visible
$tabCtrl5 = $win5.FindName("TabStage2Controls")
$tabCtrl5.SelectedIndex = 0 # Tab 1: Apps

$appContainer = $win5.FindName("ListAppsContainer")
if ($appContainer) {
    $appContainer.Items.Clear()
    $appsData = @(
        @{ Dot = "[SAFE]"; Badge = "RECOMMENDED"; Name = "Clipchamp Video Editor"; Desc = "Sponsored cloud video editor"; Inst = $true; Checked = $true; Bg = "#064E3B"; Fg = "#10B981" },
        @{ Dot = "[SAFE]"; Badge = "RECOMMENDED"; Name = "Microsoft News / Weather"; Desc = "Pre-installed MSN feed and telemetry consumer"; Inst = $true; Checked = $true; Bg = "#064E3B"; Fg = "#10B981" },
        @{ Dot = "[SAFE]"; Badge = "RECOMMENDED"; Name = "Spotify Music"; Desc = "Promotional third-party streaming bundle"; Inst = $false; Checked = $true; Bg = "#064E3B"; Fg = "#10B981" },
        @{ Dot = "[OPTIONAL]"; Badge = "OPTIONAL"; Name = "Xbox Gaming App Suite"; Desc = "Xbox Game Bar, identity provider & live services"; Inst = $true; Checked = $false; Bg = "#451A03"; Fg = "#F59E0B" },
        @{ Dot = "[OPTIONAL]"; Badge = "OPTIONAL"; Name = "Microsoft To Do"; Desc = "Task manager & cloud task synchronization"; Inst = $false; Checked = $false; Bg = "#451A03"; Fg = "#F59E0B" },
        @{ Dot = "[RISK]"; Badge = "NOT RECOMMENDED"; Name = "Microsoft Store"; Desc = "Core UWP package runtime & application catalog"; Inst = $true; Checked = $false; Bg = "#450A0A"; Fg = "#EF4444" }
    )
    foreach ($a in $appsData) {
        $cb = [System.Windows.Controls.CheckBox]::new()
        $cb.IsChecked = $a.Checked
        $sp = [System.Windows.Controls.StackPanel]::new()
        $sp.Orientation = [System.Windows.Controls.Orientation]::Horizontal

        $dot = [System.Windows.Shapes.Ellipse]::new()
        $dot.Width = 8
        $dot.Height = 8
        $dot.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($a.Fg)
        $dot.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
        $dot.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $sp.Children.Add($dot) | Out-Null

        $b = [System.Windows.Controls.Border]::new()
        $b.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($a.Bg)
        $b.Padding = [System.Windows.Thickness]::new(5, 1, 5, 1)
        $b.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $b.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $bt = [System.Windows.Controls.TextBlock]::new()
        $bt.Text = $a.Badge
        $bt.FontSize = 10
        $bt.FontWeight = [System.Windows.FontWeights]::Bold
        $bt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($a.Fg)
        $b.Child = $bt
        $sp.Children.Add($b) | Out-Null

        $t = [System.Windows.Controls.TextBlock]::new()
        $t.Text = $a.Name
        $t.FontWeight = [System.Windows.FontWeights]::SemiBold
        $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8FAFC")
        $t.FontSize = 12
        $t.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $sp.Children.Add($t) | Out-Null

        $d = [System.Windows.Controls.TextBlock]::new()
        $d.Text = " - $($a.Desc)"
        $d.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        $d.FontSize = 11
        $d.Margin = [System.Windows.Thickness]::new(4, 0, 0, 0)
        $d.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $sp.Children.Add($d) | Out-Null

        if ($a.Inst) {
            $ib = [System.Windows.Controls.Border]::new()
            $ib.CornerRadius = [System.Windows.CornerRadius]::new(3)
            $ib.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#075985")
            $ib.Padding = [System.Windows.Thickness]::new(5, 1, 5, 1)
            $ib.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
            $ib.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $it = [System.Windows.Controls.TextBlock]::new()
            $it.Text = "INSTALLED"
            $it.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
            $it.FontSize = 9
            $it.FontWeight = [System.Windows.FontWeights]::Bold
            $ib.Child = $it
            $sp.Children.Add($ib) | Out-Null
        }

        $cb.Content = $sp
        $appContainer.Items.Add($cb) | Out-Null
    }
}

$win5.Show()

$frame5 = [System.Windows.Threading.DispatcherFrame]::new()
[System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
    [System.Windows.Threading.DispatcherPriority]::Loaded,
    [System.Action]{
        param()
        $outPath5 = Join-Path $outDir "stage2-app-selection.png"
        Save-VisualToPng -visual $win5 -width 1080 -height 760 -filePath $outPath5
        $win5.Close()
        $frame5.Continue = $false
    }
)
[System.Windows.Threading.Dispatcher]::PushFrame($frame5)

# --- 6. Capture Recovery Modal: recovery-modal.png (Rollback Utilities) ---
$reader6 = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new((Get-Content $xamlPath -Raw -Encoding UTF8)))
$win6 = [System.Windows.Markup.XamlReader]::Load($reader6)
$reader6.Close()

Update-StepperState -win $win6 -stage 1
$hw6 = $win6.FindName("TxtHardwareSpecs")
if ($hw6) { $hw6.Text = "AMD Ryzen 9 5900X - 32.0 GB RAM" }

$modalRec = $win6.FindName("ModalRecoveryRollback")
if ($modalRec) { $modalRec.Visibility = [System.Windows.Visibility]::Visible }

$win6.Show()

$frame6 = [System.Windows.Threading.DispatcherFrame]::new()
[System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
    [System.Windows.Threading.DispatcherPriority]::Loaded,
    [System.Action]{
        param()
        $outPath6 = Join-Path $outDir "recovery-modal.png"
        Save-VisualToPng -visual $win6 -width 1080 -height 760 -filePath $outPath6
        $win6.Close()
        $frame6.Continue = $false
    }
)
[System.Windows.Threading.Dispatcher]::PushFrame($frame6)

Write-Host "`nAll 6 high-resolution screenshots generated successfully in $outDir"

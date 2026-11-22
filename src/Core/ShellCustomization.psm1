<#
    .SYNOPSIS
        NH Win Debloater - UI & Shell Customization Engine
    .DESCRIPTION
        Configures Windows 10 and 11 Taskbar, Start, and File Explorer behaviors,
        including icon alignment, search display, task view, widgets, chat, End Task,
        file extension visibility, and navigation pane clutter.
    .MODULEVERSION
        1.3.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
param()

function Set-RegistryPropertyHelper {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object]$Value,

        [ValidateSet("DWord", "String", "Binary", "MultiString", "ExpandString", "QWord")]
        [string]$PropertyType = "DWord"
    )

    if ($PSCmdlet.ShouldProcess("Registry Key: $Path, Value: $Name=$Value", "Set Registry Property")) {
        try {
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            }
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction Stop | Out-Null
            return [PSCustomObject]@{
                Path   = $Path
                Name   = $Name
                Value  = $Value
                Status = "Success"
            }
        }
        catch {
            return [PSCustomObject]@{
                Path   = $Path
                Name   = $Name
                Value  = $Value
                Status = "Error: $($_.Exception.Message)"
            }
        }
    }
    else {
        return [PSCustomObject]@{
            Path   = $Path
            Name   = $Name
            Value  = $Value
            Status = "Preview"
        }
    }
}

function Get-ShellSetting {
    <#
        .SYNOPSIS
            Retrieves current shell and taskbar configuration.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $adv = if (Test-Path $advPath) { Get-ItemProperty -Path $advPath -ErrorAction SilentlyContinue } else { $null }

    # Taskbar Alignment (0 = Left, 1 = Center)
    $results.Add([PSCustomObject]@{
        Id          = "TaskbarAlignment"
        Title       = "Taskbar Icon Alignment"
        Value       = if ($adv -and $null -ne $adv.TaskbarAl) { if ($adv.TaskbarAl -eq 0) { "Left" } else { "Center" } } else { "Default" }
        Category    = "Taskbar"
    })

    # Taskbar Search Mode
    $results.Add([PSCustomObject]@{
        Id          = "TaskbarSearchMode"
        Title       = "Taskbar Search Mode"
        Value       = if ($adv -and $null -ne $adv.SearchboxTaskbarMode) { $adv.SearchboxTaskbarMode } else { 3 }
        Category    = "Taskbar"
    })

    # Taskbar Widgets
    $results.Add([PSCustomObject]@{
        Id          = "HideTaskbarWidgets"
        Title       = "Hide Taskbar Widgets"
        Value       = if ($adv -and $null -ne $adv.TaskbarDa) { ($adv.TaskbarDa -eq 0) } else { $false }
        Category    = "Taskbar"
    })

    # Taskbar Chat
    $results.Add([PSCustomObject]@{
        Id          = "HideTaskbarChat"
        Title       = "Hide Taskbar Chat"
        Value       = if ($adv -and $null -ne $adv.TaskbarMn) { ($adv.TaskbarMn -eq 0) } else { $false }
        Category    = "Taskbar"
    })

    # Taskbar Task View
    $results.Add([PSCustomObject]@{
        Id          = "HideTaskView"
        Title       = "Hide Task View Button"
        Value       = if ($adv -and $null -ne $adv.ShowTaskViewButton) { ($adv.ShowTaskViewButton -eq 0) } else { $false }
        Category    = "Taskbar"
    })

    # Taskbar End Task
    $devPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
    $dev = if (Test-Path $devPath) { Get-ItemProperty -Path $devPath -ErrorAction SilentlyContinue } else { $null }
    $results.Add([PSCustomObject]@{
        Id          = "EnableTaskbarEndTask"
        Title       = "Enable 'End Task' on Taskbar"
        Value       = if ($dev -and $null -ne $dev.TaskbarEndTask) { ($dev.TaskbarEndTask -eq 1) } else { $false }
        Category    = "Taskbar"
    })

    # File Explorer Show File Extensions
    $results.Add([PSCustomObject]@{
        Id          = "ShowFileExtensions"
        Title       = "Show Known File Extensions"
        Value       = if ($adv -and $null -ne $adv.HideFileExt) { ($adv.HideFileExt -eq 0) } else { $false }
        Category    = "FileExplorer"
    })

    # File Explorer Show Hidden Files
    $results.Add([PSCustomObject]@{
        Id          = "ShowHiddenFiles"
        Title       = "Show Hidden Files and Folders"
        Value       = if ($adv -and $null -ne $adv.Hidden) { ($adv.Hidden -eq 1) } else { $false }
        Category    = "FileExplorer"
    })

    # File Explorer Launch Location (1 = This PC, 2 = Home)
    $results.Add([PSCustomObject]@{
        Id          = "ExplorerLaunchTo"
        Title       = "Open File Explorer To"
        Value       = if ($adv -and $null -ne $adv.LaunchTo) { if ($adv.LaunchTo -eq 1) { "ThisPC" } else { "Home" } } else { "Home" }
        Category    = "FileExplorer"
    })

    return $results.ToArray()
}

function Set-ShellSetting {
    <#
        .SYNOPSIS
            Applies shell, taskbar, or file explorer configurations.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("TaskbarAlignLeft", "TaskbarAlignCenter", "HideSearch", "ShowSearchIcon", "ShowSearchBox", "HideWidgets", "HideChat", "HideTaskView", "EnableEndTask", "ShowFileExtensions", "ShowHiddenFiles", "ExplorerToThisPC", "HideOneDriveNav", "HideGalleryNav", "HideSearchHighlights", "ShowCompactExplorer", "DisableSnapFlyout")]
        [string]$SettingId
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()
    $advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    switch ($SettingId) {
        "TaskbarAlignLeft" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "TaskbarAl" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "TaskbarAlignCenter" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "TaskbarAl" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "HideSearch" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "SearchboxTaskbarMode" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "ShowSearchIcon" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "SearchboxTaskbarMode" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "ShowSearchBox" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "SearchboxTaskbarMode" -Value 3 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "HideWidgets" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "TaskbarDa" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "HideChat" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "TaskbarMn" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "HideTaskView" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "ShowTaskViewButton" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "EnableEndTask" {
            $devPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
            $ops.Add((Set-RegistryPropertyHelper -Path $devPath -Name "TaskbarEndTask" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "ShowFileExtensions" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "HideFileExt" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "ShowHiddenFiles" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "Hidden" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "ExplorerToThisPC" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "LaunchTo" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "HideOneDriveNav" {
            $oneDrivePath = "HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
            $ops.Add((Set-RegistryPropertyHelper -Path $oneDrivePath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "HideGalleryNav" {
            $galleryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace_36354489\{e88865ea-0e1c-4e20-9aa6-ed353b768351}"
            if ($PSCmdlet.ShouldProcess("Registry Key: $galleryPath", "Remove Gallery Namespace")) {
                try {
                    if (Test-Path $galleryPath) {
                        Remove-Item -Path $galleryPath -Recurse -Force -ErrorAction Stop
                    }
                    $ops.Add([PSCustomObject]@{ Path = $galleryPath; Name = ""; Value = "Removed"; Status = "Success" })
                }
                catch {
                    $ops.Add([PSCustomObject]@{ Path = $galleryPath; Name = ""; Value = "Removed"; Status = "Error: $($_.Exception.Message)" })
                }
            } else {
                $ops.Add([PSCustomObject]@{ Path = $galleryPath; Name = ""; Value = "Removed"; Status = "Preview" })
            }
        }
        "HideSearchHighlights" {
            $searchSettingsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
            $ops.Add((Set-RegistryPropertyHelper -Path $searchSettingsPath -Name "IsDeviceSearchHistoryEnabled" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
            $ops.Add((Set-RegistryPropertyHelper -Path $searchSettingsPath -Name "IsDynamicSearchBoxEnabled" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "ShowCompactExplorer" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "UseCompactMode" -Value 1 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
        "DisableSnapFlyout" {
            $ops.Add((Set-RegistryPropertyHelper -Path $advPath -Name "EnableSnapAssistFlyout" -Value 0 -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        }
    }

    return $ops.ToArray()
}

function Restart-ShellExplorer {
    <#
        .SYNOPSIS
            Restarts explorer.exe cleanly to apply shell modifications.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if ($PSCmdlet.ShouldProcess("Process: explorer.exe", "Restart Windows Explorer to refresh Taskbar & Shell")) {
        try {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
            if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
                Start-Process explorer.exe
            }
            Write-Verbose "Windows Explorer restarted successfully."
        }
        catch {
            Write-Warning "Failed to restart Windows Explorer: $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function Get-ShellSetting, Set-ShellSetting, Restart-ShellExplorer

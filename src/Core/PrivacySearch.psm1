<#
    .SYNOPSIS
        NH Win Debloater - Privacy & Search Engine
    .DESCRIPTION
        Manages Windows telemetry, diagnostic data, personalized suggestions,
        AI assistants (Copilot, Recall), Activity History, and Bing Search integration.
    .MODULEVERSION
        0.1.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
param()

function Set-RegistryPropertySafe {
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

function Get-PrivacySetting {
    <#
        .SYNOPSIS
            Retrieves current status of Windows privacy and search settings.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. Telemetry / Diagnostics
    $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    $telemetryVal = if (Test-Path $telemetryPath) { (Get-ItemProperty -Path $telemetryPath -ErrorAction SilentlyContinue).AllowTelemetry } else { $null }
    $results.Add([PSCustomObject]@{
        Id          = "DisableTelemetry"
        Title       = "Diagnostic Data / Telemetry"
        Description = "Restrict system diagnostic telemetry to minimum Security/Basic level"
        IsEnabled   = ($telemetryVal -eq 0 -or $telemetryVal -eq 1)
        Category    = "Privacy"
    })

    # 2. Tailored Experiences & Ads
    $privacyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"
    $tailoredVal = if (Test-Path $privacyPath) { (Get-ItemProperty -Path $privacyPath -ErrorAction SilentlyContinue).TailoredExperiencesWithDiagnosticDataEnabled } else { $null }
    $results.Add([PSCustomObject]@{
        Id          = "DisableTailoredExperiences"
        Title       = "Tailored Experiences & Suggestions"
        Description = "Block Microsoft from using diagnostics for targeted tips and promos"
        IsEnabled   = ($tailoredVal -eq 0)
        Category    = "Privacy"
    })

    # 3. Advertising ID
    $adInfoPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    $adVal = if (Test-Path $adInfoPath) { (Get-ItemProperty -Path $adInfoPath -ErrorAction SilentlyContinue).Enabled } else { $null }
    $results.Add([PSCustomObject]@{
        Id          = "DisableAdvertisingId"
        Title       = "Advertising Tracking ID"
        Description = "Prevent applications from tracking ad engagement across apps"
        IsEnabled   = ($adVal -eq 0)
        Category    = "Privacy"
    })

    # 4. Copilot & AI Recall
    $copilotPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    $copilotVal = if (Test-Path $copilotPath) { (Get-ItemProperty -Path $copilotPath -ErrorAction SilentlyContinue).TurnOffWindowsCopilot } else { $null }
    $results.Add([PSCustomObject]@{
        Id          = "DisableCopilot"
        Title       = "Windows Copilot & AI"
        Description = "Disable Windows Copilot assistant integration and button"
        IsEnabled   = ($copilotVal -eq 1)
        Category    = "AI"
    })

    # 5. Activity History Feed
    $activityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    $activityVal = if (Test-Path $activityPath) { (Get-ItemProperty -Path $activityPath -ErrorAction SilentlyContinue).PublishUserActivities } else { $null }
    $results.Add([PSCustomObject]@{
        Id          = "DisableActivityHistory"
        Title       = "Activity History Tracking"
        Description = "Prevent Windows from recording user task and timeline history"
        IsEnabled   = ($activityVal -eq 0)
        Category    = "Privacy"
    })

    # 6. Bing Search & Suggestions in Start
    $bingPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
    $bingVal = if (Test-Path $bingPath) { (Get-ItemProperty -Path $bingPath -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions } else { $null }
    $results.Add([PSCustomObject]@{
        Id          = "DisableBingSearch"
        Title       = "Bing Web Search in Start"
        Description = "Block web search results and Cortana from Start menu search"
        IsEnabled   = ($bingVal -eq 1)
        Category    = "Search"
    })

    return $results.ToArray()
}

function Set-PrivacySetting {
    <#
        .SYNOPSIS
            Enforces privacy and search optimization settings.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("DisableTelemetry", "DisableTailoredExperiences", "DisableAdvertisingId", "DisableCopilot", "DisableActivityHistory", "DisableBingSearch", "All")]
        [string]$SettingId,

        [Parameter(Mandatory = $false)]
        [bool]$Enable = $true
    )

    $ops = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. Telemetry / Diagnostics
    if ($SettingId -eq "DisableTelemetry" -or $SettingId -eq "All") {
        $val = if ($Enable) { 0 } else { 3 }
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    # 2. Tailored Experiences & Ads
    if ($SettingId -eq "DisableTailoredExperiences" -or $SettingId -eq "All") {
        $val = if ($Enable) { 0 } else { 1 }
        $ops.Add((Set-RegistryPropertySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    # 3. Advertising ID
    if ($SettingId -eq "DisableAdvertisingId" -or $SettingId -eq "All") {
        $val = if ($Enable) { 0 } else { 1 }
        $ops.Add((Set-RegistryPropertySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    # 4. Windows Copilot & AI Recall
    if ($SettingId -eq "DisableCopilot" -or $SettingId -eq "All") {
        $copilotVal = if ($Enable) { 1 } else { 0 }
        $btnVal = if ($Enable) { 0 } else { 1 }
        $ops.Add((Set-RegistryPropertySafe -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value $copilotVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value $copilotVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value $btnVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value $copilotVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    # 5. Activity History
    if ($SettingId -eq "DisableActivityHistory" -or $SettingId -eq "All") {
        $val = if ($Enable) { 0 } else { 1 }
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value $val -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    # 6. Bing Search in Start
    if ($SettingId -eq "DisableBingSearch" -or $SettingId -eq "All") {
        $policyVal = if ($Enable) { 1 } else { 0 }
        $bingVal = if ($Enable) { 0 } else { 1 }
        $ops.Add((Set-RegistryPropertySafe -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value $policyVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value $bingVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value $bingVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value $bingVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
        $ops.Add((Set-RegistryPropertySafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value $policyVal -PropertyType "DWord" -WhatIf:$WhatIfPreference))
    }

    return $ops.ToArray()
}

Export-ModuleMember -Function Get-PrivacySetting, Set-PrivacySetting

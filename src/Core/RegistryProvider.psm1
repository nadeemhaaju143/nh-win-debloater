<#
    .SYNOPSIS
        NH Win Debloater - Exact Typed Registry Provider
    .DESCRIPTION
        Captures exact registry value existence, data, and RegistryValueKind before writes,
        performs post-apply verification, and restores exact types or deletes newly created
        values on rollback with conflict detection.
        Developed by Mohammed Nadeem BM (NH Digital - https://nhdigital.shop).
    .MODULEVERSION
        1.4.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
param()

function Get-TypedRegistryState {
    <#
        .SYNOPSIS
            Captures exact existence, value, and RegistryValueKind for a registry path and value name.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $existed = $false
    $val = $null
    $kind = "Unknown"

    if (Test-Path -Path $Path) {
        try {
            $key = Get-Item -Path $Path -ErrorAction Stop
            $queryName = if ($Name -eq "(Default)") { "" } else { $Name }
            $valueNames = @($key.GetValueNames())
            if ($valueNames -contains $queryName) {
                $existed = $true
                $val = $key.GetValue($queryName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                $kind = [string]$key.GetValueKind($queryName)
            }
        }
        catch {
            Write-Verbose "Could not read registry state '$Path\$Name': $($_.Exception.Message)"
        }
    }

    return [PSCustomObject]@{
        Path      = $Path
        Name      = $Name
        Existed   = $existed
        Value     = $val
        ValueKind = $kind
    }
}

function Set-TypedRegistryValue {
    <#
        .SYNOPSIS
            Writes a typed registry value after capturing its exact before-state, then verifies post-apply.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DWord", "QWord", "String", "ExpandString", "Binary", "MultiString")]
        [string]$PropertyType = "DWord"
    )

    $before = Get-TypedRegistryState -Path $Path -Name $Name

    if ($PSCmdlet.ShouldProcess("Key: $Path, Name: $Name ($PropertyType)", "Set Value to $Value")) {
        try {
            if (-not (Test-Path -Path $Path)) {
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            }
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction Stop | Out-Null
            $after = Get-TypedRegistryState -Path $Path -Name $Name

            $verified = $false
            if ($after.Existed -and $after.ValueKind -eq $PropertyType) {
                if ($PropertyType -eq "Binary" -and $Value -is [byte[]]) {
                    $verified = (($after.Value -join ",") -eq ($Value -join ","))
                } else {
                    $verified = ([string]$after.Value -eq [string]$Value)
                }
            }

            return [PSCustomObject]@{
                Path          = $Path
                Name          = $Name
                Value         = $Value
                ValueKind     = $PropertyType
                PreviousState = $before
                Verified      = $verified
                Status        = if ($verified) { "Success" } else { "Warning: Verification mismatch" }
            }
        }
        catch {
            return [PSCustomObject]@{
                Path          = $Path
                Name          = $Name
                Value         = $Value
                ValueKind     = $PropertyType
                PreviousState = $before
                Verified      = $false
                Status        = "Error: $($_.Exception.Message)"
            }
        }
    }

    return [PSCustomObject]@{
        Path          = $Path
        Name          = $Name
        Value         = $Value
        ValueKind     = $PropertyType
        PreviousState = $before
        Verified      = $false
        Status        = "Preview"
    }
}

function Restore-TypedRegistryEntry {
    <#
        .SYNOPSIS
            Restores a registry entry to its exact previous value and type, or deletes it if Existed was false.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PreviousState,

        [Parameter(Mandatory = $false)]
        [object]$ExpectedAppliedValue = $null,

        [Parameter(Mandatory = $false)]
        [switch]$ForceOverwrite
    )

    $path = $PreviousState.Path
    $name = $PreviousState.Name
    $current = Get-TypedRegistryState -Path $path -Name $name

    # Conflict check: warn if modified externally after apply
    if ($null -ne $ExpectedAppliedValue -and $current.Existed) {
        $curStr = if ($current.Value -is [byte[]]) { $current.Value -join "," } else { [string]$current.Value }
        $expStr = if ($ExpectedAppliedValue -is [byte[]]) { $ExpectedAppliedValue -join "," } else { [string]$ExpectedAppliedValue }
        $prevStr = if ($PreviousState.Value -is [byte[]]) { $PreviousState.Value -join "," } else { [string]$PreviousState.Value }

        if ($curStr -ne $expStr -and (-not $PreviousState.Existed -or $curStr -ne $prevStr) -and (-not $ForceOverwrite)) {
            Write-Warning "Conflict detected for '$path\$name': current value '$curStr' was modified externally."
            return [PSCustomObject]@{
                Path     = $path
                Name     = $name
                Status   = "Conflict"
                Verified = $false
            }
        }
    }

    if (-not $PreviousState.Existed) {
        if ($PSCmdlet.ShouldProcess("Key: $path, Name: $name", "Delete newly created registry value")) {
            try {
                if (Test-Path -Path $path) {
                    $queryName = if ($name -eq "(Default)") { "" } else { $name }
                    Remove-ItemProperty -Path $path -Name $queryName -Force -ErrorAction SilentlyContinue
                }
                $after = Get-TypedRegistryState -Path $path -Name $name
                return [PSCustomObject]@{
                    Path     = $path
                    Name     = $name
                    Status   = "Deleted"
                    Verified = (-not $after.Existed)
                }
            }
            catch {
                return [PSCustomObject]@{
                    Path     = $path
                    Name     = $name
                    Status   = "Error: $($_.Exception.Message)"
                    Verified = $false
                }
            }
        }
        return [PSCustomObject]@{ Path = $path; Name = $name; Status = "Preview"; Verified = $false }
    }

    $targetKind = if ($PreviousState.ValueKind -and $PreviousState.ValueKind -ne "Unknown") { $PreviousState.ValueKind } else { "String" }
    if ($PSCmdlet.ShouldProcess("Key: $path, Name: $name", "Restore exact value ($targetKind)")) {
        try {
            if (-not (Test-Path -Path $path)) {
                New-Item -Path $path -Force -ErrorAction Stop | Out-Null
            }
            New-ItemProperty -Path $path -Name $name -Value $PreviousState.Value -PropertyType $targetKind -Force -ErrorAction Stop | Out-Null
            $after = Get-TypedRegistryState -Path $path -Name $name
            return [PSCustomObject]@{
                Path     = $path
                Name     = $name
                Status   = "Restored"
                Verified = ($after.Existed -and $after.ValueKind -eq $targetKind)
            }
        }
        catch {
            return [PSCustomObject]@{
                Path     = $path
                Name     = $name
                Status   = "Error: $($_.Exception.Message)"
                Verified = $false
            }
        }
    }

    return [PSCustomObject]@{ Path = $path; Name = $name; Status = "Preview"; Verified = $false }
}

Export-ModuleMember -Function Get-TypedRegistryState, Set-TypedRegistryValue, Restore-TypedRegistryEntry

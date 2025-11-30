<#
.SYNOPSIS
Manages and optimizes WSL2 virtual hard disk (VHDX) files.

.DESCRIPTION
This script lists the VHDX files associated with installed WSL2 distributions
and can optionally optimize their size.

.PARAMETER Optimize
If specified, optimizes the size of the VHDX files for all WSL2 distributions.
This operation requires administrator privileges and will shut down WSL before optimization.

.EXAMPLE
PS> .\Manage-WslVhd.ps1
Displays the path and size of the VHDX files for installed WSL2 distributions.

.EXAMPLE
PS> .\Manage-WslVhd.ps1 -Optimize
Optimizes the VHDX files for all WSL2 distributions.
You must run PowerShell as an administrator.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Optimizes the VHDX file. Administrator privileges are required.")]
    [switch]$Optimize
)

# Check for administrator privileges if the -Optimize switch is specified
if ($Optimize) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This operation requires administrator privileges. Please re-run PowerShell as an administrator."
        exit 1
    }
}

# Registry path where WSL distribution information is stored
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"

# Get the GUID for each distribution by searching the registry path
$distributions = Get-ChildItem -Path $registryPath

if ($null -eq $distributions) {
    Write-Warning "No WSL distributions were found."
    return
}

if ($Optimize) {
    Write-Host "Shutting down WSL..."
    wsl.exe --shutdown
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to shut down WSL."
        # Output a warning message because continuing may cause unexpected behavior.
        # Optimization may not proceed as the disk might be locked.
        Write-Warning "Continuing the operation, but the VHDX file may be locked."
    } else {
        Write-Host "WSL was shut down successfully."
    }
    Write-Host "" # Add a blank line for readability
} else {
    Write-Host "Location of WSL image files:"
    Write-Host "--------------------------"
}


# Loop through and process each distribution's information
foreach ($distro in $distributions) {
    # Get the distribution name and the path to the folder containing the image
    $properties = Get-ItemProperty -Path $distro.PSPath
    $distributionName = $properties.DistributionName
    $basePath = $properties.BasePath

    # Construct the full path to the ext4.vhdx file
    $vhdxPath = Join-Path -Path $basePath -ChildPath "ext4.vhdx"

    # Check if a file exists at the constructed path
    if (Test-Path -Path $vhdxPath -PathType Leaf) {
        if ($Optimize) {
            Write-Host "Optimizing VHDX for [$distributionName]..."
            try {
                $beforeSizeBytes = (Get-Item -Path $vhdxPath).Length
                
                Optimize-VHD -Path $vhdxPath -Mode Full -ErrorAction Stop

                $afterSizeBytes = (Get-Item -Path $vhdxPath).Length
                $savedBytes = $beforeSizeBytes - $afterSizeBytes

                $beforeSizeGB = "{0:N2} GB" -f ($beforeSizeBytes / 1GB)
                $afterSizeGB = "{0:N2} GB" -f ($afterSizeBytes / 1GB)
                $savedGB = "{0:N2} GB" -f ($savedBytes / 1GB)

                Write-Host "Optimization for [$distributionName] is complete." -ForegroundColor Green
                Write-Host "File size: $beforeSizeGB -> $afterSizeGB (Saved: $savedGB)"
                Write-Host "" # Add a blank line for readability
            } catch {
                Write-Error "An error occurred while optimizing [$distributionName]: $($_.Exception.Message)"
                Write-Host "" # Add a blank line for readability
            }
        } else {
            # Format and output the results
            $vhdxSizeBytes = (Get-Item -Path $vhdxPath).Length
            $vhdxSizeGB = "{0:N2} GB" -f ($vhdxSizeBytes / 1GB)
            [PSCustomObject]@{
                Distribution = $distributionName
                VHDXPath     = $vhdxPath
                VHDXSize     = $vhdxSizeGB
            } | Format-List
        }
    } else {
        Write-Warning "Image file not found for distribution '$distributionName': $vhdxPath"
    }
}
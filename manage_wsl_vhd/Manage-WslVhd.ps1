[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Optimizes the VHDX file. Administrator privileges are required.")]
    [switch]$Optimize
)

if ($Optimize) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This operation requires administrator privileges. Please re-run PowerShell as an administrator."
        exit 1
    }
}

$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"

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
        Write-Warning "Continuing the operation, but the VHDX file may be locked."
    } else {
        Write-Host "WSL was shut down successfully."
    }
    Write-Host ""
} else {
    Write-Host "Location of WSL image files:"
    Write-Host "--------------------------"
}

foreach ($distro in $distributions) {
    $properties = Get-ItemProperty -Path $distro.PSPath
    $distributionName = $properties.DistributionName
    $basePath = $properties.BasePath
    $vhdxPath = Join-Path -Path $basePath -ChildPath "ext4.vhdx"

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
                Write-Host ""
            } catch {
                Write-Error "An error occurred while optimizing [$distributionName]: $($_.Exception.Message)"
                Write-Host ""
            }
        } else {
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

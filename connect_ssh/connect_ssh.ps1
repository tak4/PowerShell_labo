# connect_ssh.ps1
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "inifile/config.ini"
$TTLFile = Join-Path $ScriptDir "WSL_connect_ssh.ttl"

if (-not (Test-Path $ConfigFile)) {
    Add-Content -Path $ConfigFile -Value "[SelectedHost]"
    Add-Content -Path $ConfigFile -Value "SelectHost=PC1"
    Add-Content -Path $ConfigFile -Value "" # Newline for separation
    Add-Content -Path $ConfigFile -Value "[HostAddr]"
    Add-Content -Path $ConfigFile -Value "HostAddr1=127.0.0.1"
    Add-Content -Path $ConfigFile -Value "HostAddr2=172.17.71.90"
    Add-Content -Path $ConfigFile -Value "" # Newline for separation
    Add-Content -Path $ConfigFile -Value "[Port]"
    Add-Content -Path $ConfigFile -Value "PortNo=65535"
    Add-Content -Path $ConfigFile -Value "" # Newline for separation
    Add-Content -Path $ConfigFile -Value "[Paths]"
    Add-Content -Path $ConfigFile -Value "TTPMacroExe=D:\tools\teraterm-5.4.0\ttpmacro.exe"
}

# Get the path to the macro interpreter
$TTPMacroExe = (Get-Content $ConfigFile | Select-String -Pattern "TTPMacroExe=").ToString().Split('=')[1].Trim()

# Get default settings from config.ini
$DefaultSelectedHost = (Get-Content $ConfigFile | Select-String -Pattern "SelectedHost=").ToString().Split('=')[1].Trim()
$HostAddr1 = (Get-Content $ConfigFile | Select-String -Pattern "HostAddr1=").ToString().Split('=')[1].Trim()
$HostAddr2 = (Get-Content $ConfigFile | Select-String -Pattern "HostAddr2=").ToString().Split('=')[1].Trim()
$DefaultPortNo = (Get-Content $ConfigFile | Select-String -Pattern "PortNo=").ToString().Split('=')[1].Trim()

# Accept input for settings
$SelectedHostNo = Read-Host "Enter PC No. (Default: $DefaultSelectedHost)"
$PortNo = Read-Host "Enter PortNo (Default: $DefaultPortNo)"
# Use default settings if no input is provided
if ([string]::IsNullOrWhiteSpace($SelectedHostNo)) {
    $SelectedHostNo = $DefaultSelectedHost.TrimStart("PC")
}
if ([string]::IsNullOrWhiteSpace($PortNo)) {
    $PortNo = $DefaultPortNo
}

switch ($SelectedHostNo) {
    '1' {
        $HostAddr = $HostAddr1
    }
    '2' {
        $HostAddr = $HostAddr2
    }
    default {
        throw "Invalid selection: '$SelectedHostNo'. Script aborted."
    }
}

Write-Host "Selected PC   : PC$SelectedHostNo : $HostAddr" -ForegroundColor Green
Write-Host "Selected Port : $DefaultPortNo" -ForegroundColor Green

(Get-Content $ConfigFile) | ForEach-Object {
    if ($_ -like "HostAddr=*") {
        "HostAddr=$HostAddr"
    } else {
        $_
    }
} | Set-Content $ConfigFile

Start-Process -FilePath $TTPMacroExe -ArgumentList "$TTLFile $HostAddr $PortNo"

# connect_ssh.ps1
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "inifile/config.ini"
$TTLFile = Join-Path $ScriptDir "WSL_connect_ssh.ttl"

if (-not (Test-Path $ConfigFile)) {
    Add-Content -Path $ConfigFile -Value "[HostAddr]"
    Add-Content -Path $ConfigFile -Value "HostAddr=127.0.0.1"
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
$DefaultHostAddr = (Get-Content $ConfigFile | Select-String -Pattern "HostAddr=").ToString().Split('=')[1].Trim()
$DefaultPortNo = (Get-Content $ConfigFile | Select-String -Pattern "PortNo=").ToString().Split('=')[1].Trim()

# Accept input for settings
$HostAddr = Read-Host "Enter Host Address (Default: $DefaultHostAddr)"
$PortNo = Read-Host "Enter Host Address (Default: $PortNo)"
Write-Host "$DefaultHostAddr" -ForegroundColor Green
Write-Host "$DefaultPortNo" -ForegroundColor Green

# Use default settings if no input is provided
if ([string]::IsNullOrWhiteSpace($HostAddr)) {
    $HostAddr = $DefaultHostAddr
}
if ([string]::IsNullOrWhiteSpace($PortNo)) {
    $PortNo = $DefaultPortNo
}

(Get-Content $ConfigFile) | ForEach-Object {
    if ($_ -like "HostAddr=*") {
        "HostAddr=$HostAddr"
    } else {
        $_
    }
} | Set-Content $ConfigFile

Start-Process -FilePath $TTPMacroExe -ArgumentList "$TTLFile $HostAddr $PortNo"

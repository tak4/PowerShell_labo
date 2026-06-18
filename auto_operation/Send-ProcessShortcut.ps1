<#
.SYNOPSIS
指定されたプロセスのメインウィンドウにショートカットキーを送信します。
.PARAMETER ProcessName
送信対象のアプリケーションのプロセス名を指定します。
.PARAMETER KeySequence
送信するキーシーケンスを指定します。例: "Alt+L, Enter" または "Ctrl+S"。
.EXAMPLE
.\Send-ProcessShortcut.ps1 -ProcessName notepad -KeySequence "Alt+L, Enter"
#>
param(
    [string]$ProcessName = "notepad",
    [Parameter(Mandatory = $true)]
    [string]$KeySequence
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

function Convert-ToSendKeys {
    param(
        [string]$sequence
    )

    $mappings = @{
        'ALT'   = '%'
        'CTRL'  = '^'
        'CONTROL' = '^'
        'SHIFT' = '+'
        'ENTER' = '{ENTER}'
        'TAB'   = '{TAB}'
        'ESC'   = '{ESC}'
        'ESCAPE'= '{ESC}'
        'SPACE' = ' '
        'BACKSPACE' = '{BACKSPACE}'
        'DELETE' = '{DELETE}'
        'HOME'  = '{HOME}'
        'END'   = '{END}'
        'UP'    = '{UP}'
        'DOWN'  = '{DOWN}'
        'LEFT'  = '{LEFT}'
        'RIGHT' = '{RIGHT}'
    }

    $parts = $sequence -split ','
    $sendKeys = ''

    foreach ($part in $parts) {
        $trimmed = $part.Trim()
        if ($trimmed -eq '') { continue }

        $keys = $trimmed -split '\+' | ForEach-Object { $_.Trim() }
        $converted = ''
        foreach ($key in $keys) {
            $upperKey = $key.ToUpperInvariant()
            if ($mappings.ContainsKey($upperKey)) {
                $converted += $mappings[$upperKey]
            }
            elseif ($upperKey.Length -eq 1) {
                $converted += $upperKey
            }
            else {
                $converted += "{$upperKey}"
            }
        }

        $sendKeys += $converted
        $sendKeys += ' '
    }

    return $sendKeys.TrimEnd()
}

$process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $process) {
    Write-Host "Process '$ProcessName' is not running."
    exit 1
}

$hWnd = $process.MainWindowHandle
if (-not $hWnd -or $hWnd -eq [IntPtr]::Zero) {
    Write-Host "プロセス '$ProcessName' のメインウィンドウが見つかりません。"
    exit 1
}

if (-not [NativeMethods]::SetForegroundWindow($hWnd)) {
    Write-Warning "ウィンドウを前面にできませんでした。"
}

$sendKeys = Convert-ToSendKeys -sequence $KeySequence
Write-Host "Sending keys to '$ProcessName': $KeySequence -> $sendKeys"

try {
    $shell = New-Object -ComObject WScript.Shell
    Start-Sleep -Milliseconds 200
    $shell.SendKeys($sendKeys)
    Write-Host "キー送信を完了しました。"
}
catch {
    Write-Error "SendKeys の送信に失敗しました: $($_.Exception.Message)"
    exit 1
}

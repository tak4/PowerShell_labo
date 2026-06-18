<#
.SYNOPSIS
指定されたプロセスのメインウィンドウに対して、ウィンドウ内の座標をクリックします。
.PARAMETER ProcessName
クリック対象のアプリケーションのプロセス名を指定します。
.PARAMETER X
ウィンドウの左上を原点としたクリック位置のX座標（ピクセル）を指定します。
.PARAMETER Y
ウィンドウの左上を原点としたクリック位置のY座標（ピクセル）を指定します。
.EXAMPLE
.\Click-ProcessCoordinate.ps1 -ProcessName notepad -X 100 -Y 100
#>
param(
    [string]$ProcessName = "notepad",
    [Parameter(Mandatory = $true)]
    [int]$X,
    [Parameter(Mandatory = $true)]
    [int]$Y
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, UIntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

# Left mouse button down/up flags
$MOUSEEVENTF_LEFTDOWN = 0x0002
$MOUSEEVENTF_LEFTUP   = 0x0004

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
    Write-Warning "ウィンドウを前面にできませんでした。クリック位置の計算を続行します。"
}

$point = New-Object NativeMethods+POINT
$point.X = $X
$point.Y = $Y

if (-not [NativeMethods]::ClientToScreen($hWnd, [ref]$point)) {
    Write-Host "クライアント座標からスクリーン座標への変換に失敗しました。"
    exit 1
}

Write-Host "Clicking '$ProcessName' at client coordinate ($X, $Y) => screen coordinate ($($point.X), $($point.Y))."

if (-not [NativeMethods]::SetCursorPos($point.X, $point.Y)) {
    Write-Host "マウスカーソルの移動に失敗しました。"
    exit 1
}

Start-Sleep -Milliseconds 100
[NativeMethods]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 50
[NativeMethods]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [UIntPtr]::Zero)

Write-Host "クリックを実行しました。"

# 指定フォルダのパスを設定
# $folderPath = "D:\develop\PowerShell\PowerShell_labo\change_newline_code\target"
# コマンドライン引数からフォルダパスを取得
# .\change_line_ending.ps1 -folderPath "D:\develop\PowerShell\PowerShell_labo\change_newline_code\target"
param (
    [string]$folderPath
)

Write-Output $folderPath
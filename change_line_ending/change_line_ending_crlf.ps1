# 指定フォルダのパスを設定
# $folderPath = "D:\develop\PowerShell\PowerShell_labo\change_newline_code\target"
# コマンドライン引数からフォルダパスを取得
# .\change_line_ending.ps1 -folderPath "D:\develop\PowerShell\PowerShell_labo\change_newline_code\target"
param (
    [string]$folderPath
)

#
# Set-Content: 変更後の内容をファイルに書き込みます。-NoNewline パラメータを使用することで、追加の改行を防ぎます。
#
Get-ChildItem -Path $folderPath -Filter *.txt -Recurse | ForEach-Object {
    (Get-Content -Path $_.FullName -Raw) -replace "`n", "`r`n" | Set-Content -Path $_.FullName -NoNewline
}
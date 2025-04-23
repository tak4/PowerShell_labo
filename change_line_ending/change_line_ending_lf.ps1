# 指定フォルダのパスを設定
# $folderPath = "D:\develop\PowerShell\PowerShell_labo\change_newline_code\target"
# コマンドライン引数からフォルダパスを取得
# .\change_line_ending.ps1 -folderPath "D:\develop\PowerShell\PowerShell_labo\change_newline_code\target"
param (
    [string]$folderPath
)

#
# フォルダ内のすべてのテキストファイルを取得し、改行コードをLFに変更
#

#
# Get-ChildItem: 指定フォルダ内のすべての .txt ファイルを取得します。
#  -Recurse 指定したフォルダ内のすべてのサブフォルダも再帰的に検索
#
# Get-ChildItem -Path $folderPath -Filter *.txt
# Get-ChildItem -Path $folderPath -Filter *.txt -Recurse

#
# ForEach-Object: 各テキストファイルに対して処理を行います。
#
# Get-ChildItem -Path $folderPath -Filter *.txt -Recurse | ForEach-Object {
#     Write-Output $_.FullName    # Fullpath出力
# }

#
# Get-Content: ファイルの内容を取得します。-Raw パラメータを使用することで、ファイル全体を一度に読み込みます。
#
# Get-ChildItem -Path $folderPath -Filter *.txt -Recurse | ForEach-Object {
#     (Get-Content -Path $_.FullName -Raw)
# }

#
# -replace “rn”, "n": 改行コードをCRLF（\r\n）からLF（\n）に置換します。
#
# Get-ChildItem -Path $folderPath -Filter *.txt -Recurse | ForEach-Object {
#     (Get-Content -Path $_.FullName -Raw) -replace "`r`n", "`n"
# }

#
# Set-Content: 変更後の内容をファイルに書き込みます。-NoNewline パラメータを使用することで、追加の改行を防ぎます。
#
Get-ChildItem -Path $folderPath -Filter *.txt -Recurse | ForEach-Object {
    (Get-Content -Path $_.FullName -Raw -Encoding UTF8) -replace "`r`n", "`n" | Set-Content -Path $_.FullName -NoNewline -Encoding UTF8
}
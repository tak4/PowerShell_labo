# コマンドラインからの引数受け取りサンプル
param (
    [string]$folderPath,
    [int]$value
)

Write-Host $folderPath
Write-Host $value

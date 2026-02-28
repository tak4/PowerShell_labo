# 1. フォルダ構成の作成
$root = "folder1"
$sub = Join-Path $root "folder1-1"

Write-Host "Creating folder structure..."
# 既存のfolder1があれば削除してクリーンな状態にする
if (Test-Path $root) { Remove-Item $root -Recurse -Force }

New-Item -ItemType Directory -Path $sub -Force | Out-Null

New-Item -ItemType File -Path (Join-Path $root "test1-1.txt") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $root "test1-2.txt") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $root "test1-3.txt") -Force | Out-Null

# 2. folder1 の中にあるtxtファイルを folder1/folder1-1 の中へ移動
Write-Host "Moving .txt files to $sub..."
Get-ChildItem -Path $root -Filter "*.txt" | Move-Item -Destination $sub

# 3. folder1 をzipファイルに圧縮
$zipFile = "folder1_reorganized.zip"
Write-Host "Compressing $root to $zipFile..."
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
Compress-Archive -Path $root -DestinationPath $zipFile

Write-Host "Done."

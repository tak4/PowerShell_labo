Param(
    [Parameter(Mandatory=$false)]
    [string]$TargetDir = "."
)

# 指定されたフォルダが存在しない場合は作成
if (!(Test-Path $TargetDir)) {
    Write-Host "Creating target directory: $TargetDir"
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

$AbsTargetDir = (Get-Item $TargetDir).FullName
Write-Host "Operating in: $AbsTargetDir"

Push-Location $AbsTargetDir

try {
    # 1. フォルダ構成の作成
    $root = "folder1"
    $sub = Join-Path $root "folder1-1"

    Write-Host "Creating folder structure..."
    New-Item -ItemType Directory -Path $sub -Force | Out-Null

    New-Item -ItemType File -Path (Join-Path $root "test1-1.txt") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $root "test1-2.txt") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $sub "test1-1-1.txt") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $sub "test1-1-2.txt") -Force | Out-Null

    # 2. folder1 を folder1.zip に圧縮
    $zipFile = "folder1.zip"
    Write-Host "Compressing $root to $zipFile..."
    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
    Compress-Archive -Path $root -DestinationPath $zipFile

    # 3. folder1 から txt ファイルのみを削除
    Write-Host "Removing .txt files from $root..."
    Get-ChildItem -Path $root -Filter "*.txt" -Recurse | Remove-Item -Force

    Write-Host "Done."
}
finally {
    Pop-Location
}

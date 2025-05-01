# 本ファイルの文字コードは、UTF8 with BOM
# -Encoding UTF8 とすることで、UTF8 with BOMで保存される
$lines = Get-Content "sample_utf8_with_bom.txt"
foreach ($line in $lines) {
    Write-Host $line
}

Get-Content "sample_utf8_with_bom.txt" | ForEach-Object {
    Write-Host $_
}


# 本ファイルの文字コードは。SJIS
# -Encoding Default とすることで、SJISで保存すされる
$lines = Get-Content "sample_sjis.txt"
foreach ($line in $lines) {
    Write-Host $line
}

Get-Content "sample_sjis.txt" | ForEach-Object {
    Write-Host $_
}


# �{�t�@�C���̕����R�[�h�́BSJIS
# -Encoding Default �Ƃ��邱�ƂŁASJIS�ŕۑ��������
$lines = Get-Content "sample_sjis.txt"
foreach ($line in $lines) {
    Write-Host $line
}

Get-Content "sample_sjis.txt" | ForEach-Object {
    Write-Host $_
}


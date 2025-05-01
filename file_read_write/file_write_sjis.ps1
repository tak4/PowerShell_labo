# 本ファイルの文字コードは、SJIS
# -Encoding Default とすることで、SJISで保存すされる
Set-Content -Path "sample_sjis.txt" -Encoding Default -Value "書き込み内容"
Add-Content -Path "sample_sjis.txt" -Encoding Default -Value "追記内容"

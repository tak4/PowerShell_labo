# 本ファイルの文字コードは、UTF8 with BOM
# -Encoding UTF8 とすることで、UTF8 with BOMで保存される
# -Encoding UTF8 では BON付きUTF8になる
Set-Content -Path "sample_utf8_with_bom.txt" -Encoding UTF8 -Value "書き込み内容"
Add-Content -Path "sample_utf8_with_bom.txt" -Encoding UTF8 -Value "追記内容"

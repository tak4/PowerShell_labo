# 本ファイルの文字コードは、UTF8 with BOM
# これでもBOM付きになってしまう
[System.IO.File]::WriteAllLines(".\output_utf8.txt", @("書き込み内容"), [System.Text.Encoding]::UTF8)

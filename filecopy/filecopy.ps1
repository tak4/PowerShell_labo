$target_file = "testfile.xlsx"

# 日付を年月日時分秒形式で取得
$formatted_date = (Get-Date).ToString("yyyyMMddHHmm")
 
# 文字列を確認（yyyymmdd形式で表示されます）
$new_filename = $formatted_date + "_" + $target_file

Echo $new_filename

# ファイルコピー
Copy-Item -Path $target_file -Destination $new_filename



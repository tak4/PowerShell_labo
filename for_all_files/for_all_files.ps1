# カレントディレクトリを取得
$currentDirectory = Get-Location

# カレントディレクトリに移動
Set-Location $currentDirectory

# カレントディレクトリとサブディレクトリにあるすべてのtxtファイルを処理
Get-ChildItem -Path . -Recurse -Filter *.txt | ForEach-Object {
  # ファイルの内容を表示
  Get-Content -Path $_.FullName
}

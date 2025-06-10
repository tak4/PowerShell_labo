# PowerShell_labo

## Version確認
$PSVersionTable

## 実行兼確認
Get-ExecutionPolicy

AllSigned（署名付きスクリプトのみ実行可）  
Bypass（検査迂回）  
RemoteSigned（ローカルスクリプトと署名付きのリモートスクリプトのみ実行可）  
Restricted（全て実行不可）  
Undefined（未定義）  
Unrestricted（全て実行可）  

## グループポリシー確認
Get-ExecutionPolicy -list

## スクリプト実行兼付与 ※管理者権限必要
Set-ExecutionPolicy RemoteSigned

## スクリプト実行兼付与
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

## 実行時に実行権付与する
powershell -ExecutionPolicy RemoteSigned -File .\for_all_files.ps1
powershell -ExecutionPolicy Bypass -File .\for_all_files.ps1

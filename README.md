# PowerShell_labo


## 実行兼確認
Get-ExecutionPolicy

Restricted（制限）: スクリプトの実行が許可されません。
AllSigned（全て署名済み）: スクリプトは、信頼された発行元によって署名されている必要があります。そうでない場合、スクリプトの実行はブロックされます。
RemoteSigned（リモート署名済み）: ローカルで作成されたスクリプトは制限されますが、インターネットなどのリモートからダウンロードしたスクリプトは署名済みであれば実行できます。
Unrestricted（制限なし）: このポリシーでは、スクリプトの実行に関するすべての制限が解除されます。

## スクリプト実行兼付与
### リモートからダウンロードされたスクリプトは署名されている必要があるが、ローカルのスクリプトは署名なしで実行可能
Set-ExecutionPolicy RemoteSigned

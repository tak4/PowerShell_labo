$val = 100
Write-Host $val
Write-Host $val.GetType().FullName
Write-Host $val.GetType().Name
$val -is [int]
$val -is [string]

Write-Host

$val = "Hello"
Write-Host $val
Write-Host $val.GetType().FullName
Write-Host $val.GetType().Name
$val -is [int]
$val -is [string]
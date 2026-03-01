param(
    [string]$Path = "."
)
$TargetRoot = (Get-Item $Path).FullName
Get-ChildItem -Path $TargetRoot -Directory | ForEach-Object {
    $folder = $_
    $sizeBytes = (Get-ChildItem -Path $folder.FullName -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($null -eq $sizeBytes) { $sizeBytes = 0 }
    $formattedSize = if ($sizeBytes -ge 1GB) {
        "{0:N2} GB" -f ($sizeBytes / 1GB)
    } elseif ($sizeBytes -ge 1MB) {
        "{0:N2} MB" -f ($sizeBytes / 1MB)
    } elseif ($sizeBytes -ge 1KB) {
        "{0:N2} KB" -f ($sizeBytes / 1KB)
    } else {
        "$sizeBytes Bytes"
    }
    [PSCustomObject]@{
        "フォルダ名" = $folder.Name
        "フォルダサイズ" = $formattedSize
        "更新日時" = $folder.LastWriteTime
    }
} | Format-Table -AutoSize

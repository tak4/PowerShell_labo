# Get-DuEquivalent.ps1
<#
.SYNOPSIS
    ディレクトリとそのサブディレクトリのディスク使用量を、指定された深さまで表示し、ソートオプションも提供するPowerShellスクリプト。

.DESCRIPTION
    このスクリプトは、ファイルおよびディレクトリのディスク使用量を計算して表示します。
    指定された深さまでサブディレクトリを再帰的に探索できます。
    サイズは人間が読みやすい形式で表示され、出力はサイズでソートできます。

.PARAMETER Path
    ディレクトリへのパスを指定します。デフォルトは現在のディレクトリです。

.PARAMETER Depth
    表示する再帰の深さを指定します。デフォルトは1で、直下の子供とその合計サイズを表示します。深さ0は合計サイズのみを表示します。

.PARAMETER SortOrder
    サイズに基づく出力のソート順を指定します。'Ascending'（昇順）または 'Descending'（降順）を指定できます。
    指定しない場合、出力は探索順に表示されます。

.EXAMPLE
    .\Get-DuEquivalent.ps1 -SortOrder Descending
    これは、現在のディレクトリの使用量を、大きいものから小さいものへソートして表示します。
#>

# スクリプトのパラメータを定義します。
param(
    # Path: 調査対象のディレクトリパス。指定しない場合はカレントディレクトリが使われます。
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$Path = '.',
    # Depth: 表示するサブディレクトリの階層の深さ。デフォルトは1です。0を指定すると合計サイズのみ表示します。
    [Parameter(Mandatory=$false)]
    [ValidateRange(0, 100)]
    [int]$Depth = 1,
    # SortOrder: サイズに基づいたソート順。'Ascending'（昇順）または 'Descending'（降順）を指定できます。
    [Parameter(Mandatory=$false)]
    [ValidateSet('Ascending', 'Descending')]
    [string]$SortOrder
)

# バイト数を人間が読みやすい形式（KB, MB, GBなど）に変換する関数です。
function Format-Bytes ($bytes) {
    # 単位のリスト
    $suffixes = "Bytes", "KB", "MB", "GB", "TB", "PB", "EB"
    $index = 0
    # サイズが0以下の場合は "0.00 Bytes" を返します。
    if ($bytes -le 0) {
        return @{ Number = "0.00"; Unit = "Bytes" }
    }
    
    # サイズが1024より大きい間、単位を繰り上げます。
    $number = $bytes
    while ($number -ge 1024 -and $index -lt $suffixes.Count - 1) {
        $number /= 1024
        $index++
    }
    # フォーマットされた数値と単位をハッシュテーブルで返します。
    return @{ Number = ("{0:N2}" -f $number); Unit = $suffixes[$index] }
}

# 指定されたパスの使用量を取得する再帰関数です。
function Get-Usage($targetPath, $displayDepth, $currentDepth) {
    # 現在の階層が指定された深さに達したら、それ以上は処理しません。
    if ($currentDepth -ge $displayDepth) {
        return @()
    }

    # 結果を格納するためのArrayListを作成します。
    $results = New-Object System.Collections.ArrayList

    try {
        # 対象パスの子アイテムを取得します。アクセスできないディレクトリはエラーになります。
        $items = Get-ChildItem -Path $targetPath -Force -ErrorAction Stop
    } catch {
        # アクセス権がないなどの理由でエラーが発生した場合は、そのディレクトリを静かに無視します。
        return @()
    }

    # 各アイテムについて処理を繰り返します。
    foreach ($item in $items) {
        $itemPath = $item.FullName
        $size = 0

        # アイテムがディレクトリの場合
        if ($item.PSIsContainer) {
            # ディレクトリ内のすべてのファイルを再帰的に取得し、合計サイズを計算します。
            # アクセスできないファイルは無視します。
            $size = (Get-ChildItem -Path $itemPath -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        } else {
            # アイテムがファイルの場合、そのサイズを取得します。
            $size = $item.Length
        }
        
        # パスとサイズを持つカスタムオブジェクトを作成し、結果リストに追加します。
        [void]$results.Add([PSCustomObject]@{ Path = $itemPath; Size = $size })

        # アイテムがディレクトリの場合、再帰的にこの関数を呼び出してサブディレクトリの使用量を取得します。
        if ($item.PSIsContainer) {
            $childResults = Get-Usage -targetPath $itemPath -displayDepth $displayDepth -currentDepth ($currentDepth + 1)
            # サブディレクトリの結果が存在すれば、現在の結果リストに追加します。
            if ($childResults) {
                [void]$results.AddRange($childResults)
            }
        }
    }
    # 収集した結果を返します。
    return $results
}

# 入力されたパスを絶対パスに解決します。
$resolvedPath = (Resolve-Path $Path).Path

# 表示対象のアイテムリストを初期化します。
$itemsToShow = New-Object System.Collections.ArrayList
# Depthが1以上の場合、Get-Usage関数を呼び出してファイル/ディレクトリのリストとサイズを取得します。
if ($Depth -gt 0) {
    $itemsToShow = Get-Usage -targetPath $resolvedPath -displayDepth $Depth -currentDepth 0
}

# SortOrderパラメータが指定されている場合、リストをソートします。
if ($PSBoundParameters.ContainsKey('SortOrder')) {
    # 'Descending'が指定されているかどうかで、降順フラグを設定します。
    $descending = $SortOrder -eq 'Descending'
    # Sizeプロパティでリストをソートします。
    $itemsToShow = $itemsToShow | Sort-Object -Property Size -Descending:$descending
}

# 処理結果を表示します。
foreach ($item in $itemsToShow) {
    # サイズを人間が読みやすい形式に変換します。
    $formattedSize = Format-Bytes $item.Size
    # フォーマットしてコンソールに出力します。
    Write-Host ("{0,8} {1,-5}`t{2}" -f $formattedSize.Number, $formattedSize.Unit, $item.Path)
}

# 最後に、指定されたパスの合計サイズを計算して表示します。
# すべてのファイルを再帰的に取得し、その合計サイズを計算します。
$totalSize = (Get-ChildItem -Path $resolvedPath -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
# 合計サイズを人間が読みやすい形式に変換します。
$formattedTotalSize = Format-Bytes $totalSize
# フォーマットしてコンソールに出力します。
Write-Host ("{0,8} {1,-5}`t{2}" -f $formattedTotalSize.Number, $formattedTotalSize.Unit, $Path)
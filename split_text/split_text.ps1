[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "input file")]
    [string]$inputFile
)

$marker = "---SPLIT---"  # 分割の目印となる文字列

$part1 = [System.Collections.Generic.List[string]]::new()
$part2 = [System.Collections.Generic.List[string]]::new()
$isSecondPart = $false

foreach ($line in Get-Content $inputFile) {
    if (-not $isSecondPart -and $line -eq $marker) {
        $isSecondPart = $true
        # 目印行を含めたくない場合は、以下のコメントを外してください
        # continue
    }

    if (-not $isSecondPart) {
        $part1.Add($line)
    } else {
        $part2.Add($line)
    }
}

$part1 | Set-Content "part1.txt" -Encoding utf8
$part2 | Set-Content "part2.txt" -Encoding utf8

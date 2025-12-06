# Get-DuEquivalent.ps1
<#
.SYNOPSIS
    A PowerShell script to display disk usage for a directory and its subdirectories up to a specified depth, with sorting options.

.DESCRIPTION
    This script calculates and displays disk usage for files and directories.
    It can recurse into subdirectories up to a specified depth.
    Sizes are presented in a human-readable format, and the output can be sorted by size.

.PARAMETER Path
    Specifies the path to the directory. Defaults to the current directory.

.PARAMETER Depth
    Specifies the recursion depth for display. Default is 1, which shows immediate children and their total sizes. A depth of 0 shows only the total size.

.PARAMETER SortOrder
    Specifies the sort order for the output based on size. Can be 'Ascending' or 'Descending'.
    If not specified, the output is displayed in traversal order.

.EXAMPLE
    .\Get-DuEquivalent.ps1 -SortOrder Descending
    This will show usage for the current directory, sorted from largest to smallest.
#>

param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$Path = '.',
    [Parameter(Mandatory=$false)]
    [ValidateRange(0, 100)]
    [int]$Depth = 1,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Ascending', 'Descending')]
    [string]$SortOrder
)

function Format-Bytes ($bytes) {
    $suffixes = "Bytes", "KB", "MB", "GB", "TB", "PB", "EB"
    $index = 0
    if ($bytes -le 0) {
        return @{ Number = "0.00"; Unit = "Bytes" }
    }
    
    $number = $bytes
    while ($number -ge 1024 -and $index -lt $suffixes.Count - 1) {
        $number /= 1024
        $index++
    }
    return @{ Number = ("{0:N2}" -f $number); Unit = $suffixes[$index] }
}

function Get-Usage($targetPath, $displayDepth, $currentDepth) {
    if ($currentDepth -ge $displayDepth) {
        return @()
    }

    $results = New-Object System.Collections.ArrayList

    try {
        $items = Get-ChildItem -Path $targetPath -Force -ErrorAction Stop
    } catch {
        # Silently ignore directories we can't access
        return @()
    }

    foreach ($item in $items) {
        $itemPath = $item.FullName
        $size = 0

        if ($item.PSIsContainer) {
            # Directory
            $size = (Get-ChildItem -Path $itemPath -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        } else {
            # File
            $size = $item.Length
        }
        
        [void]$results.Add([PSCustomObject]@{ Path = $itemPath; Size = $size })

        if ($item.PSIsContainer) {
            $childResults = Get-Usage -targetPath $itemPath -displayDepth $displayDepth -currentDepth ($currentDepth + 1)
            if ($childResults) {
                [void]$results.AddRange($childResults)
            }
        }
    }
    return $results
}

$resolvedPath = (Resolve-Path $Path).Path

# Get all items with their sizes
$itemsToShow = New-Object System.Collections.ArrayList
if ($Depth -gt 0) {
    $itemsToShow = Get-Usage -targetPath $resolvedPath -displayDepth $Depth -currentDepth 0
}

# Sort the items if requested
if ($PSBoundParameters.ContainsKey('SortOrder')) {
    $descending = $SortOrder -eq 'Descending'
    $itemsToShow = $itemsToShow | Sort-Object -Property Size -Descending:$descending
}

# Display the items
foreach ($item in $itemsToShow) {
    $formattedSize = Format-Bytes $item.Size
    Write-Host ("{0,8} {1,-5}`t{2}" -f $formattedSize.Number, $formattedSize.Unit, $item.Path)
}

# Calculate and display total size
$totalSize = (Get-ChildItem -Path $resolvedPath -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$formattedTotalSize = Format-Bytes $totalSize
Write-Host ("{0,8} {1,-5}`t{2}" -f $formattedTotalSize.Number, $formattedTotalSize.Unit, $Path)
# Get-DuEquivalent.ps1
<#
.SYNOPSIS
    A PowerShell script equivalent to 'du -h -d 1' (disk usage human-readable depth 1).
    It lists the size of each immediate subdirectory and file, and the total size of the current directory.

.DESCRIPTION
    This script calculates and displays the disk usage for each first-level item (directories and files)
    within the current working directory, and also provides the total disk usage for the current directory itself.
    Sizes are presented in a human-readable format (e.g., KB, MB, GB).

.EXAMPLE
    .\Get-DuEquivalent.ps1
    This will execute the script in the current directory and display disk usage information.

.NOTES
    - This script may take some time to execute for directories with a large number of files or deep structures.
    - ErrorAction SilentlyContinue is used for Get-ChildItem -Recurse -File to handle potential permission issues gracefully.
    - The output format is "Size    ItemName".
#>

function Format-Bytes ($bytes) {
    $suffixes = "Bytes", "KB", "MB", "GB", "TB", "PB", "EB"
    $index = 0
    # Handle negative or zero bytes
    if ($bytes -le 0) {
        return "0 Bytes"
    }
    
    # Check for non-zero bytes before entering the loop
    while ($bytes -ge 1024 -and $index -lt $suffixes.Count - 1) {
        $bytes /= 1024
        $index++
    }
    "{0:N2} {1}" -f $bytes, $suffixes[$index]
}

# Get all items (files and directories) directly within the current path
# -Force is used to include hidden and system files/directories, similar to du's behavior
$currentDirItems = Get-ChildItem -Path . -Force -Depth 1

# Process each item at depth 1
foreach ($item in $currentDirItems) {
    $itemPath = $item.FullName
    $size = 0

    if ($item.PSIsContainer) {
        # Calculate size for subdirectory recursively.
        # -ErrorAction SilentlyContinue handles potential permission issues.
        $size = (Get-ChildItem -Path $itemPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    } else {
        # Get size for file
        $size = $item.Length
    }
    Write-Host "$(Format-Bytes $size)`t$($item.Name)"
}

# Calculate total size of the current directory recursively
# -ErrorAction SilentlyContinue handles potential permission issues.
$totalSize = (Get-ChildItem -Path . -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host "$(Format-Bytes $totalSize)`t."

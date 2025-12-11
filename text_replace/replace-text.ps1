#Requires -Version 5.1

<#
.SYNOPSIS
    Finds and replaces text in a file using regular expressions.

.DESCRIPTION
    This script finds and replaces text in a specified text file using a regular expression pattern.
    The changes are saved back to the original file.

.PARAMETER Path
    Specifies the path to the text file to be modified.

.PARAMETER Pattern
    Specifies the regular expression pattern to search for.

.PARAMETER Replacement
    Specifies the replacement string.

.EXAMPLE
    PS > .\replace-text.ps1 -Path "C:\path\to\your\file.txt" -Pattern "old-text" -Replacement "new-text"
    This command replaces all occurrences of "old-text" with "new-text" in the file.txt file.

.EXAMPLE
    PS > .\replace-text.ps1 -Path ".\data.log" -Pattern "\d{4}-\d{2}-\d{2}" -Replacement "YYYY-MM-DD"
    This command finds all date strings in the format "yyyy-mm-dd" and replaces them with "YYYY-MM-DD".
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "The path to the text file.")]
    [string]$Path,

    [Parameter(Mandatory = $true, HelpMessage = "The regular expression pattern to match.")]
    [string]$Pattern,

    [Parameter(Mandatory = $true, HelpMessage = "The string to replace the matched pattern with.")]
    [string]$Replacement
)

try {
    # Check if the file exists
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "File not found at path: $Path"
    }

    # Read the entire content of the file
    $content = Get-Content -Path $Path -Raw

    # Perform the replacement using the -replace operator, which supports regular expressions
    $newContent = $content -replace $Pattern, $Replacement

    # Write the modified content back to the file
    # Use -NoNewline to prevent adding an extra newline at the end of the file
    Set-Content -Path $Path -Value $newContent -NoNewline

    Write-Host "Successfully replaced text in $Path"
}
catch {
    Write-Error "An error occurred: $_"
    # Exit with a non-zero status code to indicate failure
    exit 1
}


# This script requires the UIAutomationClient assembly.
Add-Type -AssemblyName UIAutomationClient

# Find the Notepad process
$process = Get-Process -Name notepad -ErrorAction SilentlyContinue

if (-not $process) {
    Write-Host "Notepad is not running."
    exit
}

# Get the root element from the main window handle
$rootElement = [System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)

if (-not $rootElement) {
    Write-Host "Could not find the main window of Notepad."
    exit
}

# Use the ControlViewWalker to traverse the UI tree
$treeWalker = [System.Windows.Automation.TreeWalker]::ControlViewWalker

# Recursive function to walk the UI element tree
function Walk-UIElementTree {
    param(
        [System.Windows.Automation.AutomationElement]$element,
        [int]$level
    )

    # Print the element's details
    $indent = "  " * $level
    try {
        $info = $element.Current
        Write-Host ("{0}[{1}] - {2}" -f $indent, $info.LocalizedControlType, $info.Name)
    }
    catch {
        # Some elements might not be accessible
        Write-Host ("{0}[Unknown] - (Error accessing properties)" -f $indent)
    }


    # Recurse through children
    $child = $treeWalker.GetFirstChild($element)
    while ($child) {
        Walk-UIElementTree -element $child -level ($level + 1)
        $child = $treeWalker.GetNextSibling($child)
    }
}

# Start the traversal from the root element
Write-Host "UI Elements of Notepad:"
Walk-UIElementTree -element $rootElement -level 0

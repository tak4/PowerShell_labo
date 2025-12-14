<#
.SYNOPSIS
Dumps the UI element tree of a specified application window.

.DESCRIPTION
This script uses Windows UI Automation to traverse and display the hierarchy of UI elements for a given application.
The application can be specified by process name, window title, or process ID.

.PARAMETER ProcessName
The name of the process to inspect (e.g., "notepad", "calc").

.PARAMETER WindowTitle
A part of the window title of the application to inspect. The script will use the first process that matches the title.

.PARAMETER ProcessId
The ID of the process to inspect.

.EXAMPLE
# Dump UI elements of a Notepad window by process name
.\Dump-UIElements.ps1 -ProcessName notepad

.EXAMPLE
# Dump UI elements by a partial window title
.\Dump-UIElements.ps1 -WindowTitle "Untitled - Notepad"

.EXAMPLE
# Dump UI elements by Process ID
.\Dump-UIElements.ps1 -ProcessId 1234
#>
param(
    [Parameter(ParameterSetName='ProcessName', Mandatory=$true)]
    [string]$ProcessName,

    [Parameter(ParameterSetName='WindowTitle', Mandatory=$true)]
    [string]$WindowTitle,

    [Parameter(ParameterSetName='ProcessId', Mandatory=$true)]
    [int]$ProcessId
)

# This script requires the UIAutomationClient assembly.
Add-Type -AssemblyName UIAutomationClient

$process = $null
try {
    switch ($PsCmdlet.ParameterSetName) {
        'ProcessName' {
            Write-Host "Searching for process with name: '$ProcessName'..."
            $process = Get-Process -Name $ProcessName -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne [System.IntPtr]::Zero } | Select-Object -First 1
        }
        'WindowTitle' {
            Write-Host "Searching for process with window title containing: '$WindowTitle'..."
            $process = Get-Process | Where-Object { $_.MainWindowTitle -like "*$WindowTitle*" -and $_.MainWindowHandle -ne [System.IntPtr]::Zero } | Select-Object -First 1
        }
        'ProcessId' {
            Write-Host "Searching for process with ID: $ProcessId..."
            $process = Get-Process -Id $ProcessId -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne [System.IntPtr]::Zero } | Select-Object -First 1
        }
    }

    if (-not $process) {
        throw "Could not find a running process with a visible window that matches the criteria."
    }

    Write-Host "Process found: $($process.ProcessName) (ID: $($process.Id))" -ForegroundColor Green
    Write-Host "Window Title: $($process.MainWindowTitle)"
    Write-Host "---"

    # Get the root element from the main window handle
    $rootElement = [System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)

    if (-not $rootElement) {
        throw "Could not get the root UI element from the main window. The window may not be accessible."
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
            $controlType = $info.LocalizedControlType
            $id = $info.AutomationId
            $name = $info.Name
            $class = $info.ClassName
            $rect = $info.BoundingRectangle
            Write-Host ("{0}- ControlType: '{1}', AutomationId: '{2}', Name: '{3}', ClassName: '{4}', BoundingRectangle: '{5}'" -f $indent, $controlType, $id, $name, $class, $rect)
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
    Write-Host "Dumping UI Elements for window: '$($process.MainWindowTitle)'"
    Walk-UIElementTree -element $rootElement -level 0

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
}

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

.PARAMETER ShowSkipped
If specified, shows detailed information about skipped UI elements (elements with IsControlElement=false or IsContentElement=false).
Skipped elements are shown in gray.

.PARAMETER ShowStatistics
If specified, shows statistics about the UI element tree at the end, including:
- Total elements processed in Control View
- Offscreen elements
- Hidden elements (IsVisible=false)
- Elements skipped by Control View filter vs Raw View total
- Error elements

.EXAMPLE
# Dump UI elements of a Notepad window by process name
.\Dump-UIElements.ps1 -ProcessName notepad

.EXAMPLE
# Dump UI elements by a partial window title
.\Dump-UIElements.ps1 -WindowTitle "Untitled - Notepad"

.EXAMPLE
# Dump UI elements and show skipped elements with debug info
.\Dump-UIElements.ps1 -ProcessName notepad -ShowSkipped

.EXAMPLE
# Dump UI elements and show statistics
.\Dump-UIElements.ps1 -ProcessName notepad -ShowStatistics

.EXAMPLE
# Dump UI elements with both debug info and statistics
.\Dump-UIElements.ps1 -ProcessName notepad -ShowSkipped -ShowStatistics
#>
[CmdletBinding()]
param(
    [Parameter(ParameterSetName='ProcessName', Mandatory=$true)]
    [string]$ProcessName,

    [Parameter(ParameterSetName='WindowTitle', Mandatory=$true)]
    [string]$WindowTitle,

    [Parameter(ParameterSetName='ProcessId', Mandatory=$true)]
    [int]$ProcessId,

    [Parameter()]
    [switch]$ShowSkipped,

    [Parameter()]
    [switch]$ShowStatistics
)

# This script requires the UIAutomationClient assembly.
Add-Type -AssemblyName UIAutomationClient

# Statistics counters
$script:stats = @{
    ProcessedElements = 0
    SkippedByControlView = 0
    OffscreenElements = 0
    HiddenElements = 0
    ErrorElements = 0
}

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
    if ($ShowSkipped) {
        Write-Host "Debug Mode: Showing skipped elements (in gray)" -ForegroundColor Yellow
    }
    Write-Host "---"

    # Get the root element from the main window handle
    $rootElement = [System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)

    if (-not $rootElement) {
        throw "Could not get the root UI element from the main window. The window may not be accessible."
    }

    # Use the RawViewWalker to traverse the UI tree (shows all elements including layout containers)
    $treeWalker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    # $treeWalker = [System.Windows.Automation.TreeWalker]::RawViewWalker

    # Recursive function to walk the UI element tree
    function Walk-UIElementTree {
        param(
            [System.Windows.Automation.AutomationElement]$element,
            [int]$level,
            [string]$walkerType = "ControlView"
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
            $isControl = $info.IsControlElement
            $isContent = $info.IsContentElement
            $isVisible = $info.IsVisible
            
            # Update statistics
            $script:stats.ProcessedElements++
            
            # Determine skip reason
            $skipReasons = @()
            if (-not $isControl) { $skipReasons += "NotControlElement" }
            if (-not $isContent) { $skipReasons += "NotContentElement" }
            
            # Check for offscreen elements
            $isOffscreen = $rect.Width -eq 0 -and $rect.Height -eq 0
            if ($isOffscreen) { 
                $skipReasons += "Offscreen"
                $script:stats.OffscreenElements++
            }
            
            # Check for hidden elements
            if (-not $isVisible) {
                $skipReasons += "Hidden"
                $script:stats.HiddenElements++
            }
            
            $skipInfo = if ($skipReasons.Count -gt 0) { " [SKIPPED: $($skipReasons -join ', ')]" } else { "" }
            
            Write-Host ("{0}- ControlType: '{1}', AutomationId: '{2}', Name: '{3}', ClassName: '{4}', BoundingRectangle: '{5}'{6}" -f $indent, $controlType, $id, $name, $class, $rect, $skipInfo) -ForegroundColor $(if ($skipReasons.Count -gt 0) { "DarkGray" } else { "White" })
            
            # Show detailed information about skipped elements when -ShowSkipped is specified
            if ($ShowSkipped -and $skipReasons.Count -gt 0) {
                Write-Host ("{0}  └─ IsControlElement: {1}, IsContentElement: {2}, IsVisible: {3}, Offscreen: {4}" -f $indent, $isControl, $isContent, $isVisible, $isOffscreen) -ForegroundColor DarkGray
            }
        }
        catch {
            # Some elements might not be accessible
            $script:stats.ErrorElements++
            Write-Host ("{0}[Unknown] - (Error accessing properties)" -f $indent)
        }

        # Recurse through children
        $child = $treeWalker.GetFirstChild($element)
        while ($child) {
            Walk-UIElementTree -element $child -level ($level + 1) -walkerType $walkerType
            $child = $treeWalker.GetNextSibling($child)
        }
    }

    # Function to count all elements in Raw View (including those skipped by Control View)
    function Count-AllElements {
        param(
            [System.Windows.Automation.AutomationElement]$element
        )
        
        $count = 1
        $rawWalker = [System.Windows.Automation.TreeWalker]::RawViewWalker
        $child = $rawWalker.GetFirstChild($element)
        while ($child) {
            $count += Count-AllElements -element $child
            $child = $rawWalker.GetNextSibling($child)
        }
        return $count
    }

    # Start the traversal from the root element
    Write-Host "Dumping UI Elements for window: '$($process.MainWindowTitle)'"
    Walk-UIElementTree -element $rootElement -level 0

    # Show statistics if requested
    if ($ShowStatistics) {
        Write-Host ""
        Write-Host "========== STATISTICS ==========" -ForegroundColor Cyan
        Write-Host "Processed Elements (Control View): $($script:stats.ProcessedElements)" -ForegroundColor Green
        Write-Host "Offscreen Elements: $($script:stats.OffscreenElements)" -ForegroundColor Yellow
        Write-Host "Hidden Elements (IsVisible=false): $($script:stats.HiddenElements)" -ForegroundColor Yellow
        Write-Host "Error Elements: $($script:stats.ErrorElements)" -ForegroundColor Red
        
        # Count total elements in Raw View
        try {
            $rawWalker = [System.Windows.Automation.TreeWalker]::RawViewWalker
            $totalRawElements = Count-AllElements -element $rootElement
            $skippedByControlView = $totalRawElements - $script:stats.ProcessedElements
            
            Write-Host ""
            Write-Host "Total Elements (Raw View): $totalRawElements" -ForegroundColor Cyan
            Write-Host "Skipped by Control View Filter: $skippedByControlView" -ForegroundColor Red
        }
        catch {
            Write-Host "Could not count Raw View elements" -ForegroundColor Red
        }
        Write-Host "===============================" -ForegroundColor Cyan
    }

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
}

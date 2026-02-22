<#
.SYNOPSIS
Finds multiple UI elements in a window, each specified by its AutomationId.

.DESCRIPTION
This script uses Windows UI Automation to find multiple descendant UI elements. Each element is found using its specific AutomationId from a provided array.
The target application can be specified by process name, window title, or process ID.

.PARAMETER ProcessName
The name of the process to inspect (e.g., "notepad").
.PARAMETER WindowTitle
A part of the window title of the application to inspect.
.PARAMETER ProcessId
The ID of the process to inspect.

.PARAMETER AutomationId
An array of AutomationId properties for the UI elements to find.

.EXAMPLE
# Find multiple elements in Notepad by their AutomationIds
.\Find-UIElementsByAutomationId.ps1 -ProcessName notepad -AutomationId "4001", "4002", "15"

.EXAMPLE
# Find multiple elements in an application window by title
powershell.exe -ExecutionPolicy Bypass -Command "& {.\Find-UIElementsByAutomationId.ps1 -ProcessName notepad -AutomationId @('File', 'Edit', 'View')}" 
#>
param(
    [Parameter(ParameterSetName='ProcessName', Mandatory=$true)]
    [string]$ProcessName,

    [Parameter(ParameterSetName='WindowTitle', Mandatory=$true)]
    [string]$WindowTitle,

    [Parameter(ParameterSetName='ProcessId', Mandatory=$true)]
    [int]$ProcessId,

    [Parameter(Mandatory=$true)]
    [string[]]$AutomationId
)

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function Find-Element([System.Windows.Automation.AutomationElement]$rootElement, [string]$automationId) {
    Write-Host "`nSearching for element with AutomationId: '$automationId'..."
    $condition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::AutomationIdProperty, $automationId
    )
    $foundElement = $rootElement.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
    return $foundElement
}

function Print-ElementInfo([System.Windows.Automation.AutomationElement]$element, [string]$automationId) {
     if ($element) {
        Write-Host "✅ Element Found for AutomationId '$automationId'!" -ForegroundColor Green
        $info = $element.Current
        Write-Host "--------------------"
        Write-Host "Name:             $($info.Name)"
        Write-Host "AutomationId:     $($info.AutomationId)"
        Write-Host "ControlType:      $($info.LocalizedControlType)"
        Write-Host "ClassName:        $($info.ClassName)"
        Write-Host "IsEnabled:        $($info.IsEnabled)"
        Write-Host "BoundingRectangle:$($info.BoundingRectangle)"
        Write-Host "--------------------"
    } else {
        Write-Warning "Element not found for AutomationId '$automationId'."
    }
}


try {
    # 1. Find the target process
    $process = $null
    switch ($PsCmdlet.ParameterSetName) {
        'ProcessName' {
            $process = Get-Process -Name $ProcessName -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne [System.IntPtr]::Zero } | Select-Object -First 1
        }
        'WindowTitle' {
            $process = Get-Process | Where-Object { $_.MainWindowTitle -like "*$WindowTitle*" -and $_.MainWindowHandle -ne [System.IntPtr]::Zero } | Select-Object -First 1
        }
        'ProcessId' {
            $process = Get-Process -Id $ProcessId -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne [System.IntPtr]::Zero } | Select-Object -First 1
        }
    }

    if (-not $process) {
        throw "Could not find a running process with a visible window that matches the criteria."
    }
    Write-Host "Target Process: $($process.ProcessName) (ID: $($process.Id), Window: '$($process.MainWindowTitle)')" -ForegroundColor Green

    # 2. Get the root UI element
    $rootElement = [System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
    if (-not $rootElement) {
        throw "Could not get the root UI element from the main window."
    }

    # 3. Find and display each element from the array
    foreach ($id in $AutomationId) {
        $element = Find-Element -rootElement $rootElement -automationId $id
        Print-ElementInfo -element $element -automationId $id
    }

}
catch {
    Write-Error "❌ An error occurred: $($_.Exception.Message)"
}

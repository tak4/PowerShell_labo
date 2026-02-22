<#
.SYNOPSIS
Finds the first UI element in a window that matches the specified criteria.

.DESCRIPTION
This script uses Windows UI Automation to find the first descendant UI element that matches one or more conditions (Name, AutomationId, ClassName, ControlType).
The target application can be specified by process name, window title, or process ID.

.PARAMETER ProcessName
The name of the process to inspect (e.g., "notepad").
.PARAMETER WindowTitle
A part of the window title of the application to inspect.
.PARAMETER ProcessId
The ID of the process to inspect.

.PARAMETER Name
The Name property of the UI element to find.
.PARAMETER AutomationId
The AutomationId property of the UI element to find.
.PARAMETER ClassName
The ClassName property of the UI element to find.
.PARAMETER ControlType
The ControlType of the UI element to find (e.g., "Button", "Edit", "Document").

.EXAMPLE
# Find the main document area in Notepad
.\Find-UIElement.ps1 -ProcessName notepad -ControlType Document

.EXAMPLE
# Find the "Apply" button in the com0com setup window
.\Find-UIElement.ps1 -WindowTitle "Setup for com0com" -Name "Apply" -ControlType "Button"
#>
param(
    [Parameter(ParameterSetName='ProcessName', Mandatory=$true)]
    [string]$ProcessName,

    [Parameter(ParameterSetName='WindowTitle', Mandatory=$true)]
    [string]$WindowTitle,

    [Parameter(ParameterSetName='ProcessId', Mandatory=$true)]
    [int]$ProcessId,

    [Parameter(Mandatory=$false)]
    [string]$Name,

    [Parameter(Mandatory=$false)]
    [string]$AutomationId,

    [Parameter(Mandatory=$false)]
    [string]$ClassName,

    [Parameter(Mandatory=$false)]
    [string]$ControlType
)

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

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

    # 3. Build the search conditions
    $conditions = @()
    if ($PSBoundParameters.ContainsKey('Name')) {
        $conditions += New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $Name)
    }
    if ($PSBoundParameters.ContainsKey('AutomationId')) {
        $conditions += New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty, $AutomationId)
    }
    if ($PSBoundParameters.ContainsKey('ClassName')) {
        $conditions += New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ClassNameProperty, $ClassName)
    }
    if ($PSBoundParameters.ContainsKey('ControlType')) {
        # Convert string to ControlType object (e.g., "Button" -> [System.Windows.Automation.ControlType]::Button)
        $controlTypeValue = [System.Windows.Automation.ControlType]::$($ControlType)
        $conditions += New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, $controlTypeValue)
    }

    if ($conditions.Count -eq 0) {
        throw "At least one search criteria (-Name, -AutomationId, -ClassName, -ControlType) must be provided."
    }

    # Combine conditions if more than one is specified
    $searchCondition = $null
    if ($conditions.Count -eq 1) {
        $searchCondition = $conditions[0]
    } else {
        $searchCondition = New-Object System.Windows.Automation.AndCondition($conditions)
    }
    
    # 4. Find the element
    Write-Host "Searching for the first element matching the criteria..."
    $foundElement = $rootElement.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $searchCondition)

    # 5. Display the result
    if ($foundElement) {
        Write-Host "`n✅ Element Found!" -ForegroundColor Green
        $info = $foundElement.Current
        Write-Host "--------------------"
        Write-Host "Name:             $($info.Name)"
        Write-Host "AutomationId:     $($info.AutomationId)"
        Write-Host "ControlType:      $($info.LocalizedControlType)"
        Write-Host "ClassName:        $($info.ClassName)"
        Write-Host "IsEnabled:        $($info.IsEnabled)"
        Write-Host "IsOffscreen:      $($info.IsOffscreen)"
        Write-Host "BoundingRectangle:$($info.BoundingRectangle)"
        Write-Host "--------------------"
    } else {
        Write-Warning "Element not found with the specified criteria."
    }
}
catch {
    Write-Error "❌ An error occurred: $($_.Exception.Message)"
}

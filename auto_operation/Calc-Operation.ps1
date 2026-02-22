# Windows Calculator Automation (1 + 2 =)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function Get-UIElement {
    param(
        [System.Windows.Automation.AutomationElement]$root,
        [string]$automationId
    )
    $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty, $automationId)
    return $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
}

function Invoke-UIClick {
    param(
        [System.Windows.Automation.AutomationElement]$element
    )
    if ($element) {
        $name = $element.Current.Name
        $id = $element.Current.AutomationId
        Write-Host "Clicking: $name ($id)"
        $invokePattern = $element.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
        $invokePattern.Invoke()
    } else {
        throw "Element not found"
    }
}

try {
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    
    # "Dentaku" (Calculator in Japanese)
    $dentaku = [char]0x96FB + [char]0x5353
    $titles = @($dentaku, "Calculator")
    
    $calcElement = $null
    foreach ($title in $titles) {
        $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $title)
        $calcElement = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $condition)
        if ($calcElement) { break }
    }

    if (-not $calcElement) {
        Write-Host "Launching Calculator..."
        Start-Process "calc.exe"
        Start-Sleep -Seconds 3
        foreach ($title in $titles) {
            $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $title)
            $calcElement = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $condition)
            if ($calcElement) { break }
        }
    }

    if (-not $calcElement) {
        throw "Calculator window not found"
    }
    
    Write-Host "Calculator found: $($calcElement.Current.Name)"

    # Buttons: 1, +, 2, =
    $buttons = @("num1Button", "plusButton", "num2Button", "equalButton")

    foreach ($id in $buttons) {
        $element = Get-UIElement -root $calcElement -automationId $id
        Invoke-UIClick -element $element
        Start-Sleep -Milliseconds 300
    }

    Start-Sleep -Seconds 1
    $resultElement = Get-UIElement -root $calcElement -automationId "CalculatorResults"
    if ($resultElement) {
        Write-Host "Result: $($resultElement.Current.Name)" -ForegroundColor Green
    } else {
        Write-Warning "Result not found"
    }

} catch {
    Write-Error "Error: $($_.Exception.Message)"
}

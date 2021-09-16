#region : Open browser and navigate to page
Import-Module Selenium
$Driver = Start-SeFirefox 
Enter-SeUrl 'https://docs.google.com/forms/d/e/1FAIpQLSdxFCNr-2Q31pARzPmApDIUM2c3I1biZCSWo7akFMMrNObFww/viewform?usp=sf_link' -Driver $Driver

#endregion

#region : Finding elements Text box
$XPath = '/html/body/div/div[2]/form/div[2]/div/div[2]/div[1]/div/div/div[2]/div/div[1]/div/div[1]/input'
$textBox = Get-SeElement -By XPath -Selection $XPath -Target $Driver
Send-SeKeys -Element $textBox -Keys 'Arthur Dent'

#endregion

#region : Fill in text boxes
Function Set-TextboxValue{
    param(
        $Value,
        $XPath
    )
    $textBox = Get-SeElement -By XPath -Selection $XPath -Target $Driver
    Send-SeKeys -Element $textBox -Keys $Value
}

Set-TextboxValue -Value 'Arthur Dent' -XPath '/html/body/div/div[2]/form/div[2]/div/div[2]/div[1]/div/div/div[2]/div/div[1]/div/div[1]/input'
Set-TextboxValue -Value (Get-Date).AddDays(1).ToString('d') -XPath '/html/body/div/div[2]/form/div[2]/div/div[2]/div[2]/div/div/div[2]/div/div[1]/div/div[1]/input'
Set-TextboxValue -Value 'end of the world' -XPath '/html/body/div/div[2]/form/div[2]/div/div[2]/div[6]/div/div/div[2]/div/div[1]/div[2]/textarea'


#endregion

#region : Finding elements radio buttons
$radioButtons = Get-SeElement -By Class -Selection 'exportOuterCircle' -Target $Driver
$radioButtons | Format-Table TagName, Text, Enabled, Location

# send click to button
Send-SeClick -Element $radioButtons[0]

#endregion

#region : Get button container
$selector = Get-SeElement -By Class -Selection "docssharedWizToggleLabeledContainer" -Target $Driver
$selector | Format-Table TagName, Text, Enabled, Location

$selector.Count
$radioButtons.Count

$label = 'Full day'
$index = $selector.Text.IndexOf($label)

Send-SeClick -Element $radioButtons[$index]

#endregion

#region : Make it a function
Function Set-RadioButton{
    param(
        $label
    )
    $selector = Get-SeElement -By Class -Selection "docssharedWizToggleLabeledContainer" -Target $Driver
    $index = $selector.Text.IndexOf($label)

    $buttons = Get-SeElement -By Class -Selection "exportOuterCircle" -Target $Driver
    Send-SeClick -Element $buttons[$index]
}

Set-RadioButton -label 'Full day'
Set-RadioButton -label 'Personal leave'


#endregion

#region : Submit it
$submitButton = Get-SeElement -By CssSelector -Selection ".appsMaterialWizButtonPaperbuttonLabel" -Target $Driver
Send-SeClick -Element $submitButton

#endregion

#region : Stop it
$Driver | Stop-SeDriver

#endregion

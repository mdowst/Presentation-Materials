$ResourceGroupName = ''
$AutomationAccountName = ''
$WorkspaceName = ''

# Create the schedule object
$startTime = Get-Date '21:00:00'
$AzAutomationSchedule = @{
    ResourceGroupName = $ResourceGroupName
    AutomationAccountName = $AutomationAccountName
    Name = 'Daily Defender Updates'
    StartTime = $startTime
    DayInterval = 1
    ForUpdateConfiguration = $true
}
$schedule = New-AzAutomationSchedule @AzAutomationSchedule

$WorkspaceObject = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName

$NonAzureQuery = [Microsoft.Azure.Commands.Automation.Model.UpdateManagement.NonAzureQueryProperties]::new()
$NonAzureQuery.FunctionAlias = 'NonAzure_Windows'
$NonAzureQuery.WorkspaceResourceId = $WorkspaceObject.ResourceId
# Create the update deployment
$duration = New-TimeSpan -Hours 2
$UpdateConfiguration = @{
    ResourceGroupName = $ResourceGroupName
    AutomationAccountName = $AutomationAccountName
    Schedule = $schedule
    NonAzureQuery = $NonAzureQuery
    Windows = $true
    IncludedUpdateClassification = 'Definition'
    Duration = $duration
}
New-AzAutomationSoftwareUpdateConfiguration @UpdateConfiguration

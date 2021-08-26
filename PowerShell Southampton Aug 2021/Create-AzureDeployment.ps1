# Create the schedule object
$AzAutomationSchedule = @{
    ResourceGroupName = $ResourceGroupName
    AutomationAccountName = $AutomationAccountName
    Name = "Domain Controller Group A ($((Get-Date).ToString('yyyy-MM-dd')))"
    StartTime = (Get-Date).AddMinutes(6)
    ForUpdateConfiguration = $true
    OneTime = $true
}
$schedule = New-AzAutomationSchedule @AzAutomationSchedule

# Create the update deployment
$duration = New-TimeSpan -Hours 2
$UpdateConfiguration = @{
    ResourceGroupName = $ResourceGroupName
    AutomationAccountName = $AutomationAccountName
    Schedule = $schedule
    AzureVMResourceId = $targetMachines
    Windows = $true
    IncludedUpdateClassification = 'Definition'
    Duration = $duration
    RebootSetting = 'IfRequired'
    PreTaskRunbookName = 'PreTask-CheckStarts'
    PostTaskRunbookName = 'PostTask-DomainControllerGroupB'
}
New-AzAutomationSoftwareUpdateConfiguration @UpdateConfiguration 
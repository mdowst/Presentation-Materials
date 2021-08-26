# Add SoftwareUpdateConfigurationRunContext to param so your script can read it
param(
    $SoftwareUpdateConfigurationRunContext
)

# Convert config information to PowerShell 
$Config = $SoftwareUpdateConfigurationRunContext | ConvertFrom-Json

# Connect using Run As Account
$AutoAccount = .\Connect-RunAsAccount.ps1

# Get the deployment A settings
$Deployment = Get-AzAutomationSoftwareUpdateConfiguration @AutoAccount -Name $Config.SoftwareUpdateConfigurationName

# Get the group B machines
$targetMachines = Get-AutomationVariable -Name 'DC_GroupB'

# Create the schedule object
$AzAutomationSchedule = @{
    ResourceGroupName = $AutoAccount['ResourceGroupName']
    AutomationAccountName = $AutoAccount['AutomationAccountName']
    Name = "Domain Controller Group B ($((Get-Date).ToString('yyyy-MM-dd')))"
    StartTime = (Get-Date).AddMinutes(10)
    ForUpdateConfiguration = $true
    OneTime = $true
}
$schedule = New-AzAutomationSchedule @AzAutomationSchedule

# Create the update deployment
$duration = New-TimeSpan -Hours 2
$UpdateConfiguration = @{
    ResourceGroupName = $AutoAccount['ResourceGroupName']
    AutomationAccountName = $AutoAccount['AutomationAccountName']
    Schedule = $schedule
    AzureVMResourceId = $targetMachines
    Windows = $true
    IncludedUpdateClassification = $Deployment.UpdateConfiguration.Windows.IncludedUpdateClassifications
    Duration = $duration
    RebootSetting = $Deployment.UpdateConfiguration.Windows.rebootSetting
}
New-AzAutomationSoftwareUpdateConfiguration @UpdateConfiguration 
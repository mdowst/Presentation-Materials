# Add SoftwareUpdateConfigurationRunContext to param so your script can read it
param(
    $SoftwareUpdateConfigurationRunContext
)

# Convert config information to PowerShell 
$Config = $SoftwareUpdateConfigurationRunContext | ConvertFrom-Json

# Connect using Run As Account
$AutoAccount = .\Connect-RunAsAccount.ps1

# Create the schedule object
$AzAutomationSchedule = @{
    Name = "$($Config.SoftwareUpdateConfigurationRunId)-State"
    StartTime = (Get-Date).AddMinutes(15)
    OneTime = $true
}
$schedule = New-AzAutomationSchedule @AutoAccount @AzAutomationSchedule

# Register the schedule with the runbook
$AzAutomationScheduledRunbook = @{
	Parameters            = @{JobId = $Config.SoftwareUpdateConfigurationRunId}
	RunbookName           = 'Get-UpdateJobStates'
	ScheduleName          = $schedule.Name
}
Register-AzAutomationScheduledRunbook @AutoAccount @AzAutomationScheduledRunbook
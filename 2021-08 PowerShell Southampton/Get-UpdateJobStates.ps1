param(
    $JobId
)

$AutoAccount = .\Connect-RunAsAccount.ps1

$SendTo = Get-AutomationVariable -Name 'NotificationEmail'
$hbwGuidPattern = "(_)[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}"

# Check for queued or suspended jobs
[System.Collections.Generic.List[PSObject]] $PendingJobs = @()
Get-AzAutomationJob @AutoAccount -RunbookName 'Patch-MicrosoftOMSComputer' -Status 'Queued' | ForEach-Object{ $PendingJobs.Add($_) }
Get-AzAutomationJob @AutoAccount -RunbookName 'Patch-MicrosoftOMSComputer' -Status 'Suspended' | ForEach-Object{ $PendingJobs.Add($_) }
Get-AzAutomationJob @AutoAccount -RunbookName 'PatchMicrosoftOMSLinuxComputer' -Status 'Queued' | ForEach-Object{ $PendingJobs.Add($_) }
Get-AzAutomationJob @AutoAccount -RunbookName 'PatchMicrosoftOMSLinuxComputer' -Status 'Suspended' | ForEach-Object{ $PendingJobs.Add($_) }

# Check each job and ensure it comes from the expected parent job
foreach($job in $PendingJobs){
    $RBjobStatus = Get-AzAutomationJob @AutoAccount -Id $job.JobId
    if($RBjobStatus.JobParameters['MasterJobId'] -eq $JobId){
        $HybridWorker = [Regex]::Replace($RBjobStatus.HybridWorker, $hbwGuidPattern, '')
        #Send Notifications
        $EmailMessage = @{
            EmailBody = "$($RBjobStatus | ConvertTo-Html)"
            Subject = "$($HybridWorker) Update Deployment Failed to Start"
            To = $SendTo
        }
        .\Send-Notification.ps1 @EmailMessage
    }
}

# Get the schedule for this job
$AzAutomationScheduledRunbook = @{
	RunbookName           = 'Get-UpdateJobStates'
	ScheduleName          = "$($JobId)-State"
}
$schedule = Get-AzAutomationScheduledRunbook @AutoAccount @AzAutomationScheduledRunbook -ErrorAction SilentlyContinue

# If schedule is found unreigster and delete it
if($schedule){
    Unregister-AzAutomationScheduledRunbook @AutoAccount @AzAutomationScheduledRunbook -Force
    Remove-AzAutomationSchedule @AutoAccount -Name "$($JobId)-State" -Force
}

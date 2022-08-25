# Add SoftwareUpdateConfigurationRunContext to param so your script can read it
param(
    $SoftwareUpdateConfigurationRunContext
)

# Convert the SoftwareUpdateConfigurationRunContext JSON to a PowerShell object
$Config = $SoftwareUpdateConfigurationRunContext | ConvertFrom-Json

$HybridWorker = 'WIN-J6GVB2JARTD'
$Runbook = 'Stop-WindowsServices'
$Services = 'BITS;SNMPTRAP'

# Connect using Run As Account
$AutoAccount = .\Connect-RunAsAccount.ps1

# Start the runbook on the hybrid worker
$StartParams = @{
  Name        = $Runbook
  Parameters  = @{ 'Services' = $Services }
  RunOn       = $HybridWorker 
  ErrorAction = 'Stop'
}
$JobId = Start-AutomationRunbook @StartParams

# wait for the job to finish.
# It is good to include a timeout to prevent exceeding maintenance windows
Wait-AutomationJob -Id $JobId -TimeoutInMinutes 10

# Get the results of the automation job
$RBjobStatus = Get-AzAutomationJob @AutoAccount -Id $JobId
#In this case, we want to terminate the patch job if any run fails
if ($RBjobStatus.Status -ne 'Completed') {
  #We must throw in order to fail the patch deployment.
  throw "$($Runbook) returned a status of $($RBjobStatus.Status)"
}

# Get the output stream from the job
$JobOutput = Get-AzAutomationJobOutput @AutoAccount -Id $jobId -stream Output
[System.Collections.Generic.List[PSObject]] $ParsedResults = @()
foreach($Output in $JobOutput | Where-Object{$_.Summary -like '*{*'}){
    $JobOutputRecord = Get-AzAutomationJobOutputRecord @AutoAccount -JobId $Output.JobId -Id $Output.StreamRecordId
    ($JobOutputRecord.Value['value'] | ConvertFrom-Json) | Foreach-Object{ $ParsedResults.Add($_) }
}

# Confirm all services are stopped
if($ParsedResults | Where-Object{ $_.Status -ne 1 }){
    Write-Output "$(($Results | Where-Object{ $_.Status -ne 1 } | Format-List | Out-String).Trim())"
    throw "Something went wrong in the snapshot process"
}

# Output results
Write-Output "$(($Results | Format-Table | Out-String).Trim())"

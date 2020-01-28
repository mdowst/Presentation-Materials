$hybridWorker = 'HBW01'
$runbook = 'Stop-Services'
# Get the current job Id
$CurrentJobId = $PSPrivateMetadata.JobId.Guid

# Get the Service Principal connection details for the Connection name
$servicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"

# Connect to Azure
$params = @{
    TenantId = $servicePrincipalConnection.TenantId
    CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    ApplicationId = $servicePrincipalConnection.ApplicationId
}
Add-AzureRmAccount -ServicePrincipal @params  | Out-Null
Set-AzureRmContext -SubscriptionId $servicePrincipalConnection.SubscriptionId  | Out-Null

#Get Automation account and resource group names
$AutomationAccounts = Find-AzureRmResource -ResourceType Microsoft.Automation/AutomationAccounts
foreach ($item in $AutomationAccounts) {
  # Loop through each Automation account to find this job
  $Job = Get-AzureRmAutomationJob -ResourceGroupName $item.ResourceGroupName -AutomationAccountName $item.Name -Id $CurrentJobId -ErrorAction SilentlyContinue
  if ($Job) {
    $AutomationAccountName = $item.Name
    $ResourceGroupName = $item.ResourceGroupName
    break
  }
}

# Start the runbook on the hybrid worker
$jobId = Start-AutomationRunbook -Name $runbook -Parameters @{ "args" = $args } -RunOn $hybridWorker -ErrorAction Stop

# wait for the job to finish
$wait = Wait-AutomationJob -Id $jobId -TimeoutInMinutes 10

#In this case, we want to terminate the patch job if any run fails.
#This logic might not hold for all cases - you might want to allow success as long as at least 1 run succeeds
$JobOutput = Get-AzAutomationJobOutput -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Id $jobId -stream Any
foreach($summary in $JobOutput){
    if ($summary.Type -eq "Error"){
        #We must throw in order to fail the patch deployment.
        throw $summary.Summary
    }
}

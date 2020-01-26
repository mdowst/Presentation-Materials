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
    $RunbookName = $Job.RunbookName
    break
  }
}

# Start the runbook on the hybrid worker
$jobId = Start-AutomationRunbook -Name $runbook -Parameters @{ "args" = $args } -RunOn $server.Server -ErrorAction Stop

# wait for the job to finish
$wait = Wait-AutomationJob -Id $jobId -TimeoutInMinutes 10

# Get th output if you need it
$JobOutput = Get-AzureRMAutomationJobOutput -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Id $jobId -stream Output
[System.Collections.Generic.List[PSObject]] $ParsedResults = @()
foreach($Output in $JobOutput){
    $JobOutputRecord = Get-AzureRmAutomationJobOutputRecord -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -JobId $Output.JobId -Id $Output.StreamRecordId
    $ParsedResults.Add(($JobOutputRecord.Value['value']))
}

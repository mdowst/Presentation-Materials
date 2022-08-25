# Get the current job Id
$CurrentJobId = $PSPrivateMetadata.JobId.Guid

# Get the Service Principal connection details for the Connection name
$SPConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'

# Connect to Azure
$Params = @{
  TenantId              = $SPConnection.TenantId
  CertificateThumbprint = $SPConnection.CertificateThumbprint
  ApplicationId         = $SPConnection.ApplicationId
}
Add-AzAccount -ServicePrincipal @Params  | Out-Null
Set-AzContext -SubscriptionId $SPConnection.SubscriptionId  | Out-Null

#Get Automation account and resource group names
$AutoAccts = Get-AzResource -ResourceType Microsoft.Automation/AutomationAccounts
foreach ($Item in $AutoAccts) {
  # Loop through each Automation account to find this job
  $JobParams = @{
    ResourceGroupName     = $Item.ResourceGroupName 
    AutomationAccountName = $Item.Name 
    Id                    = $CurrentJobId 
    ErrorAction           = 'SilentlyContinue'
  }
  $Job = Get-AzAutomationJob @JobParams
  if ($Job) {
    $AutomationAccountName = $Item.Name
    $ResourceGroupName = $Item.ResourceGroupName
    break
  }
}

@{
  ResourceGroupName     = $ResourceGroupName
  AutomationAccountName = $AutomationAccountName
}
param(
    $SoftwareUpdateConfigurationRunContext
)

# Convert the SoftwareUpdateConfigurationRunContext JSON to a PowerShell object
$Config = $SoftwareUpdateConfigurationRunContext | ConvertFrom-Json

# Connect using Run As Account
$AutoAccount = .\Connect-RunAsAccount.ps1

# Get the Azure VMs associated with this deployment
$AzureVMs = Get-AutomationVariable -Name 'UpdateStarted'

if($AzureVMs -ne 'none'){
    # Send stop command to the started Azure VMs
    foreach($VmId in $AzureVMs.Split(';')){
        Stop-AzVM -Id $VmId -Force
    }
    Set-AutomationVariable -Name 'UpdateStarted' -Value 'none'
}


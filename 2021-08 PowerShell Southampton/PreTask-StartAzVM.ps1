# Add SoftwareUpdateConfigurationRunContext to param so your script can read it
param(
    $SoftwareUpdateConfigurationRunContext
)

# Convert the SoftwareUpdateConfigurationRunContext JSON to a PowerShell object
$Config = $SoftwareUpdateConfigurationRunContext | ConvertFrom-Json

# Connect using Run As Account
$AutoAccount = .\Connect-RunAsAccount.ps1

# Get the Azure VMs associated with this deployment
$AzureVMs = $Config.SoftwareUpdateConfigurationSettings.AzureVirtualMachines

# Send start command to all Azure VMs
[System.Collections.Generic.List[string]] $Started = @()
foreach($VmId in $AzureVMs){
    $status = Get-AzResource -Id $VmId | Get-AzVM -Status
    $check = $status.Statuses | Where-Object{ $_.Code -eq 'PowerState/running' }
    if(-not $check){
        Start-AzVM -Id $VmId
        $Started.Add($VmId)
    }
}

if($Started.Count -gt 0){
    Set-AutomationVariable -Name 'UpdateStarted' -Value ($Started -join(';'))
}
else{
    Set-AutomationVariable -Name 'UpdateStarted' -Value 'none'
}

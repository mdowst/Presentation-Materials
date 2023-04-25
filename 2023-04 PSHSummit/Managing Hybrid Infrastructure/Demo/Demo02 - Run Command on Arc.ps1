# Get Arc Server
$RunCommandName = 'Demo01' + (Get-Date).ToString('yyyyMMddHHmm')
$ArcSrv = Get-AzConnectedMachine -ResourceGroupName $ArcResourceGroupName -Name $ArcNameA

# Create Run Command on the Arc Server
# https://learn.microsoft.com/en-us/rest/api/hybridcompute/machine-extensions/create-or-update?tabs=HTTP
$body = @{
    "location"   = $ArcSrv.Location
    "properties" = @{
        "publisher"          = "Microsoft.Compute"
        "typeHandlerVersion" = "1.10"
        "type"               = "CustomScriptExtension"
        "forceUpdateTag"     = $RunCommandName
        "settings"           = @{
            "commandToExecute" = "pwsh.exe -Command  $ScriptContent"
        }
    }
}
$Payload = ($body | ConvertTo-Json)
$Payload

# Invoke to Azure Rest API
$URI = "https://management.azure.com$($ArcSrv.Id)/extensions/CustomScriptExtension?api-version=2021-05-20"
$submit = Invoke-AzRestMethod -Uri $URI -Method 'Put' -Payload ($body | ConvertTo-Json)
$submit


# Get Results from the Command
$AzConnectedMachineExtension = @{
    Name               = 'CustomScriptExtension'
    ResourceGroupName  = $ArcResourceGroupName
    MachineName        = $ArcNameA
}

# Wait for success
do{
    $ArcCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension
    Write-Progress -Activity "ProvisioningState : $($ArcCmd.ProvisioningState)" -Status "InstanceViewStatusCode : $($ArcCmd.InstanceViewStatusCode)" -PercentComplete 10 -id 1
    Start-Sleep -Seconds 3
}while($ArcCmd.ProvisioningState -notin 'Succeeded','Failed')
Write-Progress -Activity "Done" -Id 1 -Completed

$ArcCmd | Format-List 

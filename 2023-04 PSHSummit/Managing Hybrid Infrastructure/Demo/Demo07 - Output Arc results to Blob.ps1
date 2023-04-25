# Get Arc Server
$ArcSrv = Get-AzConnectedMachine -ResourceGroupName $ArcResourceGroupName -Name $ArcNameB

# Create URI similar to the VM URI
$ArcSrvId = $ArcSrv.Id.Split('/',[System.StringSplitOptions]::RemoveEmptyEntries)
$OutputBlobUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($ArcSrvId[1])/$($ArcSrvId[3])/$($ArcSrvId[-1])/output.txt$($SasToken)"
$ErrorBlobUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($ArcSrvId[1])/$($ArcSrvId[3])/$($ArcSrvId[-1])/error.txt$($SasToken)"

# Create the script wrapper
$ScriptContent = Get-Content -Path '.\Scripts\Get-SystemInfo.ps1' -Raw
$ScriptContentUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($ArcSrvId[1])/$($ArcSrvId[3])/$($ArcSrvId[-1])/Get-SystemInfo.txt$($SasToken)"
Write-StringToBlob -BlobUri $ScriptContentUri -Content $ScriptContent
$ArcScript = Get-ArcScriptWrapper -ScriptContentUri $ScriptContentUri -OutputBlobUri $OutputBlobUri -ErrorBlobUri $ErrorBlobUri

# Encode the script in base64
$encodedcommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ArcScript))

# Create Run Command on the Arc Server
$body = @{
    "location"   = $ArcSrv.Location
    "properties" = @{
        "publisher"          = "Microsoft.Compute"
        "typeHandlerVersion" = "1.10"
        "type"               = "CustomScriptExtension"
        "forceUpdateTag"     = $RunCommandName
        "settings"           = @{
            "commandToExecute" = "pwsh -EncodedCommand  $EncodedCommand"
        }
    }
}
$URI = "https://management.azure.com$($ArcSrv.Id)/extensions/CustomScriptExtension?api-version=2021-05-20"
$submit = Invoke-AzRestMethod -Uri $URI -Method 'Put' -Payload ($body | ConvertTo-Json)
$submit


# Get Results from the Command
$AzConnectedMachineExtension = @{
    Name               = 'CustomScriptExtension'
    ResourceGroupName  = $ArcResourceGroupName
    MachineName        = $ArcNameB
}
Write-Host "Wait for update to start"
do{
    try{
        $ArcCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension -ErrorAction Stop
    }
    catch{
        if($_.Exception.Message -notmatch 'The requested resource was not found.'){
            throw $_
        }
    }
    Write-Progress -Activity "ProvisioningState : $($ArcCmd.ProvisioningState)" -Status "InstanceViewStatusCode : $($ArcCmd.InstanceViewStatusCode)" -PercentComplete (pc) -id 1
    Start-Sleep -Seconds 3
}while($ArcCmd.ProvisioningState -notin 'Updating', 'Creating', 'Waiting')

Write-Host "Wait for success state"
while($ArcCmd.ProvisioningState -notin 'Succeeded','Failed'){
    $ArcCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension
    Write-Progress -Activity "ProvisioningState : $($ArcCmd.ProvisioningState)" -Status "InstanceViewStatusCode : $($ArcCmd.InstanceViewStatusCode)" -PercentComplete (pc) -id 1
    Start-Sleep -Seconds 3
}
Write-Progress -Activity "Done" -Id 1 -Completed

# Get return data from Blob
$ArcData = Invoke-RestMethod -Uri $OutputBlobUri
$ArcData
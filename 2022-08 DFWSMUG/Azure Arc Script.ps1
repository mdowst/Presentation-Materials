# Get Arc Server
$ResourceGroupName = 'ArcDev'
$ArcSrv = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName -Name 'OP-Win01'

# Create Run Command on the Arc Server
$encodedcommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptContent))
$body = @{
    "location"   = $ArcSrv.Location
    "properties" = @{
        "publisher"          = "Microsoft.Compute"
        "typeHandlerVersion" = "1.10"
        "type"               = "CustomScriptExtension"
        "forceUpdateTag"     = (Get-Date).ToFileTime()
        "settings"           = @{
            "commandToExecute" = "powershell.exe -EncodedCommand  $encodedcommand"
        }
    }
}

$URI = "https://management.azure.com$($ArcSrv.Id)/extensions/CustomScriptExtension?api-version=2021-05-20"
$submit = Invoke-AzRestMethod -Uri $URI -Method 'Put' -Payload ($body | ConvertTo-Json)


# Get Results from the Command
$AzConnectedMachineExtension = @{
    Name               = 'CustomScriptExtension'
    ResourceGroupName  = $ResourceGroupName
    MachineName        = $ArcSrv.Name
}
$ArcCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension
$ArcCmd | Format-List Name, ProvisioningState, InstanceViewStatusCode, InstanceViewStatusLevel, InstanceViewStatusMessage

$ArcCmd.InstanceViewStatusMessage

# Parse the output
$StdOut = $ArcCmd.InstanceViewStatusMessage
$StdOut = $StdOut.Substring($StdOut.IndexOf('StdOut:') + 7)
$StdOut = $StdOut.Substring(0, $StdOut.IndexOf(', StdErr:'))
$StdOut | ConvertFrom-Json
# Get Arc Server
$ArcWinSrv = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName -Name $ArcWinSrvName

# Create Run Command on the Arc Server
$ScriptContent = '[system.environment]::MachineName'
# The script is encoded to prevent issues with escape or illegal characters in the JSON
$encodedcommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptContent))
$body = @{
    "location"   = $ArcWinSrv.Location
    "properties" = @{
        "publisher"          = "Microsoft.Compute"
        "typeHandlerVersion" = "1.10"
        "type"               = "CustomScriptExtension"
        # The script will only reexecute if the forceUpdateTag is changed
        "forceUpdateTag"     = (Get-Date).ToFileTime()
        "settings"           = @{
            # Command to execute is similar to the Run command, so you need to specify PowerShell.
            "commandToExecute" = "powershell.exe -EncodedCommand  $encodedcommand"
        }
    }
}
$Payload = $body | ConvertTo-Json
$URI = "https://management.azure.com$($ArcWinSrv.Id)/extensions/CustomScriptExtension?api-version=2021-05-20"
$submit = Invoke-AzRestMethod -Uri $URI -Method 'Put' -Payload $Payload
$submit

# Get Results from the Command
$AzConnectedMachineExtension = @{
    Name              = 'CustomScriptExtension'
    ResourceGroupName = $ResourceGroupName
    MachineName       = $ArcWinSrv.Name
}
$ArcWinCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension
$ArcWinCmd | Format-List Name, ProvisioningState, InstanceViewStatusCode, InstanceViewStatusLevel, InstanceViewStatusMessage

$ArcWinCmd.InstanceViewStatusMessage

# Parse the output
$StdOut = $ArcWinCmd.InstanceViewStatusMessage
$StdOut = $StdOut.Substring($StdOut.IndexOf('StdOut:') + 8)
$StdOut
# Get Arc Linux Server
$ArcLinux = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName -Name $ArcLinuxName

# Create Run Command on the Arc Server
$ScriptContent = '[system.environment]::MachineName'
$encodedcommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptContent))
$body = @{
    "location"   = $ArcLinux.Location
    "properties" = @{
        "publisher"          = "Microsoft.Azure.Extensions"
        "typeHandlerVersion" = "2.1.7"
        "type"               = "CustomScript"
        # The script will only reexecute if the forceUpdateTag is changed
        "forceUpdateTag"     = (Get-Date).ToFileTime()
        "settings"           = @{
            # Command to execute is similar to the terminal command, so you need to specify PowerShell.
            # The script is encoded to prevent issues with escape or illegal characters in the JSON
            "commandToExecute" = "pwsh -EncodedCommand  $encodedcommand"
        }
    }
}

$URI = "https://management.azure.com$($ArcLinux.Id)/extensions/CustomScriptExtension?api-version=2021-05-20"
$submit = Invoke-AzRestMethod -Uri $URI -Method 'Put' -Payload ($body | ConvertTo-Json)
$submit

# Get Results from the Command
$AzConnectedMachineExtension = @{
    Name              = 'CustomScriptExtension'
    ResourceGroupName = $ResourceGroupName
    MachineName       = $ArcLinux.Name
}
$ArcLinuxCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension
$ArcLinuxCmd | Format-List Name, ProvisioningState, InstanceViewStatusCode, InstanceViewStatusLevel, InstanceViewStatusMessage

$ArcLinuxCmd.InstanceViewStatusMessage

# Parse the output
$StdOut = $ArcLinuxCmd.InstanceViewStatusMessage
$StdOut = $StdOut.Substring($StdOut.IndexOf('[stdout]') + 8)
$StdOut = $StdOut.Substring(0, $StdOut.IndexOf('[stderr]'))
$StdOut
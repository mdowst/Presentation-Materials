Function Invoke-ArcCommand {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]   
        [string]$ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]$MachineName,
        [parameter(Mandatory = $true)]
        [string]$ScriptContent
    )

    # Get the Arc Machine
    $ArcSrv = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName -Name $MachineName -ErrorAction Stop


    $encodedcommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptContent))
    if ($ArcSrv.OSName -eq 'windows') {
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
    }
    else {
        $body = @{
            "location"   = $ArcSrv.Location
            "properties" = @{
                "publisher"          = "Microsoft.Azure.Extensions"
                "typeHandlerVersion" = "2.1.7"
                "type"               = "CustomScript"
                "forceUpdateTag"     = (Get-Date).ToFileTime()
                "settings"           = @{
                    "commandToExecute" = "pwsh -EncodedCommand  $encodedcommand"
                }
            }
        }
    }
    # submit Rest request to start script
    $URI = "https://management.azure.com$($ArcSrv.Id)/extensions/CustomScriptExtension?api-version=2021-05-20"
    $submit = Invoke-AzRestMethod -Uri $URI -Method 'Put' -Payload ($body | ConvertTo-Json)
    
    # Monitor that the execution starts
    $timer = [system.diagnostics.stopwatch]::StartNew()
    do {
        $ext = Get-AzConnectedMachineExtension -ResourceGroupName $ResourceGroupName -MachineName $MachineName | 
        Where-Object { $_.InstanceViewType -eq 'CustomScriptExtension' -or $_.Name -eq 'CustomScriptExtension' } 
    } while ($ext.ProvisioningState -notin 'Updating', 'Creating', 'Waiting' -and $timer.Elapsed.TotalSeconds -le 30)
    $timer.Stop()

    if ($timer.Elapsed.TotalSeconds -gt 30) {
        Write-Error "Failed to start the provisioning - $($ext.ProvisioningState)"
    }
    elseif ($submit.StatusCode -ne 202) {
        Write-Error $submit.Content
    }
    else {
        $ext.Name
    }
}

Function Get-ArcScriptStatus {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]    
        [string]$ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]$MachineName,
        [parameter(Mandatory = $true)]
        [string]$RunCommandName
    )


    $AzConnectedMachineExtension = @{
        Name              = $RunCommandName
        ResourceGroupName = $ResourceGroupName
        MachineName       = $MachineName
    }
    $ArcCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension

    $ArcCmd.ProvisioningState
}

Function Get-ArcScriptOutput {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]   
        [string]$ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]$MachineName,
        [parameter(Mandatory = $true)]
        [string]$RunCommandName
    )


    $AzConnectedMachineExtension = @{
        Name              = $RunCommandName
        ResourceGroupName = $ResourceGroupName
        MachineName       = $MachineName
    }
    $ArcOutput = Get-AzConnectedMachineExtension @AzConnectedMachineExtension

    $StdOut = [string]::Empty
    $StdErr = [string]::Empty
    
    if (-not [string]::IsNullOrEmpty($ArcOutput.InstanceViewStatusMessage)) {
        $StdOut = $ArcOutput.InstanceViewStatusMessage
    }
    elseif (-not [string]::IsNullOrEmpty($ArcOutput.StatusMessage)) {
        $StdOut = $ArcOutput.StatusMessage
    }
    else {
        $StdOut = $ArcOutput
    }

    if ($StdOut.IndexOf('StdOut:') -gt 0) {
        $StdOut = $StdOut.Substring($StdOut.IndexOf('StdOut:') + 7)
    }
    elseif ($StdOut.IndexOf('[stdout]') -gt 0) {
        $StdOut = $StdOut.Substring($StdOut.IndexOf('[stdout]') + 8)
    }

    if ($StdOut.IndexOf(', StdErr:') -gt 0) {
        $StdErr = $StdOut.Substring($StdOut.IndexOf(', StdErr:') + 10)
        $StdOut = $StdOut.Substring(0, $StdOut.IndexOf(', StdErr:'))
    }
    elseif ($StdOut.IndexOf('[stderr]') -gt 0) {
        $StdErr = $StdOut.Substring($StdOut.IndexOf('[stderr]') + 8)
        $StdOut = $StdOut.Substring(0, $StdOut.IndexOf('[stderr]'))
    }
    else {
        $StdErr = ''
    }

    try {
        $StdOutReturn = $StdOut.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $StdOutReturn = $StdOut
    }

    try {
        $StdErrReturn = $StdErr.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $StdErrReturn = $StdErr
    }

    if ($vmJob.State -eq 'Failed') {
        $StdErrReturn = $StdOutReturn
        $StdOutReturn = ''
    }

    [pscustomobject]@{
        StdOut = $StdOutReturn
        StdErr = $StdErrReturn
    }
}
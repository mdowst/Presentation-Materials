Function Invoke-ArcCommand {
    [CmdletBinding()]
    param(
        [string]$ResourceGroupName,
        [string]$Name,
        [string]$ScriptContent
    )

    $ArcSrv = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction Stop

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
    
    $timer = [system.diagnostics.stopwatch]::StartNew()
    do {
        $ext = Get-AzConnectedMachineExtension -ResourceGroupName $ResourceGroupName -MachineName $Name | 
            Where-Object { $_.InstanceViewType -eq 'CustomScriptExtension' } 
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
        [string]$ResourceGroupName,
        [string]$MachineName,
        [string]$Name
    )


    $AzConnectedMachineExtension = @{
        Name               = $Name
        ResourceGroupName  = $ResourceGroupName
        MachineName        = $MachineName
    }
    $ArcCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension
    if($ArcCmd.ProvisioningState -in 'Succeeded','Failed'){
        $ArcCmd
    }
}

Function Get-ArcScriptOutput {
    [CmdletBinding()]
    param(
        $ArcOutput
    )

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
    if ($StdOut.IndexOf(', StdErr:') -gt 0) {
        $StdErr = $StdOut.Substring($StdOut.IndexOf(', StdErr:') + 10)
        $StdOut = $StdOut.Substring(0, $StdOut.IndexOf(', StdErr:'))
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

$ScriptContent = Get-Content '.\DFWSMUG\VSCodeExt.ps1' -Raw
$ArcCommand = Invoke-ArcCommand -ResourceGroupName 'ArcDev' -Name 'OP-Win01' -ScriptContent $ScriptContent
$ArcScriptStatus = Get-ArcScriptStatus -ResourceGroupName 'ArcDev' -MachineName 'OP-Win01' -Name $ArcCommand
Get-ArcScriptOutput -ArcOutput $ArcScriptStatus | Format-List
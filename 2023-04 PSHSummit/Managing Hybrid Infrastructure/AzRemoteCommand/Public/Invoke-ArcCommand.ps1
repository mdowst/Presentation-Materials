Function Invoke-ArcCommand {
    <#
    .SYNOPSIS
    Invoke a PowerShell script on any Arc based machines
    
    .DESCRIPTION
    Invoke a PowerShell script on any remote machine running the Arc Agent
    
    .PARAMETER ResourceGroupName
    The resource group name
    
    .PARAMETER Name
    The machine name
    
    .PARAMETER ScriptContent
    The content of the script
    
    .PARAMETER RunCommandName
    The name of the command
    
    .PARAMETER OutputBlobUri
    The URI to store the script's output stream
    
    .PARAMETER ErrorBlobUri
    The URI to store the script's error stream

    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [parameter(Mandatory = $true)]
        [string]$Name,
        
        [parameter(Mandatory = $true)]
        [string]$RunCommandName,
        
        [parameter(Mandatory = $true)]
        [string]$ScriptContentUri,
        
        [parameter(Mandatory = $true)]
        [string]$OutputBlobUri,
        
        [parameter(Mandatory = $true)]
        [string]$ErrorBlobUri
    )

    # Get Arc Server
    $ArcSrv = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName -Name $Name

    # Create the script wrapper
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
                "commandToExecute" = "powershell.exe -EncodedCommand  $EncodedCommand"
            }
        }
    }

    $URI = "https://management.azure.com$($ArcSrv.Id)/extensions/CustomScriptExtension?api-version=2021-05-20"
    $submit = Invoke-AzRestMethod -Uri $URI -Method 'Put' -Payload ($body | ConvertTo-Json)
    
    $timer = [system.diagnostics.stopwatch]::StartNew()
    do {
        $ext = Get-AzConnectedMachineExtension -ResourceGroupName $ResourceGroupName -MachineName $Name | 
        Where-Object { $_.InstanceViewType -eq 'CustomScriptExtension' } 
    } while ($ext.ProvisioningState -notin 'Updating', 'Creating', 'Waiting' -and $timer.Elapsed.TotalSeconds -le 60)
    $timer.Stop()

    if ($submit.StatusCode -ne 202) {
        Write-Error $submit.Content
    }
    elseif ($timer.Elapsed.TotalSeconds -gt 30) {
        Write-Error "Failed to start the provisioning - $($ext.ProvisioningState)"
    }
    else {
        [pscustomobject]@{
            ResourceId        = $ArcSrv.Id
            ResourceGroupName = $ResourceGroupName
            Name              = $ArcSrv.Name
            CommandName       = $ext.Name
            State             = $ext.ProvisioningState
            OutputBlobUri     = $($OutputBlobUri.Split('?')[0])
            ErrorBlobUri      = $($ErrorBlobUri.Split('?')[0])
            Type              = 'Arc'
        }
    }
}
Function Invoke-ArcCommandArm {
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
        [string]$ScriptContent,
        
        [parameter(Mandatory = $true)]
        [string]$OutputBlobUri,
        
        [parameter(Mandatory = $true)]
        [string]$ErrorBlobUri
    )

    # Get Arc Server
    $ArcSrv = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName -Name $Name

    # Create the script wrapper
    $ArcScript = Get-ArcScriptWrapper -ScriptContent $ScriptContent

    $ScriptContentUri = $OutputBlobUri.Replace('output.txt', 'arcscript.ps1') 
    
    Write-StringToBlob -BlobUri $ScriptContentUri -Content $ArcScript | Out-Null

    # Create Run Command on the Arc Server
    $TemplateObject = @{
        "`$schema"       = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
        "contentVersion" = "1.0.0.0"
        "resources"      = @(
            @{
                "type"       = "Microsoft.HybridCompute/machines/extensions"
                "apiVersion" = "2021-05-20"
                "name"       = "$($Name)/CustomScriptExtension"
                "location"   = "eastus"
                "properties" = @{
                    "publisher"               = "Microsoft.Compute"
                    "type"                    = "CustomScriptExtension"
                    "autoUpgradeMinorVersion" = $true
                    "protectedSettings"       = @{
                        "commandToExecute" = "pwsh -ExecutionPolicy Unrestricted -File arcscript.ps1"
                        "fileUris"         = @(
                            $ScriptContentUri
                        )
                    }
                }
            }
        )
    }

    $ArcCmd = New-AzResourceGroupDeployment -Name "$($RunCommandName)-$($Name)" -ResourceGroupName $ResourceGroupName -TemplateObject $TemplateObject -AsJob

    do {
        $ext = Get-AzConnectedMachineExtension -ResourceGroupName $ResourceGroupName -MachineName $Name | 
        Where-Object { $_.InstanceViewType -eq 'CustomScriptExtension' } 
    } while ($ext.ProvisioningState -notin 'Updating', 'Creating', 'Waiting' -and $ArcCmd -notin 'Completed', 'Failed')
    
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
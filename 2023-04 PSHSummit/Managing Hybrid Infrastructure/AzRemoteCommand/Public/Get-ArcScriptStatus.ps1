Function Get-ArcScriptStatus {
    <#
    .SYNOPSIS
    Get the status of a remote command execution from an Arc server
    
    .DESCRIPTION
    Get the status of a remote command execution from an Arc server
    
    .PARAMETER ResourceGroupName
    The resource group name
    
    .PARAMETER Name
    The machine name
    
    .PARAMETER RunCommandName
    The name of the command
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [parameter(Mandatory = $true)]
        [string]$Name,

        [parameter(Mandatory = $false)]
        [string]$RunCommandName = 'CustomScriptExtension'
    )


    $AzConnectedMachineExtension = @{
        Name               = $RunCommandName
        ResourceGroupName  = $ResourceGroupName
        MachineName        = $Name
    }
    $ArcCmd = Get-AzConnectedMachineExtension @AzConnectedMachineExtension
    $ArcCmd.ProvisioningState
}
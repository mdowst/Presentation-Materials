Function Get-VmScriptStatus {
    <#
    .SYNOPSIS
    Get the status of a remote command execution from an Azure VM
    
    .DESCRIPTION
    Get the status of a remote command execution from an Azure VM
    
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

        [parameter(Mandatory = $true)]
        [string]$RunCommandName
    )
    
    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $Name

    $rest = Invoke-AzRestMethod -Path "$($VM.Id)/runCommands/$($RunCommandName)?`$expand=instanceView&api-version=2022-11-01" -Method GET
    ($rest.Content | ConvertFrom-Json).Properties.provisioningState
}
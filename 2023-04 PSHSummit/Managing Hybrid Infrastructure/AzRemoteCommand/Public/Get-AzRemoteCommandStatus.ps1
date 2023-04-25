Function Get-AzRemoteCommandStatus{
    <#
    .SYNOPSIS
    Get the status of a remote command execution from an Arc server or an Azure VM
    
    .DESCRIPTION
    Get the status of a remote command execution from an Arc server or an Azure VM
    
    .PARAMETER ResourceGroupName
    The resource group name
    
    .PARAMETER Name
    The machine name
    
    .PARAMETER RunCommandName
    The name of the command
    
    .PARAMETER Type
    Arc or AzVM
    
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
        [string]$RunCommandName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Arc","VM")]
        [string]$Type
    )

    $CommandParameters = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $Name
        RunCommandName    = $RunCommandName
    }

    # Invoke the command based on the device type
    if ($Type -eq 'VM') {
        Write-Verbose "$($Name) is an Azure VM"
        $Status = Get-VmScriptStatus @CommandParameters
    }
    else {
        Write-Verbose "$($Name) is an Arc Server"
        $Status = Get-ArcScriptStatus @CommandParameters
    }
    $Status
}
Function Invoke-AzRemoteCommand {
    <#
    .SYNOPSIS
    Invoke a PowerShell script on any remote machine Azure VM or Arc Agent
    
    .DESCRIPTION
    Invoke a PowerShell script on any remote machine Azure VM or Arc Agent
    
    .PARAMETER ResourceId
    The Azure VM or Arc Server resource id
    
    .PARAMETER ScriptContent
    The script to execute on the remote machine
    
    .PARAMETER RunCommandName
    The name of the command to run
    
    .PARAMETER SasToken
    The SAS Token to store the output and error streams too

    .PARAMETER
    THe container for storing the output files
    
    .PARAMETER StorageContext
    The storage context for the SAS Token
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]$ResourceId,

        [parameter(Mandatory = $true)]
        [string]$ScriptContent,

        [parameter(Mandatory = $true)]
        [string]$RunCommandName,

        [parameter(Mandatory = $true)]
        [string]$SasToken,

        [parameter(Mandatory = $true)]
        [string]$Container,

        [parameter(Mandatory = $true)]
        [Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext]$StorageContext
    )

    # Create Run Command on VM
    $SplitId = $ResourceId.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)
    $OutputBlobUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($SplitId[1])/$($SplitId[3])/$($SplitId[-1])/output.txt$($SasToken)"
    $ErrorBlobUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($SplitId[1])/$($SplitId[3])/$($SplitId[-1])/error.txt$($SasToken)"

    # Set the parameters
    $CommandParameters = @{
        ResourceGroupName = $SplitId[3]
        Name              = $SplitId[-1]
        RunCommandName    = $RunCommandName
        OutputBlobUri     = $OutputBlobUri
        ErrorBlobUri      = $ErrorBlobUri
    }

    # Invoke the command based on the device type
    if ($ResourceId -match 'Microsoft\.Compute/virtualMachines') {
        Write-Verbose "$($SplitId[-1]) is an Azure VM"
        $RunCommand = Invoke-VmCommand @CommandParameters -ScriptContent $ScriptContent
    }
    else {
        Write-Verbose "$($SplitId[-1]) is an Arc Server"
        # Create the script URI
        $ScriptContentUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($ArcSrvId[1])/$($ArcSrvId[3])/$($ArcSrvId[-1])/Get-SystemInfo.txt$($SasToken)"
        Write-StringToBlob -BlobUri $ScriptContentUri -Content $ScriptContent | Out-Null
        
        $RunCommand = Invoke-ArcCommand @CommandParameters -ScriptContentUri $ScriptContentUri
    }

    $RunCommand
}
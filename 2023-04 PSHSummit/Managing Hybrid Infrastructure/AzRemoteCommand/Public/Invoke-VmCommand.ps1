Function Invoke-VmCommand {
    <#
    .SYNOPSIS
    Invoke a PowerShell script on any Azure VM
    
    .DESCRIPTION
    Invoke a PowerShell script on any remote machine Azure VM or Arc Agent
    
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
    [CmdletBinding()]
    param(
        [string]$ResourceGroupName,
        [string]$Name,
        [string]$ScriptContent,
        [string]$RunCommandName,
        [string]$OutputBlobUri,
        [string]$ErrorBlobUri
    )

    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $Name

    if($vm.StorageProfile.OsDisk.OsType -eq 'Linux'){
        Write-Verbose "$($SplitId[-1]) is an Linux VM"
        $prefix = ''
    }
    else{
        Write-Verbose "$($SplitId[-1]) is an Windows VM"
        $prefix = '. '
    }

    $encodedcommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptContent))
    $AzVMRunCommand = @{
        ResourceGroupName = $VM.ResourceGroupName
        VMName            = $VM.Name
        RunCommandName    = $RunCommandName
        SourceScript      = "$($prefix)pwsh -EncodedCommand  $EncodedCommand"
        Location          = $VM.Location
        OutputBlobUri     = $OutputBlobUri
        ErrorBlobUri      = $ErrorBlobUri
        AsJob             = $true
    }
    $SetCmd = Set-AzVMRunCommand @AzVMRunCommand
    
    [pscustomobject]@{
        ResourceId        = $VM.Id
        ResourceGroupName = $VM.ResourceGroupName
        Name              = $VM.Name
        CommandName       = $RunCommandName
        State             = $SetCmd.State
        OutputBlobUri     = $($OutputBlobUri.Split('?')[0])
        ErrorBlobUri      = $($ErrorBlobUri.Split('?')[0])
        Type              = 'VM'
    }
}
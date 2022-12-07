Function Invoke-VmCommand {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]    
        [string]$ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]$MachineName,
        [parameter(Mandatory = $true)]
        [string]$ScriptContent,
        [parameter(Mandatory = $false)]
        [string]$RunCommandName='CustomScriptExtension'
    )

    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $MachineName
    if($VM.OSProfile.LinuxConfiguration){
        $encodedcommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptContent))
        $ScriptContent = "pwsh -EncodedCommand  $encodedcommand"
    }
    # Create Run Command on VM
    $AzVMRunCommand = @{
        ResourceGroupName = $VM.ResourceGroupName
        VMName            = $VM.Name
        RunCommandName    = $RunCommandName
        SourceScript      = $ScriptContent
        Location          = $VM.Location
        AsJob             = $true
    }
    Set-AzVMRunCommand @AzVMRunCommand | Out-Null
    $RunCommandName
}

Function Get-VwScriptStatus {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]    
        [string]$ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]$MachineName,
        [parameter(Mandatory = $true)]
        [string]$RunCommandName
    )
    
    $AzVMRunCommand = @{
        ResourceGroupName = $ResourceGroupName
        VMName            = $MachineName
        RunCommandName    = $RunCommandName
        Expand            = 'instanceView'
    }
    $cmd = Get-AzVMRunCommand @AzVMRunCommand
    $cmd.ProvisioningState
}

Function Get-VmScriptOutput {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]    
        [string]$ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]$MachineName,
        [parameter(Mandatory = $true)]
        [string]$RunCommandName
    )
    
    $AzVMRunCommand = @{
        ResourceGroupName = $ResourceGroupName
        VMName            = $MachineName
        RunCommandName    = $RunCommandName
        Expand            = 'instanceView'
    }
    $vmOutput = Get-AzVMRunCommand @AzVMRunCommand

    $StdOut = $vmOutput.InstanceViewOutput
    $StdErr = $vmOutput.InstanceViewError
    if ([string]::IsNullOrEmpty($StdOut)) {
        $StdErr = $vmOutput
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

    [pscustomobject]@{
        StdOut = $StdOutReturn
        StdErr = $StdErrReturn
    }
}

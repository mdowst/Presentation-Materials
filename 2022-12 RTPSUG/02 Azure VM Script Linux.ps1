# Get Azure VM
$LinuxVM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $LinuxVMName

# Source script is the command to execute on the remote machine. Linux does not natively supports PowerShell.
$ScriptContent = 'pwsh -command ''[system.environment]::MachineName'''

# Run command name can be used to save the output of different scripts
$RunCommandName = 'GetSystemName'

# Create Run Command on VM
$AzVMRunCommand = @{
    ResourceGroupName = $LinuxVM.ResourceGroupName
    VMName            = $LinuxVM.Name
    RunCommandName    = $RunCommandName 
    SourceScript      = $ScriptContent
    Location          = $LinuxVM.Location
    # Running as create background job for the execution, freeing your script to continue.
    AsJob             = $true
}
$LinuxSetCmd = Set-AzVMRunCommand @AzVMRunCommand
$LinuxSetCmd

# Get Results from Run Command
$AzVMRunCommand = @{
    ResourceGroupName = $LinuxVM.ResourceGroupName
    VMName            = $LinuxVM.Name
    RunCommandName    = $RunCommandName
    Expand            = 'instanceView'
}
$LinuxCmd = Get-AzVMRunCommand @AzVMRunCommand
$LinuxCmd | Format-List Name, ProvisioningState, InstanceViewExecutionState, InstanceViewStartTime, InstanceViewEndTime, InstanceViewError,
    InstanceViewExitCode, InstanceViewOutput

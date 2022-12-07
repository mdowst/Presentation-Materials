# Get Azure VM
$WinVM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $WinVMName

# Source script is the command to execute on the remote machine. Natively supports PowerShell code.
$ScriptContent = '[system.environment]::MachineName'

# Run command name can be used to save the output of different scripts
$RunCommandName = 'GetSystemName'

# Create Run Command on VM
$AzVMRunCommand = @{
    ResourceGroupName = $WinVM.ResourceGroupName
    VMName            = $WinVM.Name
    RunCommandName    = $RunCommandName 
    SourceScript      = $ScriptContent
    Location          = $WinVM.Location
    # Running as create background job for the execution, freeing your script to continue.
    AsJob             = $true
}
$SetCmd = Set-AzVMRunCommand @AzVMRunCommand
$SetCmd

# Get Results from Run Command
$AzVMRunCommand = @{
    ResourceGroupName = $WinVM.ResourceGroupName
    VMName            = $WinVM.Name
    RunCommandName    = $RunCommandName
    Expand            = 'instanceView'
}
$cmd = Get-AzVMRunCommand @AzVMRunCommand
$cmd | Format-List Name, ProvisioningState, InstanceViewExecutionState, InstanceViewStartTime, InstanceViewEndTime, InstanceViewError,
    InstanceViewExitCode, InstanceViewOutput

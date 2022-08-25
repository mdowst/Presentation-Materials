# Get Azure VM
$VM = Get-AzVM -ResourceGroupName 'ArcDev' -Name 'az-win19'

$ScriptContent = Get-Content '.\DFWSMUG\VSCodeExt.ps1' -Raw
$RunCommandName = 'VSCodeExt'

# Create Run Command on VM
$AzVMRunCommand = @{
    ResourceGroupName = $VM.ResourceGroupName
    VMName            = $VM.Name
    RunCommandName    = $RunCommandName
    SourceScript      = $ScriptContent
    Location          = $VM.Location
    AsJob             = $true
}
$SetCmd = Set-AzVMRunCommand @AzVMRunCommand
$SetCmd

# Get Results from Run Command
$AzVMRunCommand = @{
    ResourceGroupName = $VM.ResourceGroupName
    VMName            = $VM.Name
    RunCommandName    = $RunCommandName
    Expand            = 'instanceView'
}
$cmd = Get-AzVMRunCommand @AzVMRunCommand
$cmd | Format-List Name, ProvisioningState, InstanceViewExecutionState, InstanceViewStartTime, InstanceViewEndTime, InstanceViewError,
    InstanceViewExitCode, InstanceViewOutput

$cmd.InstanceViewOutput | ConvertFrom-Json



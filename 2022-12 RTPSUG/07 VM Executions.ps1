$ScriptContent = Get-Content '.\05 Get-SystemInfo.ps1' -Raw

# Start the Azure Linux Job
$LinuxVMJob  = Invoke-VmCommand -ResourceGroupName $ResourceGroupName -MachineName $LinuxVMName -ScriptContent $ScriptContent
# Start the Azure Windows Job
$WinSrvVMJob = Invoke-VmCommand -ResourceGroupName $ResourceGroupName -MachineName $WinVMName   -ScriptContent $ScriptContent

# Check the status of each job
Get-VwScriptStatus -ResourceGroupName $ResourceGroupName -MachineName $LinuxVMName -RunCommandName $LinuxVMJob
Get-VwScriptStatus -ResourceGroupName $ResourceGroupName -MachineName $WinVMName   -RunCommandName $WinSrvVMJob

# Get the results from each job
$LinuxVmOut = Get-VmScriptOutput -ResourceGroupName $ResourceGroupName -MachineName $LinuxVMName -RunCommandName $LinuxVMJob
$LinuxVmOut.StdOut

$WinVmOut = Get-VmScriptOutput -ResourceGroupName $ResourceGroupName -MachineName $WinVMName -RunCommandName $WinSrvVMJob
$WinVmOut.StdOut





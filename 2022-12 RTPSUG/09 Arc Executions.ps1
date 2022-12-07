$ScriptContent = Get-Content '.\05 Get-SystemInfo.ps1' -Raw

# Start the Arc Linux Job
$ArcLinuxJob  = Invoke-ArcCommand -ResourceGroupName $ResourceGroupName -MachineName $ArcLinuxName  -ScriptContent $ScriptContent
# Start the Arc Windows Job
$ArcWinSrvJob = Invoke-ArcCommand -ResourceGroupName $ResourceGroupName -MachineName $ArcWinSrvName -ScriptContent $ScriptContent

# Check the status of each job
Get-ArcScriptStatus -ResourceGroupName $ResourceGroupName -MachineName $ArcLinuxName -RunCommandName $ArcLinuxJob
Get-ArcScriptStatus -ResourceGroupName $ResourceGroupName -MachineName $ArcWinSrvName -RunCommandName $ArcWinSrvJob

# Get the results from each job
$LinOut = Get-ArcScriptOutput -ResourceGroupName $ResourceGroupName -MachineName $ArcLinuxName -RunCommandName $ArcLinuxJob
$LinOut.StdOut

$WinOut = Get-ArcScriptOutput -ResourceGroupName $ResourceGroupName -MachineName $ArcWinSrvName -RunCommandName $ArcWinSrvJob
$WinOut.StdOut




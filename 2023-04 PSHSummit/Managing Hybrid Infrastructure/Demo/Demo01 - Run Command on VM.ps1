$ScriptContent = 'Get-CimInstance -Class Win32_OperatingSystem'
$RunCommandName = 'Demo01'

# Get Azure VM
$VM = Get-AzVM -ResourceGroupName $VmResourceGroupName -Name $VmName

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

# Wait for job to finish
$i = 0
while($SetCmd.State -eq 'Running' -and $i -le 3){
    $SetCmd
    Start-Sleep -Seconds 3
    $i++
}

# Wait for the command to complete
$AzVMRunCommand = @{
    ResourceGroupName = $VmResourceGroupName
    VMName            = $VmName
    RunCommandName    = $RunCommandName
    Expand            = 'instanceView'
}
do{
    $cmd = Get-AzVMRunCommand @AzVMRunCommand
    Write-Progress -Activity "Command : $($cmd.Name)" -Status "InstanceViewStatusCode : $($cmd.InstanceView.ExecutionState)" -PercentComplete 10 -id 1
    Start-Sleep -Seconds 3
}while($cmd.InstanceView.ExecutionState -notin 'Succeeded','Failed')
Write-Progress -Activity "Done" -Id 1 -Completed

# Get Results from Run Command
$cmd.InstanceView | Format-List
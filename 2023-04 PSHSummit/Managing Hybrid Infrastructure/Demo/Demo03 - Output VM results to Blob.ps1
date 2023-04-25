# Get script, but output to JSON
$ScriptContent = Get-Content -Path '.\Scripts\Get-WinSystemInfo.ps1' -Raw
$RunCommandName = 'Demo02'


# Create SAS Token to save Script Output
$key = Get-AzStorageAccountKey -ResourceGroupName $StorageResourceGroup -Name $StorageAccount | Select-Object -First 1
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $key.Value
$StartTime = Get-Date
$EndTime = $startTime.AddDays(1)
# SAS Token must have (R)ead, (A)dd, (C)reate, and (W)rite permissions
$SasToken = New-AzStorageContainerSASToken -Name $container -Permission racw -StartTime $StartTime -ExpiryTime $EndTime -context $StorageContext 


# Get Azure VM
$VM = Get-AzVM -ResourceGroupName $VMResourceGroupName -Name $VMName

# Create Run Command on VM
$VmId = $VM.Id.Split('/',[System.StringSplitOptions]::RemoveEmptyEntries)
"`n`n$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($VmId[1])/$($VmId[3])/$($VmId[-1])/output.txt$($SasTokenPlaceHolder)`n`n"

$AzVMRunCommand = @{
    ResourceGroupName = $VM.ResourceGroupName
    VMName            = $VM.Name
    RunCommandName    = $RunCommandName
    SourceScript      = $ScriptContent
    Location          = $VM.Location
    OutputBlobUri     = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($VmId[1])/$($VmId[3])/$($VmId[-1])/output.txt$($SasToken)"
    ErrorBlobUri      = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($VmId[1])/$($VmId[3])/$($VmId[-1])/error.txt$($SasToken)"
    AsJob             = $true
}
$SetCmd = Set-AzVMRunCommand @AzVMRunCommand
$SetCmd

# Wait for command to finish
$AzVMRunCommand = @{
    ResourceGroupName = $VmResourceGroupName
    VMName            = $VmName
    RunCommandName    = $RunCommandName
    Expand            = 'instanceView'
}
do{
    try{
        $cmd = Get-AzVMRunCommand @AzVMRunCommand -ErrorAction Stop
    }
    catch{
        if($_.Exception.Message -notmatch 'ResourceNotFound'){
            throw $_
        }
        $cmd = $null
    }
    Write-Progress -Activity "Command : $($cmd.Name)" -Status "InstanceViewStatusCode : $($cmd.InstanceView.ExecutionState)" -PercentComplete (pc) -id 1
    Start-Sleep -Seconds 3
}while($cmd.InstanceView.ExecutionState -notin 'Succeeded','Failed' -or -not $cmd )
Write-Progress -Activity "Done" -Id 1 -Completed

# Get return data from Blob
$VMData = Invoke-RestMethod -Uri "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($VmId[1])/$($VmId[3])/$($VmId[-1])/output.txt$($SasToken)"
$VMData
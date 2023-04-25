$ArcResourceGroupName = 'ArcServers'
$VM = Get-AzResource -ResourceGroupName $VMResourceGroupName 
$ArcSrv = Get-AzResource -ResourceGroupName $ArcResourceGroupName 
$resources = @($VM) + @($ArcSrv) | 
    Where-Object{ $_.ResourceType -in 'Microsoft.HybridCompute/machines','Microsoft.Compute/virtualMachines'} 

# Get script, but output to JSON
$ScriptContent = Get-Content -Path '.\Scripts\Get-SystemInfo.ps1' -Raw
$RunCommandName = 'Demo03_' + (Get-Date).ToFileTime()


$Executions = foreach ($r in $resources) {
    $CommandParameters = @{
        ResourceId     = $r.Id
        RunCommandName = $RunCommandName
        ScriptContent  = $ScriptContent
        SasToken       = $SasToken
        StorageContext = $StorageContext
        Container      = $Container
    }
    Invoke-AzRemoteCommand @CommandParameters -Verbose
}

while ($Executions | Where-Object { $_.State -notin 'Succeeded', 'Failed' }) {
    $running = @($Executions | Where-Object { $_.State -notin 'Succeeded', 'Failed' })
    Write-Progress -Activity "Waiting for execution" -Status "$($running.Count) of $($Executions.count)" -PercentComplete $(($running.Count / $($Executions.count)) * 100) -id 1
    foreach ($e in $Executions | Where-Object { $_.State -notin 'Succeeded', 'Failed' }) {
        $CommandParameters = @{
            ResourceGroupName = $e.ResourceGroupName
            Name              = $e.Name
            RunCommandName    = $e.CommandName
            Type              = $e.Type
        }
        $e.State = Get-AzRemoteCommandStatus @CommandParameters
        if ($e.State -in 'Succeeded', 'Failed') {
            Invoke-RestMethod -Uri "$($e.OutputBlobUri)$($SasToken)"
        }
    }
    Start-Sleep -Seconds 3
}
Write-Progress -Activity "Done" -Id 1 -Completed

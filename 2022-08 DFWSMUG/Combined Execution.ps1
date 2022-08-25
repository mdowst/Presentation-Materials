$ResourceGroupName = 'ArcDev'
$RunCommandName = 'VSCodeExt'
$ScriptContent = Get-Content '.\DFWSMUG\VSCodeExt.ps1' -Raw

$resources = Get-AzResource -ResourceGroupName $ResourceGroupName | 
    Where-Object{ $_.ResourceType -in 'Microsoft.HybridCompute/machines','Microsoft.Compute/virtualMachines'} | 
    Select-Object -Property ResourceGroupName, Name, ResourceType, Location, 
        @{l = 'Job'; e = { $null } }, @{l = 'Output'; e = { $null } }

foreach($r in $resources){
    if($r.ResourceType -eq 'Microsoft.Compute/virtualMachines'){
        $r.Job = Invoke-VmCommand -ResourceGroupName $r.ResourceGroupName -VMName $r.Name -RunCommandName $RunCommandName -ScriptContent $ScriptContent
    }
    else{
        $r.Job = Invoke-ArcCommand -ResourceGroupName $r.ResourceGroupName -Name $r.Name -ScriptContent $ScriptContent
    }
}

while($resources.Output -contains $null){
    foreach($r in $resources | Where-Object{$_.Output -eq $null}){
        if($r.ResourceType -eq 'Microsoft.Compute/virtualMachines'){
            $r.Output = Get-VwScriptStatus -ResourceGroupName $r.ResourceGroupName -VMName $r.Name -Name $RunCommandName
        }
        else{
            $r.Output = Get-ArcScriptStatus -ResourceGroupName $r.ResourceGroupName -MachineName $r.Name -Name $r.Job
        }
    }
}

foreach($r in $resources){
    if($r.ResourceType -eq 'Microsoft.Compute/virtualMachines'){
        Get-VmScriptOutput -vmOutput $r.Output | Format-List
    }
    else{
        Get-ArcScriptOutput -ArcOutput $r.Output | Format-List
    }
}
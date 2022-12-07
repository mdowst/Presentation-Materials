$Concurrent = 4
$ScriptContent = Get-Content '.\05 Get-SystemInfo.ps1' -Raw

# Get all Virtual Machines and Arc Enabled Machines
$Query = @'
resources
| where type in~ ('microsoft.hybridcompute/machines','microsoft.compute/virtualmachines')
| extend statusRaw = iif(isempty(properties.status),
coalesce(properties.powerState, properties.status.powerState, tostring(split(tolower(properties.extended.instanceView.powerState.code), "powerstate/")[1])),
properties.status)
| extend status = strcat(toupper(substring(statusRaw, 0, 1)), tolower(substring(statusRaw, 1, strlen(statusRaw)-1)))
| extend os = case(
	properties.storageProfile.osDisk.osType =~ 'Windows' or properties.osProfile.osType =~ 'Windows', 'Windows',
	properties.storageProfile.osDisk.osType =~ 'Linux' or properties.osProfile.osType =~ 'Linux', 'Linux',
	properties.osName
		) 
| extend operatingSystem = case(
os =~ 'windows', 'Windows',
os =~ 'linux', 'Linux',
'')
| project id, name, status, type, operatingSystem, resourceGroup, subscriptionId
'@
$QueryResults = Search-AzGraph -Query $Query
$resources = $QueryResults.Data | Select-Object -Property *,
@{l = 'RunCommandName'; e = { $null } }, @{l = 'JobStatus'; e = { 'Pending' } }, @{l = 'Output'; e = { $null } }


$resources | Format-Table Name, type, Status, RunCommandName, JobStatus, Output

while ($resources | Where-Object { $_.JobStatus -notin 'Succeeded', 'Failed', 'Error' }) {
    
    foreach ($r in $resources | Where-Object { $_.JobStatus -eq 'Pending' }) {
        # If concurrent executions exceeded then stop processing new jobs
        if (@($resources | Where-Object { $_.JobStatus -notin 'Pending', 'Succeeded', 'Failed', 'Error' }).Count -ge $Concurrent) {
            Write-Host "Skipping $($r.Name)"
            continue
        }
        try {
            if ($r.type -eq 'Microsoft.Compute/virtualMachines') {
                $r.RunCommandName = Invoke-VmCommand -ResourceGroupName $r.resourceGroup -MachineName $r.Name -ScriptContent $ScriptContent -ErrorAction Stop  
            }
            else {
                $r.RunCommandName = Invoke-ArcCommand -ResourceGroupName $r.resourceGroup -MachineName $r.Name -ScriptContent $ScriptContent -ErrorAction Stop
            }
            $r.JobStatus = 'Submitted'
        }
        catch {
            $r.JobStatus = 'Error'
            $r.Output = $_
        }
    }
    
    foreach ($r in $resources | Where-Object { $_.JobStatus -notin 'Pending', 'Succeeded', 'Failed', 'Error' }) {
        if ($r.type -eq 'Microsoft.Compute/virtualMachines') {
            $r.JobStatus = Get-VwScriptStatus -ResourceGroupName $r.resourceGroup -MachineName $r.Name -RunCommandName $r.RunCommandName
        }
        else {
            $r.JobStatus = Get-ArcScriptStatus -ResourceGroupName $r.resourceGroup -MachineName $r.Name -RunCommandName $r.RunCommandName
        }
    }
    $resources | Format-Table Name, Status, RunCommandName, JobStatus, Output
    if ($resources | Where-Object { $_.JobStatus -notin 'Succeeded', 'Failed', 'Error' }) {
        Start-Sleep -Seconds 30
    }
}


foreach ($r in $resources | Where-Object { $_.JobStatus -in 'Succeeded', 'Failed' }) {
    if ($r.type -eq 'Microsoft.Compute/virtualMachines') {
        $r.Output = Get-VmScriptOutput -ResourceGroupName $r.resourceGroup -MachineName $r.Name -RunCommandName $r.RunCommandName
    }
    else {
        $r.Output = Get-ArcScriptOutput -ResourceGroupName $r.resourceGroup -MachineName $r.Name -RunCommandName $r.RunCommandName
    }
}
$resources | Format-Table Name, Status, RunCommandName, JobStatus, Output
$resources | ForEach-Object{
    $_.Name
    $_.Output.StdOut
}

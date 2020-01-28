# Query log analytics group for nonAzure Windows machines
$query = @'
Heartbeat
| where OSType == "Windows" 
| summarize arg_max(TimeGenerated, *) by SourceComputerId 
'@
$queryResults = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $query
$Computers = $queryResults.Results | Select-Object -ExpandProperty Computer

# Confirm all machines are Hybrid Runbook Workers and reporting 
Get-AzAutomationHybridWorkerGroup -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName |
    Where-Object{ $_.GroupType -eq 'System'} | Select-Object -ExpandProperty RunbookWorker | 
    Where-Object{ $Computers -contains $_.Name }
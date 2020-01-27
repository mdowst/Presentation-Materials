# Server stop Health Service and clear cache and Hybrid Worker Configuration
Stop-Service -Name HealthService 
Remove-Item -Path 'C:\Program Files\Microsoft Monitoring Agent\Agent\Health Service State' -Recurse 
Remove-Item -Path "HKLM:\software\microsoft\hybridrunbookworker" -Recurse -Force

# Remove the Hybrid Worker from the Automation Account
$ResourceGroupName = ''
$AutomationAccountName = ''
$Server = ''
Get-AzAutomationHybridWorkerGroup -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName |
    Where-Object{ $_.RunbookWorker.Name -contains $Server} | Remove-AzAutomationHybridWorkerGroup

# Restart the Health Service
Start-Service -Name HealthService
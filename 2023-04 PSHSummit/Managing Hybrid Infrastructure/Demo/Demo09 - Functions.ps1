# Get Arc Server
$ResourceGroupName = 'AzureArcDev'
$Name = 'Arcbox-Ubuntu-01'

$RunCommandName = 'Demo09_' + (Get-Date).ToString('yyyyMMddHHmm')
$ArcSrv = Get-AzConnectedMachine -ResourceGroupName $ResourceGroupName -Name $Name
$ArcSrvId = $ArcSrv.Id.Split('/',[System.StringSplitOptions]::RemoveEmptyEntries)
$OutputBlobUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($ArcSrvId[1])/$($ArcSrvId[3])/$($ArcSrvId[-1])/output.txt$($SasToken)"
$ErrorBlobUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($ArcSrvId[1])/$($ArcSrvId[3])/$($ArcSrvId[-1])/error.txt$($SasToken)"
$ScriptContent = Get-Content -Path '.\Scripts\Get-WinSystemInfo.ps1' -Raw
$ScriptContentUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/$($ArcSrvId[1])/$($ArcSrvId[3])/$($ArcSrvId[-1])/Get-SystemInfo.txt$($SasToken)"
Write-StringToBlob -BlobUri $ScriptContentUri -Content $ScriptContent | Out-Null

Invoke-ArcCommand -ResourceGroupName $ResourceGroupName -Name $Name -RunCommandName $RunCommandName -ScriptContentUri $ScriptContent -OutputBlobUri $OutputBlobUri -ErrorBlobUri $ErrorBlobUri


Get-ArcScriptStatus -ResourceGroupName $ResourceGroupName -Name $Name 

Get-AzRemoteCommandOutput -ResourceGroupName $ResourceGroupName -Name $Name -RunCommandName $RunCommandName -Container $container -StorageContext $StorageContext
# Get Arc Server
$ScriptFile = Get-Item -Path '.\Scripts\Get-SystemInfo.ps1'
$ScriptText = $ScriptFile | Get-Content -Raw

# Create URI similar to the VM URI
"$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/test/$($ScriptFile.Name)$($SasTokenPlaceHolder)"

# Test writing to blob
$ScriptContentUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/test/$($ScriptFile.Name)$($SasToken)"
Write-StringToBlob -BlobUri $ScriptContentUri -Content $ScriptText

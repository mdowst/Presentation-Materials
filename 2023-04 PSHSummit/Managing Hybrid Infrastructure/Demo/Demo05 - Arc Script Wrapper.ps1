
$OutputBlobUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/test/output.txt$($SasToken)"
$ErrorBlobUri = "$($StorageContext.BlobEndPoint)$($container)/$RunCommandName/test/error.txt$($SasToken)"

$ArcScript = Get-ArcScriptWrapper -ScriptContentUri $ScriptContentUri -OutputBlobUri $OutputBlobUri -ErrorBlobUri $ErrorBlobUri

$ArcScript | Out-File '.\Demo\Demo06 - Write Command Output to Blob.ps1'



$SourceFolder = $DownloadPath
$StorageAccountName = ''
$ContainerName = ''
$ResourceGroupName = ''

# Get the Storage account context
$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context

# Upload files
Get-ChildItem -Path $SourceFolder -File -Recurse | ForEach-Object {
    $localFile = $_.FullName
    $blobName = $_.Name
    $matchingBlob = Get-AzStorageBlob -Container $ContainerName -Context $ctx -Blob $blobName -ErrorAction SilentlyContinue

    if ($matchingBlob) {
        Write-Output "DUPLICATE FOUND: '$blobName' exists in blob storage. Comparing hashes..."

        $localHash = (Get-FileHash -Path $localFile -Algorithm MD5).Hash
        $azblob = Get-AzStorageBlob -Blob $blobName -Container $ContainerName -Context $ctx
        $blobHash = -join ($azblob.BlobProperties.ContentHash | ForEach-Object { $_.ToString("x2") })

        if ($localHash -eq $blobHash) {
            Write-Output "MATCH: Hashes match. '$blobName'."
        } else {
            $timestamp = (Get-Date).ToFileTimeUtc()
            $newBlobName = "{0}_{1}{2}" -f $_.BaseName, $timestamp, $_.Extension
            Write-Output "MISMATCH: Renaming to '$newBlobName' and uploading."
            Set-AzStorageBlobContent -File $localFile -Container $ContainerName -Blob $newBlobName -Context $ctx | Out-Null
        }
    } else {
        Write-Output "NEW: Uploading '$blobName'..."
        Set-AzStorageBlobContent -File $localFile -Container $ContainerName -Blob $blobName -Context $ctx | Out-Null
    }
    Remove-Item -Path $localFile -Force
}

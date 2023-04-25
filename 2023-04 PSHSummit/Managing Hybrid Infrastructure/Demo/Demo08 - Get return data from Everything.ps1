# Get all the results from a particular job run
$Blobs = Get-AzStorageBlob -Container $container -Prefix $RunCommandName -Context $StorageContext
$Blobs | Format-Table Name

# Group them on the machine
$BlobGroups = $Blobs | Group-Object -Property {Split-Path $_.Name}
$BlobGroups

# Parse through them and get your data
[Collections.Generic.List[PSObject]] $results = @()
foreach($run in $BlobGroups){
    $data = $run.Name.Split('\')
    $results.Add([pscustomobject]@{
        RunCommand = $data[0]
        Subscription = $data[1]
        ResourceGroup = $data[2]
        Computer = $data[3]
        Errors = $null
        Output = $null
    })
    $run.Group | Where-Object{ $_.Name -match 'output.txt' } | ForEach-Object{
        $results[-1].Output = $_.ICloudBlob.DownloadText() | ConvertFrom-Json
    }
}

$results.Output | Format-List
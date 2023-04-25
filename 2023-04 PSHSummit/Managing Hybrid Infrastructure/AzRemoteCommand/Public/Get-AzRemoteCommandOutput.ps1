Function Get-AzRemoteCommandOutput {
    <#
    .SYNOPSIS
    Get the output of a remote command execution from an Arc server or an Azure VM
    
    .DESCRIPTION
    Get the status of a remote command execution from an Arc server or an Azure VM
    
    .PARAMETER ResourceGroupName
    The resource group name
    
    .PARAMETER Name
    The machine name
    
    .PARAMETER RunCommandName
    The name of the command
    
    .PARAMETER Type
    Arc or AzVM
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [string]$ResourceGroupName = '*',

        [parameter(Mandatory = $false)]
        [string]$Name = '*',

        [parameter(Mandatory = $true)]
        [string]$RunCommandName,

        [parameter(Mandatory = $true)]
        [string]$Container,

        [parameter(Mandatory = $true)]
        [Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext]$StorageContext
    )

    $Blobs = Get-AzStorageBlob -Container $container -Blob "$($RunCommandName)/*$($ResourceGroupName)/$($Name)/*.txt" -Context $StorageContext

    # Group them on the machine
    $BlobGroups = $Blobs | Group-Object -Property { Split-Path $_.Name }

    # Parse through them and get your data
    [Collections.Generic.List[PSObject]] $results = @()
    foreach ($run in $BlobGroups) {
        $data = $run.Name.Split('\')
        $results.Add([pscustomobject]@{
                RunCommand    = $data[0]
                Subscription  = $data[1]
                ResourceGroup = $data[2]
                Computer      = $data[3]
                Errors        = $null
                Output        = $null
            })
        $run.Group | Where-Object { $_.Name -match 'output.txt' } | ForEach-Object {
            $results[-1].Output = $_.ICloudBlob.DownloadText() | ConvertFrom-Json
        }
        $run.Group | Where-Object { $_.Name -match 'error.txt' } | ForEach-Object {
            $results[-1].Errors = $_.ICloudBlob.DownloadText()
        }
    }

    $results
}
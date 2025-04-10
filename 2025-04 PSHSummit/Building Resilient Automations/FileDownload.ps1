$DownloadPath = Join-Path $PSScriptRoot 'Downloads' 


Function Set-DownloadFilePath{
    [CmdletBinding()]
    [OutputType([string])]
    param(
    [Parameter(Mandatory = $true)]
    [string]$Directory,

    [Parameter(Mandatory = $true)]
    [string]$FileName
    )

    # check if the folder path exists and create it if it doesn't
    if(-not (Test-Path -Path $Directory)){
        New-Item -Path $Directory -ItemType Directory | Out-Null
        Write-Verbose "Created folder '$Directory'"
    }
    
    # Set the full path of the file
    $FilePath = Join-Path $Directory $FileName

    # confirm the file doesn't already exist. Throw a terminating error if it does
    if(Test-Path -Path $FilePath){
        $FilePath = Join-Path $Directory "$($FileName.Substring(0,$FileName.LastIndexOf('.')))_$($(Get-Date).ToString('yyyyMMdd')).$($FileName.Substring($FileName.LastIndexOf('.')+1))"
    }

    # Return the file path
    $FilePath
}

$TimePath = Join-Path $DownloadPath (Get-Date).ToFileTimeUtc()
$fileDownloads = Invoke-RestMethod -Uri 'http://localhost:8081/files'
$fileDownloads.Files | ForEach-Object {
    $outFile = Set-DownloadFilePath -Directory $TimePath -FileName $_.Name
    Invoke-WebRequest -Uri $_.Url -OutFile $outFile
}
# Include the Write-StringToBlob so that data is written to the blob
Function Write-StringToBlob { 
    [cmdletbinding()]
    param(
        [string]$BlobUri,
        [string]$Content
    )

    $method = "PUT";
    $contentLength = [System.Text.Encoding]::UTF8.GetByteCount($Content);
    
    [System.Net.HttpWebRequest]$request = [System.Net.WebRequest]::Create($BlobUri)

    $now = [DateTime]::UtcNow.ToString("R");

    $request.Method = $method;
    $request.ContentType = "text/plain; charset=UTF-8";
    $request.ContentLength = $contentLength;

    $request.Headers.Add("x-ms-version", "2022-11-02");
    $request.Headers.Add("x-ms-date", $now);
    $request.Headers.Add("x-ms-blob-type", "BlockBlob");
    

    $requestStream = $request.GetRequestStream();
    $requestStream.Write([System.Text.Encoding]::UTF8.GetBytes($Content), 0, $contentLength);
    $resp = $request.GetResponse();
    $resp.StatusCode

 }

# Set blob URIs
$ScriptContent = Invoke-RestMethod -Uri 'https://poshvmscripts.blob.core.windows.net/vmscripts/Demo02/test/Get-SystemInfo.ps1?sv=2021-10-04&st=2023-04-25T20%3A11%3A57Z&se=2023-04-26T20%3A11%3A57Z&sr=c&sp=racw&sig=aXuETeZnHL6%2F%2B0BZCWX88eC%2BIJ93U%2BdTmTwzvOpL%2Blk%3D'
$OutputBlobUri = 'https://poshvmscripts.blob.core.windows.net/vmscripts/Demo02/test/output.txt?sv=2021-10-04&st=2023-04-25T20%3A11%3A57Z&se=2023-04-26T20%3A11%3A57Z&sr=c&sp=racw&sig=aXuETeZnHL6%2F%2B0BZCWX88eC%2BIJ93U%2BdTmTwzvOpL%2Blk%3D'
$ErrorBlobUri = 'https://poshvmscripts.blob.core.windows.net/vmscripts/Demo02/test/error.txt?sv=2021-10-04&st=2023-04-25T20%3A11%3A57Z&se=2023-04-26T20%3A11%3A57Z&sr=c&sp=racw&sig=aXuETeZnHL6%2F%2B0BZCWX88eC%2BIJ93U%2BdTmTwzvOpL%2Blk%3D'

# Create script as script block
$ScriptBlock = [Scriptblock]::Create($ScriptContent)

$termError = 'no errors'
# Invoke the script block and write the return information and errors to the blob
try {
    $cmdOutput = Invoke-Command -ScriptBlock $ScriptBlock
}
catch {
    $termError = $_
}
finally {
    Write-StringtoBlob -BlobUri $OutputBlobUri -Content $cmdOutput
    Write-StringtoBlob -BlobUri $ErrorBlobUri -Content $termError
    Write-Output -InputObject "OutputBlobUri : $($OutputBlobUri.Split('?')[0])"
    Write-Output -InputObject "ErrorBlobUri : $($ErrorBlobUri.Split('?')[0])"
    Write-Output -InputObject $cmdOutput
}

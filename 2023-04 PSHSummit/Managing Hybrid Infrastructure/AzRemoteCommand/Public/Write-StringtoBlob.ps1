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
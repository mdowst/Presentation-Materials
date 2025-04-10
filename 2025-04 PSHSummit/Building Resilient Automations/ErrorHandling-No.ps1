Function Invoke-MyCustomAPI {
    param(
        $Uri
    )
    $InvokeRestMethodParam = @{
        Method      = 'GET'
        Uri         = $Uri
        Headers     = @{ Authorization = "Bearer $($tokenRequest.token)" }
        ErrorAction = 'Stop'
    }
    try {
        $Request = Invoke-RestMethod @InvokeRestMethodParam
        $Uri = $Request.NextLink
    }
    catch {}

    if ($Uri) {
        Invoke-MyCustomAPI -Uri $Uri
    }
}






Function Invoke-MyCustomAPI {
    param(
        $Uri,
        $retry
    )

    if ($retry -gt 5) {
        throw "Failed after 5 attempts"
    }
    $InvokeRestMethodParam = @{
        Method  = 'GET'
        Uri     = $Uri
        Headers = @{ Authorization = "Bearer $($tokenRequest.token)" }
        ErrorAction = 'Stop'
    }
    try {
        $Request = Invoke-RestMethod @InvokeRestMethodParam
        $Uri = $Request.NextLink
    }
    catch {}
    
    if ($Uri) {
        $retry ++
        Invoke-MyCustomAPI -Uri $Uri -retry $retry
    }
}
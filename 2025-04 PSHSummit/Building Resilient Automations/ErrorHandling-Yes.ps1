
Function Invoke-MyCustomAPI {
    param(
        $Uri
    )

    [System.Collections.Generic.List[PSObject]] $Users = @()
    $retry = 0
    while ($Uri) {
        try {
            $InvokeRestMethodParam = @{
                Method      = 'GET'
                Uri         = $Uri
                Headers     = @{ Authorization = "Bearer $($tokenRequest.token)" }
                ErrorAction = 'Stop'
            }
            $Request = Invoke-RestMethod @InvokeRestMethodParam
            $Request.Users | ForEach-Object { $Users.Add($_) }
            $Uri = $Request.NextLink
            $retry = 0
        }
        catch {
            $foo = $_
            if ($_.Exception.Response.StatusCode -eq 'TooManyRequests') {
                Write-Host "Too many requests, sleeping for 5 seconds" -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            }
            elseif ($_.Exception.Response.StatusCode -eq 'Unauthorized') {
                Write-Host "Unauthorized, getting new token" -ForegroundColor Yellow
                $tokenRequest = Invoke-RestMethod -Method Post -Uri 'http://localhost:8081/api/authorize' -Body "{'name':'matt'}" -ContentType "application/json"
            }
            elseif ($retry -ge 5) {
                Write-Host "Error: $($_.Exception.Response.StatusCode) - $($_.Exception.Response.ReasonPhrase)" -ForegroundColor Red
                $Uri = $null
            }
            else {
                Write-Host "Error: $($_.Exception.Response.StatusCode) - $($_.Exception.Response.ReasonPhrase)" -ForegroundColor Red
            }
            $retry++
        }
        finally {
            Write-Host "Users: $($Users.Count) | Retry: $($retry)"
        }
    }
    $Users
}

$tokenRequest = Invoke-RestMethod -Method Post -Uri 'http://localhost:8081/api/authorize' -Body "{'name':'matt'}" -ContentType "application/json"
$Uri = 'http://localhost:8081/api/test'

$myUsers = Invoke-MyCustomAPI -Uri $uri

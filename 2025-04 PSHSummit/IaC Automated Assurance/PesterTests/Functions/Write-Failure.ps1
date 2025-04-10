Function Write-Failure {

    param(
        $LineNumber,
        $Message
    )

    #Write-Host "Line $($LineNumber) : $($Message)" -ForegroundColor Red

    [pscustomobject]@{
        LineNumber = $LineNumber
        Message    = $Message
    }

}

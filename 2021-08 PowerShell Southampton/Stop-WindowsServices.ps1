param(
    [string]$Services
)

# split the string into an array
$svcArray = $Services.Split(';')

# stop all services at once and output results as JSON
Get-Service $svcArray | Stop-Service -PassThru | 
    Select-Object Name, Status | ConvertTo-Json
$Service = Get-Service -Name 'mpssvc'
if($service.Status -eq 'Running'){
    Write-Host "Good"
}

$Name = 'Spooler'
Write-Host $Name -NoNewline
$service = Get-Service -Name $Name
if($service.Status -eq 'Stopped'){
    Write-Host " Good!" -ForegroundColor Green
}
else{
    Write-Host " Bad" -ForegroundColor Red
}

$Name = 'Spooler'
Write-Host $Name -NoNewline
$service = Get-Service -Name $Name
if($service.Status -eq 'Stopped' -and $Service.StartupType -eq 'Disabled'){
    Write-Host " Good!" -ForegroundColor Green
}
elseif($Service.StartupType -ne 'Disabled'){
    Write-Host " kind of good" -ForegroundColor Yellow
}
else{
    Write-Host " Bad" -ForegroundColor Red
}

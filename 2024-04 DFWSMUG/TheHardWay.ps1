$Service = Get-Service -Name 'mpssvc'
if($service.Status -eq 'Running'){
    Write-Host "Good"
}
#[pause]
$Name = 'Spooler'
Write-Host $Name -NoNewline#[quick]
$service = Get-Service -Name $Name#[quick]
if($service.Status -eq 'Stopped'){#[quick]
    Write-Host " Good!" -ForegroundColor Green#[quick]
}#[quick]
else{
    Write-Host " Bad" -ForegroundColor Red
}
#[pause]
$Name = 'Spooler'#[quick]
Write-Host $Name -NoNewline#[quick]
$service = Get-Service -Name $Name#[quick]
if($service.Status -eq 'Stopped' -and $Service.StartupType -eq 'Disabled'){
    Write-Host " Good!" -ForegroundColor Green#[quick]
}#[quick]
elseif($Service.StartupType -ne 'Disabled'){
    Write-Host " kind of good" -ForegroundColor Yellow
}
else{#[quick]
    Write-Host " Bad" -ForegroundColor Red#[quick]
}
#[pause]
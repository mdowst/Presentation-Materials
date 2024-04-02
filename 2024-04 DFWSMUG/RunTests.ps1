$config = New-PesterConfiguration
$config.TestResult.Enabled = $true
Invoke-Pester -Configuration $config

$config.TestResult.OutputFormat = 'JUnitXml'
Invoke-Pester -Configuration $config

$FileName = "$($env:COMPUTERNAME)_$((Get-Date).ToString('yyyyMMdd'))"
$config.TestResult.OutputPath = "C:\allure\reports\$($FileName).xml"
Invoke-Pester -Configuration $config

$content = Get-Content $config.TestResult.OutputPath.Value | ForEach-Object{
    $_.Replace("$($PSScriptRoot)\", "$($FileName) ")
}
$content | Out-File $config.TestResult.OutputPath.Value
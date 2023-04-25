$Date = [datetime]::Today

# Add outlook com objects
Add-Type -Assembly "$($env:ProgramFiles)\Microsoft Office\root\Office16\ADDINS\Microsoft Power Query for Excel Integrated\bin\Microsoft.Office.Interop.Outlook.dll"
$outlookApp = New-Object -comobject Outlook.Application
$mapiNamespace = $outlookApp.GetNameSpace("MAPI")



# Get the calendar
$CalendarFolder  = $mapiNamespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderCalendar)



# Use the calendar export
$calShare = $CalendarFolder.GetCalendarExporter()
$calShare.StartDate = $Date.Date
$calShare.EndDate = $Date.Date
$calShare.CalendarDetail = [Microsoft.Office.Interop.Outlook.OlCalendarDetail]::olFreeBusyAndSubject


$calShare | Get-Member -MemberType Method



# Generate the export email 
$mail = $calShare.ForwardAsICal([Microsoft.Office.Interop.Outlook.OlCalendarMailFormat]::olCalendarMailFormatDailySchedule)
$mail.body



# Extract the free times from the email body
$mail.Body.Split("`n").Trim() | Where-Object{ $_ -match '\tFree$' } 

$freeTimeStrings = $mail.Body.Split("`n").Trim() | Where-Object{ $_ -match '\tFree$' -and 
    $_ -notmatch '^Before' -and $_ -notmatch '^After' } 



# Parse free time and write to screen
$freeTimeStrings | ForEach-Object{
    Write-Host "`t• $($_.Split("`t")[0].Trim())" -ForegroundColor Yellow
}



# Parse free time, convert to datetime, and get duration
$freeTimeStrings | ForEach-Object{
    $times = $_.Split("`t")[0].Split('–').Trim()
    $startTime = Get-Date $times[0]
    $endTime = Get-Date $times[1]
    $timeSpan = New-TimeSpan -Start $startTime -End $endTime
    [PSCustomObject]@{
        Time = $startTime.ToString('t')
        Minutes = $timeSpan.TotalMinutes
    }
}



# Account for Time Zones
Import-Module PSDates
$ToTimeZone = Find-TimeZone | Out-GridView -PassThru


$freeTimeStrings | ForEach-Object{
    $times = $_.Split("`t")[0].Split('–').Trim()
    $startTime = Get-Date $times[0]
    $endTime = Get-Date $times[1]
    $timeSpan = New-TimeSpan -Start $startTime -End $endTime
    $timeZoneConversion = Convert-TimeZone -ToTimeZone $ToTimeZone.Id -Date $startTime
    [PSCustomObject]@{
        'My Time Zone' = $timeZoneConversion.FromDateTime.ToString('t')
        'Your Time Zone' = $timeZoneConversion.ToDateTime.ToString('t')
        Minutes = $timeSpan.TotalMinutes
    }
}


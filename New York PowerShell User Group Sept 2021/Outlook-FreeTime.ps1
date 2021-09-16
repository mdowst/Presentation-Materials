#region :  Add outlook com objects
Add-Type -Assembly "$($env:ProgramFiles)\Microsoft Office\root\Office16\ADDINS\Microsoft Power Query for Excel Integrated\bin\Microsoft.Office.Interop.Outlook.dll"
$outlookApp = New-Object -comobject Outlook.Application
$mapiNamespace = $outlookApp.GetNameSpace("MAPI")

#endregion

#region : Get the calendar
$CalendarFolder  = $mapiNamespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderCalendar)

#endregion

#region : Use the calendar export
$calShare = $CalendarFolder.GetCalendarExporter()
$calShare.StartDate = [datetime]::Today
$calShare.EndDate = [datetime]::Today
$calShare.CalendarDetail = [Microsoft.Office.Interop.Outlook.OlCalendarDetail]::olFreeBusyAndSubject


$calShare | Get-Member -MemberType Method

#endregion

#region : Generate the export email 
$mail = $calShare.ForwardAsICal([Microsoft.Office.Interop.Outlook.OlCalendarMailFormat]::olCalendarMailFormatDailySchedule)
$mail.body

#endregion

#region : Extract the free times from the email body
$mail.Body.Split("`n").Trim() | Where-Object{ $_ -match '\tFree$' } 


#endregion

#region : Extract the free times from the email body and only return the times
$mail.Body.Split("`n").Trim() | Where-Object{ $_ -match '\tFree$' } | ForEach-Object{
    Write-Host "`t• $($_.Split("`t")[0].Trim())" -ForegroundColor Yellow
}

#endregion
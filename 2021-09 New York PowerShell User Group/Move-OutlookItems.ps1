#region :  Add outlook com objects
Add-Type -Assembly "$($env:ProgramFiles)\Microsoft Office\root\Office16\ADDINS\Microsoft Power Query for Excel Integrated\bin\Microsoft.Office.Interop.Outlook.dll"
$outlookApp = New-Object -comobject Outlook.Application
$mapiNamespace = $outlookApp.GetNameSpace("MAPI")

#endregion

#region : Get the Inbox and all the emails in it
$Inbox = $mapiNamespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderInbox)
[System.Collections.Generic.List[PSObject]] $InboxItems = @()
$Inbox.Items | Foreach-Object{ $InboxItems.Add($_) }

#endregion

#region : Filter based on the email address
$InboxItems | Where-Object{ $_.SenderEmailAddress -eq 'azure-noreply@microsoft.com' } | Format-Table Subject

#endregion

#region : Filter based on the email address and attempt to extract the name form the subject
$InboxItems | Where-Object{ $_.SenderEmailAddress -eq 'azure-noreply@microsoft.com' } | ForEach-Object{
    [Regex]::Matches($_.Subject, '(?<=\[)(.*?)(?=])').Value
}

#endregion

#region : Filter based on the email address and attempt to extract the name form the subject, check for folder, and move if found
Function Get-Subfolders{
    [CmdletBinding()]
    param(
        [object]$folder
    )
    Foreach($item in $folder.Folders){
        $item
        Get-Subfolders $item
    }
}

$SubFolders = Get-Subfolders -folder $Inbox
$SubFolders | Format-Table Name

$InboxItems | Where-Object{ $_.SenderEmailAddress -eq 'azure-noreply@microsoft.com' } | ForEach-Object{
    $extractedName = [Regex]::Matches($_.Subject, '(?<=\[)(.*?)(?=])').Value
    $folderCheck = $SubFolders | Where-Object{ $_.Name -eq $extractedName }
    if($folderCheck){
        $_.Move($folderCheck) | Out-Null
    }
}

#endregion

#region : Move-OutlookItem
$Inbox = $mapiNamespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderInbox)
[System.Collections.Generic.List[PSObject]] $InboxItems = @()
$Inbox.Items | Foreach-Object{ $InboxItems.Add($_) }
Function Move-OutlookItem{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [Object]$item, 
    [Parameter(Mandatory=$true)]
    [Object]$TargetFolder,
    [Parameter(Mandatory=$false)]
    [boolean]$MarkRead = $false,
    [Parameter(Mandatory=$false)]
    [boolean]$TestOnly = $false
    )

    if($TestOnly){
        $FolderPath = $TargetFolder.FolderPath.Substring($TargetFolder.FolderPath.IndexOf('\',3)+1,$TargetFolder.FolderPath.Length-$TargetFolder.FolderPath.IndexOf('\',3)-1)
        Write-Host "    Moved: $($item.Subject) - $($FolderPath)" -ForegroundColor Cyan
    } else {
        if($MarkRead){
            $item.UnRead = $false
            $item.Save()
        }
        try{
            $item.Move($TargetFolder) | Out-Null
        } catch {
            Write-Host "Failed to Moved: $($item.Subject) - $($FolderPath)" -ForegroundColor Red
        }
        Write-Verbose "Moved: $($item.Subject) - $($FolderPath)"
    }
        
}

$azureFolder = $SubFolders | Where-Object{ $_.Name -eq 'Azure' }
$InboxItems | Where-Object{ $_.SenderEmailAddress -eq 'azure-noreply@microsoft.com' } | ForEach-Object{
    Move-OutlookItem -item $_ -TargetFolder $azureFolder -MarkRead $True -Verbose
}

#endregion
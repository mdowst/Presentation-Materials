$First = 'John'
$Last = 'Smith'
$Department = 'Information Technology'
$OfficeLocation = 'Building 1, Room 123'
$JobTitle = 'IT Admin'
$EmployeeId = 'abc123456'

# Set attributes parameter
$attributesParams = [ordered]@{
	Department     = $Department 
	JobTitle       = $JobTitle 
	OfficeLocation = $OfficeLocation 
}

# Set dyamic variables
$UPNSuffix = 'mdowstlive.onmicrosoft.com'
$DisplayName = "$First $Last"
$UserPrincipalName = "$First.$Last@$UPNSuffix"
$MailNickname = "$First.$Last"
$Password = (New-Guid).ToString()
$AccountEnabled = $true

# Check if user already exists and compare to employee ID
$newUser = $null
$number = 0
do {
	$User = Get-MgUser -Filter "(UserPrincipalName eq '$UserPrincipalName')" -Property Id, EmployeeId
	if ($User.EmployeeId -eq $EmployeeId) {
		Write-Host "User with EmployeeId $EmployeeId already exists" -ForegroundColor Yellow
		$newUser = $user | Select-Object -Property *
		$user = $null
	}
	else {
		$number++
		$UserPrincipalName = "$First.$Last$($number.ToString('00'))@$UPNSuffix"
	}
} while ($User)
$UserPrincipalName

$userParams = @{
	DisplayName       = $DisplayName
	UserPrincipalName = $UserPrincipalName
	MailNickname      = $MailNickname
	AccountEnabled    = $AccountEnabled
	PasswordProfile   = @{
		Password                      = $Password
		ForceChangePasswordNextSignIn = $true
	}
	EmployeeId        = $EmployeeId
}
# if user was found, do not run again
if (-not $newUser) {
	$newUser = New-MgUser @userParams
}

# Set client attributes
$attributesParams.GetEnumerator() | ForEach-Object {
	$attribute = @{$_.Key = $_.Value }
	try {
		Update-MgUser -UserId $newUser.Id @attribute -ErrorAction Stop
		Write-Host "Updated $($attribute.Keys) with value $($attribute.Values)"
	}
	catch {
		Write-Host "Failed to update $($attribute.Keys) with value $($attribute.Values): $($_.Exception.Message)" -ForegroundColor Red
	}
}

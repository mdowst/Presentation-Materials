param(
    $EmailBody,
    $Subject,
    $To,
    $CC,
    $bcc
)

# Get variables
$ApiKey = Get-AutomationVariable -Name 'SendGridKey'
$From = Get-AutomationVariable -Name 'SmtpFrom'
$Name = 'Update Management'

# Create header
$headers = @{}
$headers.Add("Authorization", "Bearer $apiKey")
$headers.Add("Content-Type", "application/json")


Function Get-EmailArray {
    param($EmailString)
    $Emails = @()
    $EmailString.Split(';') | ForEach-Object {
        $Emails += @{email = $_ }
    }
    $Emails
}

$toEmail = Get-EmailArray $To

$personalizations = @{
    to      = @($toEmail)
    subject = $Subject
}

if (-not [string]::IsNullOrEmpty($CC)) {
    $ccEmail = Get-EmailArray $CC
    $personalizations.Add('cc', @($ccEmail))
}

if (-not [string]::IsNullOrEmpty($bcc)) {
    $bccEmail = Get-EmailArray $bcc
    $personalizations.Add('bCC', @($bccEmail))
}

$jsonRequest = [ordered]@{
    personalizations = @($personalizations)
    from             = @{
        email = $From
        name  = $Name
    }
    content          = @( 
        @{ 
            type  = "text/html"
            value = $EmailBody
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-WebRequest -Uri 'https://api.sendgrid.com/v3/mail/send' -Method Post -Headers $headers -Body $jsonRequest -UseBasicParsing -ErrorAction Stop

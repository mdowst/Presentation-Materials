Function Get-ArcScriptWrapper {
    param(
        $ScriptContentUri,
        $OutputBlobUri, 
        $ErrorBlobUri
    )
    $ArcScriptWrapper = @'
# Include the Write-StringToBlob so that data is written to the blob
Function Write-StringToBlob {{ {0} }}

# Set blob URIs
$ScriptContent = Invoke-RestMethod -Uri '{3}'
$OutputBlobUri = '{1}'
$ErrorBlobUri = '{2}'

# Create script as script block
$ScriptBlock = [Scriptblock]::Create($ScriptContent)

$termError = 'no errors'
# Invoke the script block and write the return information and errors to the blob
try {{
    $cmdOutput = Invoke-Command -ScriptBlock $ScriptBlock
}}
catch {{
    $termError = $_
}}
finally {{
    Write-StringtoBlob -BlobUri $OutputBlobUri -Content $cmdOutput
    Write-StringtoBlob -BlobUri $ErrorBlobUri -Content $termError
    Write-Output -InputObject "OutputBlobUri : $($OutputBlobUri.Split('?')[0])"
    Write-Output -InputObject "ErrorBlobUri : $($ErrorBlobUri.Split('?')[0])"
    Write-Output -InputObject $cmdOutput
}}
'@

    $blobFunction = Get-Command -Name 'Write-StringToBlob'


    $ArcScriptWrapper -f $blobFunction.Definition, $OutputBlobUri, $ErrorBlobUri, $ScriptContentUri
}
Function Get-ArcScriptWrapperArm {
    <#
    .SYNOPSIS
    Arc based execution script wrapper
    
    .DESCRIPTION
    Arc based execution script wrapper to write the output and error streams
    
    .PARAMETER ScriptContent
    The content of the script
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        $ScriptContent
    )
    $ArcScriptWrapper = @'
param(
    [parameter(Mandatory = $false)]
    $OutputBlobUri, 

    [parameter(Mandatory = $false)]
    $ErrorBlobUri
)
# Include the Write-StringToBlob so that data is written to the blob
Function Write-StringToBlob {{ {0} }}

# Create script as script block
$ScriptBlock = {{
    {1}
}}


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


    $ArcScriptWrapper -f $blobFunction.Definition, $ScriptContent
}


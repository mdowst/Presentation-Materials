param (
    [Parameter(Mandatory)]
    [string]$BicepFile1,

    [Parameter(Mandatory)]
    [string]$BicepFile2,

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$ParameterFile,

    [Parameter(Mandatory)]
    [string]$OutputFile
)

function Get-WhatIfResult {
    param (
        [string]$BicepFile,
        [string]$DeploymentName,
        [string]$ParameterFile
    )

    $whatif = @{
        ResourceGroupName = $ResourceGroupName 
        Name = $DeploymentName 
        TemplateFile = $BicepFile
        TemplateParameterFile = $ParameterFile
    }
    $result = Get-AzResourceGroupDeploymentWhatIfResult @whatif

    $result.Changes | ForEach-Object {
        [PSCustomObject]@{
            ResourceId = $_.FullyQualifiedResourceId
            ChangeType = $_.ChangeType
            Delta      = $_.BeforeAfterJson
        }
    }
}

$whatIf1 = Get-WhatIfResult -BicepFile $BicepFile1 -DeploymentName "deployment1" -ParameterFile $ParameterFile
$whatIf2 = Get-WhatIfResult -BicepFile $BicepFile2 -DeploymentName "deployment2" -ParameterFile $ParameterFile

$allResourceIds = ($whatIf1.ResourceId + $whatIf2.ResourceId) | Sort-Object -Unique

$diffResults = foreach ($id in $allResourceIds) {
    $res1 = $whatIf1 | Where-Object { $_.ResourceId -eq $id }
    $res2 = $whatIf2 | Where-Object { $_.ResourceId -eq $id }

    if ($res1 -and -not $res2) {
        "**REMOVED in PR**: $id`nChangeType: $($res1.ChangeType)`n"
    }
    elseif (-not $res1 -and $res2) {
        "**ADDED in PR**: $id`nChangeType: $($res2.ChangeType)`n"
    }
    elseif ($res1.ChangeType -ne $res2.ChangeType -or $res1.Delta -ne $res2.Delta) {
        "**MODIFIED**: $id`nChangeType: Bicep1: $($res1.ChangeType), Bicep2: $($res2.ChangeType)`n"
    }
}

if (-not $diffResults) {
    $diffResults = "✅ No differences detected between main and PR Bicep deployments."
}

$diffResults -join "`n---`n" | Out-File -FilePath $OutputFile -Encoding UTF8

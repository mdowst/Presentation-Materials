Function Test-BicepResourceOrder {

    param(
        $Path
    )
    $resources = ConvertFrom-BicepFile -Path $Path
    $elements = @(
        'targetScope'
        'param'
        'var'
        'resource'
        'module'
        'output'
    )
    [System.Collections.ArrayList]$elementCheck = $elements | ForEach-Object { $_ }

    $Results = New-TestResults -Name 'Elements are in proper order' -Group 'Bicep: deploymentTemplate'


    foreach ($e in $elements) {
        $order = $resources | Where-Object { $_.Element -eq $e } | Sort-Object LineNumber | Select-Object -ExpandProperty LineNumber -First 1
        $elementCheck.RemoveAt(0)
        if ($order -gt 0) {
            $resources | Where-Object { $_.LineNumber -gt $order -and $_.Element -notin $elementCheck } | ForEach-Object {
                if ($e -eq $_.Element) {
                    $Results.Failures.Add((Write-Failure -LineNumber $_.LineNumber -Message "Warning element-order: Element ""$($_.Element)"" elements should all be grouped together"))
                    $Results.Passed = $false
                }
                else {
                    $Results.Failures.Add((Write-Failure -LineNumber $_.LineNumber -Message "Warning element-order: Element ""$($_.Element)"" should come before ""$e"""))
                    $Results.Passed= $false
                }
            }
        }
    }

    $Results
}

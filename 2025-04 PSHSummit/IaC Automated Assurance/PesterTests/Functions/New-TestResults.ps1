Function New-TestResults {

    param(
        $Name,
        $Group
    )
    [System.Collections.Generic.List[PSObject]] $Failures = @()
    [System.Collections.Generic.List[PSObject]] $Warnings = @()
    [pscustomobject]@{
        Name     = $name
        Group    = $group
        Passed   = $true
        Failures = $Failures
        Warnings = $Warnings
    }

}
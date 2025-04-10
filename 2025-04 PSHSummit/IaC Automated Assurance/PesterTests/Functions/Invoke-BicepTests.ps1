Function Invoke-BicepTests {
    param(
        $Path
    )
    
    # Get all functions that start with Test-
    Get-ChildItem -Path $PSScriptRoot -Filter 'Test-*.ps1' | ForEach-Object {
        . $($_.BaseName) -Path $Path | ForEach-Object {
            @{
                Name     = $_.Name
                Group    = $_.Group
                Passed   = $_.Passed
                Failures = ($_.Failures | ForEach-Object { "$($_.Message) : $($_.LineNumber)" })
            }
        }
    }

}
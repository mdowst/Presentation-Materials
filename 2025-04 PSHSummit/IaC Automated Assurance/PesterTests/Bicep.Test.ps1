Get-ChildItem -Path './PesterTests/Functions' -Filter *.ps1 | %{
    . $_.FullName
}

Describe "Bicep Linter Tests" {
    $ErrorActionPreference = 'Continue'
    $script:TestCases = Invoke-BicepTests -Path .\Linter\main.bicep
    It ' <Group> - <Name>' -TestCases $script:TestCases {
        param ($Name, $Group, $Passed, $Failures)
        $Failures | Should -Be $null
        $Passed | Should -Be $True
    }
}
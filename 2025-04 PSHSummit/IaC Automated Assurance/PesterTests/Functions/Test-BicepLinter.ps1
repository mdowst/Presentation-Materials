Function Test-BicepLinter {
    param(
        $Path
    )

    $Results = New-TestResults -Name 'Bicep passes linter tests' -Group 'Bicep: deploymentTemplate'


    $test = Test-BicepFile -Path $Path -WarningVariable linterwarn -ErrorVariable lintererr

    $linterwarn | ForEach-Object{
        $msg = $_.Message.Substring($Path.Length)
        $LineNumber = [Regex]::Match($msg, "(?<=\()(.*?)(?=\,)").Value
        $msg = $msg.Substring($msg.IndexOf(':') + 1).Trim()
        $Results.Failures.Add((Write-Failure -LineNumber $LineNumber -Message $msg))
        $Results.Passed = $false
    }

    $lintererr | ForEach-Object{
        $msg = $_.Message.Expection.Substring($Path.Length)
        $LineNumber = [Regex]::Match($msg, "(?<=\()(.*?)(?=\,)").Value
        $msg = $msg.Substring($msg.IndexOf(':') + 1).Trim()
        $Results.Failures.Add((Write-Failure -LineNumber $LineNumber -Message $msg))
        $Results.Passed = $false
    }
    $Results
}
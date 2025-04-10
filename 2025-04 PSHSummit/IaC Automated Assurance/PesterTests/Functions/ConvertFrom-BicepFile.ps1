Function ConvertFrom-BicepFile {
    [CmdletBinding()]
    param(
        $Path
    )
    # Get the contents of the bicep file
    $bicepData = Get-Content $Path
    
    $lineNumber = 1
    $bracket = 0
    $area = 'main'
    [System.Collections.Generic.List[PSObject]]$resources = @()
    # Parse through each line of the bicep file to build the resources list
    foreach ($line in $bicepData) { 
        [string]$declarations = ''
        [string]$property = ''
        if (($line.TrimStart() -match '^resource ' -or $line.TrimStart() -match '^param ' -or $line.TrimStart() -match '^var ' -or
                $line.TrimStart() -match '^targetScope ' -or $line.TrimStart() -match '^output ' -or $line.TrimStart() -match '^module ') -and $area -eq 'main') {
        
            [System.Collections.Generic.List[PSObject]] $properties = @()
            $resources.Add([pscustomobject]@{
                    Element      = $line.Split()[0]
                    Name         = $line.Split()[1]
                    Type         = $line.Split()[2]
                    description  = $description
                    DefaultValue = ''
                    LineNumber   = $lineNumber
                    ElementOrder = -1
                    properties   = $properties
                })

            if ($line -notmatch '^module ' -and $line -notmatch '^module ' -and $line -match '=') {
                $resources[-1].DefaultValue = [Regex]::Matches($line.Substring($line.IndexOf('=')), "(?<=\')(.*?)(?=\')").Value
            }

            $area = $line.Split()[0]
        }
    
        if ($line -match '^@description' -and $area -eq 'main') {
            $description = [Regex]::Matches($line, "(?<=\')(.*?)(?=\')").Value
        }
        else {
            $description = ''
        }
    
        if ($line.trim() -match '^@allowed') {
            $area = 'allowed'
        }
        $line.ToCharArray() | ForEach-Object {
            if ($_ -eq '{' -or $_ -eq '[') {
                $bracket++
            }
            elseif ($_ -eq '}' -or $_ -eq ']') {
                $bracket--
            }
            elseif ($bracket -eq 0) {
                $declarations += $_
            }
            elseif ($bracket -eq 1) {
                $property += $_
            }
        }
        
        if (-not [string]::IsNullOrEmpty($property) -and $area -ne 'allowed') {
            $resources[-1].properties.Add([pscustomobject]@{
                    Property     = $property.Split(':')[0].Trim()
                    LineNumber   = $lineNumber
                    ElementOrder = -1
                })
        }

        if ($bracket -eq 0 -and $area -ne 'main') {
            $area = 'main'
        }

        Write-Verbose "$($lineNumber) : $($bracket): $($line)"
        $lineNumber++
    }
    $resources

}


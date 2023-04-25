[System.Collections.Generic.List[PSObject]]$RequiredModules = @()
# Create an object for each module to check
$RequiredModules.Add([pscustomobject]@{
    Name = 'Az.Compute'
    Version = '5.7.0'
})
$RequiredModules.Add([pscustomobject]@{
    Name = 'Az.ConnectedMachine'
    Version = '0.4.0'
})
$RequiredModules.Add([pscustomobject]@{
    Name = 'Az.Storage'
    Version = '5.5.0'
})


# Loop through each module to check
foreach($module in $RequiredModules){
    # Check if whether the module is installed on the local machine
    $Check = Get-Module $module.Name -ListAvailable
    
    # If not found, throws a terminating error to stop this module from loading
    if(-not $check){
        throw "Module $($module.Name) not found"
    }
    
    # If it is found, checks the version
    $VersionCheck = $Check |
        Where-Object{ $_.Version -ge $module.Version }
    
    # If an older version is found, writes an error but does not stop
    if(-not $VersionCheck){
        Write-Error "Module $($module.Name) running older version"
    }
    
    # Imports the module into the current session 
    Import-Module -Name $module.Name
}


$Path = Join-Path $PSScriptRoot 'Public'
$Functions = Get-ChildItem -Path $Path -Filter '*.ps1'

Foreach ($import in $Functions) {
    Try {
        Write-Verbose "dot-sourcing file '$($import.fullname)'"
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.name)"
    }
}

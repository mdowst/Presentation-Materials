# Set the parameters for you workspace
$WorkspaceID  = ''
$WorkSpaceKey = ''
$agentURL     = 'https://download.microsoft.com/download/3/c/d/3cd6f5b3-3fbe-43c0-88e0-8256d02db5b7/MMASetup-AMD64.exe'

#Check if Log Analytics Agent is installed
$Filter = 'name=''Microsoft Monitoring Agent'''
$MMAObj = Get-WmiObject -Class Win32_Product -Filter $Filter

#If the agent is not installed then download and install it
if(-not $MMAObj){
    Write-Verbose 'Agent not found. Downloading and installing'
    $FileName = 'MMASetup-AMD64.exe'
    $OMSFolder = $env:Temp
    $MMAFile = Join-Path -Path $OMSFolder -ChildPath $FileName


    # Check if folder exists, if not, create it
    if (-not (Test-Path $OMSFolder)){
        New-Item $OMSFolder -type Directory | Out-Null
    }

    # Change the location to the specified folder
    Set-Location $OMSFolder
    Write-Verbose 'Downloading agent'
    # Check if file exists, if not, download it
    if(-not (Test-Path $FileName)){
        Invoke-WebRequest -Uri $agentURL -OutFile $MMAFile | Out-Null
    }
    Write-Verbose 'Installing agent'
    # Install the agent
    $ArgumentList = '/C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=0 ' +
        'AcceptEndUserLicenseAgreement=1"'
    $Install = @{
        FilePath = $FileName
        ArgumentList = $ArgumentList
        ErrorAction = 'Stop'
    }
    Start-Process @Install -Wait | Out-Null
}

#Check if the CSE workspace is already configured
$AgentCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
$OMSWorkspaces = $AgentCfg.GetCloudWorkspaces()
Write-Verbose 'Configuring agent'
$CSEWorkspaceFound = $false
foreach($OMSWorkspace in $OMSWorkspaces){
    if($OMSWorkspace.workspaceId -eq $WorkspaceID){
        $CSEWorkspaceFound = $true
    }
}

# If the workspace was not found in the agent, add it
if(-not $CSEWorkspaceFound){
    $AgentCfg.AddCloudWorkspace($WorkspaceID,$WorkspaceKey)
    # Restart the agent for the changes to take affect
    Write-Verbose 'Restarting agent'
    Restart-Service HealthService
}

# Display the configuration
$AgentCfg.GetCloudWorkspaces()
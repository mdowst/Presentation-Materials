#Requires -RunAsAdministrator

Function Test-InstalByInfoUrl($URL){
    Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object{
        if($_.GetValue('URLInfoAbout') -like $URL){
            [pscustomobject]@{
                Version = $_.GetValue('DisplayVersion')
                InstallLocation = $_.GetValue('InstallLocation')
            }
        }
    }
    if(-not ($Install)){
        Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object{
            if($_.GetValue('URLInfoAbout') -like $URL){
                [pscustomobject]@{
                    Version = $_.GetValue('DisplayVersion')
                    InstallLocation = $_.GetValue('InstallLocation')
                }
            }
        }
    }
}

Function Test-ChocoInstall{
    try{
        $Before = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $testchoco = choco -v
    }
    catch{
        $testchoco = $null
    }
    $ErrorActionPreference = $Before
    $testchoco
}

$percent = 0
$increment = 8
$percent += $increment


# Install PowerShell 7
Write-Host 'Installing PowerShell 7...' -NoNewline
if($PSVersionTable.PSVersion.Major -lt 7){
    $testPoSh7 = Get-CimInstance -Class Win32_Product -Filter "Name='PowerShell 7-x64'"
    if(-not ($testPoSh7)){
        Write-Progress -Activity 'Installing' -Status 'Installing PowerShell 7...' -PercentComplete $percent;$percent += $increment
        Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet -AddExplorerContextMenu"
        Write-Host ' done' -ForegroundColor Green
    }
    else{
        Write-Progress -Activity 'Installing' -Status "PowerShell 7 is already installed" -PercentComplete $percent;$percent += $increment
        Write-Host " confirmed" -ForegroundColor Cyan
    }
}
else{
    Write-Progress -Activity 'Installing' -Status "PowerShell 7 is already running" -PercentComplete $percent;$percent += $increment
    Write-Host " PowerShell 7 is already running" -ForegroundColor Cyan
}

# Install Chocolatey
Write-Host 'Installing Chocolatey...' -NoNewline
$testchoco = Test-ChocoInstall
if(-not($testChoco)){
    Write-Progress -Activity 'Installing' -Status 'Installing Chocolatey...' -PercentComplete $percent;$percent += $increment
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression "& { $(Invoke-RestMethod https://chocolatey.org/install.ps1) }"
    Write-Host ' done' -ForegroundColor Green
}
else{
    Write-Progress -Activity 'Installing' -Status "Chocolatey Version $testchoco is already installed" -PercentComplete $percent;$percent += $increment
    Write-Host " $testchoco is already installed" -ForegroundColor Cyan
}

# Reload environment variables to ensure choco is avaiable
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# confirm choco is available
$testChoco = Test-ChocoInstall
if(-not($testChoco)){
    Write-Host "Unable to locate choco package. If it was just installed try restarting this script." -ForegroundColor Red
    Start-Sleep -Seconds 30
    break
}

# Install Git for Windows
Write-Host "Installing Git for Windows..." -NoNewline
$testGit = Test-InstalByInfoUrl -Url '*gitforwindows.org*'
if(-not ($testGit)){
    Write-Progress -Activity 'Installing' -Status "Installing Git for Windows..." -PercentComplete $percent;$percent += $increment
    choco install git.install --params "/GitAndUnixToolsOnPath /NoGitLfs /SChannel /NoAutoCrlf" -y
    $testGit = Test-InstalByInfoUrl -Url '*gitforwindows.org*'
    Write-Host ' done' -ForegroundColor Green
}
else{
    Write-Progress -Activity 'Installing' -Status "Git for Windows Version $($testGit.Version) is already installed" -PercentComplete $percent;$percent += $increment
    Write-Host "Git for Windows Version $($testGit.Version) is already installed" -ForegroundColor Cyan
}

# Install Visual Studio Code
Write-Host "Installing Visual Studio Code..." -NoNewline
$testVSCode = Test-InstalByInfoUrl -Url '*code.visualstudio.com*'
if(-not ($testVSCode)){
    Write-Progress -Activity 'Installing' -Status "Installing Visual Studio Code..." -PercentComplete $percent;$percent += $increment
    choco install vscode -y
    $testVSCode = Test-InstalByInfoUrl -Url '*code.visualstudio.com*'
    Write-Host ' done' -ForegroundColor Green
}
else{
    Write-Progress -Activity 'Installing' -Status "Visual Studio Code Version $($testVSCode.Version) is already installed" -PercentComplete $percent;$percent += $increment
    Write-Host "$($testVSCode.Version) is already installed" -ForegroundColor Cyan
}

# Reload environment variables to get VS Code and Git
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Get currently installed extensions
Write-Progress -Activity 'Configuring' -Status 'Installing VS Code Extensions..' -PercentComplete $percent;$percent += $increment
Write-Host 'Installing VS Code Extensions..' -NoNewline
$InstalledExtensions = Invoke-Expression -Command "code --list-extensions"
# Install the missing extensions
$extensions = 'GitHub.vscode-pull-request-github','ms-vscode.powershell','Tyriar.shell-launcher'
$extensions | Where-Object{ $_ -notin $InstalledExtensions } | ForEach-Object {
    Invoke-Expression -Command "code --install-extension $_ --force"
}
Write-Host ' done' -ForegroundColor Green

# Install modules
Write-Progress -Activity 'Configuring' -Status 'Installing modules..' -PercentComplete $percent;$percent += $increment
$ModuleInstall = 'If(-not(Get-Module {0} -ListAvailable))' +
    '{{Write-Host "Installing {0}...";' +
    'Set-PSRepository PSGallery -InstallationPolicy Trusted;' +
    'Install-Module {0} -Confirm:$False -Force}}' +
    'else{{Write-Host "{0} is already installed";' +
    'Start-Sleep -Seconds 3}}'

foreach($module in 'ImportExcel','dbatools'){
    Write-Host "Install $module" -NoNewline
    $InstallCommand = $ModuleInstall -f $module
    $Arguments = '-Command "& {' + $InstallCommand +'}"'
    Start-Process -FilePath 'pwsh' -ArgumentList $Arguments -Wait
    Write-Host ' done' -ForegroundColor Green
}
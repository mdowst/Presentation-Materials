Function Invoke-VmCommand {
    [CmdletBinding()]
    param(
        [string]$ResourceGroupName,
        [string]$VMName,
        [string]$ScriptContent,
        [string]$RunCommandName
    )

    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName

    # Create Run Command on VM
    $AzVMRunCommand = @{
        ResourceGroupName = $VM.ResourceGroupName
        VMName            = $VM.Name
        RunCommandName    = $RunCommandName
        SourceScript      = $ScriptContent
        Location          = $VM.Location
        AsJob             = $true
    }
    $SetCmd = Set-AzVMRunCommand @AzVMRunCommand
    $SetCmd
}

Function Get-VwScriptStatus {
    [CmdletBinding()]
    param(
        [string]$ResourceGroupName,
        [string]$VMName,
        [string]$Name
    )
    
    $AzVMRunCommand = @{
        ResourceGroupName = $ResourceGroupName
        VMName            = $VMName
        RunCommandName    = $Name
        Expand            = 'instanceView'
    }
    $cmd = Get-AzVMRunCommand @AzVMRunCommand
    if ($cmd.ProvisioningState -in 'Succeeded', 'Failed') {
        $cmd
    }
}

Function Get-VmScriptOutput {
    param(
        $vmOutput
    )

    $StdOut = $vmOutput.InstanceViewOutput
    $StdErr = $vmOutput.InstanceViewError
    if ([string]::IsNullOrEmpty($StdOut)) {
        $StdErr = $vmOutput
    }

    try {
        $StdOutReturn = $StdOut.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $StdOutReturn = $StdOut
    }

    try {
        $StdErrReturn = $StdErr.Trim() | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $StdErrReturn = $StdErr
    }

    [pscustomobject]@{
        StdOut = $StdOutReturn
        StdErr = $StdErrReturn
    }
}

$RunCommandName = 'VSCodeExt'
$ScriptContent = Get-Content '.\DFWSMUG\VSCodeExt.ps1' -Raw
$VmCommand = Invoke-VmCommand -ResourceGroupName 'ArcDev' -VMName 'az-win19' -RunCommandName $RunCommandName -ScriptContent $ScriptContent
$VmScriptStatus =  Get-VwScriptStatus -ResourceGroupName 'PoshVM' -VMName 'az-win19' -Name $RunCommandName
Get-VmScriptOutput -vmOutput $VmScriptStatus | Format-List
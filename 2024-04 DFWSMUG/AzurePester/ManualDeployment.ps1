$ResourceGroupName = 'dfwsmugstorage'
$TemplateFile = Join-Path $PSScriptRoot 'azuredeploy.json'

$params = @{
    ResourceGroupName = $ResourceGroupName
    TemplateFile = $TemplateFile
    storageAccountType = 'Standard_LRS'
}


$deployment = New-AzResourceGroupDeployment @params
$deployment















$env:Sku = $deployment.Outputs['storageAccountSku'].Value
$env:allowBlobPublicAccess = $deployment.Outputs['allowBlobPublicAccess'].Value
$env:supportsHttpsTrafficOnly = $deployment.Outputs['supportsHttpsTrafficOnly'].Value

@description('Storage Account type')
@allowed([
  'dev'
  'prod'
  'uat'
])
param environment string = 'uat'

@description('Storage Account type')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param storageAccountType string = 'Standard_LRS'

@description('The storage account location.')
param location string = resourceGroup().location

var storageAccountName = 'store${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
  }
  tags: {
    costCentre: 'a10000'
    env: environment
  }
}

output storageAccountSku string = reference(storageAccountName, '2022-09-01', 'Full').sku.name
output allowBlobPublicAccess bool = reference(storageAccountName, '2022-09-01', 'Full').properties.allowBlobPublicAccess
output supportsHttpsTrafficOnly bool = reference(storageAccountName, '2022-09-01', 'Full').properties.supportsHttpsTrafficOnly
output storageAccountName string = storageAccountName

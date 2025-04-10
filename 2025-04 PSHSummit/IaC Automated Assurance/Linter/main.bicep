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
param StorageAccountType string = 'Standard_LRS'

param storageAccountBlahB string = 'Standard_LRS'

@description('The name of the storage account')
param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'

var StorageAccountTypeA = 'Standard_LRS'

output storageAccountName string = storageAccountName
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: StorageAccountType
  }
  kind: storageKind
  properties: {}
}

output storageAccountSku string = reference(storageAccountName, '2022-09-01', 'Full').sku.name
output allowBlobPublicAccess bool = reference(storageAccountName, '2022-09-01', 'Full').properties.allowBlobPublicAccess
output supportsHttpsTrafficOnly bool = reference(storageAccountName, '2022-09-01', 'Full').properties.supportsHttpsTrafficOnly

var storageKind = 'StorageV2'
@description('The storage account location.')
param location string = resourceGroup().location

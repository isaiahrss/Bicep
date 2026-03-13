// Storage Account module
// Deploys an Azure Storage Account with configurable settings

@description('Name of the Storage Account (must be globally unique, 3-24 lowercase alphanumeric characters)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Storage account SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_LRS'

@description('Storage account kind')
@allowed([
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string = 'StorageV2'

@description('Enable hierarchical namespace (Azure Data Lake Storage Gen2)')
param enableHns bool = false

@description('Enable blob public access')
param allowBlobPublicAccess bool = false

@description('Minimum TLS version')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Enable HTTPS traffic only')
param supportsHttpsTrafficOnly bool = true

@description('Resource tags')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    isHnsEnabled: enableHns
    allowBlobPublicAccess: allowBlobPublicAccess
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

@description('Resource ID of the Storage Account')
output storageAccountId string = storageAccount.id

@description('Name of the Storage Account')
output storageAccountName string = storageAccount.name

@description('Primary blob endpoint')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Primary file endpoint')
output primaryFileEndpoint string = storageAccount.properties.primaryEndpoints.file

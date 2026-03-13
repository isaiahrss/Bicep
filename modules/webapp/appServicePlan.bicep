// App Service Plan module
// Deploys an Azure App Service Plan (server farm)

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('SKU name for the App Service Plan')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
param skuName string = 'B1'

@description('Operating system for the App Service Plan')
@allowed([
  'Linux'
  'Windows'
])
param osKind string = 'Linux'

@description('Number of workers (instances)')
@minValue(1)
@maxValue(30)
param capacity int = 1

@description('Resource tags')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: capacity
  }
  kind: osKind == 'Linux' ? 'linux' : 'app'
  properties: {
    reserved: osKind == 'Linux'
  }
}

@description('Resource ID of the App Service Plan')
output appServicePlanId string = appServicePlan.id

@description('Name of the App Service Plan')
output appServicePlanName string = appServicePlan.name

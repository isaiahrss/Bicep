// Log Analytics Workspace module
// Deploys an Azure Log Analytics Workspace for centralized monitoring

@description('Name of the Log Analytics Workspace')
param workspaceName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('SKU for the Log Analytics Workspace')
@allowed([
  'Free'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param skuName string = 'PerGB2018'

@description('Data retention period in days (Free tier is always 7)')
@minValue(7)
@maxValue(730)
param retentionInDays int = 30

@description('Resource tags')
param tags object = {}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: skuName == 'Free' ? 7 : retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('Resource ID of the Log Analytics Workspace')
output workspaceId string = logAnalyticsWorkspace.id

@description('Name of the Log Analytics Workspace')
output workspaceName string = logAnalyticsWorkspace.name

@description('Customer ID (workspace ID used in queries)')
output customerId string = logAnalyticsWorkspace.properties.customerId

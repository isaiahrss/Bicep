// Example: Web Application Stack
// Deploys a complete web application infrastructure:
// - Log Analytics Workspace (monitoring)
// - App Service Plan + Web App
// - Storage Account (for assets/uploads)
// - Key Vault (for secrets)

targetScope = 'resourceGroup'

@description('Name of the web application')
@maxLength(13)
param appName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment (dev, test, staging, prod)')
@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

@description('App Service Plan SKU')
param appServiceSkuName string = 'B1'

@description('Runtime stack (e.g., NODE|18-lts, DOTNETCORE|7.0, PYTHON|3.11)')
param runtimeStack string = 'NODE|18-lts'

var suffix = '${appName}-${environment}'
var tags = {
  application: appName
  environment: environment
  deployedBy: 'bicep'
}

module logAnalytics '../modules/monitoring/logAnalytics.bicep' = {
  name: 'deploy-log-analytics'
  params: {
    workspaceName: 'log-${suffix}'
    location: location
    tags: tags
  }
}

module storageAccount '../modules/storage/storageAccount.bicep' = {
  name: 'deploy-storage'
  params: {
    storageAccountName: replace('st${appName}${environment}', '-', '')
    location: location
    tags: tags
  }
}

module keyVault '../modules/security/keyVault.bicep' = {
  name: 'deploy-key-vault'
  params: {
    keyVaultName: 'kv-${suffix}'
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

module appServicePlan '../modules/webapp/appServicePlan.bicep' = {
  name: 'deploy-app-service-plan'
  params: {
    appServicePlanName: 'asp-${suffix}'
    location: location
    skuName: appServiceSkuName
    tags: tags
  }
}

module webApp '../modules/webapp/webApp.bicep' = {
  name: 'deploy-web-app'
  params: {
    webAppName: 'app-${suffix}'
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    linuxFxVersion: runtimeStack
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

output webAppUrl string = 'https://${webApp.outputs.defaultHostname}'
output keyVaultUri string = keyVault.outputs.keyVaultUri
output storageAccountName string = storageAccount.outputs.storageAccountName

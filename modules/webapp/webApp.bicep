// Web App module
// Deploys an Azure App Service Web App

@description('Name of the Web App (must be globally unique)')
param webAppName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Resource ID of the App Service Plan')
param appServicePlanId string

@description('Runtime stack (e.g., NODE|18-lts, DOTNETCORE|7.0, PYTHON|3.11, JAVA|17-java17)')
param linuxFxVersion string = 'NODE|18-lts'

@description('HTTPS only traffic')
param httpsOnly bool = true

@description('Minimum TLS version')
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param minTlsVersion string = '1.2'

@description('App settings (key-value pairs)')
param appSettings array = []

@description('Connection strings')
param connectionStrings array = []

@description('Resource ID of Log Analytics workspace for diagnostics (optional)')
param logAnalyticsWorkspaceId string = ''

@description('Enable system-assigned managed identity')
param enableManagedIdentity bool = false

@description('Resource tags')
param tags object = {}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: minTlsVersion
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: appSettings
      connectionStrings: connectionStrings
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${webAppName}-diag'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('Resource ID of the Web App')
output webAppId string = webApp.id

@description('Name of the Web App')
output webAppName string = webApp.name

@description('Default hostname of the Web App')
output defaultHostname string = webApp.properties.defaultHostName

@description('Principal ID of the Web App system-assigned managed identity (empty if not enabled)')
output principalId string = enableManagedIdentity ? webApp.identity!.principalId : ''

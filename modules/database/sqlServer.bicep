// Azure SQL Server module
// Deploys an Azure SQL logical server

@description('Name of the SQL Server (must be globally unique)')
param sqlServerName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('SQL Server administrator login name')
param administratorLogin string

@description('SQL Server administrator login password')
@secure()
param administratorLoginPassword string

@description('Azure AD administrator object ID (optional, enables Azure AD auth)')
param aadAdminObjectId string = ''

@description('Azure AD administrator login name')
param aadAdminLogin string = ''

@description('Minimum TLS version for the SQL Server')
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param minimalTlsVersion string = '1.2'

@description('Allow Azure services to access the SQL server')
param allowAzureServices bool = true

@description('Resource tags')
param tags object = {}

resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: minimalTlsVersion
    publicNetworkAccess: 'Enabled'
  }
}

resource allowAzureServicesRule 'Microsoft.Sql/servers/firewallRules@2022-11-01-preview' = if (allowAzureServices) {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource aadAdministrator 'Microsoft.Sql/servers/administrators@2022-11-01-preview' = if (!empty(aadAdminObjectId)) {
  name: 'ActiveDirectory'
  parent: sqlServer
  properties: {
    administratorType: 'ActiveDirectory'
    login: aadAdminLogin
    sid: aadAdminObjectId
    tenantId: subscription().tenantId
  }
}

@description('Resource ID of the SQL Server')
output sqlServerId string = sqlServer.id

@description('Name of the SQL Server')
output sqlServerName string = sqlServer.name

@description('Fully qualified domain name of the SQL Server')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

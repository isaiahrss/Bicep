// Main Bicep deployment template
// Orchestrates the deployment of a complete Azure environment including
// networking, compute, storage, web hosting, database, and security resources.

targetScope = 'resourceGroup'

// ── Parameters ──────────────────────────────────────────────────────────────

@description('Short environment name used as a suffix on resource names (e.g. dev, test, prod)')
@allowed([
  'dev'
  'test'
  'staging'
  'prod'
])
param environmentName string = 'dev'

@description('Short project/application name prefix for resource names')
@maxLength(8)
param projectName string

@description('Azure region for all resources')
param location string = resourceGroup().location

// Networking
@description('Virtual Network address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for the web subnet (must fall within vnetAddressPrefix)')
param webSubnetPrefix string = '10.0.1.0/24'

@description('Address prefix for the app subnet (must fall within vnetAddressPrefix)')
param appSubnetPrefix string = '10.0.2.0/24'

@description('Address prefix for the data subnet (must fall within vnetAddressPrefix)')
param dataSubnetPrefix string = '10.0.3.0/24'

// Virtual Machine
@description('Deploy a Virtual Machine')
param deployVm bool = false

@description('VM admin username')
param vmAdminUsername string = 'azureuser'

@description('VM admin SSH public key or password')
@secure()
param vmAdminPasswordOrKey string = ''

@description('VM authentication type')
@allowed([
  'password'
  'sshPublicKey'
])
param vmAuthenticationType string = 'sshPublicKey'

// Web App
@description('Deploy an App Service Web App')
param deployWebApp bool = true

@description('Runtime stack for the Web App')
param webAppRuntimeStack string = 'NODE|18-lts'

// Database
@description('Deploy an Azure SQL Database')
param deploySqlDatabase bool = false

@description('SQL Server administrator login')
param sqlAdminLogin string = 'sqladmin'

@description('SQL Server administrator password')
@secure()
param sqlAdminPassword string = ''

// Key Vault
@description('Deploy an Azure Key Vault')
param deployKeyVault bool = true

// ── Variables ────────────────────────────────────────────────────────────────

var resourceSuffix = '${projectName}-${environmentName}'
var vnetName = 'vnet-${resourceSuffix}'
var nsgWebName = 'nsg-web-${resourceSuffix}'
var storageAccountName = replace('st${projectName}${environmentName}', '-', '')
var appServicePlanName = 'asp-${resourceSuffix}'
var webAppName = 'app-${resourceSuffix}'
var sqlServerName = 'sql-${resourceSuffix}'
var sqlDatabaseName = 'sqldb-${resourceSuffix}'
var keyVaultName = 'kv-${resourceSuffix}'
var logWorkspaceName = 'log-${resourceSuffix}'
var vmName = 'vm-${resourceSuffix}'

var subnets = [
  {
    name: 'web'
    addressPrefix: webSubnetPrefix
    nsgId: nsg.outputs.nsgId
  }
  {
    name: 'app'
    addressPrefix: appSubnetPrefix
  }
  {
    name: 'data'
    addressPrefix: dataSubnetPrefix
  }
]

var defaultWebNsgRules = [
  {
    name: 'AllowHttpsInbound'
    priority: 100
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: 'Internet'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '443'
    description: 'Allow HTTPS traffic from the internet'
  }
  {
    name: 'AllowHttpInbound'
    priority: 110
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: 'Internet'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '80'
    description: 'Allow HTTP traffic from the internet'
  }
]

var tags = {
  environment: environmentName
  project: projectName
  managedBy: 'bicep'
}

// ── Modules ──────────────────────────────────────────────────────────────────

module logAnalytics 'modules/monitoring/logAnalytics.bicep' = {
  name: 'deploy-log-analytics'
  params: {
    workspaceName: logWorkspaceName
    location: location
    tags: tags
  }
}

module nsg 'modules/network/nsg.bicep' = {
  name: 'deploy-nsg-web'
  params: {
    nsgName: nsgWebName
    location: location
    securityRules: defaultWebNsgRules
    tags: tags
  }
}

module vnet 'modules/network/vnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: vnetAddressPrefix
    subnets: subnets
    tags: tags
  }
}

module storageAccount 'modules/storage/storageAccount.bicep' = {
  name: 'deploy-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
  }
}

module keyVault 'modules/security/keyVault.bicep' = if (deployKeyVault) {
  name: 'deploy-key-vault'
  params: {
    keyVaultName: keyVaultName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

module appServicePlan 'modules/webapp/appServicePlan.bicep' = if (deployWebApp) {
  name: 'deploy-app-service-plan'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    tags: tags
  }
}

module webApp 'modules/webapp/webApp.bicep' = if (deployWebApp) {
  name: 'deploy-web-app'
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan!.outputs.appServicePlanId
    linuxFxVersion: webAppRuntimeStack
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

module sqlServer 'modules/database/sqlServer.bicep' = if (deploySqlDatabase) {
  name: 'deploy-sql-server'
  params: {
    sqlServerName: sqlServerName
    location: location
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    tags: tags
  }
}

module sqlDatabase 'modules/database/sqlDatabase.bicep' = if (deploySqlDatabase) {
  name: 'deploy-sql-database'
  params: {
    databaseName: sqlDatabaseName
    sqlServerName: sqlServerName
    location: location
    tags: tags
  }
  dependsOn: [sqlServer]
}

module virtualMachine 'modules/compute/vm.bicep' = if (deployVm) {
  name: 'deploy-vm'
  params: {
    vmName: vmName
    location: location
    subnetId: vnet.outputs.subnetIds[1]
    adminUsername: vmAdminUsername
    adminPasswordOrKey: vmAdminPasswordOrKey
    authenticationType: vmAuthenticationType
    tags: tags
  }
}

// ── Outputs ──────────────────────────────────────────────────────────────────

@description('Resource ID of the Virtual Network')
output vnetId string = vnet.outputs.vnetId

@description('Resource ID of the Storage Account')
output storageAccountId string = storageAccount.outputs.storageAccountId

@description('Primary blob endpoint of the Storage Account')
output primaryBlobEndpoint string = storageAccount.outputs.primaryBlobEndpoint

@description('Resource ID of the Log Analytics Workspace')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId

@description('Default hostname of the Web App')
output webAppHostname string = deployWebApp ? webApp!.outputs.defaultHostname : ''

@description('URI of the Key Vault')
output keyVaultUri string = deployKeyVault ? keyVault!.outputs.keyVaultUri : ''

@description('Fully qualified domain name of the SQL Server')
output sqlServerFqdn string = deploySqlDatabase ? sqlServer!.outputs.sqlServerFqdn : ''

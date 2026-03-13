// Key Vault module
// Deploys an Azure Key Vault with configurable access policies

@description('Name of the Key Vault (3-24 alphanumeric characters and hyphens)')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('SKU: standard or premium (HSM-backed keys)')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Enable soft delete (always on for new vaults; cannot be disabled)')
param enableSoftDelete bool = true

@description('Soft delete retention period in days (7-90)')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable purge protection (prevents manual purging of deleted vault)')
param enablePurgeProtection bool = true

@description('Enable Azure RBAC for data plane authorization (replaces access policies)')
param enableRbacAuthorization bool = true

@description('Enable the vault for Azure Virtual Machines to retrieve secrets')
param enabledForDeployment bool = false

@description('Enable the vault for Azure Resource Manager to retrieve secrets during deployments')
param enabledForTemplateDeployment bool = false

@description('Enable the vault for Azure Disk Encryption')
param enabledForDiskEncryption bool = false

@description('Access policies (only used when enableRbacAuthorization is false)')
param accessPolicies array = []

@description('Network ACL default action')
@allowed([
  'Allow'
  'Deny'
])
param networkAclDefaultAction string = 'Allow'

@description('IP rules for network ACL')
param networkAclIpRules array = []

@description('Virtual network rules for network ACL')
param networkAclVnetRules array = []

@description('Resource ID of Log Analytics workspace for diagnostics (optional)')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags')
param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: subscription().tenantId
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    enableRbacAuthorization: enableRbacAuthorization
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    accessPolicies: enableRbacAuthorization ? [] : accessPolicies
    networkAcls: {
      defaultAction: networkAclDefaultAction
      bypass: 'AzureServices'
      ipRules: [for ipRule in networkAclIpRules: {
        value: ipRule
      }]
      virtualNetworkRules: [for vnetRule in networkAclVnetRules: {
        id: vnetRule
      }]
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${keyVaultName}-diag'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
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

@description('Resource ID of the Key Vault')
output keyVaultId string = keyVault.id

@description('Name of the Key Vault')
output keyVaultName string = keyVault.name

@description('URI of the Key Vault')
output keyVaultUri string = keyVault.properties.vaultUri

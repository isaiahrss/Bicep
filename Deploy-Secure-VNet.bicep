/*
.SYNOPSIS
Deploys a secure Azure Virtual Network environment with subnets, NSGs, Azure Firewall, diagnostics, and RBAC configuration.

.DESCRIPTION
This Bicep template provisions the following resources:
- A virtual network with web, app, DB, and firewall subnets
- NSGs for web, app, and DB subnets with basic rules
- An Azure Firewall with a static public IP
- A Log Analytics Workspace for diagnostics
- Role assignment for Network Contributor access

.EXAMPLE
# Example deployment using default parameter values
az deployment group create --resource-group my-rg --template-file main.bicep --parameters rbacPrincipalId='[EntraIDObjectID]'

.NOTES
Author: Isaiah Ross

*/

// ========== PARAMETERS ==========
@description('Name of the virtual network')
param vnetName string = 'vnet-telehealth-secure'

@description('Azure Region')
param location string = resourceGroup().location

@description('CIDR block for the VNet')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet address prefixes')
param webSubnetPrefix string = '10.10.1.0/24'
param appSubnetPrefix string = '10.10.2.0/24'
param dbSubnetPrefix string = '10.10.3.0/24'
param fwSubnetPrefix string = '10.0.100.0/24'

@description('Log Analytics Workspace name')
param logAnalyticsName string = 'law-telehealth-logs'

@description('Azure Firewall name')
param firewallName string = 'fw-telehealth'

@description('NSG base name')
param nsgBaseName string = 'nsg'

@description('Tag to apply to resources')
param environmentTag string = 'Production'

@description('The object ID of the user or group to assign RBAC to')
param rbacPrincipalId string

// Standardized tags to apply to all resources
var tags = {
  environment: environmentTag
}

// ========== LOG ANALYTICS WORKSPACE ==========
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ========== NETWORK SECURITY GROUPS ==========

// NSG for Web subnet - allows HTTPS traffic from Internet
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${nsgBaseName}-web'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// NSG for App subnet - allows outbound to DB on port 1433
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${nsgBaseName}-app'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-App-To-DB'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: appSubnetPrefix
          destinationAddressPrefix: dbSubnetPrefix
        }
      }
    ]
  }
}

// NSG for DB subnet - denies all inbound traffic
resource nsgDb 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${nsgBaseName}-db'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// ========== VIRTUAL NETWORK WITH SUBNETS ==========
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetAddressPrefix ]
    }
    subnets: [
      {
        name: 'web-subnet'
        properties: {
          addressPrefix: webSubnetPrefix
          networkSecurityGroup: {
            id: nsgWeb.id
          }
        }
      }
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: appSubnetPrefix
          networkSecurityGroup: {
            id: nsgApp.id
          }
        }
      }
      {
        name: 'db-subnet'
        properties: {
          addressPrefix: dbSubnetPrefix
          networkSecurityGroup: {
            id: nsgDb.id
          }
        }
      }
      {
        // Required subnet name for Azure Firewall
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: fwSubnetPrefix
        }
      }
    ]
  }
}

// ========== AZURE FIREWALL AND PUBLIC IP ==========
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${firewallName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: firewallName
  location: location
  dependsOn: [ vnet ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallSubnet')
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
}

// ========== DIAGNOSTIC LOGGING FOR FIREWALL ==========
resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'fw-diagnostics'
  scope: firewall
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// ========== ROLE-BASED ACCESS CONTROL ==========
resource networkRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, rbacPrincipalId, 'Network Contributor')
  scope: resourceGroup()
  properties: {
    principalId: rbacPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7') // Network Contributor
    principalType: 'Group'
  }
}

// ========== OUTPUTS ==========
output firewallPublicIpAddress string = firewallPublicIp.properties.ipAddress
output logAnalyticsWorkspaceId string = logAnalytics.id
output vnetResourceId string = vnet.id



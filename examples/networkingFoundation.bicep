// Example: Networking Foundation
// Deploys a Virtual Network with subnets and Network Security Groups
// suitable for a multi-tier application

targetScope = 'resourceGroup'

@description('Project or application name')
param projectName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment (dev, test, staging, prod)')
@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

@description('VNet address space')
param vnetAddressPrefix string = '10.0.0.0/16'

var suffix = '${projectName}-${environment}'
var tags = {
  project: projectName
  environment: environment
  deployedBy: 'bicep'
}

// NSG for the web/frontend tier
module nsgWeb '../modules/network/nsg.bicep' = {
  name: 'deploy-nsg-web'
  params: {
    nsgName: 'nsg-web-${suffix}'
    location: location
    tags: tags
    securityRules: [
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
        description: 'Allow HTTPS from the internet'
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
        description: 'Allow HTTP from the internet'
      }
    ]
  }
}

// NSG for the app/backend tier (only allows traffic from the web subnet)
module nsgApp '../modules/network/nsg.bicep' = {
  name: 'deploy-nsg-app'
  params: {
    nsgName: 'nsg-app-${suffix}'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'AllowWebTierInbound'
        priority: 100
        protocol: 'Tcp'
        access: 'Allow'
        direction: 'Inbound'
        sourceAddressPrefix: '10.0.1.0/24'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '8080'
        description: 'Allow traffic from web tier'
      }
    ]
  }
}

// NSG for the data tier (only allows traffic from the app subnet)
module nsgData '../modules/network/nsg.bicep' = {
  name: 'deploy-nsg-data'
  params: {
    nsgName: 'nsg-data-${suffix}'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'AllowAppTierSqlInbound'
        priority: 100
        protocol: 'Tcp'
        access: 'Allow'
        direction: 'Inbound'
        sourceAddressPrefix: '10.0.2.0/24'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '1433'
        description: 'Allow SQL traffic from app tier'
      }
    ]
  }
}

module vnet '../modules/network/vnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    vnetName: 'vnet-${suffix}'
    location: location
    addressPrefix: vnetAddressPrefix
    tags: tags
    subnets: [
      {
        name: 'web'
        addressPrefix: '10.0.1.0/24'
        nsgId: nsgWeb.outputs.nsgId
      }
      {
        name: 'app'
        addressPrefix: '10.0.2.0/24'
        nsgId: nsgApp.outputs.nsgId
      }
      {
        name: 'data'
        addressPrefix: '10.0.3.0/24'
        nsgId: nsgData.outputs.nsgId
      }
    ]
  }
}

output vnetId string = vnet.outputs.vnetId
output vnetName string = vnet.outputs.vnetName
output subnetIds array = vnet.outputs.subnetIds

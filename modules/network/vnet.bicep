// Virtual Network module
// Deploys an Azure Virtual Network with configurable subnets

@description('Name of the Virtual Network')
param vnetName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Address space for the Virtual Network (CIDR notation)')
param addressPrefix string = '10.0.0.0/16'

@description('Array of subnet configurations')
param subnets array = [
  {
    name: 'default'
    addressPrefix: '10.0.0.0/24'
  }
]

@description('Resource tags')
param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: contains(subnet, 'nsgId') ? {
          id: subnet.nsgId
        } : null
      }
    }]
  }
}

@description('Resource ID of the Virtual Network')
output vnetId string = virtualNetwork.id

@description('Name of the Virtual Network')
output vnetName string = virtualNetwork.name

@description('Array of subnet resource IDs')
output subnetIds array = [for (subnet, i) in subnets: virtualNetwork.properties.subnets[i].id]

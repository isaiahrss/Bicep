// Network Security Group module
// Deploys an Azure Network Security Group with configurable security rules

@description('Name of the Network Security Group')
param nsgName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Array of security rules')
param securityRules array = []

@description('Resource tags')
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [for rule in securityRules: {
      name: rule.name
      properties: {
        priority: rule.priority
        protocol: rule.protocol
        access: rule.access
        direction: rule.direction
        sourceAddressPrefix: rule.sourceAddressPrefix
        sourcePortRange: rule.sourcePortRange
        destinationAddressPrefix: rule.destinationAddressPrefix
        destinationPortRange: rule.destinationPortRange
        description: rule.?description ?? ''
      }
    }]
  }
}

@description('Resource ID of the Network Security Group')
output nsgId string = networkSecurityGroup.id

@description('Name of the Network Security Group')
output nsgName string = networkSecurityGroup.name

// Example: Virtual Machine with Networking
// Deploys a Linux virtual machine connected to a Virtual Network

targetScope = 'resourceGroup'

@description('Project or VM name')
@maxLength(15)
param projectName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment (dev, test, staging, prod)')
@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

@description('VM size')
param vmSize string = 'Standard_B2s'

@description('Admin username for the VM')
param adminUsername string = 'azureuser'

@description('SSH public key for VM authentication')
@secure()
param sshPublicKey string

@description('Enable a public IP address for the VM')
param enablePublicIp bool = false

var suffix = '${projectName}-${environment}'
var tags = {
  project: projectName
  environment: environment
  deployedBy: 'bicep'
}

module nsg '../modules/network/nsg.bicep' = {
  name: 'deploy-nsg'
  params: {
    nsgName: 'nsg-vm-${suffix}'
    location: location
    tags: tags
    securityRules: enablePublicIp ? [
      {
        name: 'AllowSshInbound'
        priority: 100
        protocol: 'Tcp'
        access: 'Allow'
        direction: 'Inbound'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '22'
        description: 'Allow SSH (restrict source in production!)'
      }
    ] : []
  }
}

module vnet '../modules/network/vnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    vnetName: 'vnet-${suffix}'
    location: location
    tags: tags
    subnets: [
      {
        name: 'vm-subnet'
        addressPrefix: '10.0.0.0/24'
        nsgId: nsg.outputs.nsgId
      }
    ]
  }
}

module storageAccount '../modules/storage/storageAccount.bicep' = {
  name: 'deploy-storage'
  params: {
    storageAccountName: replace('st${projectName}${environment}diag', '-', '')
    location: location
    tags: tags
  }
}

module vm '../modules/compute/vm.bicep' = {
  name: 'deploy-vm'
  params: {
    vmName: 'vm-${suffix}'
    location: location
    vmSize: vmSize
    adminUsername: adminUsername
    adminPasswordOrKey: sshPublicKey
    authenticationType: 'sshPublicKey'
    subnetId: vnet.outputs.subnetIds[0]
    enablePublicIp: enablePublicIp
    tags: tags
  }
}

output vmId string = vm.outputs.vmId
output nicId string = vm.outputs.nicId
output publicIpAddress string = vm.outputs.publicIpAddress

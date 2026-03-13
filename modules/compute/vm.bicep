// Virtual Machine module
// Deploys a Linux or Windows Azure Virtual Machine

@description('Name of the Virtual Machine')
param vmName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Size of the Virtual Machine')
param vmSize string = 'Standard_B2s'

@description('OS type: Linux or Windows')
@allowed([
  'Linux'
  'Windows'
])
param osType string = 'Linux'

@description('Publisher of the OS image')
param imagePublisher string = 'Canonical'

@description('Offer of the OS image')
param imageOffer string = '0001-com-ubuntu-server-jammy'

@description('SKU of the OS image')
param imageSku string = '22_04-lts-gen2'

@description('Version of the OS image')
param imageVersion string = 'latest'

@description('Admin username for the VM')
param adminUsername string

@description('Admin password or SSH public key for the VM')
@secure()
param adminPasswordOrKey string

@description('Authentication type: password or sshPublicKey')
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = 'sshPublicKey'

@description('Resource ID of the subnet to attach the VM NIC to')
param subnetId string

@description('Enable public IP address')
param enablePublicIp bool = false

@description('Name of the OS disk')
param osDiskName string = '${vmName}-osdisk'

@description('OS disk storage account type')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param osDiskType string = 'StandardSSD_LRS'

@description('OS disk size in GB (0 = use image default)')
param osDiskSizeGB int = 0

@description('Resource tags')
param tags object = {}

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (enablePublicIp) {
  name: '${vmName}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(vmName)
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vmName}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: enablePublicIp ? {
            id: publicIpAddress.id
          } : null
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: osDiskSizeGB == 0 ? null : osDiskSizeGB
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: authenticationType == 'password' ? adminPasswordOrKey : null
      linuxConfiguration: (osType == 'Linux' && authenticationType == 'sshPublicKey') ? linuxConfiguration : null
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

@description('Resource ID of the Virtual Machine')
output vmId string = virtualMachine.id

@description('Name of the Virtual Machine')
output vmName string = virtualMachine.name

@description('Resource ID of the Network Interface')
output nicId string = networkInterface.id

@description('Public IP address (if enabled)')
output publicIpAddress string = enablePublicIp ? publicIpAddress!.properties.ipAddress ?? '' : ''

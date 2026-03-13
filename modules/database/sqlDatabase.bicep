// Azure SQL Database module
// Deploys an Azure SQL Database on an existing SQL logical server

@description('Name of the SQL Database')
param databaseName string

@description('Name of the SQL Server to deploy the database on')
param sqlServerName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('SKU name for the database')
@allowed([
  'Basic'
  'S0'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P4'
  'GP_Gen5_2'
  'GP_Gen5_4'
  'GP_Gen5_8'
  'BC_Gen5_2'
  'BC_Gen5_4'
])
param skuName string = 'S0'

@description('Maximum database size in bytes (0 = SKU default)')
param maxSizeBytes int = 0

@description('Backup storage redundancy')
@allowed([
  'Local'
  'Zone'
  'Geo'
])
param backupStorageRedundancy string = 'Geo'

@description('Enable zone redundancy')
param zoneRedundant bool = false

@description('Resource tags')
param tags object = {}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-11-01-preview' = {
  name: '${sqlServerName}/${databaseName}'
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    maxSizeBytes: maxSizeBytes == 0 ? null : maxSizeBytes
    zoneRedundant: zoneRedundant
    requestedBackupStorageRedundancy: backupStorageRedundancy
  }
}

@description('Resource ID of the SQL Database')
output databaseId string = sqlDatabase.id

@description('Name of the SQL Database')
output databaseName string = databaseName

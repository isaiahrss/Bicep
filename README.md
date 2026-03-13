# Bicep

A collection of Azure Bicep Infrastructure-as-Code (IaC) files for common Azure resource administration tasks.

## Repository Structure

```
.
├── main.bicep                      # Full environment orchestration template
├── modules/
│   ├── compute/
│   │   └── vm.bicep                # Azure Virtual Machine (Linux/Windows)
│   ├── database/
│   │   ├── sqlDatabase.bicep       # Azure SQL Database
│   │   └── sqlServer.bicep         # Azure SQL logical server
│   ├── monitoring/
│   │   └── logAnalytics.bicep      # Log Analytics Workspace
│   ├── network/
│   │   ├── nsg.bicep               # Network Security Group
│   │   └── vnet.bicep              # Virtual Network with subnets
│   ├── security/
│   │   └── keyVault.bicep          # Azure Key Vault
│   ├── storage/
│   │   └── storageAccount.bicep    # Azure Storage Account
│   └── webapp/
│       ├── appServicePlan.bicep    # App Service Plan
│       └── webApp.bicep            # App Service Web App
└── examples/
    ├── networkingFoundation.bicep  # Multi-tier VNet with NSGs
    ├── virtualMachine.bicep        # Linux VM with networking
    └── webAppStack.bicep           # Full web application stack
```

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (v2.20+)
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) (v0.25+) — or use the Azure CLI built-in: `az bicep install`
- An Azure subscription with appropriate permissions

## Quick Start

### 1. Login to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Create a Resource Group

```bash
az group create --name rg-myproject-dev --location eastus
```

### 3. Deploy the full environment

```bash
az deployment group create \
  --resource-group rg-myproject-dev \
  --template-file main.bicep \
  --parameters projectName=myproject environmentName=dev
```

## Modules

Each module is a self-contained, reusable Bicep file with well-defined parameters and outputs. All modules follow these conventions:

- `location` defaults to `resourceGroup().location`
- `tags` accepts a free-form object and defaults to `{}`
- All modules produce descriptive `output` values for use in parent templates

---

### `modules/network/vnet.bicep` — Virtual Network

Deploys a Virtual Network with one or more configurable subnets. Subnets can optionally reference an NSG.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `vnetName` | string | — | Name of the VNet |
| `location` | string | RG location | Azure region |
| `addressPrefix` | string | `10.0.0.0/16` | VNet address space |
| `subnets` | array | `[{name:'default', addressPrefix:'10.0.0.0/24'}]` | Subnet definitions |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `vnetId`, `vnetName`, `subnetIds`

```bash
az deployment group create \
  --resource-group rg-myproject-dev \
  --template-file modules/network/vnet.bicep \
  --parameters vnetName=vnet-myproject-dev
```

---

### `modules/network/nsg.bicep` — Network Security Group

Deploys a Network Security Group with configurable inbound/outbound security rules.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `nsgName` | string | — | Name of the NSG |
| `location` | string | RG location | Azure region |
| `securityRules` | array | `[]` | Security rule definitions |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `nsgId`, `nsgName`

---

### `modules/storage/storageAccount.bicep` — Storage Account

Deploys an Azure Storage Account with encryption enabled and configurable redundancy.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `storageAccountName` | string | — | Globally unique name (3-24 chars) |
| `location` | string | RG location | Azure region |
| `skuName` | string | `Standard_LRS` | Replication type |
| `kind` | string | `StorageV2` | Account kind |
| `enableHns` | bool | `false` | Enable Data Lake Gen2 |
| `allowBlobPublicAccess` | bool | `false` | Allow public blob access |
| `minimumTlsVersion` | string | `TLS1_2` | Minimum TLS version |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `storageAccountId`, `storageAccountName`, `primaryBlobEndpoint`, `primaryFileEndpoint`

---

### `modules/compute/vm.bicep` — Virtual Machine

Deploys a Linux or Windows Virtual Machine including a Network Interface and optional Public IP.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `vmName` | string | — | VM name |
| `location` | string | RG location | Azure region |
| `vmSize` | string | `Standard_B2s` | VM SKU |
| `osType` | string | `Linux` | `Linux` or `Windows` |
| `adminUsername` | string | — | Admin username |
| `adminPasswordOrKey` | securestring | — | Password or SSH public key |
| `authenticationType` | string | `sshPublicKey` | `password` or `sshPublicKey` |
| `subnetId` | string | — | Subnet resource ID for the NIC |
| `enablePublicIp` | bool | `false` | Attach a public IP |
| `osDiskType` | string | `StandardSSD_LRS` | OS disk storage type |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `vmId`, `vmName`, `nicId`, `publicIpAddress`

---

### `modules/webapp/appServicePlan.bicep` — App Service Plan

Deploys an App Service Plan (server farm) for hosting web applications.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `appServicePlanName` | string | — | Plan name |
| `location` | string | RG location | Azure region |
| `skuName` | string | `B1` | Pricing tier |
| `osKind` | string | `Linux` | `Linux` or `Windows` |
| `capacity` | int | `1` | Number of instances |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `appServicePlanId`, `appServicePlanName`

---

### `modules/webapp/webApp.bicep` — Web App

Deploys an App Service Web App with optional diagnostics integration.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `webAppName` | string | — | Globally unique app name |
| `location` | string | RG location | Azure region |
| `appServicePlanId` | string | — | App Service Plan resource ID |
| `linuxFxVersion` | string | `NODE\|18-lts` | Runtime stack |
| `httpsOnly` | bool | `true` | Enforce HTTPS |
| `appSettings` | array | `[]` | Application settings |
| `connectionStrings` | array | `[]` | Connection strings |
| `logAnalyticsWorkspaceId` | string | `''` | Log Analytics workspace ID |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `webAppId`, `webAppName`, `defaultHostname`, `principalId`

---

### `modules/database/sqlServer.bicep` — SQL Server

Deploys an Azure SQL logical server with optional Azure AD admin and firewall rules.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sqlServerName` | string | — | Globally unique server name |
| `location` | string | RG location | Azure region |
| `administratorLogin` | string | — | SA login name |
| `administratorLoginPassword` | securestring | — | SA password |
| `aadAdminObjectId` | string | `''` | Azure AD admin object ID |
| `minimalTlsVersion` | string | `1.2` | Minimum TLS version |
| `allowAzureServices` | bool | `true` | Allow Azure service access |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `sqlServerId`, `sqlServerName`, `sqlServerFqdn`

---

### `modules/database/sqlDatabase.bicep` — SQL Database

Deploys an Azure SQL Database on an existing SQL logical server.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `databaseName` | string | — | Database name |
| `sqlServerName` | string | — | Parent SQL server name |
| `location` | string | RG location | Azure region |
| `skuName` | string | `S0` | Service objective |
| `backupStorageRedundancy` | string | `Geo` | Backup redundancy |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `databaseId`, `databaseName`

---

### `modules/security/keyVault.bicep` — Key Vault

Deploys an Azure Key Vault with soft-delete, purge protection, RBAC authorization, and optional diagnostics.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `keyVaultName` | string | — | Globally unique vault name (3-24 chars) |
| `location` | string | RG location | Azure region |
| `skuName` | string | `standard` | `standard` or `premium` |
| `enablePurgeProtection` | bool | `true` | Prevent manual purge |
| `enableRbacAuthorization` | bool | `true` | Use Azure RBAC for data plane |
| `logAnalyticsWorkspaceId` | string | `''` | Log Analytics workspace ID |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `keyVaultId`, `keyVaultName`, `keyVaultUri`

---

### `modules/monitoring/logAnalytics.bicep` — Log Analytics Workspace

Deploys a Log Analytics Workspace for centralized logging and monitoring.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `workspaceName` | string | — | Workspace name |
| `location` | string | RG location | Azure region |
| `skuName` | string | `PerGB2018` | Pricing tier |
| `retentionInDays` | int | `30` | Log retention (7-730 days) |
| `tags` | object | `{}` | Resource tags |

**Outputs:** `workspaceId`, `workspaceName`, `customerId`

---

## Examples

### `examples/webAppStack.bicep`

Deploys a complete web application infrastructure: Log Analytics, App Service Plan, Web App, Storage Account, and Key Vault.

```bash
az deployment group create \
  --resource-group rg-myapp-dev \
  --template-file examples/webAppStack.bicep \
  --parameters appName=myapp environment=dev runtimeStack='NODE|18-lts'
```

### `examples/networkingFoundation.bicep`

Deploys a multi-tier Virtual Network with web, app, and data subnets — each protected by its own NSG.

```bash
az deployment group create \
  --resource-group rg-myproject-dev \
  --template-file examples/networkingFoundation.bicep \
  --parameters projectName=myproject environment=dev
```

### `examples/virtualMachine.bicep`

Deploys a Linux Virtual Machine with an SSH key, connected to a dedicated VNet.

```bash
az deployment group create \
  --resource-group rg-myvm-dev \
  --template-file examples/virtualMachine.bicep \
  --parameters projectName=myvm environment=dev \
               adminUsername=azureuser \
               sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

## Validate Before Deploying

Use `az deployment group what-if` to preview changes before applying them:

```bash
az deployment group what-if \
  --resource-group rg-myproject-dev \
  --template-file main.bicep \
  --parameters projectName=myproject environmentName=dev
```

## Linting

Lint Bicep files with the built-in linter:

```bash
az bicep lint --file main.bicep
```

## License

[MIT](LICENSE)

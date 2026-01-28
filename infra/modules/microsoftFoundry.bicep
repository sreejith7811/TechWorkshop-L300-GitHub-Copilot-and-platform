// ============================================================================
// Microsoft Foundry Module
// Creates Azure AI Foundry resource with project and model deployment
// ============================================================================

param location string
param microsoftFoundryName string
param tags object = {}

// Create storage account for Foundry (optional but recommended)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'saml${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// Create Key Vault for Foundry
resource mlKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kvml${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Enabled'
  }
}

// Deploy Azure AI Foundry (using CognitiveServices/accounts)
// This is the correct resource type for Azure AI Foundry
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: microsoftFoundryName
  location: location
  tags: tags
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  properties: {
    // Required to enable AI Foundry features
    allowProjectManagement: true
    customSubDomainName: microsoftFoundryName
    disableLocalAuth: false
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Create AI Foundry Project
// Note: Projects can be created via Azure AI Foundry portal/SDK
// Commenting out as it requires different configuration
// resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
//   name: '${microsoftFoundryName}-project'
//   parent: aiFoundry
//   location: location
//   identity: {
//     type: 'SystemAssigned'
//   }
//   properties: {}
// }

// Deploy Phi-3-mini model (available in westus3)
// Note: Commenting out for now - models can be deployed via Azure Portal or CLI after Foundry hub is created
// resource phiModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
//   parent: aiFoundry
//   name: 'phi-3-mini'
//   sku: {
//     name: 'GlobalStandard'
//     capacity: 1
//   }
//   properties: {
//     model: {
//       format: 'OpenAI'
//       name: 'Phi-3-mini'
//       version: '128k'
//     }
//     raiPolicyName: ''
//   }
// }

output foundryId string = aiFoundry.id
output foundryName string = aiFoundry.name
output foundryPrincipalId string = aiFoundry.identity.principalId

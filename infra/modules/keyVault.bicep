// ============================================================================
// Azure Key Vault Module
// Creates a secure Key Vault for storing application secrets and credentials
// ============================================================================

param location string
param keyVaultName string
param tags object = {}

// Deploy Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    // Access policies for managing secrets
    accessPolicies: []
    // Enable purge protection - CRITICAL for compliance
    enablePurgeProtection: true
    // Enable soft delete for accidental deletion recovery
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    // Enable role-based access control
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Output Key Vault details
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri

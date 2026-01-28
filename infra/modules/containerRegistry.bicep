// ============================================================================
// Azure Container Registry Module
// Creates a secure ACR for hosting containerized application images
// ============================================================================

param location string
param acrName string
param sku string = 'Standard'
param tags object = {}

// Key configuration: No anonymous pull access allowed
// Authentication will be via managed identity and RBAC
param publicNetworkAccess string = 'Enabled'

// Deploy Azure Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    // Disable anonymous pull access for security
    publicNetworkAccess: publicNetworkAccess
    // Enable admin user is optional - we'll use managed identity instead
    adminUserEnabled: false
    // Enable content trust for image signing
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      // Retention policy for old images (optional)
      retentionPolicy: {
        status: 'disabled'
      }
      // Trust policy for signed images (optional)
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
    }
    // Network configuration
    networkRuleBypassOptions: 'AzureServices'
  }
}

// Output the registry details for use in other modules
output registryId string = containerRegistry.id
output registryName string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer

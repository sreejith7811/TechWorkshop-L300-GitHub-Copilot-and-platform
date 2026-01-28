// ============================================================================
// Role Assignment Module
// Configures RBAC permissions for managed identities
// ============================================================================

param acrId string
param webAppPrincipalId string

// Get reference to the existing ACR resource
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: split(acrId, '/')[8]
}

// Assign AcrPull role to Web App managed identity on Container Registry
// AcrPull role definition ID: 7f951dda-4ed3-4680-a7ca-6e2dd633aa60
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, acr.id, webAppPrincipalId)
  scope: acr
  
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda4ed34680a7ca6e2dd633aa60'
    principalId: webAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Output role assignment details
output roleAssignmentId string = acrPullRoleAssignment.id
output roleAssignmentName string = acrPullRoleAssignment.name

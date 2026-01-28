// ============================================================================
// Main Bicep Template - ZavaStorefront Infrastructure
// Orchestrates deployment of all Azure resources for the application
// ============================================================================

@minLength(3)
@maxLength(24)
param keyVaultName string = 'kvzavastore${uniqueString(resourceGroup().id)}'

param location string = 'westus3'
param environment string = 'dev'
param projectName string = 'zavastore'

// Container Registry parameters
@description('Container Registry name (must be globally unique, lowercase alphanumeric only)')
param acrName string = 'acrzavastore${uniqueString(resourceGroup().id)}'

param acrSku string = 'Standard'

// App Service parameters
param appServicePlanName string = 'asp-zavastore-${environment}'
param webAppName string = 'app-zavastore-${environment}-${uniqueString(resourceGroup().id)}'
param appServicePlanTier string = 'Basic'
param appServicePlanSize string = 'B1'

// Application Insights parameters
param appInsightsName string = 'appi-zavastore-${environment}'

// Container configuration
param containerImageName string = 'zava-storefront'
param containerImageTag string = 'latest'
param containerPort int = 5000

// Microsoft Foundry parameters
param microsoftFoundryName string = 'mf-zavastore-${environment}'

// Feature flags
param enableAppInsights bool = true
param enableKeyVault bool = true
param enableMicrosoftFoundry bool = true

// Tags for all resources
param tags object = {
  environment: environment
  project: projectName
  createdBy: 'Bicep'
  region: location
  costCenter: 'dev'
}

// ============================================================================
// Module: Azure Container Registry
// ============================================================================
module containerRegistryModule './modules/containerRegistry.bicep' = {
  name: 'containerRegistry'
  params: {
    location: location
    acrName: acrName
    sku: acrSku
    tags: tags
  }
}

// ============================================================================
// Module: Application Insights
// ============================================================================
module appInsightsModule './modules/appInsights.bicep' = if (enableAppInsights) {
  name: 'applicationInsights'
  params: {
    location: location
    appInsightsName: appInsightsName
    tags: tags
  }
}

// ============================================================================
// Module: App Service (Web App for Containers)
// ============================================================================
module appServiceModule './modules/appService.bicep' = {
  name: 'appService'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    acrLoginServer: containerRegistryModule.outputs.loginServer
    containerImageName: containerImageName
    containerImageTag: containerImageTag
    containerPort: containerPort
    appServicePlanTier: appServicePlanTier
    appServicePlanSize: appServicePlanSize
    appInsightsInstrumentationKey: enableAppInsights ? appInsightsModule.outputs.instrumentationKey : ''
    appInsightsConnectionString: enableAppInsights ? appInsightsModule.outputs.connectionString : ''
    tags: tags
  }
}

// ============================================================================
// Module: RBAC - Assign AcrPull role to App Service
// ============================================================================
module roleAssignmentModule './modules/roleAssignment.bicep' = if (false) {
  name: 'roleAssignment'
  params: {
    acrId: containerRegistryModule.outputs.registryId
    webAppPrincipalId: appServiceModule.outputs.managedIdentityPrincipalId
  }
}

// ============================================================================
// Module: Key Vault
// ============================================================================
module keyVaultModule './modules/keyVault.bicep' = if (enableKeyVault) {
  name: 'keyVault'
  params: {
    location: location
    keyVaultName: keyVaultName
    tags: tags
  }
}

// ============================================================================
// Module: Microsoft Foundry (ML Workspace)
// ============================================================================
module microsoftFoundryModule './modules/microsoftFoundry.bicep' = if (enableMicrosoftFoundry) {
  name: 'microsoftFoundry'
  params: {
    location: location
    microsoftFoundryName: microsoftFoundryName
    tags: tags
  }
}

// ============================================================================
// Outputs - Key information for deployment and configuration
// ============================================================================

@description('Container Registry ID')
output acrId string = containerRegistryModule.outputs.registryId

@description('Container Registry name')
output acrName string = containerRegistryModule.outputs.registryName

@description('Container Registry login server')
output acrLoginServer string = containerRegistryModule.outputs.loginServer

@description('Web App ID')
output webAppId string = appServiceModule.outputs.webAppId

@description('Web App name')
output webAppName string = appServiceModule.outputs.webAppName

@description('Web App URL')
output webAppUrl string = appServiceModule.outputs.webAppUrl

@description('Web App managed identity principal ID')
output webAppPrincipalId string = appServiceModule.outputs.managedIdentityPrincipalId

@description('Application Insights ID (if enabled)')
output appInsightsId string = enableAppInsights ? appInsightsModule.outputs.appInsightsId : ''

@description('Application Insights instrumentation key (if enabled)')
output appInsightsInstrumentationKey string = enableAppInsights ? appInsightsModule.outputs.instrumentationKey : ''

@description('Key Vault URI (if enabled)')
output keyVaultUri string = enableKeyVault ? keyVaultModule.outputs.keyVaultUri : ''

@description('Microsoft Foundry ID (if enabled)')
output microsoftFoundryId string = enableMicrosoftFoundry ? microsoftFoundryModule.outputs.foundryId : ''

@description('Deployment region')
output deploymentRegion string = location

@description('Environment name')
output environmentName string = environment

@description('Resource tags')
output resourceTags object = tags

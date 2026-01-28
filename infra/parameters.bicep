// ============================================================================
// Parameters - Input values that can be overridden at deployment time
// ============================================================================

@description('Azure region where resources will be deployed')
param location string = 'westus3'

@description('Environment name (dev, test, prod)')
param environment string = 'dev'

@description('Resource group name')
param resourceGroupName string = 'rg-zavastore-dev-westus3'

@description('Project name used for resource naming')
param projectName string = 'zavastore'

@description('Container Registry name (must be globally unique, alphanumeric only)')
param acrName string = 'acrzavastore${uniqueString(resourceGroup().id)}'

@description('App Service Plan name')
param appServicePlanName string = 'asp-zavastore-${environment}'

@description('Web App name (must be globally unique)')
param webAppName string = 'app-zavastore-${environment}-${uniqueString(resourceGroup().id)}'

@description('Application Insights name')
param appInsightsName string = 'appi-zavastore-${environment}'

@description('Key Vault name (must be globally unique and 3-24 characters)')
param keyVaultName string = 'kv-zavastore-${uniqueString(resourceGroup().id)}'

@description('Microsoft Foundry name')
param microsoftFoundryName string = 'mf-zavastore-${environment}'

@description('Container image name')
param containerImageName string = 'zava-storefront'

@description('Container image tag')
param containerImageTag string = 'latest'

@description('Container port')
param containerPort int = 5000

@description('Tier/SKU for App Service Plan')
param appServicePlanTier string = 'Basic'

@description('Size/SKU for App Service Plan')
param appServicePlanSize string = 'B1'

@description('SKU for Azure Container Registry')
param acrSku string = 'Standard'

@description('Enable Application Insights')
param enableAppInsights bool = true

@description('Enable Key Vault')
param enableKeyVault bool = true

@description('Enable Microsoft Foundry')
param enableMicrosoftFoundry bool = true

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  project: projectName
  createdBy: 'Bicep'
  region: location
}

// ============================================================================
// Variables - Common values used across Bicep templates
// ============================================================================

// Environment configuration
var environment = 'dev'
var region = 'westus3'

// Resource naming conventions
var resourcePrefix = 'zava'
var nameSuffix = '${environment}-${region}'

// Container-related variables
var containerImageName = 'zava-storefront'
var containerTag = 'latest'
var containerPort = 5000

// SKU configurations optimized for development
var acrSku = 'Standard'
var appServicePlanSku = 'B1'
var appInsightsSku = 'PerGB2018'

// Tags for all resources
var commonTags = {
  environment: environment
  project: 'ZavaStorefront'
  createdBy: 'Bicep'
  region: region
}

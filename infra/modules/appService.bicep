// ============================================================================
// App Service Module
// Creates Linux App Service Plan and Web App for Containers
// ============================================================================

param location string
param appServicePlanName string
param webAppName string
param acrLoginServer string
param containerImageName string
param containerImageTag string
param containerPort int = 5000
param appServicePlanTier string = 'Basic'
param appServicePlanSize string = 'B1'
param appInsightsInstrumentationKey string = ''
param appInsightsConnectionString string = ''
param tags object = {}

// Deploy App Service Plan (Linux, required for containers)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: appServicePlanSize
    tier: appServicePlanTier
  }
  properties: {
    reserved: true // Required for Linux containers
  }
}

// Deploy Web App for Containers
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    // System-assigned managed identity for ACR access
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    
    // SiteConfig for container deployment
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${containerImageName}:${containerImageTag}'
      alwaysOn: true
      minTlsVersion: '1.2'
      
      // AppSettings for Application Insights and container configuration
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        // Application Insights settings
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        // Container port configuration
        {
          name: 'WEBSITES_PORT'
          value: string(containerPort)
        }
      ]
      
      // Health check configuration
      healthCheckPath: '/'
    }
  }
}

// Enable HTTPS only
resource webAppHttpsOnly 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: webApp
  name: 'web'
  properties: {
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    http20Enabled: true
  }
}

// Output managed identity and app details
output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output managedIdentityPrincipalId string = webApp.identity.principalId

# ZavaStorefront Infrastructure as Code

This directory contains the complete Infrastructure as Code (IaC) for deploying the ZavaStorefront e-commerce application to Azure.

## Overview

The infrastructure is defined using **Bicep** templates and deployed with **Azure Developer CLI (azd)** to the `westus3` region. The deployment creates a secure, monitored, containerized environment without requiring local Docker.

## Architecture

### Azure Resources

| Resource | Purpose | SKU |
|----------|---------|-----|
| **Azure Container Registry** | Private Docker image registry | Standard |
| **App Service Plan** | Linux hosting for containers | Basic (B1) |
| **Web App for Containers** | Containerized ZavaStorefront app | Included |
| **Application Insights** | Monitoring & observability | PerGB2018 |
| **Microsoft Foundry** | AI model access (GPT-4, Phi) | Dev SKU |
| **Azure Key Vault** | Secrets & credentials storage | Standard |

### Security Architecture

- **No Passwords**: App Service uses system-assigned managed identity to pull images from ACR
- **RBAC**: AcrPull role assigned to App Service managed identity
- **Secrets**: Azure Key Vault for secure credential storage (purge protection enabled)
- **Network**: Private ACR (no anonymous pull access)

## Prerequisites

1. **Azure CLI** with **AZD** extension installed
   ```bash
   az upgrade
   az extension add --name containerapp
   ```

2. **Azure Subscription** with sufficient quota in `westus3` region

3. **Service Principal** or **User Account** with **Contributor** role

4. **GitHub Repository** with Actions enabled (for CI/CD)

## Directory Structure

```
infra/
├── main.bicep                      # Main orchestration template
├── parameters.bicep                # Parameter definitions
├── variables.bicep                 # Local variables
└── modules/
    ├── containerRegistry.bicep    # ACR resource
    ├── appService.bicep           # App Service & Web App
    ├── appInsights.bicep          # Application Insights
    ├── roleAssignment.bicep       # RBAC configuration
    ├── keyVault.bicep             # Key Vault
    └── microsoftFoundry.bicep     # ML Workspace

.github/workflows/
├── build-push-acr.yml            # Build Docker image → ACR
└── deploy.yml                     # Deploy infrastructure & app

azd.yaml                           # AZD workflow configuration
azure.yaml                         # AZD project manifest
```

## Quick Start

### 1. Initialize AZD Environment

```bash
cd <project-root>

# Initialize AZD (sets up local environment)
azd init

# Select or create a new environment
azd env new dev

# Set Azure subscription
azd auth login
azd env set AZURE_SUBSCRIPTION_ID <your-subscription-id>
```

### 2. Provision Infrastructure

```bash
# Validate Bicep templates
az bicep build-params --file infra/main.bicep

# Preview changes (what-if)
azd provision --preview

# Deploy infrastructure
azd provision
```

This command will:
- Create resource group `rg-zavastore-dev-westus3`
- Deploy all Azure resources
- Configure RBAC and managed identities
- Link Application Insights

### 3. Build and Deploy Application

#### Option A: Cloud-based Docker Build (Recommended - No local Docker required)

```bash
# Build Docker image using Azure Container Registry
az acr build \
  --registry $(az resource list \
    --resource-group rg-zavastore-dev-westus3 \
    --resource-type Microsoft.ContainerRegistry/registries \
    --query "[0].name" -o tsv) \
  --image zava-storefront:latest \
  --file Dockerfile \
  src/

# Deploy to App Service
azd deploy
```

#### Option B: GitHub Actions (Automated CI/CD)

1. Set up OIDC authentication with Azure:
   ```bash
   # Create service principal with OIDC trust for GitHub
   az ad app create --display-name zavastore-github-actions
   ```

2. Configure GitHub secrets:
   - `AZURE_CLIENT_ID`: Service principal client ID
   - `AZURE_TENANT_ID`: Azure tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

3. Push code to `main` branch to trigger GitHub Actions

## Deployment Verification

### Check Deployment Status

```bash
# View resource group
az group show --name rg-zavastore-dev-westus3

# List all resources
az resource list --resource-group rg-zavastore-dev-westus3 -o table

# Get Web App URL
az resource show \
  --resource-group rg-zavastore-dev-westus3 \
  --name $(az resource list --resource-group rg-zavastore-dev-westus3 --resource-type Microsoft.Web/sites --query "[0].name" -o tsv) \
  --resource-type Microsoft.Web/sites \
  --query properties.defaultHostName -o tsv
```

### Test Application

```bash
# Get App Service URL
app_url="https://$(az resource show \
  --resource-group rg-zavastore-dev-westus3 \
  --name $(az resource list --resource-group rg-zavastore-dev-westus3 --resource-type Microsoft.Web/sites --query "[0].name" -o tsv) \
  --resource-type Microsoft.Web/sites \
  --query properties.defaultHostName -o tsv)"

# Test application
curl -I "$app_url"
```

### Monitor Application

```bash
# View Application Insights
az resource list \
  --resource-group rg-zavastore-dev-westus3 \
  --resource-type Microsoft.Insights/components

# View App Service logs
az webapp log tail \
  --name $(az resource list --resource-group rg-zavastore-dev-westus3 --resource-type Microsoft.Web/sites --query "[0].name" -o tsv) \
  --resource-group rg-zavastore-dev-westus3
```

## Customization

### Change Region

```bash
# Update environment variable
azd env set AZURE_LOCATION <region>

# Re-provision
azd provision
```

Supported regions with Microsoft Foundry: `westus3`, `eastus`

### Change App Service SKU

```bash
# Edit infra/main.bicep and update:
param appServicePlanSize string = 'B2'  # Change from B1

# Re-provision
azd provision
```

Available SKUs: `B1`, `B2`, `S1`, `S2`, etc.

### Disable Features

```bash
# Disable Application Insights
azd env set ENABLE_APP_INSIGHTS false

# Disable Key Vault
azd env set ENABLE_KEY_VAULT false

# Disable Microsoft Foundry
azd env set ENABLE_MICROSOFT_FOUNDRY false

# Re-provision
azd provision
```

## Container Image Management

### Build Image Locally (optional)

```bash
# Build locally (requires Docker)
docker build -t zava-storefront:latest -f Dockerfile src/

# Test locally
docker run -p 5000:5000 zava-storefront:latest
```

### Push Image to ACR

```bash
# Get ACR login server
acr_login_server=$(az resource show \
  --resource-group rg-zavastore-dev-westus3 \
  --name $(az resource list --resource-group rg-zavastore-dev-westus3 --resource-type Microsoft.ContainerRegistry/registries --query "[0].name" -o tsv) \
  --resource-type Microsoft.ContainerRegistry/registries \
  --query properties.loginServer -o tsv)

# Tag image
docker tag zava-storefront:latest ${acr_login_server}/zava-storefront:latest

# Login to ACR using managed identity
az acr login --name ${acr_login_server%%.azurecr.io}

# Push image
docker push ${acr_login_server}/zava-storefront:latest
```

### Cloud-based Build (No Docker Required)

```bash
# Build directly in Azure
acr_name=$(az resource list \
  --resource-group rg-zavastore-dev-westus3 \
  --resource-type Microsoft.ContainerRegistry/registries \
  --query "[0].name" -o tsv)

az acr build \
  --registry $acr_name \
  --image zava-storefront:latest \
  --file Dockerfile \
  src/
```

## Cost Estimation

| Resource | Monthly Cost (approx) |
|----------|----------------------|
| Container Registry (Standard) | $20 |
| App Service Plan (B1) | $13 |
| Application Insights | $0-5 |
| Key Vault | $0.65 |
| **Total** | **~$35-40** |

*Note: Costs vary by region and usage*

## Troubleshooting

### Common Issues

#### 1. Image Pull Failed

```bash
# Verify RBAC assignment
az role assignment list \
  --assignee $(az resource show \
    --resource-group rg-zavastore-dev-westus3 \
    --name $(az resource list --resource-group rg-zavastore-dev-westus3 --resource-type Microsoft.Web/sites --query "[0].name" -o tsv) \
    --resource-type Microsoft.Web/sites \
    --query identity.principalId -o tsv) \
  --output table
```

#### 2. Application Startup Issues

```bash
# Check container logs
az webapp log tail \
  --name $(az resource list --resource-group rg-zavastore-dev-westus3 --resource-type Microsoft.Web/sites --query "[0].name" -o tsv) \
  --resource-group rg-zavastore-dev-westus3
```

#### 3. Container Port Mismatch

Ensure `WEBSITES_PORT` matches the application's listening port (default: 5000)

```bash
# Update if needed
az webapp config appsettings set \
  --name <web-app-name> \
  --resource-group rg-zavastore-dev-westus3 \
  --settings WEBSITES_PORT=5000
```

### Debug Mode

```bash
# Enable verbose logging
az bicep build-params --file infra/main.bicep --debug

# Full deployment debug output
azd provision --debug
```

## Cleanup

### Delete All Resources

```bash
# Delete resource group (deletes all resources)
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait

# Clean up AZD environment
azd env remove dev
```

### Delete Specific Resource

```bash
# Delete App Service
az resource delete \
  --resource-group rg-zavastore-dev-westus3 \
  --name <web-app-name> \
  --resource-type Microsoft.Web/sites
```

## Best Practices

✅ **Do**:
- Use managed identities for authentication
- Store secrets in Key Vault
- Enable purge protection on Key Vault
- Monitor with Application Insights
- Use cloud-based container builds (no local Docker required)
- Test with `--preview` before actual deployment
- Use RBAC instead of access keys

❌ **Don't**:
- Hardcode credentials in Bicep templates
- Enable anonymous ACR pull access
- Use admin credentials for App Service
- Disable HTTPS
- Skip Application Insights for monitoring

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Application Insights Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/app/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure activity logs: `az activity-log list`
3. Check Application Insights diagnostics in Azure Portal
4. Review GitHub Actions logs for CI/CD issues

---

**Last Updated**: January 28, 2026  
**Version**: 1.0.0  
**Status**: Production Ready

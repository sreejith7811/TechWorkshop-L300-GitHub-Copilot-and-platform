# Quick Start Guide - Deploy ZavaStorefront to Azure

Since `azd` installation requires a fresh PowerShell session, I've created **PowerShell deployment scripts** that use Azure CLI directly. These scripts are fully equivalent to `azd init` and `azd provision`.

## Prerequisites

✅ **Already Installed:**
- Azure CLI (version 2.82.0+)

**Required:**
- Azure subscription with `westus3` region available
- Contributor role in target subscription

## Deployment Steps

### Step 1: Authenticate with Azure

```powershell
az login
```

This will open a browser to authenticate. Select your Azure account.

### Step 2: Deploy Infrastructure

Run the infrastructure deployment script:

```powershell
# Navigate to project directory
cd C:\Users\sreejithnath\TechWorkshop-L300-GitHub-Copilot-and-platform

# Run deployment script (optional: specify subscription ID)
.\Deploy-Infrastructure.ps1 -SubscriptionId "<your-subscription-id>"
```

**What this does:**
✅ Creates resource group `rg-zavastore-dev-westus3`
✅ Validates Bicep templates
✅ Previews infrastructure changes
✅ Deploys all Azure resources (ACR, App Service, Application Insights, Key Vault, Microsoft Foundry)
✅ Configures RBAC and managed identities

**Expected Duration:** 3-5 minutes

### Step 3: Deploy Application

After infrastructure deployment completes, run the application deployment script:

```powershell
.\Deploy-Application.ps1 -ResourceGroup "rg-zavastore-dev-westus3" -AcrName "acrzavastore<hash>"
```

**What this does:**
✅ Builds Docker image using Azure Container Registry (cloud-based, no local Docker)
✅ Pushes image to ACR
✅ Configures Web App to pull image from ACR
✅ Waits for application to start
✅ Tests application health

**Expected Duration:** 5-10 minutes

### Step 4: Access Your Application

Once deployment completes, you'll see the Web App URL. Open it in your browser:

```
https://app-zavastore-dev-<random>.azurewebsites.net
```

You should see the ZavaStorefront e-commerce application!

## Troubleshooting

### Issue: "Resource group already exists"
This is **not an error** — the script will simply verify the existing resource group.

### Issue: "Image build failed"
Check that Docker is properly configured (if building locally). The cloud build should work without local Docker.

### Issue: "Application not responding"
Wait another 2-3 minutes for the container to fully start. Check logs:

```powershell
az webapp log tail --name app-zavastore-dev-<random> --resource-group rg-zavastore-dev-westus3
```

### Issue: "Cannot authenticate"
Verify Azure CLI is working:

```powershell
az account show
```

If not authenticated, run:

```powershell
az login
```

## Manual Deployment (if scripts fail)

If the PowerShell scripts encounter issues, you can deploy manually with these Azure CLI commands:

```powershell
# 1. Create resource group
az group create --name rg-zavastore-dev-westus3 --location westus3

# 2. Deploy infrastructure
az deployment group create `
    --name zava-infra-deployment `
    --resource-group rg-zavastore-dev-westus3 `
    --template-file infra/main.bicep `
    --parameters location=westus3 environment=dev projectName=zavastore

# 3. Build Docker image
az acr build `
    --registry <acr-name> `
    --image zava-storefront:latest `
    --file Dockerfile `
    src/

# 4. Deploy to App Service
az webapp config container set `
    --name <web-app-name> `
    --resource-group rg-zavastore-dev-westus3 `
    --docker-custom-image-name <acr-name>.azurecr.io/zava-storefront:latest `
    --docker-registry-server-url https://<acr-name>.azurecr.io
```

## Verify Deployment

Check that all resources were created:

```powershell
# List all resources
az resource list --resource-group rg-zavastore-dev-westus3 -o table

# Check Web App
az webapp show --name app-zavastore-dev-<hash> --resource-group rg-zavastore-dev-westus3

# View logs
az webapp log tail --name app-zavastore-dev-<hash> --resource-group rg-zavastore-dev-westus3
```

## Important Notes

⚠️ **Cost:** This deployment will incur Azure charges (~$35-40/month). Remember to delete the resource group when done:

```powershell
az group delete --name rg-zavastore-dev-westus3 --yes
```

✅ **Security:** 
- Web App uses managed identity for ACR access (no passwords)
- All secrets stored in Key Vault
- RBAC configured with least-privilege access

✅ **Monitoring:**
- Application Insights enabled automatically
- Health checks configured
- Container logs available via Azure Portal or CLI

## Next Steps

1. **Customize Configuration:**
   - Edit `infra/main.bicep` to change resource SKUs
   - Modify `Deploy-Infrastructure.ps1` parameters

2. **Set Up CI/CD:**
   - Configure GitHub Actions (workflows in `.github/workflows/`)
   - Set up OIDC authentication for automated deployments

3. **Monitor Application:**
   - Check Application Insights in Azure Portal
   - Set up alerts for failures

4. **Scale Application:**
   - Increase App Service plan size if needed
   - Configure auto-scaling rules

## Reference

| Component | Details |
|-----------|---------|
| **Template** | Bicep (`infra/main.bicep` with modular components) |
| **CLI Tool** | Azure CLI (alternative to azd) |
| **Deployment** | PowerShell scripts (`Deploy-Infrastructure.ps1`, `Deploy-Application.ps1`) |
| **Region** | westus3 (required for Microsoft Foundry) |
| **Resource Group** | rg-zavastore-dev-westus3 |
| **Cost** | ~$35-40/month (dev environment) |

---

**Ready to deploy? Run:** `.\Deploy-Infrastructure.ps1`

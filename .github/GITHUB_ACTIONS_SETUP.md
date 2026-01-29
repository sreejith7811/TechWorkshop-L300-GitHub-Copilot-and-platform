# GitHub Actions Setup Guide

## Overview

This guide explains how to configure your GitHub repository with the correct secrets and variables for the CI/CD workflows to deploy ZavaStorefront to Azure.

## Prerequisites

✅ **Already Completed:**
- Infrastructure deployed to Azure (resource group: `zava-dev`)
- Azure Container Registry (ACR) created
- App Service created
- All resources in `westus3` region

**Required:**
- GitHub repository access with Admin or Maintainer role
- Azure subscription access with ability to create service principals
- Azure CLI installed locally (for creating service principal)

## Step 1: Create a Service Principal for GitHub Actions (OIDC)

This approach is **more secure** than using account keys because credentials are time-limited and tied to specific workflows.

### Option A: Using Azure CLI (Recommended)

```powershell
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Create a service principal for GitHub Actions
# Replace YOUR-ORG and YOUR-REPO with your actual GitHub org and repo name
$servicePrincipalJson = az ad sp create-for-rbac `
  --name "github-actions-zavastore" `
  --role "Contributor" `
  --scopes "/subscriptions/<your-subscription-id>/resourceGroups/rg-zavastore-dev-westus3" `
  --json-auth | ConvertFrom-Json

# Display the values needed for GitHub
Write-Host "=== Add these values to GitHub Secrets ===" -ForegroundColor Green
Write-Host "AZURE_CLIENT_ID: $($servicePrincipalJson.clientId)"
Write-Host "AZURE_TENANT_ID: $($servicePrincipalJson.tenantId)"
Write-Host "AZURE_SUBSCRIPTION_ID: $($servicePrincipalJson.subscriptionId)"
```

Save these values - you'll need them in the next step.

### Option B: Using Azure Portal

1. Go to **Azure Portal** → **Azure Active Directory** → **App registrations**
2. Click **New registration**
3. Name: `github-actions-zavastore`
4. Select **Accounts in any organizational directory**
5. Click **Register**
6. Copy the **Application (client) ID** and **Directory (tenant) ID**
7. Go to **Certificates & secrets** → **New client secret**
8. Copy the secret value

## Step 2: Configure GitHub Secrets

1. In GitHub, go to your repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

| Secret Name | Value | Source |
|---|---|---|
| `AZURE_CLIENT_ID` | Your client ID | Service Principal |
| `AZURE_TENANT_ID` | Your tenant ID | Service Principal |
| `AZURE_SUBSCRIPTION_ID` | Your subscription ID | Azure Account |

**Example:**
- `AZURE_CLIENT_ID`: `12a34b5c-6789-0def-1234-56789abcdef0`
- `AZURE_TENANT_ID`: `12a34b5c-6789-0def-1234-56789abcdef1`
- `AZURE_SUBSCRIPTION_ID`: `12a34b5c-6789-0def-1234-56789abcdef2`

## Step 3: Configure GitHub Variables (Optional)

GitHub Variables are less sensitive configuration values. They're optional but helpful for reference:

1. Click **Settings** → **Secrets and variables** → **Variables**
2. Add these variables (or let the workflows discover them dynamically):

| Variable Name | Value | Notes |
|---|---|---|
| `AZURE_RESOURCE_GROUP` | `rg-zavastore-dev-westus3` | Optional - workflows discover this automatically |
| `AZURE_LOCATION` | `westus3` | Optional - workflows discover this automatically |

## Step 4: Verify Dockerfile Location

The workflows expect the Dockerfile to be at the **repository root**:
- ✅ Correct: `/Dockerfile` (at root)
- ❌ Wrong: `/src/Dockerfile` (in src folder)

If your Dockerfile is in a different location, update the path in:
- `.github/workflows/deploy.yml` (line with `--file Dockerfile`)
- `.github/workflows/build-push-acr.yml` (line with `--file Dockerfile`)

## Step 5: Test the Workflows

### Test Build Workflow
```
1. Push a commit to main that includes changes to src/ or Dockerfile
2. Go to GitHub → Actions
3. Watch the "Build and Push to ACR" workflow
4. Check for any errors in the logs
```

### Test Deployment Workflow
```
1. Push a commit to main (or manually trigger)
2. Go to GitHub → Actions
3. Watch the "Build and Deploy to App Service" workflow
4. Check the deployment logs
5. Verify the App Service is running the new image
```

## Troubleshooting

### ❌ "Error: Resource not found"
- **Cause**: Azure resource group or resources don't exist
- **Fix**: 
  ```powershell
  az resource list --resource-group rg-zavastore-dev-westus3
  ```
  Ensure all resources are created

### ❌ "Error: AZURE_CLIENT_ID not found"
- **Cause**: GitHub secrets not configured
- **Fix**: 
  1. Go to **Settings** → **Secrets and variables** → **Actions**
  2. Verify all three secrets exist (CLIENT_ID, TENANT_ID, SUBSCRIPTION_ID)

### ❌ "Error: Permission denied"
- **Cause**: Service principal doesn't have contributor role on resource group
- **Fix**:
  ```powershell
  az role assignment create `
    --assignee "<client-id>" `
    --role "Contributor" `
    --scope "/subscriptions/<subscription-id>/resourceGroups/rg-zavastore-dev-westus3"
  ```

### ❌ "Docker: command not found"
- **Cause**: Workflows are trying to use local Docker
- **Fix**: 
  - Workflows now use `az acr build` (cloud-based) - no Docker required
  - Make sure you're using the updated workflow files

### ❌ "App Service deployment timeout"
- **Cause**: Container takes too long to start
- **Fix**:
  1. Wait 5-10 minutes for App Service to pull and start the image
  2. Check App Service logs:
     ```powershell
     az webapp log tail --name "app-zavastore-dev-xxxxx" --resource-group "rg-zavastore-dev-westus3"
     ```

## Workflow Files Explained

### `deploy.yml`
**Purpose**: Build, push to ACR, and deploy to App Service
**Triggers**: 
- Push to `main` branch (changes to `src/`, `Dockerfile`, or workflow file)
- Manual trigger (`workflow_dispatch`)

**Steps**:
1. Checks out code
2. Authenticates to Azure using OIDC
3. Dynamically discovers ACR and App Service names
4. Builds image using `az acr build` (cloud-based, no local Docker)
5. Pushes image with git SHA and `latest` tags
6. Deploys image to App Service

### `build-push-acr.yml`
**Purpose**: Build and push image to ACR only (useful for separate testing)
**Triggers**:
- Push to `main` (changes to `src/`, `Dockerfile`)
- Pull requests to `main`
- Manual trigger

**Steps**:
1. Checks out code
2. Authenticates to Azure using OIDC
3. Gets ACR name dynamically
4. Builds and pushes image
5. Outputs image details

## Next Steps

1. ✅ Create service principal and gather credentials
2. ✅ Add secrets to GitHub
3. ✅ Make a test commit to trigger workflows
4. ✅ Monitor workflow execution
5. ✅ Verify application is accessible

## Security Best Practices

- ✅ Use **OIDC** authentication (time-limited, no long-lived secrets)
- ✅ Scope service principal to specific resource group only
- ✅ Rotate credentials regularly (Azure recommends every 90 days)
- ✅ Use **GitHub branch protection** rules before merging to main
- ✅ Review workflow logs for sensitive data leaks
- ✅ Don't commit `.env` or `.azure` files

## Additional Resources

- [GitHub Actions with Azure](https://github.com/Azure/webapps-deploy)
- [Azure Container Registry Build](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-tasks-overview)
- [GitHub OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

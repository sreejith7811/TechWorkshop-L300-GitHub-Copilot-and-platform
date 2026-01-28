# GitHub Actions Deployment Setup

This workflow builds and deploys the ZavaStorefront .NET application as a Docker container to Azure App Service.

## Required GitHub Secrets

Configure these secrets in your repository settings (Settings > Secrets and variables > Actions):

### 1. `ACR_USERNAME`
Azure Container Registry username for pushing images.

**How to get:**
```bash
az acr credential show --name acrzavastore53xc4kg64odyq --query "username" -o tsv
```

### 2. `ACR_PASSWORD`
Azure Container Registry password for pushing images.

**How to get:**
```bash
az acr credential show --name acrzavastore53xc4kg64odyq --query "passwords[0].value" -o tsv
```

### 3. `AZURE_CREDENTIALS`
Azure service principal credentials in JSON format for deploying to App Service.

**How to create:**
```bash
az ad sp create-for-rbac --name "github-actions" --role "Contributor" --scopes "/subscriptions/{subscriptionId}/resourceGroups/zava-dev" --json-auth
```

Replace `{subscriptionId}` with your Azure subscription ID. Copy the entire JSON output and paste it as the secret value.

## How to Configure

1. **Fork or own the repository** on GitHub
2. **Navigate to Settings** > **Secrets and variables** > **Actions**
3. **Click "New repository secret"** and add each secret above
4. **Push to main branch** to trigger the workflow, or **use workflow_dispatch** to trigger manually

## Workflow Behavior

- **Trigger:** Push to `main` branch or manual trigger via Actions tab
- **Build:** Creates Docker image from `src/Dockerfile`
- **Push:** Pushes images to Azure Container Registry (tagged with commit SHA and `latest`)
- **Deploy:** Deploys latest image to App Service: `app-zavastore-dev-53xc4kg64odyq`

## Viewing Logs

1. Go to **Actions** tab in your GitHub repository
2. Click the workflow run under "Build and Deploy"
3. Click the job to see detailed logs for each step

## Troubleshooting

- **ACR_USERNAME or ACR_PASSWORD errors:** Verify credentials are correct and haven't expired
- **AZURE_CREDENTIALS errors:** Ensure the service principal has "Contributor" role on the resource group
- **Docker build failures:** Check that `src/Dockerfile` exists and is valid

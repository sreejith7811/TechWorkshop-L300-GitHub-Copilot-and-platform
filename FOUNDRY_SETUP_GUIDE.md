# Microsoft Foundry Deployment Guide

## Overview

Microsoft Foundry provides access to advanced AI models including GPT-4 and Phi models. While the core infrastructure deployment includes the necessary storage and key vault resources, the ML Workspace deployment requires additional Azure setup and configuration.

## Current Status

- ✅ **Storage Account**: Created and ready (saml53xc4kg64odyq)
- ✅ **Key Vault (ML)**: Created and ready (kvml53xc4kg64odyq)
- ⏳ **ML Workspace**: Requires manual setup or Bicep refinement

## Why Manual Setup is Recommended

The Microsoft Machine Learning Workspace resource requires:
1. Proper Azure resource provider registration
2. Specific region availability for Phi models
3. Network configuration and policy compliance
4. Additional workspace settings not available in ARM templates

## Option 1: Deploy via Azure Portal (Recommended for First Time)

### Step 1: Create Machine Learning Workspace

1. Open [Azure Portal](https://portal.azure.com)
2. Navigate to **Create a resource**
3. Search for **Machine Learning**
4. Click **Create**
5. Fill in the details:
   - **Resource group**: `zava-dev`
   - **Workspace name**: `mf-zavastore-dev` or similar
   - **Region**: `West US 3` (required for Phi model access)
   - **Storage account**: Select `saml53xc4kg64odyq`
   - **Key vault**: Select `kvml53xc4kg64odyq`
   - **Application Insights**: (Optional) Select existing one
   - **Container Registry**: (Optional) Select `acrzavastore53xc4kg64odyq`
6. Click **Review + Create** then **Create**

### Step 2: Access Models in ML Studio

1. Once workspace is created, go to [Azure ML Studio](https://ml.azure.com)
2. Navigate to **Models** in the left sidebar
3. Search for available models:
   - `gpt-4` (requires specific region and quota)
   - `Phi-3` (available in West US 3)
   - `Phi-3-mini`, `Phi-3-small` (lightweight options)
4. Create API deployments for the models you want to use

## Option 2: Deploy via Bicep (Advanced)

If you want to automate this, follow these steps:

### Step 1: Enable Foundry in Bicep

```bicep
param enableMicrosoftFoundry bool = true  // Change from false to true
```

### Step 2: Update the Module

The `infra/modules/microsoftFoundry.bicep` needs additional configuration. Add these properties:

```bicep
properties: {
    friendlyName: 'Zava Storefront AI'
    description: 'Microsoft Foundry for GPT-4 and Phi model access'
    storageAccount: storageAccount.id
    keyVault: mlKeyVault.id
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${location}.api.azureml.ms/discovery'
    hbiWorkspace: false  // May need to set based on policy
    imageBuildCompute: null  // Optional - leave null for now
}
```

### Step 3: Deploy

Run the deployment:

```powershell
cd C:\Users\sreejithnath\TechWorkshop-L300-GitHub-Copilot-and-platform
azd up
```

## Option 3: Deploy via PowerShell Script

A helper script is provided: `Deploy-Foundry.ps1`

```powershell
.\Deploy-Foundry.ps1 -ResourceGroupName zava-dev -Location westus3 -ProjectName zavastore
```

## Accessing AI Models via Code

Once the ML Workspace is deployed, you can access models programmatically:

### Via Azure AI SDK

```python
from azure.ai.generative.clients import OpenAIClient
from azure.identity import DefaultAzureCredential

# Create client
client = OpenAIClient(
    endpoint="https://<workspace-name>.openai.azure.com/",
    credential=DefaultAzureCredential()
)

# Use deployed model
response = client.chat.completions.create(
    model="gpt-4-deployment-name",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

### Via REST API

```bash
curl -X POST https://<workspace-name>.openai.azure.com/deployments/<deployment-name>/chat/completions?api-version=2024-02-15-preview \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}],
    "model": "gpt-4"
  }'
```

## Troubleshooting

### Issue: "Missing dependent resources in workspace json"

**Cause**: The workspace requires additional properties or the resource provider isn't properly registered.

**Solution**:
1. Ensure `Microsoft.MachineLearningServices` provider is registered:
   ```powershell
   az provider register --namespace Microsoft.MachineLearningServices
   ```
2. Wait 10-15 minutes for registration to complete
3. Try deployment again

### Issue: "Region not available for model X"

**Cause**: Some models are only available in specific regions (Phi-3 requires West US 3).

**Solution**: Ensure your deployment is in `westus3` or check [Azure AI Model Availability](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models)

### Issue: "Quota exceeded"

**Cause**: Your subscription doesn't have quota for the selected model.

**Solution**:
1. Go to Azure Portal → Quotas
2. Select the relevant quota (e.g., "Standard: GPT-4 per-minute-k")
3. Request increase

## Next Steps

1. **Deploy ML Workspace** using one of the options above
2. **Create Model Deployments** in ML Studio for the models you need
3. **Update Application Settings** in your App Service to point to the ML endpoints
4. **Integrate** with your application code to use the AI models

## Resources

- [Azure Machine Learning Documentation](https://learn.microsoft.com/en-us/azure/machine-learning/)
- [Azure OpenAI Service Models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models)
- [Phi-3 Model Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#phi-3)
- [Azure AI Python SDK](https://learn.microsoft.com/en-us/python/api/azure-ai-generative/)

## Support

For issues with Microsoft Foundry deployment:
- Check Azure service health dashboard
- Review resource provider registration status
- Consult Azure ML support documentation
- Contact Microsoft support for quota or regional availability issues

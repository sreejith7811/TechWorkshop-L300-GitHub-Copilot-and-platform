# Deploy Microsoft Foundry ML Workspace - Manual Azure CLI Commands

This guide provides working Azure CLI commands to deploy the ML Workspace since ARM/Bicep deployment has validation limitations.

## Prerequisites
- Azure CLI installed
- Logged in to Azure: `az login`
- Existing storage account and key vault in resource group `zava-dev`

## Step 1: Set Variables
```powershell
$resourceGroup = "zava-dev"
$location = "westus3"
$workspaceName = "mf-zavastore-dev"
$storageName = "saml53xc4kg64odyq"  # From existing deployment
$keyVaultName = "kvml53xc4kg64odyq"  # From existing deployment
```

## Step 2: Verify Resources Exist
```powershell
# Check storage account
az storage account show --name $storageName --resource-group $resourceGroup

# Check key vault
az keyvault show --name $keyVaultName --resource-group $resourceGroup
```

## Step 3: Create ML Workspace via Azure Portal (Recommended)

Since ARM template deployment is blocked by Azure validation, the easiest method is:

1. Go to **Azure Portal** → https://portal.azure.com
2. Click **Create a resource**
3. Search for **Machine Learning**
4. Click **Create**
5. Fill in:
   - **Subscription**: Your current subscription
   - **Resource group**: `zava-dev`
   - **Workspace name**: `mf-zavastore-dev`
   - **Region**: `West US 3`
   - **Storage account**: Select `saml53xc4kg64odyq`
   - **Key vault**: Select `kvml53xc4kg64odyq`
   - **Application Insights**: (Optional)
   - **Container Registry**: (Optional) Select `acrzavastore53xc4kg64odyq`
6. Click **Review + Create**
7. Click **Create**

**Time to complete**: ~5-10 minutes

## Step 4: Access ML Studio

Once deployed:

1. Go to **Azure ML Studio** → https://ml.azure.com
2. Select your workspace: `mf-zavastore-dev`
3. Navigate to **Models**
4. Search and deploy:
   - `gpt-4` (requires quota)
   - `Phi-3` or `Phi-3-mini` (available in westus3)

## Step 5: Verify Deployment via CLI
```powershell
# Get workspace info
az ml workspace show --name $workspaceName --resource-group $resourceGroup

# List deployed models
az ml model list --workspace-name $workspaceName --resource-group $resourceGroup

# Get workspace details
az ml workspace list --resource-group $resourceGroup -o table
```

## Troubleshooting

### Issue: "Region not available"
- Ensure you're using `West US 3` (required for Phi models)
- Check model availability: https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models

### Issue: "Quota exceeded"
- Go to **Quotas** in Azure Portal
- Request increase for needed model SKUs

### Issue: "Storage account not found"
- Ensure storage account is in same region and resource group
- Check storage account exists: `az storage account show --name saml53xc4kg64odyq --resource-group zava-dev`

## Using ML Workspace from Code

### Python Example
```python
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential

# Authenticate
credential = DefaultAzureCredential()

# Connect to workspace
ml_client = MLClient(
    credential=credential,
    subscription_id="12e375cf-242a-40e8-84ef-d8cf6ec23cc4",
    resource_group_name="zava-dev",
    workspace_name="mf-zavastore-dev"
)

# List models
models = ml_client.models.list()
for model in models:
    print(f"Model: {model.name}")
```

### REST API Example
```bash
# Get workspace details
curl -X GET "https://westus3.api.azureml.ms/subscriptions/12e375cf-242a-40e8-84ef-d8cf6ec23cc4/resourceGroups/zava-dev/providers/Microsoft.MachineLearningServices/workspaces/mf-zavastore-dev?api-version=2024-01-01-preview" \
  -H "Authorization: Bearer $(az account get-access-token --query accessToken -o tsv)"
```

## Next Steps

1. ✅ **Core Infrastructure Deployed** - All resources created
2. ⏳ **Create ML Workspace** - Via Portal (takes 5-10 min)
3. 📦 **Deploy Models** - In ML Studio (GPT-4, Phi-3)
4. 🔌 **Integrate with App** - Call model endpoints from code

## Resources

- [Azure ML Documentation](https://learn.microsoft.com/en-us/azure/machine-learning/)
- [Model Availability by Region](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models)
- [Phi-3 Models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#phi-3)
- [Azure ML Python SDK](https://learn.microsoft.com/en-us/python/api/azure-ai-ml/)

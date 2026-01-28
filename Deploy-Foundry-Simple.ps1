#!/usr/bin/env pwsh
# ============================================================================
# Deploy Microsoft Foundry (Machine Learning Workspace)
# ============================================================================

param(
    [string]$ResourceGroupName = "zava-dev",
    [string]$Location = "westus3",
    [string]$ProjectName = "zavastore"
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "Microsoft Foundry ML Workspace Deployment"
Write-Host "=========================================="

# Check Azure CLI
try {
    az account show > $null 2>&1
} catch {
    Write-Host "Error: Azure CLI not found or not logged in"
    exit 1
}

$subscriptionId = az account show --query id -o tsv
Write-Host "Subscription: $subscriptionId"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host ""

# Get existing suffix from ACR
Write-Host "Extracting suffix from existing resources..."
$acr = az resource list --resource-group $ResourceGroupName --resource-type "Microsoft.ContainerRegistry/registries" --query "[0].name" -o tsv
if ($acr) {
    $suffix = $acr -replace "acrzavastore", ""
    Write-Host "Found suffix: $suffix"
} else {
    Write-Host "Error: Could not find existing resources to extract suffix"
    exit 1
}

# ML Workspace name
$mlWorkspaceName = "mf-${ProjectName}-dev"
$storageName = "saml${suffix}"
$kvName = "kvml${suffix}"

Write-Host ""
Write-Host "Creating ML Workspace: $mlWorkspaceName"
Write-Host "Storage Account: $storageName"
Write-Host "Key Vault: $kvName"
Write-Host ""

# Check if ML workspace already exists
$existing = az ml workspace list --resource-group $ResourceGroupName --query "[?name=='$mlWorkspaceName'].id" -o tsv 2>&1 | Where-Object {$_ -and $_ -notmatch "warning|error"}

if ($existing) {
    Write-Host "ML Workspace already exists: $existing"
} else {
    Write-Host "Deploying ML Workspace..."
    
    # Get storage and keyvault resource IDs
    $storageId = az resource list --resource-group $ResourceGroupName --name $storageName --resource-type "Microsoft.Storage/storageAccounts" --query "[0].id" -o tsv
    $kvId = az resource list --resource-group $ResourceGroupName --name $kvName --resource-type "Microsoft.KeyVault/vaults" --query "[0].id" -o tsv
    
    if (-not $storageId -or -not $kvId) {
        Write-Host "Error: Could not find Storage Account or Key Vault"
        Write-Host "Storage ID: $storageId"
        Write-Host "KV ID: $kvId"
        exit 1
    }
    
    Write-Host "Storage ID: $storageId"
    Write-Host "KV ID: $kvId"
    Write-Host ""
    
    # Create ML Workspace using az ml command
    try {
        az ml workspace create `
            --name $mlWorkspaceName `
            --resource-group $ResourceGroupName `
            --storage-account $storageId `
            --key-vault $kvId `
            --display-name "Zava Storefront AI" `
            --location $Location
        
        Write-Host ""
        Write-Host "SUCCESS: ML Workspace created"
    } catch {
        Write-Host "Attempting REST API approach..."
        
        $token = az account get-access-token --query accessToken -o tsv
        
        $bodyJson = ConvertTo-Json @{
            location = $Location
            properties = @{
                friendlyName = "Zava Storefront AI"
                description = "Machine Learning workspace for GPT-4 and Phi models"
                storageAccount = $storageId
                keyVault = $kvId
                publicNetworkAccess = "Enabled"
            }
        }
        
        $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.MachineLearningServices/workspaces/$mlWorkspaceName?api-version=2024-01-01-preview"
        
        $response = Invoke-WebRequest `
            -Uri $uri `
            -Method Put `
            -Headers @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" } `
            -Body $bodyJson `
            -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -in 200,201) {
            Write-Host "SUCCESS: ML Workspace created via REST API"
        } else {
            Write-Host "FAILED: ML Workspace creation failed"
            Write-Host "Status: $($response.StatusCode)"
            exit 1
        }
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Deployment Complete"
Write-Host "=========================================="
Write-Host ""
Write-Host "Next Steps:"
Write-Host "1. Open https://ml.azure.com"
Write-Host "2. Select workspace: $mlWorkspaceName"
Write-Host "3. Go to Models section"
Write-Host "4. Deploy GPT-4 or Phi models"
Write-Host ""
Write-Host "=========================================="

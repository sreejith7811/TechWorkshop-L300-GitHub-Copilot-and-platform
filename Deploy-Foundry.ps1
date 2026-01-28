# ============================================================================
# Deploy Microsoft Foundry (Machine Learning Workspace)
# Deploys ML Workspace that Bicep templates struggle with
# ============================================================================

param(
    [string]$ResourceGroupName = "zava-dev",
    [string]$Location = "westus3",
    [string]$ProjectName = "zavastore",
    [switch]$SkipStorageAndKeyVault
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "Microsoft Foundry (ML Workspace) Deployment"
Write-Host "=========================================="

# Ensure we're logged in
try {
    $context = az account show 2>$null
    if (-not $context) {
        Write-Host "Not logged in. Running: az login"
        az login
    }
} catch {
    Write-Host "Error checking login status: $_"
    exit 1
}

$subscriptionId = az account show --query id -o tsv
Write-Host "Subscription: $subscriptionId`n"

# Check if resource group exists
$rgExists = az group exists --resource-group $ResourceGroupName -o tsv
if ($rgExists -ne "true") {
    Write-Host "Creating resource group: $ResourceGroupName"
    az group create --name $ResourceGroupName --location $Location | Out-Null
}

# Generate unique suffix from resource group
$suffix = $(az group show --name $ResourceGroupName --query tags.suffix -o tsv 2>/dev/null)
if (-not $suffix) {
    # Extract from existing resource
    $existing = az resource list --resource-group $ResourceGroupName --query "[0].name" -o tsv 2>/dev/null
    if ($existing -match "([a-z0-9]{24})") {
        $suffix = $matches[1]
    } else {
        $suffix = -join ((48..57) + (97..122) | Get-Random -Count 24 | ForEach-Object {[char]$_})
    }
}

Write-Host "Using suffix: $suffix`n"

# Storage account name
$storageName = "saml$suffix".Substring(0, 24)
$storageExists = az storage account check-name --name $storageName --query nameAvailable -o tsv 2>/dev/null

if ($storageExists -eq "true") {
    Write-Host "Creating Storage Account: $storageName"
    $storageAccount = az storage account create `
        --name $storageName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --https-only true `
        --min-tls-version TLS1_2 `
        --query id -o tsv
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Storage Account created: $storageName"
    }
} else {
    Write-Host "✓ Storage Account already exists: $storageName"
    $storageAccount = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageName"
}

# Key Vault name
$kvName = "kvml$suffix".Substring(0, 24)
$kvExists = az keyvault list --resource-group $ResourceGroupName --query "[?name=='$kvName'].id" -o tsv

if (-not $kvExists) {
    Write-Host "Creating Key Vault for ML Workspace: $kvName"
    $keyVault = az keyvault create `
        --name $kvName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --enable-purge-protection true `
        --enable-rbac-authorization true `
        --query id -o tsv
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Key Vault created: $kvName"
    }
} else {
    Write-Host "✓ Key Vault already exists: $kvName"
    $keyVault = $kvExists
}

# ML Workspace name
$mlWorkspaceName = "mf-$ProjectName-$Location"

Write-Host "`nCreating Machine Learning Workspace: $mlWorkspaceName"

# Create ML Workspace using Azure CLI
$mlWorkspace = az ml workspace create `
    --name $mlWorkspaceName `
    --resource-group $ResourceGroupName `
    --storage-account $storageAccount `
    --key-vault $keyVault `
    --container-registry "" `
    --query id -o tsv 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Machine Learning Workspace created successfully"
    Write-Host "  Name: $mlWorkspaceName"
    Write-Host "  ID: $mlWorkspace`n"
} else {
    # If az ml fails, try REST API approach
    Write-Host "⚠ Direct az ml command failed, trying REST API approach..."
    
    # Get access token
    $token = az account get-access-token --query accessToken -o tsv
    
    # Construct workspace properties
    $workspaceBody = @{
        location = $Location
        tags = @{
            environment = "dev"
            project = $ProjectName
        }
        properties = @{
            friendlyName = "Zava Storefront AI Workspace"
            description = "Machine Learning workspace for GPT-4 and Phi model access"
            storageAccount = $storageAccount
            keyVault = $keyVault
            publicNetworkAccess = "Enabled"
        }
    } | ConvertTo-Json -Depth 10
    
    $apiVersion = "2024-01-01-preview"
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.MachineLearningServices/workspaces/$mlWorkspaceName" + "?api-version=$apiVersion"
    
    Write-Host "Deploying via REST API..."
    $response = Invoke-WebRequest -Uri $uri `
        -Method Put `
        -Headers @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        } `
        -Body $workspaceBody -ErrorAction SilentlyContinue
    
    if ($response.StatusCode -in @(200, 201)) {
        Write-Host "✓ Machine Learning Workspace created via REST API"
    } else {
        Write-Host "✗ REST API deployment failed"
        Write-Host "Status: $($response.StatusCode)"
        Write-Host "Response: $($response.Content)"
        exit 1
    }
}

# List created resources
Write-Host "`n=========================================="
Write-Host "Deployment Summary"
Write-Host "=========================================="
Write-Host "✓ Storage Account: $storageName"
Write-Host "✓ Key Vault: $kvName"
Write-Host "✓ ML Workspace: $mlWorkspaceName"
Write-Host "`nResources are ready in: $ResourceGroupName"
Write-Host "Region: $Location"
Write-Host "`nNext steps:"
Write-Host "1. Go to https://ml.azure.com"
Write-Host "2. Select workspace: $mlWorkspaceName"
Write-Host "3. Navigate to 'Models' to deploy GPT-4 or Phi models"
Write-Host "=========================================="


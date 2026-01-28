# Deploy-Infrastructure.ps1
# PowerShell script to deploy ZavaStorefront infrastructure using Azure CLI

param(
    [string]$SubscriptionId,
    [string]$ResourceGroup = "rg-zavastore-dev-westus3",
    [string]$Location = "westus3",
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ZavaStorefront Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Azure CLI
Write-Host "[*] Step 1: Checking Azure CLI..." -ForegroundColor Yellow
$cliVersion = az version -o json | ConvertFrom-Json
Write-Host "[OK] Azure CLI version: $($cliVersion.'azure-cli')" -ForegroundColor Green

# Step 2: Login to Azure
Write-Host ""
Write-Host "[*] Step 2: Authenticating with Azure..." -ForegroundColor Yellow
$account = az account show 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Not logged in. Starting login process..." -ForegroundColor Yellow
    az login
} else {
    $accountInfo = $account | ConvertFrom-Json
    Write-Host "[OK] Logged in as: $($accountInfo.user.name)" -ForegroundColor Green
}

# Step 3: Set subscription
if ($SubscriptionId) {
    Write-Host ""
    Write-Host "[*] Step 3: Setting subscription..." -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
    Write-Host "[OK] Subscription set: $SubscriptionId" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[!] No subscription provided. Using default subscription." -ForegroundColor Yellow
    $defaultSub = az account show -o json | ConvertFrom-Json
    Write-Host "Default subscription: $($defaultSub.name) ($($defaultSub.id))" -ForegroundColor Green
}

# Step 4: Create resource group
Write-Host ""
Write-Host "[*] Step 4: Creating resource group '$ResourceGroup'..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location | Out-Null
Write-Host "[OK] Resource group created/verified: $ResourceGroup" -ForegroundColor Green

# Step 5: Validate Bicep templates
Write-Host ""
Write-Host "[*] Step 5: Validating Bicep templates..." -ForegroundColor Yellow
try {
    az bicep build-params --file infra/main.bicep | Out-Null
    Write-Host "[OK] Bicep templates are valid" -ForegroundColor Green
} catch {
    Write-Host "[!] Bicep validation failed: $_" -ForegroundColor Red
    exit 1
}

# Step 6: Preview deployment
Write-Host ""
Write-Host "[*] Step 6: Previewing infrastructure changes..." -ForegroundColor Yellow
Write-Host "Running 'what-if' analysis..." -ForegroundColor Gray
az deployment group what-if `
    --name "zava-infra-deployment-preview" `
    --resource-group $ResourceGroup `
    --template-file infra/main.bicep `
    --parameters `
        location=$Location `
        environment=$Environment `
        projectName=zavastore `
        acrSku=Standard `
        appServicePlanTier=Basic `
        appServicePlanSize=B1 `
        containerPort=5000 `
        containerImageName=zava-storefront `
        containerImageTag=latest `
        enableAppInsights=true `
        enableKeyVault=true `
        enableMicrosoftFoundry=true | Out-Null

Write-Host "[OK] What-if analysis complete" -ForegroundColor Green

# Step 7: Ask for confirmation
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Location: $Location"
Write-Host "Environment: $Environment"
Write-Host ""
$confirm = Read-Host "Do you want to proceed with deployment? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "[!] Deployment cancelled" -ForegroundColor Red
    exit 0
}

# Step 8: Deploy infrastructure
Write-Host ""
Write-Host "[*] Step 8: Deploying infrastructure..." -ForegroundColor Yellow
Write-Host "This may take 3-5 minutes..." -ForegroundColor Gray

$deploymentOutput = az deployment group create `
    --name "zava-infra-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
    --resource-group $ResourceGroup `
    --template-file infra/main.bicep `
    --parameters `
        location=$Location `
        environment=$Environment `
        projectName=zavastore `
        acrSku=Standard `
        appServicePlanTier=Basic `
        appServicePlanSize=B1 `
        containerPort=5000 `
        containerImageName=zava-storefront `
        containerImageTag=latest `
        enableAppInsights=true `
        enableKeyVault=true `
        enableMicrosoftFoundry=true `
    --output json

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Infrastructure deployed successfully!" -ForegroundColor Green
    
    # Parse outputs
    $outputs = ($deploymentOutput | ConvertFrom-Json).properties.outputs
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment Outputs" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Azure Container Registry (ACR):" -ForegroundColor Cyan
    Write-Host "  Name: $($outputs.acrName.value)"
    Write-Host "  Login Server: $($outputs.acrLoginServer.value)"
    
    Write-Host ""
    Write-Host "Web Application:" -ForegroundColor Cyan
    Write-Host "  Name: $($outputs.webAppName.value)"
    Write-Host "  URL: $($outputs.webAppUrl.value)"
    
    if ($outputs.appInsightsId.value) {
        Write-Host ""
        Write-Host "Application Insights:" -ForegroundColor Cyan
        Write-Host "  Instrumentation Key: $($outputs.appInsightsInstrumentationKey.value)"
    }
    
    if ($outputs.keyVaultUri.value) {
        Write-Host ""
        Write-Host "Azure Key Vault:" -ForegroundColor Cyan
        Write-Host "  URI: $($outputs.keyVaultUri.value)"
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "1. Build Docker image:"
    Write-Host "   az acr build --registry $($outputs.acrName.value) --image zava-storefront:latest --file Dockerfile src/"
    Write-Host ""
    Write-Host "2. Deploy application:"
    Write-Host "   .\Deploy-Application.ps1 -ResourceGroup '$ResourceGroup' -AcrName '$($outputs.acrName.value)'"
    Write-Host ""
    
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host $deploymentOutput
    exit 1
}

# ============================================================================
# Deploy-Application.ps1
# PowerShell script to build and deploy ZavaStorefront to Azure App Service
# ============================================================================

param(
    [string]$ResourceGroup = "rg-zavastore-dev-westus3",
    [string]$AcrName = "",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ZavaStorefront Application Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get ACR details
Write-Host "📋 Step 1: Retrieving ACR details..." -ForegroundColor Yellow

if (-not $AcrName) {
    Write-Host "Looking for Container Registry in resource group..." -ForegroundColor Gray
    $acrInfo = az resource list --resource-group $ResourceGroup --resource-type "Microsoft.ContainerRegistry/registries" -o json | ConvertFrom-Json
    
    if ($acrInfo.Count -eq 0) {
        Write-Host "❌ No Container Registry found in resource group" -ForegroundColor Red
        exit 1
    }
    
    $AcrName = $acrInfo[0].name
}

$acrDetails = az acr show --name $AcrName --resource-group $ResourceGroup -o json | ConvertFrom-Json
$acrLoginServer = $acrDetails.loginServer

Write-Host "✅ Found ACR: $AcrName" -ForegroundColor Green
Write-Host "   Login Server: $acrLoginServer" -ForegroundColor Gray

# Step 2: Build Docker image in ACR
Write-Host ""
Write-Host "📋 Step 2: Building Docker image..." -ForegroundColor Yellow
Write-Host "Using Azure Container Registry cloud build (no local Docker required)" -ForegroundColor Gray
Write-Host ""

try {
    az acr build `
        --registry $AcrName `
        --image "zava-storefront:$ImageTag" `
        --image "zava-storefront:latest" `
        --file Dockerfile `
        --timeout 600 `
        src/
    
    Write-Host ""
    Write-Host "✅ Docker image built successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Image build failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Get App Service details
Write-Host ""
Write-Host "📋 Step 3: Retrieving Web App details..." -ForegroundColor Yellow

$appServiceInfo = az resource list --resource-group $ResourceGroup --resource-type "Microsoft.Web/sites" -o json | ConvertFrom-Json

if ($appServiceInfo.Count -eq 0) {
    Write-Host "❌ No Web App found in resource group" -ForegroundColor Red
    exit 1
}

$webAppName = $appServiceInfo[0].name
$webAppDetails = az webapp show --name $webAppName --resource-group $ResourceGroup -o json | ConvertFrom-Json
$webAppUrl = "https://$($webAppDetails.defaultHostName)"

Write-Host "✅ Found Web App: $webAppName" -ForegroundColor Green
Write-Host "   URL: $webAppUrl" -ForegroundColor Gray

# Step 4: Configure Web App to use image from ACR
Write-Host ""
Write-Host "📋 Step 4: Configuring Web App container settings..." -ForegroundColor Yellow

az webapp config container set `
    --name $webAppName `
    --resource-group $ResourceGroup `
    --docker-custom-image-name "${acrLoginServer}/zava-storefront:${ImageTag}" `
    --docker-registry-server-url "https://${acrLoginServer}" `
    --docker-registry-server-username "" `
    --docker-registry-server-password "" | Out-Null

Write-Host "✅ Container settings configured" -ForegroundColor Green

# Step 5: Restart Web App
Write-Host ""
Write-Host "📋 Step 5: Restarting Web App..." -ForegroundColor Yellow

az webapp restart --name $webAppName --resource-group $ResourceGroup | Out-Null

Write-Host "✅ Web App restarted" -ForegroundColor Green

# Step 6: Wait for app to start and test
Write-Host ""
Write-Host "📋 Step 6: Waiting for application to start..." -ForegroundColor Yellow
Write-Host "This may take 1-2 minutes..." -ForegroundColor Gray

Start-Sleep -Seconds 30

$maxRetries = 10
$retryCount = 0
$success = $false

while ($retryCount -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri $webAppUrl -Method Head -TimeoutSec 5 -SkipHttpErrorCheck
        
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 301 -or $response.StatusCode -eq 302) {
            Write-Host "✅ Application is responding (HTTP $($response.StatusCode))" -ForegroundColor Green
            $success = $true
            break
        }
    } catch {
        # Ignore errors during health checks
    }
    
    $retryCount++
    if ($retryCount -lt $maxRetries) {
        Write-Host "   Attempt $retryCount/$maxRetries - waiting..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

if (-not $success) {
    Write-Host "⚠️  Application is not responding yet. This may take a few more minutes." -ForegroundColor Yellow
    Write-Host "   Check logs at: https://portal.azure.com" -ForegroundColor Gray
}

# Step 7: Display summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Application Details:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  Web App: $webAppName"
Write-Host "  URL: $webAppUrl"
Write-Host "  Container Image: ${acrLoginServer}/zava-storefront:${ImageTag}"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Open the application: $webAppUrl"
Write-Host "  2. Check Application Insights for monitoring"
Write-Host "  3. View logs: az webapp log tail --name $webAppName --resource-group $ResourceGroup"
Write-Host ""

#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy AI models (GPT-4 and Phi-3-mini) to Azure AI Foundry hub
.DESCRIPTION
This script deploys GPT-4 and Phi-3-mini models to the Microsoft Foundry hub
using Azure CLI commands.
#>

# Configuration
$ResourceGroup = "zava-dev"
$FoundryName = "mf-zavastore-dev"
$Location = "westus3"

Write-Host "=========================================="
Write-Host "Azure AI Foundry Model Deployment"
Write-Host "=========================================="
Write-Host ""
Write-Host "Target: $FoundryName"
Write-Host "Region: $Location"
Write-Host ""

# Deploy GPT-4
Write-Host "Deploying GPT-4 (2024-05-13)..."
$gpt4 = az cognitiveservices account deployment create `
    --resource-group $ResourceGroup `
    --name $FoundryName `
    --deployment-name "gpt-4-deployment" `
    --model-name "gpt-4" `
    --model-version "2024-05-13" `
    --model-format OpenAI `
    --sku-name GlobalStandard `
    --sku-capacity 1 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ GPT-4 deployment succeeded"
    $gpt4Status = "Success"
} else {
    Write-Host "⚠ GPT-4 response: $gpt4"
    $gpt4Status = "Check status"
}

Write-Host ""

# Deploy Phi-3-mini  
Write-Host "Deploying Phi-3-mini (4K)..."
$phi3 = az cognitiveservices account deployment create `
    --resource-group $ResourceGroup `
    --name $FoundryName `
    --deployment-name "phi-3-mini-deployment" `
    --model-name "Phi-3-mini" `
    --model-version "4K" `
    --model-format OpenAI `
    --sku-name GlobalStandard `
    --sku-capacity 1 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Phi-3-mini deployment succeeded"
    $phi3Status = "Success"
} else {
    Write-Host "⚠ Phi-3-mini response: $phi3"
    $phi3Status = "Check status"
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Deployment Summary"
Write-Host "=========================================="
Write-Host "Foundry Hub: $FoundryName"
Write-Host "Resource Group: $ResourceGroup"
Write-Host ""
Write-Host "Model Deployments:"
Write-Host "  • GPT-4 (2024-05-13): $gpt4Status"
Write-Host "  • Phi-3-mini (4K): $phi3Status"
Write-Host ""

# List deployed models
Write-Host "Listing deployed models..."
Write-Host ""
az cognitiveservices account deployment list `
    --resource-group $ResourceGroup `
    --name $FoundryName `
    --query "[].{name:name, provisioningState:provisioningState, sku:sku.name}" `
    -o table

Write-Host ""
Write-Host "=========================================="
Write-Host "Next Steps"
Write-Host "=========================================="
Write-Host "1. Open Azure AI Foundry: https://ai.azure.com"
Write-Host "2. Select your Foundry hub: $FoundryName"
Write-Host "3. Go to 'Deployments' to see deployed models"
Write-Host "4. Test models in the Playground"
Write-Host ""
Write-Host "Note: Model deployments may take a few minutes to be ready."
Write-Host "=========================================="

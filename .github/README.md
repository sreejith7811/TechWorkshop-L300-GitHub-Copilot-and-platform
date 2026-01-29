# GitHub Actions Workflows - Quick Reference

## 📋 Current Status

The GitHub Actions workflows have been **reconstructed from scratch** with the following improvements:

✅ **Fixed Issues:**
- Dynamic resource discovery (no hardcoded ACR/App Service names)
- Correct Dockerfile path (at repository root)
- Proper OIDC authentication (more secure, no long-lived secrets)
- Aligned with actual resource group: `rg-zavastore-dev-westus3`
- Cloud-based ACR builds (no local Docker required)
- Proper error handling and verification steps

## 🔄 Available Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **Build and Push to ACR** | `build-push-acr.yml` | Push to main, Pull Requests | Build Docker image and push to ACR only |
| **Build and Deploy** | `deploy.yml` | Push to main | Build, push, and deploy to App Service |

## 🚀 Quick Start

### 1. Create Azure Service Principal
```powershell
$sp = az ad sp create-for-rbac `
  --name "github-actions-zavastore" `
  --role "Contributor" `
  --scopes "/subscriptions/<subscription-id>/resourceGroups/rg-zavastore-dev-westus3" `
  --json-auth | ConvertFrom-Json

Write-Host "CLIENT_ID: $($sp.clientId)"
Write-Host "TENANT_ID: $($sp.tenantId)"
Write-Host "SUBSCRIPTION_ID: $($sp.subscriptionId)"
```

### 2. Add GitHub Secrets
In your GitHub repository → **Settings** → **Secrets and variables** → **Actions**, add:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

### 3. Make a Test Commit
```bash
git add .github/workflows/
git commit -m "Update GitHub Actions workflows"
git push origin main
```

### 4. Monitor Workflow
Go to **Actions** tab in GitHub to see the workflow run.

## 📝 Configuration Details

**Resource Group**: `zava-dev`
**Region**: `westus3`
**Authentication**: OIDC (OpenID Connect) - no secrets in workflow files
**Build Method**: Azure Container Registry (cloud-based, no local Docker needed)
**Deployment Target**: Azure App Service

## 🔐 Security Features

- ✅ OIDC authentication (time-limited tokens)
- ✅ No hardcoded credentials in workflows
- ✅ Scoped service principal (resource group only)
- ✅ Signed container images
- ✅ Audit trail of all deployments

## ❓ Need Help?

See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for:
- Detailed setup instructions
- Troubleshooting guide
- Security best practices
- Workflow explanations

## 📂 File Structure

```
.github/
├── workflows/
│   ├── build-push-acr.yml          ← Build & push to ACR
│   ├── deploy.yml                  ← Build, push & deploy
│   └── jekyll-gh-pages.yml          ← Documentation site
├── GITHUB_ACTIONS_SETUP.md         ← Complete setup guide
└── README.md                         ← This file
```

## ✨ Workflow Improvements

### Before (Issues)
- ❌ Hardcoded ACR registry name: `acrzavastore53xc4kg64odyq.azurecr.io`
- ❌ Hardcoded App Service name: `app-zavastore-dev-53xc4kg64odyq`
- ❌ Hardcoded resource group: `zava-dev`
- ❌ Dockerfile path error: `src/Dockerfile` (wrong location)
- ❌ Using deprecated `azure/docker-login@v1` with static credentials
- ❌ Manual secret management in workflow
- ❌ No error handling

### After (Fixed)
- ✅ Dynamic resource discovery from Azure
- ✅ Works with any resource group
- ✅ Correct Dockerfile location at repository root
- ✅ Modern OIDC authentication
- ✅ No credentials in workflow files
- ✅ Comprehensive error handling
- ✅ Verification steps after deployment

## 🎯 Next Actions

1. [ ] Create service principal (Step 1 in setup guide)
2. [ ] Add secrets to GitHub (Step 2)
3. [ ] Test workflows with a commit
4. [ ] Monitor App Service for successful deployment
5. [ ] Access application via App Service URL

---

**Last Updated**: January 2026
**Status**: ✅ Ready for deployment

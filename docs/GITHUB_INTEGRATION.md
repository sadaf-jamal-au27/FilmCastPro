# GitHub Integration Guide for ArgoCD

Complete guide to integrate GitHub with ArgoCD for automated deployments.

---

## 📋 Table of Contents

1. [GitHub Actions Secrets Setup](#1-github-actions-secrets-setup)
2. [GitHub Webhook Setup](#2-github-webhook-setup)
3. [Testing the Integration](#3-testing-the-integration)
4. [Troubleshooting](#4-troubleshooting)

---

## 1️⃣ GitHub Actions Secrets Setup

GitHub Actions needs AWS credentials to build and push Docker images to ECR.

### Step-by-Step Instructions:

#### Step 1: Go to Repository Settings
1. Open your browser and navigate to:
   ```
   https://github.com/sadaf-jamal-au27/FilmCastPro
   ```

2. Click on **Settings** (top menu bar)

#### Step 2: Navigate to Secrets
1. In the left sidebar, scroll down to **Security** section
2. Click on **Secrets and variables**
3. Click on **Actions**

#### Step 3: Add AWS Access Key ID
1. Click **"New repository secret"** button
2. Fill in:
   - **Name:** `AWS_ACCESS_KEY_ID`
   - **Value:** Your AWS Access Key (from AWS IAM)
   
   ```
   Example format: AKIAIOSFODNN7EXAMPLE
   ```

3. Click **"Add secret"**

#### Step 4: Add AWS Secret Access Key
1. Click **"New repository secret"** button again
2. Fill in:
   - **Name:** `AWS_SECRET_ACCESS_KEY`
   - **Value:** Your AWS Secret Key (from AWS IAM)
   
   ```
   Example format: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```

3. Click **"Add secret"**

### 🔍 How to Get AWS Credentials:

**If you already have them:** Use your existing IAM user credentials

**If you need new ones:**
```bash
# Check your current IAM user
aws sts get-caller-identity

# Required IAM permissions:
# - AmazonEC2ContainerRegistryPowerUser (for ECR)
# - Or create custom policy with these permissions:
# - ecr:GetAuthorizationToken
# - ecr:BatchCheckLayerAvailability
# - ecr:GetDownloadUrlForLayer
# - ecr:PutImage
# - ecr:InitiateLayerUpload
# - ecr:UploadLayerPart
# - ecr:CompleteLayerUpload
```

### ✅ Verify Secrets are Added

After adding both secrets, you should see:
```
AWS_ACCESS_KEY_ID        ✓ (Updated X minutes ago)
AWS_SECRET_ACCESS_KEY    ✓ (Updated X minutes ago)
```

---

## 2️⃣ GitHub Webhook Setup

Webhooks enable ArgoCD to sync immediately when you push code (instead of waiting 3 minutes).

### Step 1: Get ArgoCD Webhook URL

Run this command to get the webhook URL:

```bash
# Get ArgoCD server URL
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "ArgoCD Webhook URL:"
echo "http://$ARGOCD_URL/api/webhook"
```

**Example output:**
```
http://a551743f3fc024c65a454d33fc456236-1486486352.us-east-1.elb.amazonaws.com/api/webhook
```

### Step 2: Configure GitHub Webhook

1. Go to your GitHub repository:
   ```
   https://github.com/sadaf-jamal-au27/FilmCastPro
   ```

2. Click on **Settings** → **Webhooks** → **Add webhook**

3. Fill in the webhook form:

   **Payload URL:**
   ```
   http://a551743f3fc024c65a454d33fc456236-1486486352.us-east-1.elb.amazonaws.com/api/webhook
   ```

   **Content type:**
   ```
   application/json
   ```

   **Secret:** (leave empty for now)

   **Which events would you like to trigger this webhook?**
   - Select: **Just the push event**

   **Active:**
   - ✓ Check this box

4. Click **"Add webhook"**

### Step 3: Verify Webhook

After adding:
1. GitHub will send a test ping
2. Check for a green checkmark ✓ next to the webhook
3. Click on the webhook to see delivery history

---

## 3️⃣ Testing the Integration

### Test 1: GitHub Actions Pipeline

1. Make a small change to your code:
   ```bash
   cd /Users/sadafperveen05/Devops/FilmCastPro
   
   # Make a small change
   echo "# Test change" >> README.md
   
   # Commit and push
   git add README.md
   git commit -m "test: trigger GitHub Actions"
   git push origin main
   ```

2. Check GitHub Actions:
   - Go to: https://github.com/sadaf-jamal-au27/FilmCastPro/actions
   - You should see a new workflow run starting
   - Watch the progress (Build → Push to ECR → Update values.yaml)

3. Expected flow:
   ```
   ✓ Checkout code
   ✓ Configure AWS credentials
   ✓ Login to ECR
   ✓ Build Docker image
   ✓ Push to ECR
   ✓ Update Helm values
   ✓ Commit changes
   ```

### Test 2: ArgoCD Auto-Sync

1. After GitHub Actions completes, ArgoCD should automatically sync

2. Check in ArgoCD UI:
   - Go to: http://[ARGOCD-URL]
   - Look for "filmcastpro" application
   - Status should change to "Syncing" then "Synced"

3. Or check via CLI:
   ```bash
   kubectl get application filmcastpro -n argocd -w
   ```

### Test 3: End-to-End

Verify the full pipeline works:

```bash
# 1. Check current image tag
kubectl get deployment filmcastpro -n filmcastpro -o jsonpath='{.spec.template.spec.containers[0].image}'

# 2. Make a code change
echo "// Pipeline test" >> src/App.tsx

# 3. Push to GitHub
git add src/App.tsx
git commit -m "feat: test CI/CD pipeline"
git push origin main

# 4. Watch GitHub Actions
# Go to: https://github.com/sadaf-jamal-au27/FilmCastPro/actions

# 5. Watch ArgoCD sync
kubectl get application filmcastpro -n argocd -w

# 6. Verify new image deployed
kubectl get deployment filmcastpro -n filmcastpro -o jsonpath='{.spec.template.spec.containers[0].image}'
# Should show new SHA tag
```

---

## 4️⃣ Troubleshooting

### Issue 1: GitHub Actions Fails

**Error: "The security token included in the request is invalid"**

**Solution:**
- Double-check AWS credentials in GitHub Secrets
- Ensure credentials have ECR permissions
- Regenerate AWS access keys if expired

**Check logs:**
```
Go to: https://github.com/sadaf-jamal-au27/FilmCastPro/actions
Click on failed run → Click on job → Expand failed step
```

### Issue 2: ArgoCD Not Syncing

**Error: "Application not found"**

**Solution:**
```bash
# Deploy the application
kubectl apply -f argocd/filmcastpro-app.yaml

# Verify
kubectl get application filmcastpro -n argocd
```

**Error: "ComparisonError: rpc error: code = Unknown"**

**Solution:**
```bash
# Check repository connection
kubectl get secret -n argocd | grep repo

# Re-add repository in ArgoCD UI:
Settings → Repositories → Connect Repo
```

### Issue 3: Webhook Not Triggering

**Check webhook status:**
1. Go to: https://github.com/sadaf-jamal-au27/FilmCastPro/settings/hooks
2. Click on your webhook
3. Check "Recent Deliveries"
4. Look for green ✓ or red ✗

**Solution if failing:**
```bash
# Verify ArgoCD server is accessible
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test webhook endpoint
curl -X POST http://$ARGOCD_URL/api/webhook \
  -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/main"}'
```

### Issue 4: Image Not Updating

**Check if values.yaml was updated:**
```bash
git log -1 --oneline charts/filmcastpro/values.yaml
```

**Check image tag in cluster:**
```bash
kubectl describe deployment filmcastpro -n filmcastpro | grep Image
```

**Force sync:**
```bash
# Via CLI
argocd app sync filmcastpro --force

# Via kubectl
kubectl patch application filmcastpro -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

---

## 📊 Monitoring the Pipeline

### GitHub Actions Status Badge

Add to your README.md:
```markdown
![Deploy Status](https://github.com/sadaf-jamal-au27/FilmCastPro/actions/workflows/deploy.yml/badge.svg)
```

### Check Pipeline Health

```bash
# GitHub Actions runs
# Visit: https://github.com/sadaf-jamal-au27/FilmCastPro/actions

# ArgoCD application status
kubectl get application filmcastpro -n argocd

# Pod status
kubectl get pods -n filmcastpro

# Recent events
kubectl get events -n filmcastpro --sort-by='.lastTimestamp' | tail -10
```

---

## 🎯 Complete Integration Checklist

- [ ] GitHub Actions secrets added (AWS credentials)
- [ ] GitHub webhook configured
- [ ] ArgoCD application deployed
- [ ] Test push triggers GitHub Actions
- [ ] GitHub Actions builds and pushes image
- [ ] values.yaml updated with new image tag
- [ ] ArgoCD detects change and syncs
- [ ] Application updated in cluster
- [ ] LoadBalancer accessible with new version

---

## 🔐 Security Best Practices

1. **Rotate AWS credentials regularly** (every 90 days)
2. **Use least privilege IAM policies** (only ECR permissions)
3. **Enable branch protection** on main branch
4. **Require PR reviews** before merging to main
5. **Add webhook secret** for production (in ArgoCD settings)
6. **Enable 2FA** on GitHub account
7. **Use separate AWS accounts** for dev/staging/prod

---

## 📚 Additional Resources

- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **ArgoCD Webhooks:** https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/
- **AWS ECR Docs:** https://docs.aws.amazon.com/ecr/
- **Repository:** https://github.com/sadaf-jamal-au27/FilmCastPro

---

## 🆘 Need Help?

1. Check GitHub Actions logs
2. Check ArgoCD application status
3. Review this guide's troubleshooting section
4. Check `docs/ARGOCD_SETUP.txt` for detailed setup
5. Review kubectl/ArgoCD logs

---

**Last Updated:** October 6, 2025  
**Version:** 1.0


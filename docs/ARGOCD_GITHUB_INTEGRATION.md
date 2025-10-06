# How ArgoCD Connects with GitHub Actions

## 🔄 The Complete Integration Flow

ArgoCD and GitHub Actions work **together** but handle **different parts** of the deployment pipeline.

---

## 📊 Visual Workflow Diagram

```
Developer
    |
    | git push
    ↓
┌─────────────────────────────────────────────────────────────┐
│                         GITHUB                              │
│                                                             │
│  ┌────────────────────┐         ┌────────────────────┐    │
│  │  GitHub Repository │◄────────│  GitHub Actions    │    │
│  │  (Source Code +    │         │  (CI Pipeline)     │    │
│  │   Helm Charts)     │         │                    │    │
│  └────────┬───────────┘         └────────┬───────────┘    │
│           │                               │                │
│           │ Webhook (instant)             │ Commits back   │
│           │                               │ new image tag  │
└───────────┼───────────────────────────────┼────────────────┘
            │                               │
            │                               │
            ↓                               ↓
┌───────────────────────┐      ┌──────────────────────────┐
│      ARGOCD           │      │      AWS ECR             │
│  (CD/GitOps Tool)     │      │  (Container Registry)    │
│                       │      │                          │
│  - Watches Git repo   │◄─────│  Stores Docker images    │
│  - Syncs to cluster   │      │  with tags               │
│  - Deploys changes    │      └──────────────────────────┘
└───────────┬───────────┘
            │
            │ kubectl apply
            ↓
┌───────────────────────┐
│    EKS CLUSTER        │
│  (Kubernetes)         │
│                       │
│  - Pulls new image    │
│  - Deploys pods       │
│  - Updates app        │
└───────────────────────┘
```

---

## 🎯 How They Connect (The Git Repository!)

**Connection Point: Your Git Repository**

- **GitHub Actions** writes TO Git (commits new image tags)
- **ArgoCD** reads FROM Git (syncs manifests to Kubernetes)
- **Git is the single source of truth** for both!

---

## 📝 Detailed Flow Breakdown

### Part 1: GitHub Actions (CI - Continuous Integration)

**Trigger:** Code push to `main` branch

**What it does:**
1. ✅ Detects code changes in `src/`
2. ✅ Builds Docker image
3. ✅ Pushes image to AWS ECR with commit SHA tag
4. ✅ Updates `charts/filmcastpro/values.yaml` with new image tag
5. ✅ Commits updated `values.yaml` back to Git

**File:** `.github/workflows/deploy.yml`

```yaml
# Simplified GitHub Actions workflow
on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - 'Dockerfile'

jobs:
  build:
    - Build Docker image
    - Tag: 008099619893.dkr.ecr.../filmcastpro:abc123def
    - Push to ECR
    - Update values.yaml: tag: "abc123def"
    - git commit & push values.yaml
```

---

### Part 2: ArgoCD (CD - Continuous Deployment)

**Trigger:** Git repository changes (via webhook OR polling)

**What it does:**
1. ✅ Detects `values.yaml` was updated
2. ✅ Compares Git state vs Cluster state
3. ✅ Sees cluster is "OutOfSync"
4. ✅ Pulls new manifests from Git
5. ✅ Applies changes to Kubernetes
6. ✅ Kubernetes pulls new image from ECR
7. ✅ Deploys updated pods

**File:** `argocd/filmcastpro-app.yaml`

```yaml
# ArgoCD Application
spec:
  source:
    repoURL: https://github.com/sadaf-jamal-au27/FilmCastPro
    path: charts/filmcastpro
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 🔗 The Connection Points

### 1. GitHub Repository (Primary Connection)

Both tools watch the **same Git repository**:

```
sadaf-jamal-au27/FilmCastPro
├── src/                    ← GitHub Actions monitors
├── Dockerfile              ← GitHub Actions monitors
├── charts/filmcastpro/     ← ArgoCD monitors
    └── values.yaml         ← THE KEY CONNECTION FILE!
```

### 2. GitHub Webhook (Secondary Connection)

Enables instant ArgoCD sync:

```
GitHub → Webhook → ArgoCD
         (instant notification when Git changes)
```

**Webhook URL:**
```
http://a551743f3fc024c65a454d33fc456236-1486486352.us-east-1.elb.amazonaws.com/api/webhook
```

When GitHub Actions commits `values.yaml`, the webhook instantly tells ArgoCD!

---

## 🎬 Complete Timeline Example

**Scenario:** You change `src/App.tsx` and push to GitHub

```
T+0:00  │ git push origin main
        │
T+0:05  │ GitHub Actions workflow starts
        │ └─ Checkout code
        │ └─ Login to ECR
        │ └─ Build Docker image
        │
T+2:00  │ GitHub Actions pushes image to ECR
        │ Image: filmcastpro:7320a70... ✓
        │
T+2:30  │ GitHub Actions updates values.yaml
        │ OLD: tag: "abc123"
        │ NEW: tag: "7320a70..."
        │
T+2:35  │ GitHub Actions commits to Git
        │ git commit -m "Update image tag to 7320a70"
        │ git push
        │ 
T+2:36  │ GitHub webhook fires → ArgoCD
        │ "Hey ArgoCD! Git changed!"
        │
T+2:37  │ ArgoCD detects changes
        │ Compares: Git (7320a70) vs Cluster (abc123)
        │ Status: OutOfSync
        │
T+2:40  │ ArgoCD syncs automatically
        │ kubectl apply -f charts/filmcastpro/
        │
T+3:00  │ Kubernetes pulls new image
        │ docker pull ...filmcastpro:7320a70
        │
T+3:30  │ New pod starts
        │ Old pod terminates
        │ LoadBalancer routes traffic
        │
T+4:00  │ ✨ DEPLOYMENT COMPLETE!
        │ Users see new version
```

---

## 🔑 Key Files That Connect Them

### 1. `.github/workflows/deploy.yml` (GitHub Actions)

The part that updates Git:

```yaml
- name: Update Helm values with new image tag
  env:
    IMAGE_TAG: ${{ github.sha }}
  run: |
    sed -i "s|tag:.*|tag: \"$IMAGE_TAG\"|" charts/filmcastpro/values.yaml

- name: Commit and push updated values
  run: |
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add charts/filmcastpro/values.yaml
    git commit -m "chore: update image tag to $IMAGE_TAG [skip ci]"
    git push
```

This is the **CONNECTION POINT** - GitHub Actions writes the new image tag!

### 2. `argocd/filmcastpro-app.yaml` (ArgoCD Config)

The part that watches Git:

```yaml
spec:
  source:
    repoURL: https://github.com/sadaf-jamal-au27/FilmCastPro
    targetRevision: main
    path: charts/filmcastpro
    helm:
      valueFiles:
        - values.yaml  # ← Watches this file!
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true  # Auto-sync when changes detected
```

ArgoCD reads the new image tag and deploys it!

### 3. `charts/filmcastpro/values.yaml` (The Bridge)

The file that connects both:

```yaml
image:
  repository: 008099619893.dkr.ecr.us-east-1.amazonaws.com/filmcastpro
  tag: "7320a7007f64149f5f7502c1eca461a4a67e9903"  # ← Updated by GitHub Actions
  pullPolicy: IfNotPresent                          # ← Read by ArgoCD
```

---

## 🧠 Understanding the Separation

### GitHub Actions (CI) = Image Builder

**Responsibility:**
- Build application
- Create Docker images
- Push to container registry
- Update Git with new image tags

**Does NOT:**
- Deploy to Kubernetes
- Manage kubectl/helm directly
- Know about cluster state

### ArgoCD (CD) = Deployment Manager

**Responsibility:**
- Monitor Git repository
- Sync Git → Kubernetes
- Manage cluster state
- Handle rollouts and rollbacks

**Does NOT:**
- Build Docker images
- Push to ECR
- Run CI tests

---

## 🔄 Why This Separation is Powerful

### 1. **Single Source of Truth (Git)**
Everything is in Git - full audit trail

### 2. **Separation of Concerns**
- GitHub Actions: Build & package
- ArgoCD: Deploy & maintain

### 3. **Security**
GitHub Actions doesn't need cluster access!
Only ArgoCD talks to Kubernetes

### 4. **Easy Rollbacks**
```bash
git revert HEAD        # Revert the commit
# ArgoCD auto-deploys previous version!
```

### 5. **Multi-Environment**
Same GitHub Actions builds image
Different ArgoCD apps deploy to dev/staging/prod

---

## 📡 The Webhook Connection

### Why Webhooks Matter

Without webhook:
```
ArgoCD polls Git every 3 minutes
│
├─ 0:00 - Check Git (no change)
├─ 3:00 - Check Git (no change)
├─ 6:00 - Check Git (FOUND CHANGE!) → Sync
```
**Delay: Up to 3 minutes**

With webhook:
```
GitHub Actions commits → Webhook fires → ArgoCD syncs immediately
```
**Delay: ~5 seconds!** ⚡

### How to Verify Webhook Works

```bash
# Check ArgoCD received webhook
kubectl logs -n argocd deploy/argocd-server | grep webhook

# Check GitHub webhook deliveries
# Go to: https://github.com/sadaf-jamal-au27/FilmCastPro/settings/hooks
# Click your webhook → "Recent Deliveries"
# Should show green ✓ for successful deliveries
```

---

## 🎯 Testing the Integration

### Test 1: GitHub Actions Only

```bash
# Make a code change
echo "console.log('test');" >> src/App.tsx
git add src/App.tsx
git commit -m "test: trigger GitHub Actions"
git push

# Check GitHub Actions
# https://github.com/sadaf-jamal-au27/FilmCastPro/actions
# Should see workflow running
```

### Test 2: ArgoCD Only

```bash
# Make a config change
# Edit charts/filmcastpro/values.yaml
# Change replicaCount: 2
git add charts/filmcastpro/values.yaml
git commit -m "scale: increase replicas"
git push

# Check ArgoCD
# Should sync and create 2 pods
kubectl get pods -n filmcastpro
```

### Test 3: Full Integration

```bash
# Code change triggers both
echo "// Integration test" >> src/App.tsx
git add src/App.tsx
git commit -m "test: full pipeline"
git push

# Watch the flow:
# 1. GitHub Actions builds image
# 2. Updates values.yaml
# 3. Webhook triggers ArgoCD
# 4. ArgoCD deploys to cluster
```

---

## 🐛 Troubleshooting the Connection

### Issue 1: GitHub Actions Runs But ArgoCD Doesn't Sync

**Check:**
```bash
# Did GitHub Actions update values.yaml?
git log -1 charts/filmcastpro/values.yaml

# Is webhook working?
# GitHub → Settings → Webhooks → Check delivery status
```

**Fix:**
- Ensure GitHub Actions has permission to push
- Check webhook URL is correct
- Verify ArgoCD can reach GitHub

### Issue 2: ArgoCD Syncs But Old Image

**Check:**
```bash
# What image tag is in Git?
cat charts/filmcastpro/values.yaml | grep tag

# What image is running?
kubectl get deployment filmcastpro -n filmcastpro -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Fix:**
- Ensure GitHub Actions pushed new tag to ECR
- Check ArgoCD pulled latest from Git
- Force sync: `argocd app sync filmcastpro`

### Issue 3: GitHub Actions Fails

**Check:**
```bash
# Are AWS credentials in GitHub Secrets?
# GitHub → Settings → Secrets → Actions

# Check workflow logs
# GitHub → Actions → Click failed run
```

**Fix:**
- Add AWS_ACCESS_KEY_ID
- Add AWS_SECRET_ACCESS_KEY
- Verify IAM permissions

---

## 📚 Summary

### How They Connect:

1. **Git Repository** = Communication medium
2. **GitHub Actions** = Writes new image tags to Git
3. **Webhook** = Notifies ArgoCD of changes
4. **ArgoCD** = Reads from Git and deploys to Kubernetes

### The Flow:

```
Code Change
    ↓
GitHub Actions (CI)
    ↓
Git Commit (values.yaml update)
    ↓
Webhook Notification
    ↓
ArgoCD (CD)
    ↓
Kubernetes Deployment
```

### Key Insight:

**They don't directly communicate!**
They both use **Git as the integration layer**.

This is the core principle of **GitOps**:
> Git is the single source of truth

---

## 🎓 Further Learning

- **GitOps Principles:** https://opengitops.dev/
- **ArgoCD Architecture:** https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Your Setup:** All files in `/Users/sadafperveen05/Devops/FilmCastPro/`

---

**Last Updated:** October 6, 2025  
**Version:** 1.0


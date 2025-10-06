# ArgoCD Installation & Setup Guide

## Quick Installation Steps

### 1. Install ArgoCD on EKS

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 2. Access ArgoCD UI

**Option A: LoadBalancer (Recommended)**
```bash
# Expose via LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get LoadBalancer URL
kubectl get svc argocd-server -n argocd

# Access: http://[EXTERNAL-IP]
```

**Option B: Port Forward (Quick Testing)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access: https://localhost:8080
```

### 3. Get Admin Password

```bash
# Get initial admin password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Login credentials:
# Username: admin
# Password: [output from above]
```

### 4. Install ArgoCD CLI (Optional)

**macOS:**
```bash
brew install argocd
```

**Linux:**
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

**Login via CLI:**
```bash
argocd login [ARGOCD-SERVER-URL]
# Enter admin username and password
```

### 5. Deploy FilmCastPro Application

```bash
# Apply the ArgoCD application manifest
kubectl apply -f argocd/filmcastpro-app.yaml

# Verify application is created
kubectl get application filmcastpro -n argocd

# Check sync status
argocd app get filmcastpro
```

### 6. Setup GitHub Actions (CI/CD)

**Add GitHub Secrets:**
1. Go to: https://github.com/sadaf-jamal-au27/FilmCastPro/settings/secrets/actions
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

**Workflow is already configured in:**
`.github/workflows/deploy.yml`

**How it works:**
1. Push code to `main` branch
2. GitHub Actions builds Docker image
3. Pushes to ECR with new tag
4. Updates Helm values.yaml with new tag
5. Commits changes to Git
6. ArgoCD detects change and auto-deploys

### 7. Verify Deployment

```bash
# Check ArgoCD application status
argocd app list
argocd app get filmcastpro

# Check pods in filmcastpro namespace
kubectl get pods -n filmcastpro

# Get LoadBalancer URL
kubectl get svc filmcastpro -n filmcastpro
```

## GitOps Workflow

```
┌──────────────┐
│   Developer  │
│  Pushes Code │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  GitHub Actions  │
│  Builds Image    │
│  Pushes to ECR   │
│  Updates values  │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│   Git Repository │
│  (Source of      │
│   Truth)         │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│     ArgoCD       │
│  Detects Change  │
│  Auto Syncs      │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│   EKS Cluster    │
│  FilmCastPro     │
│  Updated!        │
└──────────────────┘
```

## Useful Commands

### ArgoCD Application Management
```bash
# List all applications
argocd app list

# Get application details
argocd app get filmcastpro

# Sync application manually
argocd app sync filmcastpro

# View application logs
argocd app logs filmcastpro

# Delete application
argocd app delete filmcastpro
```

### Troubleshooting
```bash
# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Check application status
kubectl describe application filmcastpro -n argocd

# Force sync
argocd app sync filmcastpro --force

# View diff between Git and cluster
argocd app diff filmcastpro
```

## Next Steps

1. ✅ Install ArgoCD
2. ✅ Deploy FilmCastPro app
3. ✅ Setup GitHub Actions
4. 📝 Change admin password
5. 📝 Configure RBAC for team access
6. 📝 Set up monitoring and alerts
7. 📝 Create dev/staging environments

## Documentation

- Full ArgoCD setup guide: `docs/ARGOCD_SETUP.txt`
- ArgoCD official docs: https://argo-cd.readthedocs.io/
- ArgoCD GitHub: https://github.com/argoproj/argo-cd


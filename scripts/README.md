# 🚀 FilmCastPro - Automation Scripts

This folder contains automation scripts for managing your EKS deployment.

## 📋 Scripts Overview

### 1. `START_EKS_TOMORROW.sh`
**Purpose:** Deploy complete EKS infrastructure and application

**What it does:**
- ✅ Checks prerequisites (AWS credentials, tools)
- ✅ Deploys EKS cluster with Terraform (~15 minutes)
- ✅ Configures kubectl
- ✅ Installs ArgoCD (~5 minutes)
- ✅ Deploys FilmCastPro application (~3 minutes)
- ✅ Provides access URLs and credentials

**Usage:**
```bash
cd /Users/sadafperveen05/Devops/FilmCastPro
./scripts/START_EKS_TOMORROW.sh
```

**Time:** ~30 minutes  
**Cost:** Starts charging ~$0.25/hour

---

### 2. `STOP_EKS.sh`
**Purpose:** Clean up all AWS resources to stop charges

**What it does:**
- ✅ Deletes Kubernetes Load Balancers
- ✅ Destroys all AWS infrastructure with Terraform
- ✅ Stops all AWS charges
- ✅ Preserves your code and Docker images

**Usage:**
```bash
cd /Users/sadafperveen05/Devops/FilmCastPro
./scripts/STOP_EKS.sh
```

**Time:** ~10 minutes  
**Result:** $0/hour AWS charges

---

## 🔄 Daily Workflow

### Morning (Start Work)
```bash
./scripts/START_EKS_TOMORROW.sh
```
Wait ~30 minutes for complete setup.

### During Day (Make Changes)
```bash
# Edit your code
cd src/
# ... make changes ...

# Commit and push
git add .
git commit -m "your changes"
git push

# Check email 📧 for deployment notification!
# ArgoCD automatically deploys your changes
```

### Evening (Stop Charges)
```bash
./scripts/STOP_EKS.sh
```
Wait ~10 minutes for cleanup.

---

## 💰 Cost Management

| Duration | Cost |
|----------|------|
| 1 hour | ~$0.25 |
| 8 hours (workday) | ~$2.00 |
| 24 hours | ~$6.00 |
| Month (24/7) | ~$160 |
| Month (8h/day, 20 days) | ~$40 |

**Pro Tip:** Always run `STOP_EKS.sh` at end of day to minimize costs!

---

## 🔍 Quick Reference Commands

After starting with `START_EKS_TOMORROW.sh`, use these:

```bash
# Check cluster status
kubectl get nodes

# Check your application pods
kubectl get pods -n filmcastpro

# View application logs
kubectl logs -n filmcastpro -l app.kubernetes.io/name=filmcastpro -f

# Get application URL
kubectl get svc -n filmcastpro filmcastpro

# Access ArgoCD dashboard
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Then open: https://localhost:8080

# Check ArgoCD applications
kubectl get applications -n argocd

# Restart your application
kubectl rollout restart deployment/filmcastpro -n filmcastpro
```

---

## 🚨 Important Notes

### Before Running START_EKS_TOMORROW.sh:
- ✅ AWS credentials configured: `aws sts get-caller-identity`
- ✅ Docker running: `docker ps`
- ✅ All tools installed: `terraform`, `kubectl`, `helm`
- ✅ Have ~30 minutes to wait for setup

### Before Running STOP_EKS.sh:
- ⚠️ This will DELETE all AWS resources
- ✅ Your code in GitHub is safe
- ✅ Docker images in ECR are preserved
- ✅ You can restart tomorrow with START_EKS_TOMORROW.sh

### Security:
- 🔐 Never commit AWS credentials to Git
- 🔐 ArgoCD password is shown once during setup (save it!)
- 🔐 GitHub Actions secrets are already configured

---

## 📧 Email Notifications

Both scripts work with your existing email notification setup.

Every code push triggers:
1. GitHub Actions builds Docker image
2. Pushes to ECR
3. Updates Helm chart in Git
4. ArgoCD auto-syncs to Kubernetes
5. **Email sent to:** jamalsadaff4@gmail.com ✉️

Email includes:
- ✅ Deployment status (success/failure)
- ✅ Commit details
- ✅ Direct link to your app
- ✅ Troubleshooting tips

---

## 🐛 Troubleshooting

### If START_EKS_TOMORROW.sh fails:

1. **Pre-flight check fails:**
   ```bash
   aws configure  # Set up AWS credentials
   ```

2. **Terraform fails:**
   ```bash
   cd infra/eks
   terraform destroy -auto-approve  # Clean up
   terraform apply -auto-approve    # Try again
   ```

3. **ArgoCD not installing:**
   - Wait 5 more minutes (it takes time)
   - Check pods: `kubectl get pods -n argocd`

4. **Application not deploying:**
   ```bash
   kubectl get pods -n filmcastpro
   kubectl describe pod -n filmcastpro <pod-name>
   kubectl logs -n filmcastpro <pod-name>
   ```

### If STOP_EKS.sh hangs:

1. **Load balancers not deleting:**
   - Script handles this automatically
   - Wait for it to complete (up to 10 minutes)

2. **Terraform destroy fails:**
   ```bash
   # Manually check what's left
   cd infra/eks
   terraform state list
   
   # Force destroy
   terraform destroy -auto-approve
   ```

---

## 📚 Related Documentation

- **Complete Guide:** `../docs/RESTART_GUIDE.md`
- **Deployment Details:** `../docs/DEPLOYMENT_GUIDE.txt`
- **ArgoCD Setup:** `../docs/ARGOCD_SETUP.txt`
- **Email Setup:** `../docs/EMAIL_NOTIFICATIONS_SETUP.md`
- **Architecture:** `../docs/ARCHITECTURE.txt`

---

## 🎯 What You're Learning

By using these scripts, you're practicing:

- **Infrastructure as Code** (Terraform)
- **Container Orchestration** (Kubernetes/EKS)
- **GitOps** (ArgoCD)
- **CI/CD** (GitHub Actions)
- **Cloud Management** (AWS)
- **Cost Optimization**
- **Automation & Scripting**

---

## ✅ Success Criteria

After running `START_EKS_TOMORROW.sh`, you should have:

- ✅ EKS cluster running with 2 nodes
- ✅ ArgoCD installed and accessible
- ✅ FilmCastPro application deployed
- ✅ Public URL for your application
- ✅ ArgoCD credentials saved
- ✅ GitOps pipeline active

After running `STOP_EKS.sh`, you should have:

- ✅ All AWS resources deleted
- ✅ $0/hour charges
- ✅ Code safe in GitHub
- ✅ Ready to restart tomorrow

---

## 🆘 Need Help?

1. Check the script output messages (they're detailed!)
2. Review troubleshooting section above
3. Check the full documentation in `/docs/`
4. Verify AWS credentials: `aws sts get-caller-identity`

---

**Happy DevOps! 🚀**


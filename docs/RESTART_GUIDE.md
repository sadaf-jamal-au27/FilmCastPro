# 🚀 RESTART GUIDE - How to Redeploy Everything

## Quick Start Tomorrow (30 minutes)

### Prerequisites Check
```bash
# Verify tools are installed
aws --version
terraform --version
kubectl version --client
helm version
docker --version
```

---

## 🎯 OPTION 1: Full EKS Deployment (Recommended for Production)

### Step 1: Start AWS Infrastructure (15 minutes)
```bash
cd /Users/sadafperveen05/Devops/FilmCastPro/infra/eks

# Initialize Terraform (only if fresh start)
terraform init

# Preview what will be created
terraform plan

# Create all AWS resources
terraform apply -auto-approve

# This creates:
# ✅ VPC & Networking
# ✅ EKS Cluster
# ✅ 2x t3.small worker nodes
# ✅ Load Balancer
# ✅ IAM roles & policies

# Wait ~15 minutes for cluster to be ready
```

### Step 2: Configure kubectl (1 minute)
```bash
# Connect to your EKS cluster
aws eks update-kubeconfig --region us-east-1 --name filmcastpro

# Verify connection
kubectl get nodes
# You should see 2 nodes in Ready state
```

### Step 3: Install ArgoCD (5 minutes)
```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready (2-3 minutes)
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
# Save this password!

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open browser: https://localhost:8080
# Username: admin
# Password: (from command above)
```

### Step 4: Deploy Your Application (5 minutes)
```bash
cd /Users/sadafperveen05/Devops/FilmCastPro

# Deploy app via ArgoCD
kubectl apply -f argocd/filmcastpro-app.yaml

# Wait for deployment
kubectl get pods -n filmcastpro --watch
# Wait until pods show "Running" status

# Get your application URL
kubectl get svc -n filmcastpro filmcastpro -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# This will show your public URL (takes 2-3 minutes to provision)
```

### Step 5: Verify Everything Works
```bash
# Check ArgoCD sync status
kubectl get application -n argocd filmcastpro

# Check your pods
kubectl get pods -n filmcastpro

# Check your service
kubectl get svc -n filmcastpro

# Get logs if needed
kubectl logs -n filmcastpro -l app.kubernetes.io/name=filmcastpro
```

**🎉 Done! Your app is live with automatic GitOps deployment!**

---

## 🎯 OPTION 2: Local Development with Kind (5 minutes)

### Perfect for testing without AWS costs!

```bash
cd /Users/sadafperveen05/Devops/FilmCastPro

# Create Kind cluster
kind create cluster --name filmcastpro --config kind-config.yaml

# Build Docker image
docker build -t filmcastpro:latest .

# Load image into Kind
kind load docker-image filmcastpro:latest --name filmcastpro

# Deploy with Helm
helm upgrade --install filmcastpro ./charts/filmcastpro \
  --set image.repository=filmcastpro \
  --set image.tag=latest \
  --set service.type=NodePort \
  --set service.nodePort=30080 \
  --create-namespace \
  --namespace filmcastpro

# Access your app
open http://localhost:30080
```

**🎉 Done! App running locally, no AWS charges!**

---

## 📧 Re-enable Email Notifications

Your GitHub Actions workflow is already configured!

Just make sure these secrets are still in GitHub:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EMAIL_USERNAME` (your Gmail address)
- `EMAIL_PASSWORD` (Gmail App Password)

Any code push to `main` branch will:
1. Build Docker image
2. Push to ECR
3. Update Helm values
4. ArgoCD auto-syncs
5. **Send you an email!** 📧

---

## 🔄 Making Changes Tomorrow

### To update your application:

```bash
cd /Users/sadafperveen05/Devops/FilmCastPro

# Make your code changes in src/

# Commit and push
git add .
git commit -m "feat: your changes"
git push origin main

# That's it! GitHub Actions will:
# ✅ Build new Docker image
# ✅ Push to ECR
# ✅ Update Git with new image tag
# ✅ ArgoCD will detect change and deploy
# ✅ Email you when done!
```

---

## 🛑 Stop Everything (To Avoid Charges)

### At end of day, destroy AWS resources:

```bash
cd /Users/sadafperveen05/Devops/FilmCastPro/infra/eks

# Delete all AWS resources
terraform destroy -auto-approve

# Takes ~10 minutes
# Cost: $0 while stopped!
```

### For Kind (local):
```bash
kind delete cluster --name filmcastpro
```

**Note:** All automation scripts are now in the `scripts/` folder!

---

## 💰 Cost Management

### Running Costs (EKS):
- **Per Hour**: ~$0.25/hour
- **8-hour workday**: ~$2/day
- **Full month 24/7**: ~$160/month

### My Recommendation:
```bash
# Morning (Start work)
cd infra/eks && terraform apply -auto-approve

# Evening (Stop work)
cd infra/eks && terraform destroy -auto-approve

# Cost: ~$2/day for 8 hours
```

---

## 📝 Quick Reference Commands

### Check Cluster Status
```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

### View Logs
```bash
kubectl logs -n filmcastpro -l app.kubernetes.io/name=filmcastpro --tail=50 -f
```

### ArgoCD Dashboard
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
```

### Get App URL
```bash
kubectl get svc -n filmcastpro filmcastpro -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Restart Deployment
```bash
kubectl rollout restart deployment/filmcastpro -n filmcastpro
```

---

## 🐛 Troubleshooting

### If Terraform fails:
```bash
cd /Users/sadafperveen05/Devops/FilmCastPro/infra/eks
terraform destroy -auto-approve
terraform apply -auto-approve
```

### If pods are not starting:
```bash
kubectl describe pod -n filmcastpro <pod-name>
kubectl logs -n filmcastpro <pod-name>
```

### If ArgoCD not syncing:
```bash
# Force sync
kubectl patch application filmcastpro -n argocd --type merge -p '{"operation": {"sync": {}}}'
```

### If Load Balancer stuck:
```bash
# Delete and recreate service
kubectl delete svc filmcastpro -n filmcastpro
kubectl rollout restart deployment/filmcastpro -n filmcastpro
```

---

## 🎓 What to Practice Tomorrow

1. **Morning**: Deploy with Option 1 (EKS)
2. **Make a code change** in `src/App.tsx`
3. **Push to GitHub** and watch the pipeline
4. **Check your email** for deployment notification
5. **View in ArgoCD** dashboard
6. **Evening**: Destroy resources

**Time investment**: 30 min setup + however long you want to work

---

## 📚 Documentation References

All your guides are in `/docs/`:
- `DEPLOYMENT_GUIDE.txt` - Detailed step-by-step
- `QUICK_START.txt` - Fast reference
- `ARCHITECTURE.txt` - How everything connects
- `ARGOCD_SETUP.txt` - ArgoCD deep dive
- `EMAIL_NOTIFICATIONS_SETUP.md` - Email setup
- `GITHUB_INTEGRATION.md` - GitHub + ArgoCD integration

---

## 🎯 Tomorrow's Goal Suggestions

### Beginner Level:
- ✅ Deploy to EKS successfully
- ✅ Make a small UI change
- ✅ See it auto-deploy via GitOps
- ✅ Destroy resources when done

### Intermediate Level:
- ✅ Add a new route to the app
- ✅ Configure custom domain (Route53)
- ✅ Add SSL certificate (ACM)
- ✅ Monitor with CloudWatch

### Advanced Level:
- ✅ Set up staging + production environments
- ✅ Add automated testing in pipeline
- ✅ Implement blue-green deployment
- ✅ Add Prometheus monitoring

---

## 🆘 Need Help?

All commands are in this guide. If stuck:
1. Check the error message
2. Look in `/docs/` for detailed guides
3. Review the troubleshooting section above
4. Check kubectl logs for pod issues

---

## ✅ Pre-Flight Checklist for Tomorrow

Before starting:
- [ ] AWS credentials configured (`aws configure`)
- [ ] `terraform`, `kubectl`, `helm`, `kind` installed
- [ ] Docker running
- [ ] GitHub repo accessible
- [ ] This guide handy!

---

**You're all set! Tomorrow will be productive! 🚀**


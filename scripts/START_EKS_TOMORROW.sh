#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════╗
# ║          🚀 FILMCASTPRO - EKS START SCRIPT 🚀                        ║
# ║                  Run this tomorrow morning!                          ║
# ╚══════════════════════════════════════════════════════════════════════╝

set -e  # Exit on any error

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║          🚀 Starting FilmCastPro on AWS EKS 🚀                       ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# STEP 1: Pre-flight checks
# ============================================================================
echo -e "${BLUE}Step 1/6: Running pre-flight checks...${NC}"
echo ""

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured!"
    echo "Run: aws configure"
    exit 1
fi
echo "✅ AWS credentials configured"

# Check required tools
command -v terraform >/dev/null 2>&1 || { echo "❌ terraform not installed"; exit 1; }
echo "✅ Terraform installed"

command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not installed"; exit 1; }
echo "✅ kubectl installed"

command -v helm >/dev/null 2>&1 || { echo "❌ helm not installed"; exit 1; }
echo "✅ Helm installed"

echo ""
echo -e "${GREEN}✅ All pre-flight checks passed!${NC}"
echo ""

# ============================================================================
# STEP 2: Deploy AWS Infrastructure with Terraform
# ============================================================================
echo -e "${BLUE}Step 2/6: Deploying AWS Infrastructure (EKS Cluster)...${NC}"
echo "This will take approximately 15 minutes ⏱️"
echo ""

cd /Users/sadafperveen05/Devops/FilmCastPro/infra/eks

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Apply Terraform
echo ""
echo "Creating AWS resources..."
echo "  • VPC & Networking"
echo "  • EKS Cluster"
echo "  • 2x t3.small worker nodes"
echo "  • Load Balancer"
echo "  • IAM roles & policies"
echo ""

terraform apply -auto-approve

echo ""
echo -e "${GREEN}✅ AWS Infrastructure deployed!${NC}"
echo ""

# ============================================================================
# STEP 3: Configure kubectl
# ============================================================================
echo -e "${BLUE}Step 3/6: Configuring kubectl for EKS...${NC}"
echo ""

aws eks update-kubeconfig --region us-east-1 --name filmcastpro

echo "Waiting for nodes to be ready..."
sleep 30

kubectl get nodes

echo ""
echo -e "${GREEN}✅ kubectl configured!${NC}"
echo ""

# ============================================================================
# STEP 4: Install ArgoCD
# ============================================================================
echo -e "${BLUE}Step 4/6: Installing ArgoCD...${NC}"
echo ""

# Create ArgoCD namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo "Waiting for ArgoCD to be ready (this takes ~3 minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo ""
echo -e "${GREEN}✅ ArgoCD installed!${NC}"
echo ""

# Get ArgoCD password
echo "📝 ArgoCD Admin Password:"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "   Save this password! You'll need it to access ArgoCD dashboard."
echo ""

# ============================================================================
# STEP 5: Deploy Application via ArgoCD
# ============================================================================
echo -e "${BLUE}Step 5/6: Deploying FilmCastPro application...${NC}"
echo ""

cd /Users/sadafperveen05/Devops/FilmCastPro

# Apply ArgoCD application
kubectl apply -f argocd/filmcastpro-app.yaml

echo ""
echo "Waiting for application to deploy (this takes ~3 minutes)..."
sleep 60

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=filmcastpro -n filmcastpro --timeout=300s || true

echo ""
echo -e "${GREEN}✅ Application deployed!${NC}"
echo ""

# ============================================================================
# STEP 6: Get Access URLs
# ============================================================================
echo -e "${BLUE}Step 6/6: Getting access information...${NC}"
echo ""

# Get Load Balancer URL
echo "⏳ Waiting for Load Balancer to be ready (this takes ~2 minutes)..."
sleep 120

APP_URL=$(kubectl get svc -n filmcastpro filmcastpro -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Still provisioning...")

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                    🎉 DEPLOYMENT COMPLETE! 🎉                        ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 YOUR APPLICATION:"
echo "   URL: http://$APP_URL"
echo "   (If 'Still provisioning', wait 2 more minutes and run: kubectl get svc -n filmcastpro)"
echo ""
echo "🎨 ARGOCD DASHBOARD:"
echo "   1. Run in new terminal: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   2. Open: https://localhost:8080"
echo "   3. Login with:"
echo "      Username: admin"
echo "      Password: $ARGOCD_PASSWORD"
echo ""
echo "📧 EMAIL NOTIFICATIONS:"
echo "   Already configured! You'll receive emails at: jamalsadaff4@gmail.com"
echo "   Every code push to GitHub triggers:"
echo "     ✅ Automatic build"
echo "     ✅ Push to ECR"
echo "     ✅ ArgoCD sync"
echo "     ✅ Email notification"
echo ""
echo "🔄 TO MAKE CHANGES:"
echo "   1. Edit code in: src/"
echo "   2. git add . && git commit -m 'your message' && git push"
echo "   3. Check your email for deployment notification 📧"
echo "   4. Changes go live automatically via ArgoCD!"
echo ""
echo "📊 USEFUL COMMANDS:"
echo "   Check pods:          kubectl get pods -n filmcastpro"
echo "   Check logs:          kubectl logs -n filmcastpro -l app.kubernetes.io/name=filmcastpro -f"
echo "   Check ArgoCD apps:   kubectl get applications -n argocd"
echo "   Restart app:         kubectl rollout restart deployment/filmcastpro -n filmcastpro"
echo ""
echo "💰 COST INFO:"
echo "   Current cost: ~\$0.25/hour (~\$2 for 8-hour workday)"
echo "   Running 24/7: ~\$160/month"
echo ""
echo "🛑 TO STOP & AVOID CHARGES (at end of day):"
echo "   cd /Users/sadafperveen05/Devops/FilmCastPro/infra/eks"
echo "   terraform destroy -auto-approve"
echo ""
echo "✅ You're all set! Happy coding! 🚀"
echo ""


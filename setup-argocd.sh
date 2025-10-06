#!/bin/bash
################################################################################
# ArgoCD Setup Script for FilmCastPro
# This script installs and configures ArgoCD on your EKS cluster
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ArgoCD Setup for FilmCastPro         ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed. Aborting.${NC}" >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI is required but not installed. Aborting.${NC}" >&2; exit 1; }

# Verify EKS connection
kubectl cluster-info >/dev/null 2>&1 || { echo -e "${RED}Not connected to Kubernetes cluster. Run: aws eks update-kubeconfig --region us-east-1 --name filmcastpro${NC}" >&2; exit 1; }
echo -e "${GREEN}✓ Prerequisites verified${NC}"
echo ""

# Install ArgoCD
echo -e "${YELLOW}[2/7] Installing ArgoCD...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo -e "${GREEN}✓ ArgoCD installed${NC}"
echo ""

# Wait for ArgoCD to be ready
echo -e "${YELLOW}[3/7] Waiting for ArgoCD pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
echo -e "${GREEN}✓ ArgoCD is ready${NC}"
echo ""

# Expose ArgoCD via LoadBalancer
echo -e "${YELLOW}[4/7] Exposing ArgoCD via LoadBalancer...${NC}"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
echo -e "${GREEN}✓ ArgoCD server exposed${NC}"
echo ""

# Get admin password
echo -e "${YELLOW}[5/7] Retrieving admin password...${NC}"
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
echo -e "${GREEN}✓ Password retrieved${NC}"
echo ""

# Wait for LoadBalancer
echo -e "${YELLOW}[6/7] Waiting for LoadBalancer URL...${NC}"
echo "This may take 2-3 minutes..."
ARGOCD_URL=""
for i in {1..60}; do
  ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [ -n "$ARGOCD_URL" ]; then
    break
  fi
  sleep 5
  echo -n "."
done
echo ""

if [ -z "$ARGOCD_URL" ]; then
  echo -e "${YELLOW}LoadBalancer URL not available yet. Check manually with: kubectl get svc argocd-server -n argocd${NC}"
else
  echo -e "${GREEN}✓ LoadBalancer ready${NC}"
fi
echo ""

# Deploy FilmCastPro application
echo -e "${YELLOW}[7/7] Deploying FilmCastPro application...${NC}"
kubectl apply -f argocd/filmcastpro-app.yaml
echo -e "${GREEN}✓ FilmCastPro application created${NC}"
echo ""

# Print summary
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Setup Complete! 🎉            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}ArgoCD Access Details:${NC}"
echo -e "  URL:      ${GREEN}http://${ARGOCD_URL}${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}${ARGOCD_PASSWORD}${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Access ArgoCD UI at the URL above"
echo "  2. Login with the credentials shown"
echo "  3. Navigate to 'filmcastpro' application"
echo "  4. Check sync status and health"
echo ""
echo -e "${YELLOW}ArgoCD CLI Setup (optional):${NC}"
echo "  brew install argocd"
echo "  argocd login ${ARGOCD_URL}"
echo ""
echo -e "${YELLOW}View Application Status:${NC}"
echo "  kubectl get application filmcastpro -n argocd"
echo "  kubectl get pods -n filmcastpro"
echo ""
echo -e "${YELLOW}GitHub Actions Setup:${NC}"
echo "  1. Go to: https://github.com/sadaf-jamal-au27/FilmCastPro/settings/secrets/actions"
echo "  2. Add: AWS_ACCESS_KEY_ID"
echo "  3. Add: AWS_SECRET_ACCESS_KEY"
echo "  4. Push to main branch to trigger auto-deployment"
echo ""
echo -e "${GREEN}Documentation:${NC}"
echo "  Quick Guide:  argocd/INSTALL.md"
echo "  Full Guide:   docs/ARGOCD_SETUP.txt"
echo ""


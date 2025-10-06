#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════╗
# ║          🛑 FILMCASTPRO - EKS STOP SCRIPT 🛑                         ║
# ║              Run this at end of day to stop charges!                 ║
# ╚══════════════════════════════════════════════════════════════════════╝

set -e  # Exit on any error

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║          🛑 Stopping FilmCastPro EKS Resources 🛑                    ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  This will DELETE all AWS resources for FilmCastPro${NC}"
echo ""
echo "This includes:"
echo "  • EKS Cluster"
echo "  • Worker Nodes"
echo "  • Load Balancers"
echo "  • VPC & Networking"
echo ""
echo "What will be PRESERVED:"
echo "  ✅ Your code in GitHub"
echo "  ✅ Docker images in ECR"
echo "  ✅ Terraform state"
echo "  ✅ All documentation"
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled. No resources were deleted."
    exit 0
fi

echo ""
echo -e "${RED}Starting cleanup process...${NC}"
echo ""

# ============================================================================
# STEP 1: Delete Kubernetes Load Balancers
# ============================================================================
echo "Step 1/2: Cleaning up Kubernetes resources..."
echo ""

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=filmcastpro" --query "Vpcs[0].VpcId" --output text 2>/dev/null || echo "")

if [ "$VPC_ID" != "" ] && [ "$VPC_ID" != "None" ]; then
    echo "Found VPC: $VPC_ID"
    echo ""
    
    # Delete Classic Load Balancers
    echo "Deleting Classic Load Balancers..."
    for lb in $(aws elb describe-load-balancers --region us-east-1 --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text 2>/dev/null); do
        echo "  Deleting: $lb"
        aws elb delete-load-balancer --load-balancer-name $lb --region us-east-1 2>/dev/null || echo "  Already deleted"
    done
    
    # Delete Application Load Balancers
    echo "Deleting Application Load Balancers..."
    for lb in $(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text 2>/dev/null); do
        echo "  Deleting: $lb"
        aws elbv2 delete-load-balancer --load-balancer-arn $lb --region us-east-1 2>/dev/null || echo "  Already deleted"
    done
    
    echo ""
    echo "Waiting 60 seconds for load balancers to fully delete..."
    sleep 60
fi

echo ""
echo "✅ Kubernetes resources cleaned up"
echo ""

# ============================================================================
# STEP 2: Destroy Terraform Infrastructure
# ============================================================================
echo "Step 2/2: Destroying AWS infrastructure with Terraform..."
echo "This will take approximately 10 minutes ⏱️"
echo ""

cd /Users/sadafperveen05/Devops/FilmCastPro/infra/eks

terraform destroy -auto-approve

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ CLEANUP COMPLETE! ✅                           ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 ALL AWS CHARGES STOPPED!"
echo ""
echo "What was deleted:"
echo "  ✅ EKS Cluster"
echo "  ✅ Worker Nodes"
echo "  ✅ Load Balancers"
echo "  ✅ NAT Gateways"
echo "  ✅ VPC & Networking"
echo ""
echo "What remains (no cost):"
echo "  ✅ Code in GitHub"
echo "  ✅ Docker images in ECR (minimal cost)"
echo "  ✅ Terraform code"
echo "  ✅ Documentation"
echo ""
echo "🚀 TO RESTART TOMORROW:"
echo "   ./START_EKS_TOMORROW.sh"
echo ""
echo "💸 Current AWS cost: \$0/hour"
echo ""
echo "✅ You're all set! See you tomorrow! 👋"
echo ""


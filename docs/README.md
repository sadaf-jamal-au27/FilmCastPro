# FilmCastPro

A modern React-based film casting application deployed on AWS EKS with complete DevOps automation.

## 🚀 Live Demo

**Application URL:** `http://a594e11411ab740019c57084a40b5fa5-1983588965.us-east-1.elb.amazonaws.com`

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Deployment](#deployment)
- [Documentation](#documentation)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Contributing](#contributing)

## 🎯 Overview

FilmCastPro is a professional casting platform built with modern web technologies and deployed using cloud-native practices. The application is containerized with Docker and orchestrated on Amazon EKS (Elastic Kubernetes Service) using Terraform and Helm.

## 🏗️ Architecture

```
Internet → AWS Load Balancer → EKS Cluster → FilmCastPro Pods
                                    ├── VPC (10.0.0.0/16)
                                    ├── 2 AZs (us-east-1a, us-east-1b)
                                    ├── Public & Private Subnets
                                    └── 2 x t3.small Worker Nodes
```

### Key Components:
- **Container Registry:** Amazon ECR
- **Orchestration:** Kubernetes (EKS v1.30)
- **Infrastructure as Code:** Terraform
- **Package Manager:** Helm
- **Load Balancer:** AWS Classic ELB
- **Networking:** VPC with NAT Gateway

## ⚡ Quick Start

### Prerequisites
- AWS CLI configured
- Docker Desktop
- kubectl
- Terraform (≥1.6.0)
- Helm (v3.x)

### Deploy in 5 Steps

```bash
# 1. Build and push Docker image
cd /path/to/FilmCastPro
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 008099619893.dkr.ecr.us-east-1.amazonaws.com
docker buildx build --platform linux/amd64 -t 008099619893.dkr.ecr.us-east-1.amazonaws.com/filmcastpro:latest --push .

# 2. Provision EKS infrastructure
cd infra/eks
terraform init
terraform apply -auto-approve

# 3. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name filmcastpro

# 4. Deploy application
cd ../..
kubectl create namespace filmcastpro
helm upgrade --install filmcastpro ./charts/filmcastpro -n filmcastpro --wait

# 5. Get application URL
kubectl get svc filmcastpro -n filmcastpro
```

## 📚 Documentation

Comprehensive documentation available in the `docs/` directory:

- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.txt)** - Complete step-by-step deployment instructions
- **[Quick Start](docs/QUICK_START.txt)** - Fast track for experienced engineers
- **[Architecture](docs/ARCHITECTURE.txt)** - Detailed technical architecture documentation

## 🛠️ Tech Stack

### Frontend
- **Framework:** React 18 with TypeScript
- **Build Tool:** Vite
- **Styling:** Tailwind CSS
- **Routing:** React Router v6

### DevOps
- **Containerization:** Docker (multi-stage build)
- **Container Registry:** Amazon ECR
- **Orchestration:** Kubernetes (EKS)
- **IaC:** Terraform
- **Package Management:** Helm
- **Web Server:** Nginx (alpine)
- **Cloud Provider:** AWS

### Infrastructure
- **EKS Version:** 1.30
- **Node Type:** t3.small (2 instances)
- **Region:** us-east-1
- **Availability Zones:** 2 (Multi-AZ)
- **Service Type:** LoadBalancer

## 📁 Project Structure

```
FilmCastPro/
├── src/                    # React application source
│   ├── components/         # React components
│   ├── data/              # Application data
│   └── types/             # TypeScript types
├── charts/                # Helm charts
│   └── filmcastpro/
│       ├── templates/     # Kubernetes manifests
│       └── values.yaml    # Configuration values
├── infra/                 # Infrastructure as Code
│   └── eks/
│       ├── main.tf        # EKS & VPC configuration
│       ├── variables.tf   # Terraform variables
│       └── versions.tf    # Provider versions
├── docs/                  # Documentation
│   ├── DEPLOYMENT_GUIDE.txt
│   ├── QUICK_START.txt
│   └── ARCHITECTURE.txt
├── Dockerfile             # Multi-stage Docker build
└── README.md             # This file
```

## 🔧 Configuration

### Environment Variables
- **AWS Region:** `us-east-1`
- **EKS Cluster:** `filmcastpro`
- **ECR Repository:** `008099619893.dkr.ecr.us-east-1.amazonaws.com/filmcastpro`

### Helm Values
Key configurations in `charts/filmcastpro/values.yaml`:
```yaml
replicaCount: 1
image:
  repository: 008099619893.dkr.ecr.us-east-1.amazonaws.com/filmcastpro
  tag: latest
service:
  type: LoadBalancer
  port: 80
```

## 🔒 Security Features

- ✅ Worker nodes in private subnets
- ✅ IAM roles for service accounts (IRSA)
- ✅ EKS secrets encrypted with KMS
- ✅ Security groups with least privilege
- ✅ Container image scanning (ECR)
- ✅ IMDSv2 enforced on nodes

## 📊 Monitoring & Logging

- **CloudWatch Logs:** EKS control plane logs
- **Container Insights:** Available for setup
- **kubectl commands:**
  ```bash
  kubectl top nodes
  kubectl top pods -n filmcastpro
  kubectl logs -n filmcastpro -l app.kubernetes.io/name=filmcastpro
  ```

## 🎛️ Scaling

### Horizontal Pod Autoscaling
```bash
kubectl autoscale deployment filmcastpro -n filmcastpro --cpu-percent=70 --min=3 --max=10
```

### Node Group Scaling
Edit `infra/eks/main.tf` and adjust:
```hcl
eks_managed_node_groups = {
  main = {
    min_size     = 2
    max_size     = 5
    desired_size = 3
  }
}
```

## 🧹 Cleanup

```bash
# Delete application
helm uninstall filmcastpro -n filmcastpro
kubectl delete namespace filmcastpro

# Destroy infrastructure
cd infra/eks
terraform destroy -auto-approve

# Delete ECR repository (optional)
aws ecr delete-repository --repository-name filmcastpro --region us-east-1 --force
```

## 💰 Cost Estimation

Monthly costs (us-east-1):
- EKS Cluster: ~$72
- EC2 (2 x t3.small): ~$30
- NAT Gateway: ~$32
- Load Balancer: ~$16
- **Total: ~$150-200/month**

## 🐛 Troubleshooting

Common issues and solutions:

**ImagePullBackOff:**
```bash
kubectl delete pod -n filmcastpro --all
```

**Auth errors:**
```bash
aws eks update-kubeconfig --region us-east-1 --name filmcastpro
```

**Pod capacity issues:**
```bash
# Scale down CoreDNS
kubectl scale deployment coredns -n kube-system --replicas=1
```

See [Troubleshooting Guide](docs/DEPLOYMENT_GUIDE.txt#troubleshooting) for detailed solutions.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 👥 Authors

- **Sadaf Jamal** - [sadaf-jamal-au27](https://github.com/sadaf-jamal-au27)

## 🔗 Links

- **GitHub Repository:** [https://github.com/sadaf-jamal-au27/FilmCastPro](https://github.com/sadaf-jamal-au27/FilmCastPro)
- **Original Fork:** [rajesh-305/FilmCastPro](https://github.com/rajesh-305/FilmCastPro)
- **Live Application:** See deployment outputs

## 📞 Support

For issues and questions:
1. Check the [Deployment Guide](docs/DEPLOYMENT_GUIDE.txt)
2. Review [Architecture Documentation](docs/ARCHITECTURE.txt)
3. Open an issue on GitHub
4. Check AWS CloudWatch logs

---

**Made with ❤️ using React, Kubernetes, and AWS**

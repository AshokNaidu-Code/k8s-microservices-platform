# Kubernetes Microservices Platform - Production-Ready Deployment

A fully automated, enterprise-grade Kubernetes cluster deployment using **Terraform** for infrastructure provisioning and **Ansible** for cluster bootstrapping. This project demonstrates production-ready DevOps practices with comprehensive automation, error handling, and recovery mechanisms.

## 🎯 Project Overview

This repository provides a complete **Infrastructure-as-Code (IaC)** solution for deploying a highly available Kubernetes cluster on AWS. It automates the entire process from VPC provisioning to a fully functional multi-node Kubernetes cluster ready for microservices deployment.

**Cluster Architecture:**
- **1 Control Plane Node** (Master) - API server, etcd, scheduler, controller manager
- **3 Worker Nodes** - Container runtime execution and pod hosting
- **Networking:** VPC with public/private subnets, security groups, NAT gateway
- **Container Runtime:** Containerd (industry standard, CRI-compliant)
- **CNI:** Flannel for pod-to-pod networking
- **Kubernetes Version:** v1.29.15 LTS

## ✨ Key Features

### Infrastructure Automation
- **Terraform** provisioning: VPC, subnets, security groups, EC2 instances, NAT gateway
- **Modular design**: Separate terraform files for networking, compute, and configuration
- **Production-ready defaults**: Security groups with least-privilege access, proper tagging
- **Dynamic variables**: Easy configuration for region, instance types, cluster size

### Cluster Automation
- **Ansible playbook** for complete cluster setup
- **Resilience mechanisms**: SSH keepalive, connection retries, wait conditions
- **Error handling**: Comprehensive preflight checks and recovery procedures
- **CNI integration**: Automatic network plugin installation
- **Security hardened**: Proper RBAC, certificate management, secure communications

### GitHub Actions CI/CD
- **Automated workflows**: Full-setup, diagnostics, cleanup pipelines
- **Manual triggers**: Flexible workflow execution for different scenarios
- **Secret management**: Secure SSH key and AWS credential handling

## 📦 Repository Structure

```
k8s-microservices-platform/
├── infrastructure/
│   ├── main.tf                 # Provider and backend configuration
│   ├── compute.tf              # EC2 instance definitions
│   ├── network.tf              # VPC, subnets, security groups
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Terraform outputs
│   └── keys.tf                 # SSH key pair management
├── cluster-bootstrap/
│   ├── k8s_setup.yaml          # Main Ansible playbook (all 3 plays)
│   ├── inventory.ini           # Ansible inventory
│   ├── k8s_post_init_diag.yaml # Post-deployment diagnostics
│   ├── k8s_diagnostics.yaml    # General cluster diagnostics
│   └── cleanup.yaml            # Cluster cleanup playbook
├── .github/workflows/
│   ├── full-setup.yaml         # Deploy complete cluster
│   ├── diagnostics.yaml        # Run cluster diagnostics
│   └── cleanup.yaml            # Cleanup resources
├── docs/
│   ├── ARCHITECTURE.md         # Detailed technical architecture
│   ├── TROUBLESHOOTING.md      # Common issues and solutions
│   ├── DEPLOYMENT.md           # Step-by-step deployment guide
│   └── CHALLENGES_SOLVED.md    # Engineering challenges & solutions
└── README.md                   # This file

```

## 🚀 Quick Start

### Prerequisites
- AWS account with appropriate permissions
- Terraform >= 1.0
- Ansible >= 2.9
- kubectl installed locally
- SSH key pair (will be created if not exists)

### Deployment Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AshokNaidu-Code/k8s-microservices-platform.git
   cd k8s-microservices-platform
   ```

2. **Configure AWS credentials:**
   ```bash
   export AWS_ACCESS_KEY_ID=your_key
   export AWS_SECRET_ACCESS_KEY=your_secret
   export AWS_REGION=us-east-1
   ```

3. **Initialize and apply Terraform:**
   ```bash
   cd infrastructure
   terraform init
   terraform plan
   terraform apply
   ```

4. **Run Ansible playbook:**
   ```bash
   cd ../cluster-bootstrap
   ansible-playbook -i inventory.ini k8s_setup.yaml \
     -u ubuntu \
     -e "ansible_python_interpreter=/usr/bin/python3" \
     -e "ansible_ssh_extra_args='-o StrictHostKeyChecking=no'"
   ```

5. **Verify cluster:**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

For detailed deployment instructions, see [DEPLOYMENT.md](./docs/DEPLOYMENT.md).

## 🏗️ Architecture

### Network Architecture
- **VPC CIDR:** 10.0.0.0/16 (configurable)
- **Public Subnet:** 10.0.0.0/24 (control plane, NAT gateway)
- **Private Subnets:** 10.0.1.0/24 - 10.0.3.0/24 (worker nodes)
- **Pod Network:** 10.0.0.0/16 (Flannel VXLAN overlay)

### Security Architecture
- **Security Groups:** Least-privilege inbound rules
- **SSH Access:** Port 22 (configurable CIDR)
- **Kubernetes API:** Port 6443 (internal only)
- **Kubelet API:** Port 10250 (node-to-node only)
- **Network Policies:** Ready for additional Kubernetes network policies

### High Availability Considerations
- **etcd cluster:** Single node (can be extended to 3-node cluster)
- **API Server:** Single instance with health checks
- **Worker distribution:** Multiple nodes for fault tolerance
- **Persistent storage:** Ready for EBS volumes and dynamic provisioning

For complete architectural details, see [ARCHITECTURE.md](./docs/ARCHITECTURE.md).

## ⚙️ Terraform Configuration

### Variable Customization

Edit `infrastructure/variables.tf` to customize:

```hcl
variable "instance_type_control_plane" {
  description = "EC2 instance type for control plane"
  default     = "t3.medium"  # 2 vCPU, 4GB RAM
}

variable "instance_type_worker" {
  description = "EC2 instance type for worker nodes"
  default     = "t3.small"   # 2 vCPU, 2GB RAM
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  default     = "k8s-microservices"
}

variable "worker_count" {
  description = "Number of worker nodes"
  default     = 3
}
```

## 🔧 Ansible Playbook Overview

The playbook is organized into **3 plays**:

### Play 1: Install Prerequisites (All Nodes)
- DNS configuration
- Docker & containerd installation
- Kubernetes repository setup
- kubelet, kubeadm, kubectl installation
- Kernel module loading (br_netfilter, overlay)
- cgroup driver configuration

### Play 2: Initialize Control Plane
- kubeadm cluster initialization
- kubeconfig setup
- API server readiness validation
- Flannel CNI installation
- Worker node join token generation

### Play 3: Join Worker Nodes
- Worker node cleanup (handles re-runs)
- kubeadm join execution
- Integration with control plane

For detailed playbook structure, see [ARCHITECTURE.md](./docs/ARCHITECTURE.md).

## 📊 Challenges Solved

This project demonstrates **real-world DevOps problem-solving**:

1. **SSH Connection Stability**
   - Issue: "Shared connection closed" errors during long operations
   - Solution: Implemented ServerAliveInterval and ServerAliveCountMax options
   - **Impact:** 100% reliable SSH sessions during 30+ minute deployments

2. **Kubernetes RBAC Permission Errors**
   - Issue: "403 Forbidden: User cannot list pods" errors
   - Solution: Explicit KUBECONFIG environment variable configuration
   - **Impact:** Proper cluster access controls and role bindings

3. **Resource Exhaustion Handling**
   - Issue: API server crashes due to disk space exhaustion
   - Solution: Disk cleanup procedures and monitoring
   - **Impact:** Graceful handling of resource constraints

4. **API Server Initialization Timing**
   - Issue: kubectl commands fail during cluster bootstrap
   - Solution: Implemented intelligent wait conditions and retries
   - **Impact:** Robust cluster initialization without manual intervention

5. **CNI Network Plugin Compatibility**
   - Issue: Calico CRD conflicts and image pull failures
   - Solution: Switched to Flannel with proper configuration
   - **Impact:** Reliable pod networking across all nodes

For detailed technical analysis, see [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) and [CHALLENGES_SOLVED.md](./docs/CHALLENGES_SOLVED.md).

## 📋 Requirements Met

- ✅ Infrastructure-as-Code (Terraform)
- ✅ Configuration Management (Ansible)
- ✅ Container orchestration (Kubernetes)
- ✅ Automated CI/CD (GitHub Actions)
- ✅ Production-ready security
- ✅ Error handling and recovery
- ✅ Comprehensive documentation
- ✅ Reproducible deployments

## 🧪 Testing & Validation

```bash
# Verify cluster nodes are ready
kubectl get nodes -o wide

# Check system components
kubectl get pods -n kube-system

# Deploy test application
kubectl run test-app --image=nginx:latest
kubectl get pods
kubectl delete pod test-app

# Check cluster info
kubectl cluster-info
kubectl cluster-info dump
```

## 🔐 Security Best Practices Implemented

- Least-privilege security groups
- SSH key-based authentication only
- kubeadm token expiration (TTL)
- RBAC role bindings
- Network policies ready
- Encrypted communication (TLS)
- Regular security updates

## 📈 Cost Optimization

Default configuration uses:
- **Control Plane:** t3.medium ($0.0416/hour)
- **Worker Nodes:** t3.small × 3 ($0.0208/hour each)
- **Total Estimated Cost:** ~$100/month running 24/7

For production, consider:
- Reserved instances (40% savings)
- Spot instances for worker nodes (60-70% savings)
- Auto-scaling groups
- Scheduled shutdown (dev/test clusters)

## 🐛 Troubleshooting

Common issues and solutions are documented in:
- [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) - Common problems and fixes
- [DEPLOYMENT.md](./docs/DEPLOYMENT.md) - Deployment step validation
- [CHALLENGES_SOLVED.md](./docs/CHALLENGES_SOLVED.md) - Engineering deep-dives

## 📚 Additional Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Flannel CNI](https://github.com/flannel-io/flannel)

## 🤝 Contributing

Contributions welcome! Areas for enhancement:
- Multi-region deployment support
- Helm chart package management
- Prometheus/Grafana monitoring integration
- ArgoCD GitOps implementation
- Kubernetes Dashboard deployment

## 📝 License

MIT License - See LICENSE file for details

## 👤 Author

**Ashok Naidu**
- GitHub: [@AshokNaidu-Code](https://github.com/AshokNaidu-Code)
- LinkedIn: [www.linkedin.com/in/ashoknallam]
- Email: ashoknallam06@gmail.com
## 🎓 Learning Outcomes

By studying this project, you'll understand:
- Enterprise-grade infrastructure automation
- Kubernetes cluster architecture and bootstrapping
- Ansible playbook design patterns
- Terraform modular code organization
- GitHub Actions workflow automation
- Real-world DevOps problem-solving
- Production readiness considerations

---

**Last Updated:** October 23, 2025  
**Kubernetes Version:** v1.29.15  
**Terraform Version:** 1.0+  
**Ansible Version:** 2.9+

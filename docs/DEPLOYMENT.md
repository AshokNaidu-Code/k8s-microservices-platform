# Step-by-Step Deployment Guide

Complete walkthrough for deploying the Kubernetes microservices platform from scratch.

## Prerequisites

Before starting, ensure you have:

- **AWS Account** with appropriate permissions (EC2, VPC, IAM, EBS)
- **AWS CLI** configured with credentials
- **Terraform** >= 1.0 installed and configured
- **Ansible** >= 2.9 installed
- **kubectl** installed locally
- **Git** for cloning the repository
- SSH key pair (will be generated if not exists)
- **Bash** shell environment

### Verify Prerequisites

```bash
# Check Terraform
terraform --version
# Expected: >= 1.0

# Check Ansible
ansible --version
# Expected: >= 2.9

# Check kubectl
kubectl version --client
# Expected: any recent version

# Check AWS CLI
aws --version
# Expected: version 2.x

# Verify AWS credentials
aws sts get-caller-identity
# Expected: Shows your AWS account info
```

## Phase 1: Infrastructure Provisioning (Terraform)

### Step 1: Clone Repository

```bash
git clone https://github.com/AshokNaidu-Code/k8s-microservices-platform.git
cd k8s-microservices-platform
```

### Step 2: Configure AWS Credentials

```bash
# Option 1: Using AWS CLI profile
export AWS_PROFILE=default

# Option 2: Using environment variables
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"

# Verify connection
aws sts get-caller-identity
```

### Step 3: Configure Terraform Variables

```bash
cd infrastructure

# Create terraform.tfvars with custom values
cat > terraform.tfvars << EOF
aws_region                        = "us-east-1"
cluster_name                      = "k8s-microservices"
environment                       = "development"
vpc_cidr                         = "10.0.0.0/16"
ssh_cidr                         = "YOUR_IP/32"  # Replace with your IP
instance_type_control_plane      = "t3.medium"
instance_type_worker             = "t3.small"
root_volume_size_control_plane   = 50
root_volume_size_worker          = 30
worker_count                     = 3
EOF
```

### Step 4: Initialize Terraform

```bash
terraform init

# Output should show:
# Terraform has been successfully configured!
```

### Step 5: Plan Infrastructure

```bash
terraform plan -out=tfplan

# Review the plan carefully
# Expected resources:
# - 1 VPC
# - 4 Subnets (1 public, 3 private)
# - Internet Gateway
# - NAT Gateway
# - Route tables
# - 4 EC2 instances (1 control plane, 3 workers)
# - Security groups
# - Network interfaces
```

### Step 6: Apply Terraform Configuration

```bash
terraform apply tfplan

# Grab these outputs for the next phase:
terraform output -json > ../outputs.json

# Manually note:
# - control_plane_ip (private IP)
# - worker_ips (private IPs)
# - ssh_key_path (private key location)
```

**⏱️ Time: 5-10 minutes**

## Phase 2: Cluster Bootstrap (Ansible)

### Step 7: Update Ansible Inventory

```bash
cd ../cluster-bootstrap

# Edit inventory.ini with IPs from Terraform
cat > inventory.ini << EOF
[control_plane]
control_plane_host ansible_host=CONTROL_PLANE_IP

[worker_nodes]
worker1 ansible_host=WORKER_IP_1
worker2 ansible_host=WORKER_IP_2
worker3 ansible_host=WORKER_IP_3

[all:vars]
ansible_user=ubuntu
ansible_private_key_file=~/.ssh/id_rsa_k8s
ansible_python_interpreter=/usr/bin/python3
EOF
```

### Step 8: Verify SSH Connectivity

```bash
# Test SSH to all nodes
ansible -i inventory.ini all -m ping

# Expected output: All hosts should return "pong"
```

### Step 9: Run Ansible Playbook

```bash
# Full cluster deployment
ansible-playbook -i inventory.ini k8s_setup.yaml \
  -u ubuntu \
  -e "ansible_python_interpreter=/usr/bin/python3" \
  -e "ansible_ssh_extra_args='-o StrictHostKeyChecking=no -o ServerAliveInterval=50 -o ServerAliveCountMax=10'"

# Monitor output:
# - Look for "PLAY [01 - Install Prerequisites..."
# - Each task should show "ok" or "changed"
# - Final "PLAY RECAP" should show all tasks successful
```

### Step 10: Wait for Cluster Stabilization

```bash
# After playbook completes, wait 2-3 minutes for:
sleep 180

# Pods to initialize
# API server to stabilize
# CNI networking to be ready
```

**⏱️ Time: 15-20 minutes**

## Phase 3: Verification & Validation

### Step 11: Verify Cluster Nodes

```bash
# SSH to control plane
ssh -i ~/.ssh/id_rsa_k8s ubuntu@CONTROL_PLANE_IP

# Check nodes
kubectl get nodes -o wide

# Expected output:
# NAME            STATUS   ROLES           AGE   VERSION
# ip-10-0-1-182   Ready    control-plane   2m    v1.29.15
# ip-10-0-1-141   Ready    <none>          1m    v1.29.15
# ip-10-0-1-199   Ready    <none>          1m    v1.29.15
# ip-10-0-1-208   Ready    <none>          1m    v1.29.15
```

### Step 12: Check System Pods

```bash
kubectl get pods -n kube-system

# Expected:
# - All pods should be READY 1/1
# - All pods should be in Running status
# - CoreDNS pods should be running (for DNS)
# - etcd pod should be running
# - API server should be running
```

### Step 13: Verify Network Connectivity

```bash
# Check cluster info
kubectl cluster-info

# Expected: Shows API server endpoint and CoreDNS endpoint

# Check API connectivity
kubectl api-resources | head -5

# Expected: List of Kubernetes resource types
```

### Step 14: Test Pod Networking

```bash
# Deploy test pod
kubectl run test-pod --image=nginx:latest --image-pull-policy=IfNotPresent

# Wait for pod to start
kubectl wait --for=condition=Ready pod/test-pod --timeout=300s

# Verify pod got IP
kubectl get pod test-pod -o wide

# Expected: Pod has IP in 10.0.x.x range

# Test connectivity from another pod
kubectl run -it --rm test-client --image=busybox --restart=Never -- \
  wget -O- http://test-pod

# Expected: "200 OK" and nginx welcome page

# Cleanup
kubectl delete pod test-pod test-client
```

### Step 15: Verify Persistent Storage Support

```bash
# Check storage classes
kubectl get storageclass

# Expected: Should show available storage options
# (AWS EBS provisioning ready)
```

## Phase 4: Post-Deployment Tasks

### Step 16: Configure Local kubectl

```bash
# Copy kubeconfig from control plane
mkdir -p ~/.kube
scp -i ~/.ssh/id_rsa_k8s ubuntu@CONTROL_PLANE_IP:~/.kube/config ~/.kube/config

# Set permissions
chmod 600 ~/.kube/config

# Verify local access
kubectl get nodes

# Expected: Same output as remote
```

### Step 17: Enable Dashboard (Optional)

```bash
# Deploy Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create proxy access
kubectl proxy &

# Access at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Step 18: Setup Monitoring (Optional)

```bash
# Install Prometheus and Grafana
kubectl create namespace monitoring

# Add Prometheus Helm chart repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus Operator
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring

# Access Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Login at http://localhost:3000 (admin/prom-operator)
```

**⏱️ Time: 5-10 minutes**

## Troubleshooting During Deployment

### Issue: SSH Connection Timeout

```bash
# Solution: Check security group rules
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=k8s-microservices-*"

# Verify your IP is in the SSH CIDR
# Check: ssh_cidr in terraform.tfvars is correct
```

### Issue: Ansible Cannot Find Hosts

```bash
# Verify inventory
cat inventory.ini

# Test SSH manually
ssh -i ~/.ssh/id_rsa_k8s ubuntu@CONTROL_PLANE_IP

# If fails: Check security group inbound rules
```

### Issue: kubectl Cannot Connect

```bash
# Check if API server is running
ssh ubuntu@CONTROL_PLANE_IP "sudo systemctl status kubelet"

# Check logs
ssh ubuntu@CONTROL_PLANE_IP "sudo tail -50 /var/log/pods/kube-system_*/kube-apiserver*/kube-apiserver/*.log"

# If needed, restart
ssh ubuntu@CONTROL_PLANE_IP "sudo systemctl restart kubelet"
```

### Issue: Pods in Pending State

```bash
# Check events
kubectl describe pod POD_NAME

# Common causes:
# 1. Insufficient resources - check node allocatable
kubectl describe nodes

# 2. Network plugin not ready - check CNI
kubectl get pods -n kube-system | grep flannel

# 3. Storage not available - check PV/PVC
kubectl get pv,pvc
```

### Issue: High CPU/Disk Usage

```bash
# SSH to node
ssh ubuntu@WORKER_IP

# Check disk
df -h

# If low disk space, cleanup:
sudo docker system prune -af --volumes
sudo rm -rf /var/log/pods/kube-system_*

# Check processes
top -b -n 1 | head -20
```

## Cleanup & Cost Management

### To Destroy Everything

```bash
cd infrastructure

# Destroy all resources
terraform destroy

# Confirm the destruction
# Expected: All AWS resources cleaned up within 5-10 minutes
```

### To Reduce Costs While Paused

```bash
# Stop all instances (cheaper than running)
aws ec2 stop-instances --instance-ids i-xxxxx i-yyyyy i-zzzzz

# Start again later
aws ec2 start-instances --instance-ids i-xxxxx i-yyyyy i-zzzzz
```

### Estimated Monthly Costs

| Component | Size | Count | Cost/Month |
|-----------|------|-------|-----------|
| Control Plane (t3.medium) | 2 vCPU, 4GB | 1 | $28.80 |
| Worker Nodes (t3.small) | 2 vCPU, 2GB | 3 | $62.88 |
| EBS Storage (30-50GB) | - | 4 | $16.00 |
| **Total** | - | - | **~$108/month** |

With reserved instances: ~65 USD/month (40% savings)
With spot instances: ~40 USD/month (60% savings)

## Next Steps After Deployment

1. **Deploy Applications:** Use kubectl or Helm to deploy microservices
2. **Setup CI/CD:** Integrate with GitOps tools (ArgoCD, Flux)
3. **Enable Monitoring:** Install Prometheus/Grafana for observability
4. **Configure Logging:** Setup ELK stack or Loki for log aggregation
5. **Setup Backup:** Configure etcd backups and PV snapshots
6. **Security Hardening:** Implement network policies, RBAC rules
7. **Load Testing:** Verify cluster can handle expected load

## Support & Documentation

- **Kubernetes Docs:** https://kubernetes.io/docs/
- **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest
- **Ansible Documentation:** https://docs.ansible.com/
- **Flannel CNI:** https://github.com/flannel-io/flannel

---

**Last Updated:** October 23, 2025  
**Version:** 1.0

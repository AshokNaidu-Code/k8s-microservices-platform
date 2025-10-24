# Troubleshooting Guide - Kubernetes Microservices Platform

Common issues, error messages, and solutions encountered during deployment and operation.

---

## 🔍 Quick Diagnosis Table

|             Symptom             |       Likely Cause       |               Jump To                     |
|---------------------------------|--------------------------|-------------------------------------------|
| "Connection refused" on kubectl |  API server not running  |  [API Server Issues](#api-server-issues)  |
|     Pods stuck in "Pending"     | Network plugin not ready |  [Network Issues](#network-cni-issues)    |
|    "403 Forbidden" errors       |  RBAC/kubeconfig issues  |  [RBAC Issues](#rbac-permission-errors)   |
|     Disk space errors           |   /var full from logs    |  [Disk Space](#disk-space-exhaustion)     |
|     SSH connection timeouts     | Keepalive not configured |  [SSH Issues](#ssh-connection-problems)   |
|     Worker nodes won't join     | Token expired or network |  [Worker Join](#worker-node-join-failures)|

---

## 🚨 Critical Issues

### API Server Issues

#### Error: "The connection to the server X.X.X.X:6443 was refused"

**Cause:** API server container isn't running or hasn't started yet.

**Diagnosis:**
```bash
# Check if API server is running
sudo docker ps | grep apiserver

# Check API server logs
sudo tail -100 /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log

# Check kubelet status
sudo systemctl status kubelet
```

**Solutions:**

1. **Wait for initialization** (first time only):
   ```bash
   # API server can take 60-90 seconds to start
   sleep 90
   kubectl get nodes
   ```

2. **Restart kubelet**:
   ```bash
   sudo systemctl restart kubelet
   sleep 30
   kubectl get nodes
   ```

3. **Check for port conflicts**:
   ```bash
   sudo ss -tlnp | grep 6443
   # Should show kube-apiserver listening
   ```

4. **Check certificates** (if API server crashes repeatedly):
   ```bash
   sudo kubeadm certs check-expiration
   ```

---

### Disk Space Exhaustion

#### Error: "No space left on device" or Disk at 98%+

**Cause:** Container logs, images, and etcd data fill up disk.

**Diagnosis:**
```bash
# Check disk usage
df -h
# Look for /dev/root at 90%+ usage

# Find largest directories
sudo du -sh /var/* | sort -hr | head -10
```

**Solutions:**

1. **Quick cleanup** (immediate relief):
   ```bash
   # Clean up apt cache
   sudo apt-get clean
   sudo apt-get autoclean
   
   # Remove old logs
   sudo journalctl --vacuum-time=1d
   
   # Clean up container logs
   sudo truncate -s 0 /var/log/pods/*/*/*.log
   ```

2. **Container image cleanup**:
   ```bash
   # List images
   sudo ctr -n k8s.io images ls
   
   # Remove unused images
   sudo ctr -n k8s.io images rm $(sudo ctr -n k8s.io images ls -q | tail -n +10)
   ```

3. **Permanent solution** - Increase disk size:
   - Stop instances
   - Modify EBS volume to 50GB (control plane) / 30GB (workers)
   - Restart instances
   - Resize filesystem: `sudo resize2fs /dev/xvda1`

**Prevention:**
- Use larger volumes in Terraform (see variables.tf)
- Set up log rotation
- Monitor disk usage with CloudWatch alarms

---

### Network (CNI) Issues

#### Error: Pods stuck in "Pending" or "ContainerCreating"

**Cause:** Network plugin (Flannel/Calico) not running.

**Diagnosis:**
```bash
# Check CNI pods
kubectl get pods -n kube-system | grep -E 'flannel|calico'

# Check pod events
kubectl describe pod <pod-name>
# Look for: "network plugin not ready"
```

**Solutions:**

1. **Verify CNI installation**:
   ```bash
   # For Flannel
   kubectl get pods -n kube-flannel
   # All should be Running
   
   # For Calico
   kubectl get pods -n kube-system | grep calico
   # All should be Running
   ```

2. **Reinstall Flannel** (if broken):
   ```bash
   # Remove old CNI
   kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
   
   # Wait 30 seconds
   sleep 30
   
   # Reinstall
   kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
   
   # Wait for pods to start
   kubectl wait --for=condition=Ready pod -l app=flannel -n kube-flannel --timeout=300s
   ```

3. **Check network connectivity**:
   ```bash
   # Verify VXLAN port is open
   sudo ss -ulnp | grep 4789
   
   # Ping between nodes
   ping -c 3 <other-node-ip>
   ```

---

### RBAC Permission Errors

#### Error: "403 Forbidden: User cannot list pods/nodes"

**Cause:** kubeconfig not found or RBAC not configured.

**Diagnosis:**
```bash
# Check kubeconfig exists
ls -la ~/.kube/config
# Or
ls -la /etc/kubernetes/admin.conf

# Check current context
kubectl config current-context

# Check user
kubectl config view
```

**Solutions:**

1. **Set KUBECONFIG environment variable**:
   ```bash
   export KUBECONFIG=/etc/kubernetes/admin.conf
   kubectl get nodes
   ```

2. **Copy kubeconfig to user directory**:
   ```bash
   mkdir -p ~/.kube
   sudo cp /etc/kubernetes/admin.conf ~/.kube/config
   sudo chown $(id -u):$(id -g) ~/.kube/config
   chmod 600 ~/.kube/config
   ```

3. **Verify RBAC role binding**:
   ```bash
   kubectl get clusterrolebinding kubernetes-admin -o yaml
   # Should show cluster-admin role
   ```

---

## ⚠️ Common Issues

### SSH Connection Problems

#### Error: "Shared connection closed" during Ansible

**Cause:** SSH timeout during long operations.

**Solutions:**

1. **Add SSH keepalive** (in Ansible playbook):
   ```yaml
   - name: Set SSH extra args
     set_fact:
       ansible_ssh_extra_args: "-o ServerAliveInterval=50 -o ServerAliveCountMax=10"
   ```

2. **Increase timeout** in `ansible.cfg`:
   ```ini
   [defaults]
   timeout = 600
   ```

3. **Use connection persistence**:
   ```yaml
   # In playbook
   vars:
     ansible_ssh_common_args: '-o ControlMaster=auto -o ControlPersist=60s'
   ```

---

### Worker Node Join Failures

#### Error: "kubeadm join failed: port already in use"

**Cause:** Previous join attempt left services running.

**Solutions:**

1. **Reset worker node**:
   ```bash
   # On worker node
   sudo kubeadm reset -f
   sudo rm -rf /etc/cni/net.d/*
   sudo systemctl restart kubelet
   ```

2. **Generate new token**:
   ```bash
   # On control plane
   kubeadm token create --print-join-command
   # Copy the entire output
   ```

3. **Rejoin worker**:
   ```bash
   # On worker node, paste the join command:
   sudo kubeadm join 10.0.0.100:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
   ```

---

### Terraform Apply Failures

#### Error: "Error creating EC2 instance: InvalidKeyPair.NotFound"

**Cause:** SSH key not created or wrong region.

**Solutions:**

1. **Verify key exists**:
   ```bash
   aws ec2 describe-key-pairs --region us-east-1
   ```

2. **Create key manually**:
   ```bash
   aws ec2 create-key-pair --key-name k8s-platform-key --region us-east-1
   ```

3. **Check terraform.tfvars**:
   ```hcl
   ssh_public_key = file("~/.ssh/id_rsa.pub")
   ```

---

#### Error: "Error launching source instance: InsufficientInstanceCapacity"

**Cause:** AWS doesn't have capacity for requested instance type in AZ.

**Solutions:**

1. **Try different instance type**:
   ```hcl
   instance_type_control_plane = "t3a.medium"  # Alternative
   ```

2. **Try different region/AZ**:
   ```hcl
   aws_region = "us-west-2"
   ```

---

### Ansible Execution Issues

#### Error: "UNREACHABLE! Connection timed out"

**Cause:** Security group not allowing SSH or wrong IP.

**Solutions:**

1. **Verify security group**:
   ```bash
   aws ec2 describe-security-groups --group-ids <sg-id>
   # Check port 22 is open from your IP
   ```

2. **Test SSH manually**:
   ```bash
   ssh -i ~/.ssh/id_rsa ubuntu@<instance-ip>
   ```

3. **Update security group**:
   ```bash
   # Get your current IP
   curl ifconfig.me
   
   # Update terraform.tfvars
   ssh_cidr = "YOUR_IP/32"
   
   # Apply
   terraform apply
   ```

---

#### Error: "Failed to download packages: Connection timed out"

**Cause:** NAT gateway not configured or no internet access.

**Solutions:**

1. **Verify NAT gateway exists**:
   ```bash
   terraform output | grep nat_gateway
   ```

2. **Check route tables**:
   ```bash
   aws ec2 describe-route-tables --filters "Name=tag:Name,Values=k8s*"
   # Private subnets should route 0.0.0.0/0 to NAT gateway
   ```

3. **Test internet from instance**:
   ```bash
   ssh ubuntu@<instance-ip>
   ping -c 3 8.8.8.8
   curl -I https://packages.cloud.google.com
   ```

---

### GitHub Actions Workflow Failures

#### Error: "Terraform init failed: Backend initialization required"

**Cause:** Terraform backend not configured.

**Solutions:**

1. **Add backend config** in `main.tf`:
   ```hcl
   terraform {
     backend "local" {
       path = "terraform.tfstate"
     }
   }
   ```

2. **Or use S3 backend**:
   ```hcl
   terraform {
     backend "s3" {
       bucket = "my-terraform-state"
       key    = "k8s-cluster/terraform.tfstate"
       region = "us-east-1"
     }
   }
   ```

---

#### Error: "Secret not found: AWS_ACCESS_KEY_ID"

**Cause:** GitHub secrets not configured.

**Solutions:**

1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `K8S_SSH_KEY` (private key content)

---

## 🛠️ Diagnostic Commands

### Cluster Health Check

```bash
# Quick cluster status
kubectl get nodes
kubectl get pods -A
kubectl get componentstatuses

# Detailed node info
kubectl describe nodes

# Check system pods
kubectl get pods -n kube-system -o wide

# Check events
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Component Logs

```bash
# API server logs
sudo journalctl -u kubelet | grep apiserver

# Controller manager logs
kubectl logs -n kube-system <controller-manager-pod>

# Scheduler logs
kubectl logs -n kube-system <scheduler-pod>

# etcd logs
sudo journalctl -u etcd

# Flannel logs
kubectl logs -n kube-flannel <flannel-pod>
```

### Network Debugging

```bash
# Check pod networking
kubectl run test-pod --image=busybox --restart=Never -- sleep 3600
kubectl exec test-pod -- ping -c 3 8.8.8.8
kubectl exec test-pod -- nslookup kubernetes.default

# Check DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- http://kubernetes.default
```

---

## 📊 Monitoring & Alerts

### Key Metrics to Watch

|     Metric   |    Threshold   |           Action            |
|--------------|----------------|-----------------------------|
|  Disk usage  |      >85%      | Cleanup logs, expand volume |
| Memory usage |      >90%      | Add swap, upgrade instance  |
|  CPU usage   | >80% sustained | Scale up or distribute load |
| Pod restarts | >5 in 10 min   | Check logs, resource limits |
| etcd latency |      >100ms    | Check disk I/O, network     |

### Set Up CloudWatch Alarms

```bash
# Example: High disk usage alarm
aws cloudwatch put-metric-alarm \
  --alarm-name k8s-control-plane-disk-high \
  --alarm-description "Alert when disk usage exceeds 85%" \
  --metric-name DiskSpaceUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 85 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

---

## 🔄 Recovery Procedures

### Complete Cluster Reset

```bash
# On all nodes:
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d/*
sudo rm -rf /var/lib/etcd/*
sudo systemctl restart kubelet

# Re-run Ansible playbook
ansible-playbook -i inventory.ini k8s_setup.yaml
```

### Restore from Backup

```bash
# Restore etcd snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored

# Restart etcd pointing to restored data
# (Update /etc/kubernetes/manifests/etcd.yaml)
```

---

## 📞 Getting Help

### Where to Look

1. **Kubernetes Slack**: kubernetes.slack.com
2. **Stack Overflow**: Tag `kubernetes`, `terraform`, `ansible`
3. **GitHub Issues**: 
   - Kubernetes: github.com/kubernetes/kubernetes/issues
   - Flannel: github.com/flannel-io/flannel/issues

### Information to Provide

When asking for help, include:
```bash
# Cluster info
kubectl version
kubectl get nodes -o wide
kubectl get pods -A

# Logs
kubectl logs -n kube-system <pod-name>
sudo journalctl -u kubelet | tail -50

# System info
cat /etc/os-release
free -h
df -h
```

---

## ✅ Prevention Best Practices

1. **Monitoring**: Set up CloudWatch alarms for critical metrics
2. **Backups**: Regular etcd snapshots (automated via cron)
3. **Updates**: Keep Kubernetes, Docker, OS packages updated
4. **Documentation**: Document any manual changes made
5. **Testing**: Test disaster recovery procedures quarterly

---

**Last Updated:** October 24, 2025  
**Version:** 1.0  
**Kubernetes Version:** v1.29.15

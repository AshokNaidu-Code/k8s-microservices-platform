# Architecture Documentation - Kubernetes Microservices Platform

## System Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS ACCOUNT                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              VPC 10.0.0.0/16                               │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  Public Subnet 10.0.0.0/24                           │  │ │
│  │  │  ┌─────────────────────────────────────────────────┐ │  │ │
│  │  │  │ Internet Gateway                                │ │  │ │
│  │  │  │ NAT Gateway                                     │ │  │ │
│  │  │  │ ┌────────────────────────────────────────────┐  │ │  │ │
│  │  │  │ │ Control Plane (t3.medium)                  │  │ │  │ │
│  │  │  │ │ - kube-apiserver                           │  │ │  │ │
│  │  │  │ │ - etcd                                     │  │ │  │ │
│  │  │  │ │ - kube-controller-manager                  │  │ │  │ │
│  │  │  │ │ - kube-scheduler                           │  │ │  │ │
│  │  │  │ │ - kubelet                                  │  │ │  │ │
│  │  │  │ └────────────────────────────────────────────┘  │ │  │ │
│  │  │  └─────────────────────────────────────────────────┘ │  │ │
│  │  │                                                      │  │ │
│  │  │  ┌──────────────────────────────────────────────────┐│  │ │
│  │  │  │  Private Subnets (10.0.1.0/24, 10.0.2.0/24, etc) ││  │ │
│  │  │  │  ┌──────────────┐  ┌──────────────┐ ┌──────────┐ ││  │ │
│  │  │  │  │ Worker Node 1│  │ Worker Node 2│ │Worker N3 │ ││  │ │
│  │  │  │  │ (t3.small)   │  │ (t3.small)   │ │(t3.sml)  │ ││  │ │
│  │  │  │  │              │  │              │ │          │ ││  │ │
│  │  │  │  │ - kubelet    │  │ - kubelet    │ │-kubelet  │ ││  │ │
│  │  │  │  │ - kube-proxy │  │ - kube-proxy │ │-kproxy   │ ││  │ │
│  │  │  │  │ - pods       │  │ - pods       │ │- pods    │ ││  │ │
│  │  │  │  └──────────────┘  └──────────────┘ └──────────┘ ││  │ │
│  │  │  └──────────────────────────────────────────────────┘│  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VPC and Subnets

| Component | CIDR | Type | Purpose |
|-----------|------|------|---------|
| VPC | 10.0.0.0/16 | Primary | Main network range |
| Public Subnet | 10.0.0.0/24 | Public | Control plane, NAT gateway |
| Private Subnet 1 | 10.0.1.0/24 | Private | Worker node 1 |
| Private Subnet 2 | 10.0.2.0/24 | Private | Worker node 2 |
| Private Subnet 3 | 10.0.3.0/24 | Private | Worker node 3 |
| Pod Network | 10.0.0.0/16 | Overlay | Flannel VXLAN |

### Security Groups

#### Control Plane Security Group
- **Inbound Rules:**
  - SSH (22) from YourIP/32
  - API Server (6443) from Worker nodes
  - kubelet API (10250) from Worker nodes
  - etcd (2379-2380) from Worker nodes
- **Outbound Rules:**
  - All traffic allowed

#### Worker Node Security Group
- **Inbound Rules:**
  - SSH (22) from YourIP/32
  - kubelet API (10250) from Control Plane & Workers
  - kube-proxy (31000-32767) from all nodes
  - Pod-to-Pod (VXLAN 4789) from all nodes
- **Outbound Rules:**
  - All traffic allowed

### Routing

- **Public Route Table:**
  - 0.0.0.0/0 → Internet Gateway
  - 10.0.0.0/16 → Local

- **Private Route Table:**
  - 0.0.0.0/0 → NAT Gateway (in public subnet)
  - 10.0.0.0/16 → Local

## Kubernetes Cluster Architecture

### Control Plane Components

```
┌─ Control Plane (ip-10-0-1-182) ─┐
│                                 │
│  ┌─────────────────────────────┐│
│  │   kube-apiserver (6443)     ││
│  │   - REST API endpoint       ││
│  │   - Authentication & AuthZ  ││
│  │   - etcd communication      ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │   etcd (2379-2380)          ││
│  │   - Distributed key-value   ││
│  │   - Cluster state store     ││
│  │   - 1-node setup (can scale)││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │  kube-controller-manager    ││
│  │   - Handles node lifecycle  ││
│  │   - Manages replication     ││
│  │   - Watches for state drift ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │   kube-scheduler            ││
│  │   - Assigns pods to nodes   ││
│  │   - Resource requirements   ││
│  │   - Affinity/anti-affinity  ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │   kubelet (10250)           ││
│  │   - Container runtime mgmt  ││
│  │   - Volume mounts           ││
│  │   - Liveness/readiness      ││
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Worker Node Components

```
┌─ Worker Node (ip-10-0-1-141) ─┐
│                               │
│  ┌──────────────────────────┐ │
│  │   kubelet (10250)        │ │
│  │   - Pod lifecycle mgmt   │ │
│  │   - Container exec       │ │
│  │   - Volume management    │ │
│  └──────────────────────────┘ │
│                               │
│  ┌──────────────────────────┐ │
│  │  kube-proxy (30000+)     │ │
│  │  - Service load balancer │ │
│  │  - iptables rules        │ │
│  │  - Network forwarding    │ │
│  └──────────────────────────┘ │
│                               │
│  ┌──────────────────────────┐ │
│  │  containerd runtime      │ │
│  │  - Container creation    │ │
│  │  - Image management      │ │
│  │  - Resource limits       │ │
│  └──────────────────────────┘ │
│                               │
│  ┌──────────────────────────┐ │
│  │  CNI (Flannel)           │ │
│  │  - VXLAN overlay network │ │
│  │  - Pod IP allocation     │ │
│  │  - Inter-pod routing     │ │
│  └──────────────────────────┘ │
│                               │
│  ┌──────────────────────────┐ │
│  │  User Workload Pods      │ │
│  │  - Your microservices    │ │
│  │  - Data processing       │ │
│  │  - Web applications      │ │
│  └──────────────────────────┘ │
│                               │
└───────────────────────────────┘
```

## Container Runtime: Containerd

### Why Containerd?

- **CRI Compliant:** Works natively with Kubernetes
- **Performance:** Lightweight, low resource overhead
- **Reliability:** Industry standard (used by Docker, Kubernetes)
- **Security:** Image signature verification, SELinux support
- **Features:** OCI runtime support, plugins architecture

### Configuration

- **CRI Socket:** `/run/containerd/containerd.sock`
- **Config:** `/etc/containerd/config.toml`
- **Cgroup Driver:** `systemd` (compatible with kubelet)
- **Log Driver:** `json-file` with rotation

## CNI Plugin: Flannel

### Network Model

```
Pod-to-Pod Communication:

Pod A (10.0.1.10)          Pod B (10.0.2.10)
    │                            │
    ├─ Flannel veth              ├─ Flannel veth
    │                            │
    └─ VXLAN tunnel (UDP 4789) ─┘
         (Encapsulation)
```

### Flannel VXLAN Overlay

- **Overlay Protocol:** VXLAN (Virtual Extensible LAN)
- **Encapsulation:** UDP port 4789
- **Subnet Per Node:** Each node gets /24 subnet
  - Control Plane: 10.0.0.0/24
  - Worker 1: 10.0.1.0/24
  - Worker 2: 10.0.2.0/24
  - Worker 3: 10.0.3.0/24

### Flannel Components

- **flanneld:** Daemon running on each node
- **cni0 bridge:** Container bridge interface
- **flannel.1 interface:** VXLAN tunnel endpoint
- **etcd backend:** Subnet allocation via etcd

## Deployment Process

### Phase 1: Infrastructure Provisioning (Terraform)

```
Step 1: VPC Creation
  ├─ VPC 10.0.0.0/16
  ├─ Public Subnet 10.0.0.0/24
  ├─ Private Subnets (10.0.1-3.0/24)
  └─ Route tables, NAT Gateway

Step 2: Security Groups
  ├─ Control plane security group
  └─ Worker node security group

Step 3: EC2 Instance Creation
  ├─ Control plane (1 × t3.medium)
  ├─ Worker nodes (3 × t3.small)
  └─ SSH key pair generation

Step 4: Instance Configuration
  ├─ SSH security group rules
  ├─ EBS volume configuration
  └─ Instance tagging
```

### Phase 2: Cluster Bootstrap (Ansible)

```
PLAY 1: Common Prerequisites (All Nodes)
  ├─ DNS configuration (Google DNS)
  ├─ Container runtime installation (containerd, runc)
  ├─ Kubernetes package repository
  ├─ kubelet, kubeadm, kubectl installation
  ├─ System kernel modules (br_netfilter, overlay)
  ├─ Swap disable (kubelet requirement)
  ├─ sysctl configuration (IP forwarding, bridge-nf)
  └─ cgroup driver configuration (systemd)

PLAY 2: Control Plane Initialization
  ├─ kubeadm init
  │  ├─ API server binding
  │  ├─ etcd initialization
  │  └─ CA certificate generation
  ├─ kubeconfig setup for user access
  ├─ Wait for API server (6443)
  ├─ Flannel CNI installation
  └─ Join token generation

PLAY 3: Worker Node Join
  ├─ Previous configuration cleanup
  ├─ kubeadm join execution
  │  ├─ Certificate copy
  │  ├─ kubelet configuration
  │  └─ Node registration
  └─ Health check verification
```

## Data Flow

### API Server Request Flow

```
kubectl get nodes
    │
    ├─ kubectl resolves API endpoint (10.0.1.182:6443)
    │
    ├─ TLS handshake with API server
    │
    ├─ Authentication (kubeconfig cert)
    │
    ├─ Authorization (RBAC rules)
    │
    ├─ API server queries etcd for node list
    │
    ├─ Response serialization (JSON/YAML)
    │
    └─ Display to user
```

### Pod Networking Flow

```
Pod A sends packet to Pod B:
    │
    ├─ Source IP: 10.0.1.10
    │
    ├─ Flannel daemon intercepts (cni0 bridge)
    │
    ├─ Lookup destination subnet in etcd
    │ └─ Destination is on node with 10.0.2.0/24
    │
    ├─ VXLAN encapsulation
    │ └─ Outer headers: Worker1 → Worker2
    │
    ├─ UDP transmission (port 4789)
    │
    ├─ Worker2 Flannel receives packet
    │
    ├─ VXLAN decapsulation
    │
    └─ Delivery to Pod B via cni0
```

## Storage Considerations

### Current Configuration
- **Root Volumes:** EBS gp3, 30GB per node
- **Container Storage:** `/var/lib/containerd/`
- **etcd Storage:** `/var/lib/etcd/` (on control plane)
- **kubelet Storage:** `/var/lib/kubelet/`

### Production Enhancements
- **Persistent Volumes:** EBS volumes with dynamic provisioning
- **StorageClass:** Define performance tiers
- **etcd Backup:** Automated snapshots to S3
- **Log Rotation:** Prevent disk exhaustion

## Scalability Architecture

### Current Setup
- **Control Plane:** 1 node (single point of failure)
- **Worker Nodes:** 3 nodes
- **Capacity:** ~30-50 pods per node (depends on pod size)
- **Total Capacity:** ~100-150 pods

### Production Scaling Strategy
- **HA Control Plane:** 3 etcd nodes + load balancer
- **Worker Auto-Scaling:** ASG based on CPU/memory
- **Node Pools:** Separate node groups for different workloads
- **Multi-Region:** Federated clusters for disaster recovery

## High Availability (HA) Considerations

### Current Implementation
- Basic cluster with single control plane
- No built-in HA (acceptable for dev/test)

### HA Architecture (for production)
```
Load Balancer (NLB)
    │
    ├─ API Server 1 (10.0.0.10:6443)
    ├─ API Server 2 (10.0.0.20:6443)
    └─ API Server 3 (10.0.0.30:6443)

etcd Cluster
    ├─ etcd 1 (peer 2380, client 2379)
    ├─ etcd 2 (peer 2380, client 2379)
    └─ etcd 3 (peer 2380, client 2379)
```

## Monitoring and Logging

### Recommended Stack
- **Prometheus:** Metrics collection
- **Grafana:** Visualization
- **Loki:** Log aggregation
- **Alert Manager:** Alerting

### Key Metrics to Monitor
- Node CPU/Memory/Disk utilization
- Pod creation/deletion rates
- API server latency
- etcd commit duration
- Network I/O

## Security Architecture

### Implemented Security
- Security group ingress filtering
- kubeadm certificate-based auth
- RBAC with service accounts
- Network policy capability (via Flannel)
- SSH key-based access only

### Additional Security (Production)
- Pod Security Standards
- Network Policies
- OIDC integration
- Audit logging
- Image scanning
- Runtime security

## Disaster Recovery

### Current Backup Strategy
- Manual snapshots of EBS volumes
- etcd backup files

### Production DR Plan
- Automated EBS snapshots daily
- etcd backups to S3 every hour
- Cross-region replication
- RTO: 1 hour, RPO: 30 minutes

---

**Last Updated:** October 23, 2025  
**Architecture Version:** 1.0

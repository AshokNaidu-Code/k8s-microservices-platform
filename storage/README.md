# Storage Layer - Persistent Data Management

This folder contains Kubernetes storage configurations for persistent data in databases and applications.

## 📋 What's Included

### 1. StorageClass (AWS EBS)
- Dynamic provisioning
- gp3 volume type (general purpose SSD)
- 3000 IOPS, 125 MB/s throughput
- Automatic cleanup (Delete policy)
- AES-256 encryption enabled

### 2. Persistent Volume Claims (PVCs)
- **MySQL PVC:** 20GB for database
- **Redis PVC:** 10GB for cache
- **MongoDB PVC:** 50GB for document store (optional)

### 3. Volume Mounting
- Automatic mount to pod containers
- ReadWriteOnce access mode
- Mount paths configured in deployments

## 🗂️ Storage Architecture

\`\`\`
┌─────────────────────────────────────┐
│   Persistent Data (AWS EBS)          │
├─────────────────────────────────────┤
│                                     │
│  StorageClass (gp3)                 │
│        ↓                            │
│  [MySQL-PVC] [Redis-PVC] [Mongo-PVC]│
│        ↓          ↓           ↓     │
│   /var/lib/    /data/      /data/   │
│   mysql/       redis/      mongo/   │
│        ↓          ↓           ↓     │
│  [MySQL Pod] [Redis Pod] [Mongo Pod]│
│                                     │
└─────────────────────────────────────┘
\`\`\`

## 🚀 Prerequisites

1. **AWS EBS CSI Driver installed:**
   \`\`\`bash
   kubectl get daemonset -n kube-system ebs-csi-node
   \`\`\`

2. **Persistent Volume Provisioner working**

3. **IAM permissions for EC2 volume management**

## 📊 Storage Configuration

| Component | Type | Size | Throughput | IOPS |
|-----------|------|------|-----------|------|
| MySQL | gp3 | 20GB | 125 MB/s | 3000 |
| Redis | gp3 | 10GB | 125 MB/s | 3000 |
| MongoDB | gp3 | 50GB | 125 MB/s | 3000 |

## 🔄 Data Persistence Workflow

1. **Pod created** → Requests PVC
2. **PVC created** → Requests PV from StorageClass
3. **StorageClass** → Creates AWS EBS volume
4. **Volume attached** → Mounted to pod container
5. **Data written** → Persisted on AWS EBS
6. **Pod deleted** → Volume retained (unless reclaim policy = Delete)

## 💾 Volume Reclaim Policies

| Policy | Behavior | Use Case |
|--------|----------|----------|
| **Retain** | Keep volume after PVC deleted | Production databases |
| **Recycle** | Delete data, reuse volume | Dev/test |
| **Delete** | Destroy volume completely | Temporary storage |

Current policy: **Delete** (automatic cleanup)

## 🧪 Testing Persistent Storage

### 1. Verify StorageClass
\`\`\`bash
kubectl get storageclass
kubectl describe storageclass gp3-storage
\`\`\`

### 2. Check PVCs
\`\`\`bash
kubectl get pvc -n microservices
kubectl describe pvc mysql-pvc -n microservices
\`\`\`

### 3. Verify Volumes
\`\`\`bash
kubectl get pv
kubectl describe pv <pv-name>
\`\`\`

### 4. Test Data Persistence
\`\`\`bash
# Write data to MySQL
kubectl exec -it mysql-xxx -n microservices -- mysql -uroot -proot123 \\
  -e "CREATE DATABASE test_db; CREATE TABLE test_db.users (id INT);"

# Delete MySQL pod
kubectl delete pod mysql-xxx -n microservices

# Wait for new pod to start
sleep 30

# Verify data persisted
kubectl exec -it mysql-xxx -n microservices -- mysql -uroot -proot123 \\
  -e "SHOW DATABASES;"

# Should see: test_db ✅
\`\`\`

## 🔒 Security & Encryption

### EBS Encryption
- ✅ AES-256 encryption enabled
- ✅ Automatic key management (AWS KMS)
- ✅ Zero performance overhead

### Access Control
- ✅ PVCs in microservices namespace only
- ✅ Only mounted pods can access
- ✅ Network policies enforce isolation

## 📈 Scaling Storage

### Expand PVC Size
\`\`\`bash
kubectl patch pvc mysql-pvc -n microservices -p \\
  '{"spec":{"resources":{"requests":{"storage":"30Gi"}}}}'
\`\`\`

### Add New PVC
Edit storage yaml and add:
\`\`\`yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: elasticsearch-pvc
  namespace: microservices
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: gp3-storage
  resources:
    requests:
      storage: 100Gi
\`\`\`

## 💰 Cost Estimation

| Resource | Monthly Cost |
|----------|--------------|
| MySQL 20GB | \$2.00 |
| Redis 10GB | \$1.00 |
| MongoDB 50GB | \$5.00 |
| **Total** | **~\$8/month** |

## 🧹 Cleanup

Remove all PVCs (this deletes data!):
\`\`\`bash
kubectl delete pvc --all -n microservices
\`\`\`

Remove StorageClass:
\`\`\`bash
kubectl delete storageclass gp3-storage
\`\`\`

---

For deployment results, see \`STORAGE-RESULTS.md\`

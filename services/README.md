# Microservices Layer

This folder contains production-ready Kubernetes manifests for a multi-tier microservices application architecture.

## 📋 Services Included

### Database Tier
- **MySQL** - Primary relational database
  - Replicas: 1
  - Port: 3306
  - Storage: EmptyDir (for demo)

### Cache Tier
- **Redis** - In-memory data store
  - Replicas: 1
  - Port: 6379
  - Storage: EmptyDir (for demo)

### Application Tier
- **API Server** - REST API backend
  - Replicas: 3
  - Port: 8080
  - Language: Python/Node.js compatible

- **Web App** - Frontend application
  - Replicas: 1
  - Port: 80

### Utility Tier
- **Worker Job** - Background job processor
  - Replicas: 1
  - Port: N/A

## 🚀 Quick Start

### Deploy All Services
\`\`\`bash
# Single command deployment
kubectl apply -k .

# Verify deployment
kubectl get pods -n microservices
kubectl get svc -n microservices
\`\`\`

### Check Service Status
\`\`\`bash
# Watch pod creation in real-time
kubectl get pods -n microservices -w

# Get detailed pod info
kubectl describe pods -n microservices

# Check service IPs
kubectl get svc -n microservices -o wide
\`\`\`

### Test Connectivity

#### 1. Access MySQL
\`\`\`bash
kubectl exec -it mysql-xxx -n microservices -- mysql -uroot -proot123 -e "SELECT VERSION();"
\`\`\`

#### 2. Access Redis
\`\`\`bash
kubectl exec -it redis-xxx -n microservices -- redis-cli ping
\`\`\`

#### 3. Test API Server
\`\`\`bash
# Port forward to API server
kubectl port-forward svc/api-server 8080:8080 -n microservices

# Test in another terminal
curl http://localhost:8080/api/health
\`\`\`

## 📊 Architecture Diagram

\`\`\`
┌─────────────────────────────────────────┐
│       Microservices Platform            │
├─────────────────────────────────────────┤
│                                         │
│  [Web App]  ←→  [API Server] ×3        │
│                      ↓                  │
│            [MySQL] + [Redis]            │
│                      ↓                  │
│            [Background Worker]          │
│                                         │
└─────────────────────────────────────────┘
\`\`\`

## 📝 Configuration

All services use a shared namespace: \`microservices\`

To use a different namespace, edit \`kustomization.yaml\`:
\`\`\`yaml
namespace: your-namespace-here
\`\`\`

## 🧹 Cleanup

Remove all services:
\`\`\`bash
kubectl delete namespace microservices
\`\`\`

---

For deployment results, see \`DEPLOYMENT-RESULTS.md\`

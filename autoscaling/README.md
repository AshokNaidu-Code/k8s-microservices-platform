# Auto-Scaling Layer - Horizontal Pod Autoscaler (HPA)

This folder contains Kubernetes HPA (Horizontal Pod Autoscaler) configurations that automatically scale microservices based on CPU and memory metrics.

## 📋 HPA Configurations

### HPA 1: API Server Auto-Scaling
- **Target:** api-server Deployment
- **Metrics:** CPU (70%), Memory (80%)
- **Min Replicas:** 2
- **Max Replicas:** 10
- **Scale-up:** Aggressive (instant)
- **Scale-down:** Conservative (5 minutes)

### HPA 2: Web App Auto-Scaling
- **Target:** web-app Deployment
- **Metrics:** CPU (75%), Memory (85%)
- **Min Replicas:** 1
- **Max Replicas:** 5
- **Scale-up:** Moderate
- **Scale-down:** Moderate (3 minutes)

### HPA 3: Worker Job Auto-Scaling
- **Target:** worker-job Deployment
- **Metrics:** CPU (80%), Memory (90%)
- **Min Replicas:** 1
- **Max Replicas:** 3
- **Scale-up:** Moderate
- **Scale-down:** Conservative (5 minutes)

## 📊 How HPA Works

Metrics Server collects resource metrics (CPU, Memory)

HPA controller reads metrics every 15 seconds

If CPU > threshold, replica count increases

If CPU < threshold, replica count decreases (with delay)

Pods scheduled on available nodes


## 🚀 Prerequisites

Before applying HPA:

1. **Metrics Server installed:**
   \`\`\`bash
   kubectl get deployment metrics-server -n kube-system
   \`\`\`

2. **Services deployed:**
   \`\`\`bash
   kubectl get pods -n microservices
   \`\`\`

3. **Resource requests/limits defined:**
   (Already configured in Phase 1 manifests)

## 📝 Configuration Reference

### HPA Scaling Decisions

| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU < 50% | Too low | Scale down |
| CPU 50-70% | Normal | Maintain |
| CPU > 70% | High | Scale up |
| CPU > 90% | Critical | Max scale up |

## 🧪 Testing HPA

### 1. Monitor HPA Status
\`\`\`bash
kubectl get hpa -n microservices
kubectl describe hpa api-server-hpa -n microservices
\`\`\`

### 2. Generate Load
\`\`\`bash
# Create load generator pod
kubectl run -it --rm load-generator --image=busybox /bin/sh

# Inside pod, run:
while true; do wget -q -O- http://api-server:8080/api/load; done
\`\`\`

### 3. Watch Scaling
\`\`\`bash
kubectl get hpa -n microservices -w
\`\`\`

### 4. Monitor Metrics
\`\`\`bash
kubectl top pods -n microservices
kubectl top nodes
\`\`\`

## 📈 Expected Behavior

### Under Normal Load
- API Server: 2 replicas
- Web App: 1 replica
- Worker: 1 replica

### Under High Load (50+ concurrent requests)
- API Server: 2 → 4 → 6 → 8 replicas (within 2-3 minutes)
- Web App: 1 → 2 → 3 replicas (within 2-3 minutes)
- Worker: 1 → 2 → 3 replicas (within 1-2 minutes)

### After Load Reduces
- All replicas scale down (5 minute cooldown)
- Back to minimum replicas

## 🎯 Key Metrics to Track

| Metric | Expected Value | Note |
|--------|-----------------|------|
| Scale-up latency | < 2 min | How fast replicas increase |
| Scale-down delay | 5 min | Conservative to prevent flapping |
| Pod startup time | 30-60 sec | Time for new pod to be ready |
| Response time | < 200ms | API latency under scaling |
| Resource utilization | 60-80% | Optimal efficiency |

## ⚙️ Advanced Configuration

### Custom Metrics
To use custom metrics instead of CPU/Memory:

\`\`\`bash
kubectl apply -f custom-metrics-hpa.yaml
\`\`\`

### Vertical Pod Autoscaler (VPA)
To automatically adjust resource requests/limits:

\`\`\`bash
kubectl apply -f vpa-deployment.yaml
\`\`\`

## 🧹 Cleanup

Remove all HPA:
\`\`\`bash
kubectl delete hpa --all -n microservices
\`\`\`

---

For deployment results, see \`SCALING-RESULTS.md\`

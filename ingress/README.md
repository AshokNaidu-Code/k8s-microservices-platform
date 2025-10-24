# Ingress & TLS Layer - External Traffic Routing

This folder contains Kubernetes Ingress configurations for external traffic routing with TLS/HTTPS encryption.

## 📋 What's Included

### 1. Nginx Ingress Controller
- Deployment-based controller
- Listens on ports 80 (HTTP) and 443 (HTTPS)
- Automatically creates LoadBalancer service

### 2. TLS Certificate (Self-Signed)
- Self-signed certificate for demo
- Valid for 365 days
- Covers: *.microservices.local

### 3. Ingress Routes
- api.microservices.local → api-server service
- app.microservices.local → web-app service
- All routes encrypted with TLS

## 🔐 TLS Configuration

### Certificate Details
- **Type:** Self-signed X.509
- **Common Name:** microservices.local
- **Subject Alt Names:** *.microservices.local
- **Key Type:** RSA 2048-bit
- **Valid Days:** 365

### Ingress Rules
| Hostname | Path | Service | Port |
|----------|------|---------|------|
| api.microservices.local | / | api-server | 8080 |
| app.microservices.local | / | web-app | 80 |

## 🚀 Prerequisites

Before applying Ingress:

1. **Services deployed:**
   \`\`\`bash
   kubectl get svc -n microservices
   \`\`\`

2. **Nginx controller deployment ready**

3. **Certificate secret created**

## 📝 Deployment Steps

### Step 1: Install Nginx Controller
\`\`\`bash
kubectl apply -f 01-nginx-controller.yaml
\`\`\`

### Step 2: Create TLS Secret
\`\`\`bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout tls.key -out tls.crt \\
  -days 365 -nodes \\
  -subj "/CN=microservices.local/O=Demo/C=IN"

# Create secret
kubectl create secret tls tls-secret \\
  --cert=tls.crt \\
  --key=tls.key \\
  -n ingress-nginx
\`\`\`

### Step 3: Apply Ingress Rules
\`\`\`bash
kubectl apply -f 02-ingress-rules.yaml
\`\`\`

## 🧪 Testing Ingress

### Get Ingress Details
\`\`\`bash
kubectl get ingress -n microservices
kubectl describe ingress microservices-ingress -n microservices
\`\`\`

### Get Service LoadBalancer IP
\`\`\`bash
kubectl get svc -n ingress-nginx

# Note the EXTERNAL-IP of nginx-ingress service
\`\`\`

### Test HTTP (non-TLS)
\`\`\`bash
curl -H "Host: api.microservices.local" \\
  http://<EXTERNAL-IP>/api/get
\`\`\`

### Test HTTPS (TLS)
\`\`\`bash
# Ignore certificate warnings (self-signed)
curl -k -H "Host: api.microservices.local" \\
  https://<EXTERNAL-IP>/api/get
\`\`\`

### Local Testing (Port Forward)
\`\`\`bash
# Port forward nginx service
kubectl port-forward -n ingress-nginx svc/nginx-ingress 80:80 443:443 &

# Test in another terminal
curl -k https://api.microservices.local/api/get \\
  -H "Host: api.microservices.local"
\`\`\`

## 🔧 Advanced Configuration

### Add Another Route
Edit 02-ingress-rules.yaml and add:
\`\`\`yaml
- host: monitor.microservices.local
  http:
    paths:
    - path: /
      pathType: Prefix
      backend:
        service:
          name: grafana
          port:
            number: 3000
\`\`\`

### Use Production Certificate (Let's Encrypt)
Install cert-manager:
\`\`\`bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
\`\`\`

### SSL Redirect (HTTP → HTTPS)
Add annotation to ingress:
\`\`\`yaml
annotations:
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
\`\`\`

## 📊 Ingress Architecture

\`\`\`
┌─────────────────────────────────────────┐
│     External Traffic (Internet)          │
├─────────────────────────────────────────┤
│                                         │
│  HTTP:80 + HTTPS:443                    │
│        ↓                                │
│  Nginx Ingress Controller                │
│        ↓                                │
│  TLS Termination                         │
│        ↓                                │
│  Route Rules                             │
│  ├─ api.microservices.local → API       │
│  └─ app.microservices.local → Web       │
│        ↓                                │
│  Service Discovery                       │
│        ↓                                │
│  Pod Selection (Kube-proxy)              │
│        ↓                                │
│  Microservices Pods                      │
│                                         │
└─────────────────────────────────────────┘
\`\`\`

## ⚡ Performance Notes

- **Latency:** +1-2ms (TLS termination overhead)
- **Throughput:** Minimal impact (hardware accelerated)
- **Connections:** Persistent (keep-alive enabled)
- **Load Balancing:** Round-robin by default

## 🔒 Security Considerations

1. **Self-Signed Certificate**
   - ✅ Good for dev/test
   - ❌ Browsers show warnings
   - ❌ Not for production

2. **Production Setup**
   - Use Let's Encrypt (free TLS)
   - Use cert-manager for automation
   - Implement HSTS headers

3. **Security Headers**
   - Add X-Frame-Options: DENY
   - Add X-Content-Type-Options: nosniff
   - Add Strict-Transport-Security

## 🧹 Cleanup

Remove Ingress:
\`\`\`bash
kubectl delete ingress --all -n microservices
kubectl delete svc -n ingress-nginx
kubectl delete deployment -n ingress-nginx
kubectl delete namespace ingress-nginx
\`\`\`

---

For deployment results, see \`INGRESS-RESULTS.md\`

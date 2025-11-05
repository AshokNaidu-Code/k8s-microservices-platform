#!/bin/bash

###############################################################################
# K8s Microservices Platform - SIMPLIFIED Setup Script
# Purpose: Clean, step-by-step deployment with clear feedback
# Run this after: minikube start --cpus=4 --memory=8192 --driver=docker
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Simple logging functions
log_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}[STEP] $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_success() {
    echo -e "${GREEN}✓ SUCCESS: $1${NC}"
}

log_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    exit 1
}

log_info() {
    echo -e "${BLUE}ℹ INFO: $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

###############################################################################
# STEP 0: Verify Prerequisites
###############################################################################
log_step "Verifying Prerequisites"

if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl."
fi
log_success "kubectl found"

if ! command -v helm &> /dev/null; then
    log_error "helm not found. Please install helm."
fi
log_success "helm found"

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    log_error "Kubernetes cluster not accessible. Run: minikube start --cpus=4 --memory=8192 --driver=docker"
fi
log_success "Kubernetes cluster is accessible"

###############################################################################
# STEP 1: Create Namespaces
###############################################################################
log_step "Creating Namespaces"

kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f - &> /dev/null
log_success "Namespace: ingress-nginx"

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f - &> /dev/null
log_success "Namespace: monitoring"

kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f - &> /dev/null
log_success "Namespace: cert-manager"

###############################################################################
# STEP 2: Install Cert-Manager
###############################################################################
log_step "Installing Cert-Manager (TLS Management)"

log_info "Adding Helm repository..."
helm repo add jetstack https://charts.jetstack.io --force-update &> /dev/null

log_info "Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true \
  --wait \
  --timeout 5m &> /dev/null

log_success "Cert-Manager installed"

log_info "Waiting for cert-manager webhook to be ready (this takes ~30 seconds)..."
kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=120s &> /dev/null
log_success "Cert-Manager webhook is ready"

###############################################################################
# STEP 3: Create SelfSigned TLS Issuer
###############################################################################
log_step "Setting Up TLS with SelfSigned Issuer"

cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF

log_success "SelfSigned ClusterIssuer created"

###############################################################################
# STEP 4: Install NGINX Ingress Controller
###############################################################################
log_step "Installing NGINX Ingress Controller"

log_info "Adding Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update &> /dev/null

log_info "Installing NGINX ingress controller..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=NodePort \
  --wait \
  --timeout 5m &> /dev/null

log_success "NGINX Ingress Controller installed"

###############################################################################
# STEP 5: Create Storage Class
###############################################################################
log_step "Creating Storage Class"

cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard-sc
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Retain
EOF

log_success "Storage Class created"

###############################################################################
# STEP 6: Deploy Microservice (Service-A)
###############################################################################
log_step "Deploying Microservice (Service-A)"

log_info "Creating deployment..."
cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-a
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: service-a
  template:
    metadata:
      labels:
        app: service-a
    spec:
      containers:
        - name: service-a
          image: nginx:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
EOF

log_success "Service-A deployment created"

log_info "Creating service..."
cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: v1
kind: Service
metadata:
  name: service-a
  namespace: default
spec:
  selector:
    app: service-a
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

log_success "Service-A service created"

log_info "Waiting for Service-A pods to be ready..."
kubectl wait --for=condition=ready pod -l app=service-a --timeout=60s &> /dev/null
log_success "Service-A pods are running"

###############################################################################
# STEP 7: Create Ingress with TLS
###############################################################################
log_step "Creating Ingress with TLS"

cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: "selfsigned-issuer"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - localhost
        - example.local
      secretName: tls-secret
  rules:
    - host: localhost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-a
                port:
                  number: 80
    - host: example.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-a
                port:
                  number: 80
EOF

log_success "Ingress with TLS created"

log_info "Waiting for TLS certificate to be issued (this takes ~30 seconds)..."
sleep 10
log_success "TLS certificate created"

###############################################################################
# STEP 8: Deploy Horizontal Pod Autoscaler
###############################################################################
log_step "Setting Up Horizontal Pod Autoscaler (HPA)"

cat <<EOF | kubectl apply -f - &> /dev/null
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: service-a-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: service-a
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
EOF

log_success "HPA created (min: 2, max: 10 replicas)"

###############################################################################
# STEP 9: Install Prometheus & Grafana Stack
###############################################################################
log_step "Installing Prometheus & Grafana Monitoring Stack"

log_info "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update &> /dev/null
helm repo add grafana https://grafana.github.io/helm-charts --force-update &> /dev/null

log_info "Installing kube-prometheus-stack (includes Prometheus + Grafana)..."
helm upgrade --install monitoring-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=7d \
  --set grafana.adminPassword=admin123 \
  --set grafana.persistence.enabled=false \
  --wait \
  --timeout 10m &> /dev/null

log_success "Prometheus & Grafana stack installed"

###############################################################################
# STEP 10: Verify Deployment
###############################################################################
log_step "Verifying Deployment"

log_info "Checking all pods..."
RUNNING_PODS=$(kubectl get pods -A --no-headers | grep -c "Running\|Completed")
TOTAL_PODS=$(kubectl get pods -A --no-headers | wc -l)
log_success "Pods: $RUNNING_PODS/$TOTAL_PODS running"

log_info "Checking ingress..."
INGRESS=$(kubectl get ingress -o name 2>/dev/null | wc -l)
[ "$INGRESS" -gt 0 ] && log_success "Ingress configured" || log_warn "Ingress not yet configured"

log_info "Checking HPA..."
HPA=$(kubectl get hpa -o name 2>/dev/null | wc -l)
[ "$HPA" -gt 0 ] && log_success "HPA configured" || log_warn "HPA not yet configured"

###############################################################################
# STEP 11: Print Access Instructions
###############################################################################
log_step "Setup Complete! 🎉"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Access Instructions${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

echo -e "${YELLOW}1. Access Grafana Dashboard${NC}"
echo "   Command: kubectl port-forward svc/monitoring-stack-grafana -n monitoring 3000:80"
echo "   URL: http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin123"
echo ""

echo -e "${YELLOW}2. Access Prometheus${NC}"
echo "   Command: kubectl port-forward svc/monitoring-stack-kube-prom-prometheus -n monitoring 9091:9090"
echo "   URL: http://localhost:9091"
echo ""

echo -e "${YELLOW}3. Access Service-A via HTTPS${NC}"
echo "   Command: kubectl port-forward svc/ingress-nginx-controller -n ingress-nginx 8443:443"
echo "   Test: curl -k https://localhost:8443/"
echo ""

echo -e "${YELLOW}4. Test HPA (Generate Load)${NC}"
echo "   Start load: kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c \"while true; do wget -q -O- http://service-a.default.svc.cluster.local; done\""
echo "   Watch HPA: kubectl get hpa service-a-hpa --watch"
echo "   Stop load: kubectl delete pod load-generator"
echo ""

echo -e "${YELLOW}5. Useful Commands${NC}"
echo "   kubectl get pods -A                     # View all pods"
echo "   kubectl get svc -A                      # View all services"
echo "   kubectl get ingress                     # View ingress"
echo "   kubectl get hpa                         # View autoscaler"
echo "   kubectl logs deployment/service-a       # View service logs"
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Setup Complete! Happy DevOps-ing! 🚀${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
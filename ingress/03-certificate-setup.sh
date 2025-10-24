#!/bin/bash
# Script to generate self-signed TLS certificate and create Kubernetes secret

set -e

NAMESPACE="ingress-nginx"
SECRET_NAME="tls-secret"
CN="microservices.local"
DAYS=365

echo "🔐 Generating self-signed TLS certificate..."

# Generate private key and certificate
openssl req -x509 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -days $DAYS \
  -nodes \
  -subj "/CN=$CN/O=Demo/C=IN/ST=AP/L=Bhimavaram" \
  -addext "subjectAltName=DNS:*.microservices.local,DNS:microservices.local"

echo "✅ Certificate generated:"
echo "   - CN: $CN"
echo "   - Days: $DAYS"
echo "   - Size: 2048-bit RSA"

# Verify certificate
echo ""
echo "📋 Certificate Details:"
openssl x509 -in tls.crt -text -noout | grep -A 2 "Subject:\|Issuer:\|Not Before:\|Not After"

# Create Kubernetes secret
echo ""
echo "📦 Creating Kubernetes secret..."

kubectl create secret tls $SECRET_NAME \
  --cert=tls.crt \
  --key=tls.key \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret created: $SECRET_NAME in namespace $NAMESPACE"

# Verify secret
echo ""
echo "✔️ Verifying secret..."
kubectl get secret $SECRET_NAME -n $NAMESPACE -o yaml | grep "tls\."

echo ""
echo "🎉 TLS setup complete!"
echo ""
echo "Next steps:"
echo "1. Apply ingress rules: kubectl apply -f 02-ingress-rules.yaml"
echo "2. Check ingress: kubectl get ingress -n microservices"
echo "3. Get LoadBalancer IP: kubectl get svc -n ingress-nginx"
echo "4. Add to /etc/hosts: <EXTERNAL-IP> api.microservices.local app.microservices.local"
echo "5. Test: curl -k https://api.microservices.local/"

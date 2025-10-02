#!/bin/bash
set -e

echo "========================================"
echo "   Installing NGINX Ingress Controller (EKS)"
echo "========================================"

# Adicionar repositório Helm do NGINX Ingress
echo "[INFO] Adding NGINX Ingress Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo ""
echo "[INFO] Installing NGINX Ingress Controller..."

# Instalar NGINX Ingress Controller
# Usando hostNetwork para que o controller use a rede do host (worker nodes)
# Isso permite que o NLB do Terraform encaminhe tráfego diretamente para os nós
# SEM criar um LoadBalancer adicional
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.hostNetwork=true \
  --set controller.kind=DaemonSet \
  --set controller.service.type=ClusterIP \
  --set controller.ingressClassResource.default=true \
  --set controller.metrics.enabled=true \
  --set controller.podAnnotations."prometheus\.io/scrape"="true" \
  --set controller.podAnnotations."prometheus\.io/port"="10254" \
  --wait --timeout=5m

echo ""
echo "[INFO] Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo ""
echo "[INFO] Checking Ingress Controller status..."
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

echo ""
echo "[SUCCESS] NGINX Ingress Controller installed successfully!"
echo ""
echo "✅ Configuration:"
echo "   - Controller running as DaemonSet with hostNetwork"
echo "   - Using the NLB created by Terraform (no additional LoadBalancer)"
echo "   - Worker nodes are automatically registered in the NLB Target Group"
echo ""
echo "Next steps:"
echo "1. Verify that worker nodes are registered in the Target Group (via Terraform)"
echo "2. Deploy your ingress resources"
echo "3. Test via API Gateway URL"
echo ""

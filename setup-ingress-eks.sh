#!/bin/bash
set -e

echo "========================================"
echo "   Installing NGINX Ingress Controller (EKS)"
echo "========================================"

# Adicionar repositório Helm do NGINX Ingress
echo "[INFO] Adding NGINX Ingress Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Obter o ARN do Target Group do Terraform
# Este valor deve ser passado como variável de ambiente ou secret do GitHub Actions
if [ -z "$TARGET_GROUP_ARN" ]; then
  echo "[WARNING] TARGET_GROUP_ARN not set. Installing without target group annotation."
  echo "[WARNING] You will need to register the LoadBalancer manually to the NLB."
fi

echo ""
echo "[INFO] Installing NGINX Ingress Controller..."

# Instalar NGINX Ingress Controller
# O controller criará um Service do tipo LoadBalancer que será registrado no NLB
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-internal"="true" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internal" \
  $(if [ -n "$TARGET_GROUP_ARN" ]; then echo "--set controller.service.annotations.\"service\.beta\.kubernetes\.io/aws-load-balancer-target-group-arn\"=\"${TARGET_GROUP_ARN}\""; fi) \
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
echo "Next steps:"
echo "1. The LoadBalancer service will create an internal NLB"
echo "2. Register this NLB with the Terraform-created Target Group"
echo "3. Deploy your ingress resources"
echo ""

# Obter o endereço do LoadBalancer
echo "[INFO] Waiting for LoadBalancer address..."
sleep 10
LB_HOSTNAME=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -n "$LB_HOSTNAME" ]; then
  echo "LoadBalancer Hostname: $LB_HOSTNAME"
else
  echo "[WARNING] LoadBalancer address not ready yet. Check with: kubectl get svc -n ingress-nginx"
fi

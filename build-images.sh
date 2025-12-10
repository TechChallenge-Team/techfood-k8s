#!/bin/bash

# Script para fazer build das imagens Docker no Minikube (microservices + frontends)

echo "🐳 Fazendo build das imagens Docker para o Minikube..."

# Configura o ambiente Docker para usar o Minikube
echo "🔧 Configurando ambiente Docker do Minikube..."
eval $(minikube docker-env)

images=(
    "grupotechchallenge/techfood-order-api:latest|services/order-api/Dockerfile|services/order-api"
    "grupotechchallenge/techfood-order-worker:latest|services/order-worker/Dockerfile|services/order-worker"
    "grupotechchallenge/techfood-payment-api:latest|services/payment-api/Dockerfile|services/payment-api"
    "grupotechchallenge/techfood-payment-worker:latest|services/payment-worker/Dockerfile|services/payment-worker"
    "grupotechchallenge/techfood-backoffice-api:latest|services/backoffice-api/Dockerfile|services/backoffice-api"
    "grupotechchallenge/techfood-kitchen-api:latest|services/kitchen-api/Dockerfile|services/kitchen-api"
    "grupotechchallenge/techfood-kitchen-worker:latest|services/kitchen-worker/Dockerfile|services/kitchen-worker"
    # Frontends e nginx
    "techfood.admin:latest|apps/admin/Dockerfile|apps/admin"
    "techfood.self-order:latest|apps/self-order/Dockerfile|apps/self-order"
    "techfood.monitor:latest|apps/monitor/Dockerfile|apps/monitor"
    "techfood.nginx:latest|nginx/Dockerfile|nginx"
)

for entry in "${images[@]}"; do
    IFS='|' read -r tag dockerfile context <<<"$entry"
    if [ ! -f "$dockerfile" ]; then
        echo "⚠️  Dockerfile não encontrado para $tag em $dockerfile, pulando..."
        continue
    fi

    echo "📦 Building $tag ..."
    docker build -t "$tag" -f "$dockerfile" "$context"
    if [ $? -ne 0 ]; then
        echo "❌ Erro ao fazer build de $tag"
        exit 1
    fi
done

echo "✅ Todas as imagens foram processadas."
echo ""
echo "Para fazer o deploy, execute:"
echo "kubectl apply -k src/overlays/development/"
echo ""
echo "Ou use o script de deploy:"
echo "./deploy.sh"

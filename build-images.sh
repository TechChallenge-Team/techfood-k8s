#!/bin/bash

# Script para fazer build das imagens Docker no Minikube

echo "🐳 Fazendo build das imagens Docker para o Minikube..."

# Configura o ambiente Docker para usar o Minikube
echo "🔧 Configurando ambiente Docker do Minikube..."
eval $(minikube docker-env)

# Build da API
echo "📦 Building TechFood.Api..."
docker build -t techfood.api:latest -f src/TechFood.Api/Dockerfile .
if [ $? -ne 0 ]; then
    echo "❌ Erro ao fazer build da API"
    exit 1
fi

# Build do Admin
echo "📦 Building TechFood.Admin..."
docker build -t techfood.admin:latest -f apps/admin/Dockerfile .
if [ $? -ne 0 ]; then
    echo "❌ Erro ao fazer build do Admin"
    exit 1
fi

# Build do Self-Order
echo "📦 Building TechFood.Self-Order..."
docker build -t techfood.self-order:latest -f apps/self-order/Dockerfile .
if [ $? -ne 0 ]; then
    echo "❌ Erro ao fazer build do Self-Order"
    exit 1
fi

# Build do Monitor
echo "📦 Building TechFood.Monitor..."
docker build -t techfood.monitor:latest -f apps/monitor/Dockerfile .
if [ $? -ne 0 ]; then
    echo "❌ Erro ao fazer build do Monitor"
    exit 1
fi

# Build do Nginx
echo "📦 Building TechFood.Nginx..."
docker build -t techfood.nginx:latest -f nginx/Dockerfile nginx/
if [ $? -ne 0 ]; then
    echo "❌ Erro ao fazer build do Nginx"
    exit 1
fi

echo "✅ Todas as imagens foram criadas com sucesso!"
echo ""
echo "Para fazer o deploy, execute:"
echo "kubectl apply -k k8s/overlays/development/"
echo ""
echo "Ou use o script de deploy:"
echo "./k8s/deploy.sh"

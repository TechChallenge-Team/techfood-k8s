#!/bin/bash

# Script para limpeza completa do deployment Kubernetes

echo "🧹 Limpando recursos do TechFood no Kubernetes..."

echo ""
echo "⚠️ Este script irá remover todos os recursos do namespace techfood"
echo "⚠️ Isso inclui pods, services, deployments, PVCs e dados persistentes"
echo ""
read -p "Tem certeza que deseja continuar? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 0
fi

echo ""
echo "🗑️ Removendo recursos do namespace techfood..."

# Remover namespace (isso remove todos os recursos dentro dele)
if kubectl delete namespace techfood --ignore-not-found=true; then
    echo "✅ Namespace techfood removido com sucesso"
else
    echo "❌ Erro ao remover namespace"
    echo ""
    echo "🔧 Tentando limpeza manual..."
    kubectl delete all --all -n techfood --ignore-not-found=true
    kubectl delete pvc --all -n techfood --ignore-not-found=true
    kubectl delete configmap --all -n techfood --ignore-not-found=true
    kubectl delete secret --all -n techfood --ignore-not-found=true
    kubectl delete hpa --all -n techfood --ignore-not-found=true
    kubectl delete namespace techfood --ignore-not-found=true
fi

echo ""
echo "🔍 Verificando se ainda existem recursos..."
if kubectl get all -n techfood 2>/dev/null; then
    echo "⚠️ Ainda existem alguns recursos. Você pode precisar removê-los manualmente."
else
    echo "✅ Todos os recursos foram removidos"
fi

echo ""
echo "🎉 Limpeza concluída!"
echo ""
echo "💡 Para fazer um novo deploy:"
echo "   ./k8s/build-images.sh"
echo "   ./k8s/deploy.sh"
echo ""

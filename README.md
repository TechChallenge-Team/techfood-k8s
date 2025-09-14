# TechFood - Kubernetes Deployment

Este diretório contém os manifestos e scripts necessários para fazer o deploy da aplicação TechFood no Kubernetes usando Minikube.

## Pré-requisitos

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) instalado e configurado
- [kubectl](https://kubernetes.io/docs/tasks/tools/) instalado
- [Docker](https://docs.docker.com/get-docker/) instalado
- Mínimo de 4GB de RAM disponível para o Minikube

## Instalação do Minikube

1. Baixe o arquivo .exe do [site oficial](https://minikube.sigs.k8s.io/docs/start/)
2. Adicione ao PATH do sistema

## Instalação do kubectl

1. Baixe o arquivo .exe do [site oficial](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
2. Adicione ao PATH do sistema

## Deploy Rápido

### 1. Iniciar o Minikube

```bash
minikube start --memory=4096 --cpus=2 --driver=docker
```

### 2. Habilitar Addons Necessários

```bash
minikube addons enable metrics-server
minikube addons enable ingress
```

### 3. Verificar Instalação

```bash
minikube status
kubectl cluster-info
kubectl get nodes
```

### 4. Build das Imagens

Execute o script para fazer build das imagens Docker:

```bash
# Windows
build-images.bat

# Linux/Mac
./build-images.sh
```

### 5. Deploy da Aplicação

Execute o script de deploy:

```bash
# Windows
deploy.bat

# Linux/Mac
./deploy.sh
```

### 6. Validar o Deploy

```bash
# Windows
validate.bat

# Linux/Mac
./validate.sh
```

### 7. Port Forward para o Serviço Nginx

```bash
kubectl port-forward service/techfood-nginx-service 30000:30000 -n techfood
```

### 8. Acessar a Aplicação

```bash
minikube service techfood-nginx-service -n techfood
```

### 9. Limpeza (Opcional)

```bash
# Windows
cleanup.bat

# Linux/Mac
./cleanup.sh
```

## Arquitetura

A aplicação TechFood é composta pelos seguintes componentes:

### Frontend Applications

- **Admin**: Interface administrativa para gerenciar produtos e pedidos
- **Self-Order**: Interface de autoatendimento para clientes
- **Monitor**: Dashboard para monitoramento de pedidos

### Backend Services

- **API**: API REST principal da aplicação
- **Database**: SQL Server para persistência de dados
- **Nginx**: Reverse proxy e load balancer

### Infraestrutura Kubernetes

- **Namespace**: `techfood` - Isolamento dos recursos
- **ConfigMaps**: Configurações não sensíveis
- **Secrets**: Dados sensíveis (senhas, tokens)
- **PersistentVolumes**: Armazenamento persistente
- **Services**: Exposição interna dos serviços
- **Deployments**: Gerenciamento dos pods
- **HPA**: Auto-escalabilidade baseada em CPU/memória

## Escalabilidade (HPA)

A aplicação está configurada com Horizontal Pod Autoscaler:

| Componente | Min Replicas | Max Replicas | CPU Target | Memory Target |
| ---------- | ------------ | ------------ | ---------- | ------------- |
| API        | 2            | 10           | 70%        | 80%           |
| Self-Order | 3            | 15           | 70%        | 80%           |
| Admin      | 2            | 5            | 70%        | 80%           |
| Monitor    | 2            | 5            | 70%        | 80%           |
| Nginx      | 2            | 5            | 70%        | 80%           |

## Segurança

### ConfigMaps (Dados não sensíveis)

- Configurações de ambiente
- URLs e endpoints
- Configurações do Nginx

### Secrets (Dados sensíveis)

- Senhas do banco de dados
- Tokens JWT
- Chaves de API do Mercado Pago

## Estrutura dos Manifestos

```
src/
├── base/                           # Manifestos base
│   ├── namespace.yaml             # Namespace da aplicação
│   ├── configmaps.yaml            # Configurações não sensíveis
│   ├── secrets.yaml               # Dados sensíveis
│   ├── pvc.yaml                   # Persistent Volume Claims
│   ├── techfood-db.yaml           # Database deployment
│   ├── techfood-api.yaml          # API deployment
│   ├── techfood-admin.yaml        # Admin app deployment
│   ├── techfood-self-order.yaml   # Self-order app deployment
│   ├── techfood-monitor.yaml      # Monitor app deployment
│   ├── techfood-nginx.yaml        # Nginx deployment
│   ├── hpa.yaml                   # Horizontal Pod Autoscalers
│   └── kustomization.yaml         # Kustomize configuration
├── overlays/
│   └── development/               # Configurações para desenvolvimento
│       ├── kustomization.yaml
│       └── development-patches.yaml
├── build-images.bat              # Script para build das imagens
├── deploy.bat                    # Script de deploy
└── README.md                     # Este arquivo
```

## Endpoints

Após o deploy, a aplicação estará disponível nos seguintes endpoints:

- **Admin**: http://localhost:30000/admin
- **Self-Order**: http://localhost:30000/self-order
- **Monitor**: http://localhost:30000/monitor
- **API**: http://localhost:30000/api
- **Health Check**: http://localhost:30000/health

### Monitoramento

```bash
# Ver todos os recursos
kubectl get all -n techfood

# Monitorar pods em tempo real
kubectl get pods -n techfood -w

# Monitorar HPA
kubectl get hpa -n techfood -w

# Ver logs de um pod
kubectl logs -f <pod-name> -n techfood

# Acessar shell de um pod
kubectl exec -it <pod-name> -n techfood -- /bin/bash
```

### Debugging

```bash
# Descrever um recurso
kubectl describe pod <pod-name> -n techfood

# Ver eventos do namespace
kubectl get events -n techfood --sort-by='.metadata.creationTimestamp'
```

### Limpeza

```bash
# Remover todos os recursos
kubectl delete namespace techfood

# Ou usar kustomize
kubectl delete -k src/overlays/development/
```

## Notas de Desenvolvimento

- As imagens Docker são construídas localmente no Minikube
- O banco de dados usa armazenamento persistente
- As configurações de desenvolvimento reduzem os recursos para economizar CPU/memória
- O HPA requer o metrics-server habilitado
- Por padrão, o serviço é exposto via NodePort na porta 30000

## Comandos Adicionais

### Parar o Minikube

```bash
minikube stop
```

### Deletar o Cluster

```bash
minikube delete
```

### Dashboard do Kubernetes

```bash
minikube dashboard
```

### Logs do Minikube

```bash
minikube logs
```

### Testar se a API está respondendo dentro do cluster

```bash
kubectl exec -it deployment/techfood-nginx -n techfood -- curl -v http://techfood-api-service:8080/health
```

### Reiniciar o deployment Nginx

```bash
kubectl rollout restart deployment/techfood-nginx -n techfood
```

### Verificar o status do deployment Nginx

```bash
kubectl rollout status deployment/techfood-nginx -n techfood
```

## Troubleshooting

### Problema: Minikube não inicia

```bash
# Verificar drivers disponíveis
minikube start --help | Select-String "driver"

# Verificar perfil do Minikube
minikube profile list

# Remover e recriar o cluster
minikube delete
minikube start --driver=docker
```

### Problema: Imagens não são encontradas

```bash
# Configurar Docker environment
minikube docker-env | Invoke-Expression

# Verificar imagens
docker images
```

### Problema: Pods em CrashLoopBackOff

```bash
# Ver logs detalhados
kubectl logs -f <pod-name> -n techfood
kubectl describe pod <pod-name> -n techfood
```

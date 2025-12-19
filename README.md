# TechFood - Kubernetes Deployment

Este diretório contém os manifestos e scripts necessários para fazer o deploy da aplicação TechFood no Kubernetes.

## 🚀 Deploy em AWS EKS

Para deploy em produção no AWS EKS com integração ao NLB do Terraform, consulte:
- **[NLB-INTEGRATION.md](./NLB-INTEGRATION.md)** - Integração otimizada do Nginx Ingress com o Load Balancer do Terraform
- **[NGINX-INGRESS-SETUP.md](./NGINX-INGRESS-SETUP.md)** - Setup do Nginx Ingress no EKS
- **[INTEGRATION-GUIDE.md](./INTEGRATION-GUIDE.md)** - Guia completo de integração

### Scripts para EKS:
- `setup-ingress-eks.sh/.bat` - Instala Nginx Ingress otimizado para AWS EKS
- `validate-nlb-integration.sh/.bat` - Valida a integração com o NLB do Terraform

---

## 🏠 Deploy Local (Minikube)

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
```

**Nota**: O addon do Ingress será instalado automaticamente pelo script `setup-ingress.bat/.sh`

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

### 6. Setup do Ingress Controller

Execute o script para instalar o NGINX Ingress Controller:

```bash
# Windows
setup-ingress.bat

# Linux/Mac
./setup-ingress.sh
```

### 7. Validar o Deploy

```bash
# Windows
validate.bat

# Linux/Mac
./validate.sh
```

### 8. Acessar a Aplicação

Após o deploy, você pode acessar a aplicação de duas formas:

#### Opção 1: Via hostname (recomendado)

1. Obtenha o IP do Minikube:
```bash
minikube ip
```

2. Adicione uma entrada no arquivo hosts do seu sistema:
```bash
# Windows: C:\Windows\System32\drivers\etc\hosts
# Linux/Mac: /etc/hosts
<MINIKUBE_IP> techfood.local
```

3. Acesse no navegador: `http://techfood.local`

#### Opção 2: Via IP direto

Acesse diretamente via IP do Minikube (sem precisar configurar hosts):
```bash
# Obter IP e acessar no navegador
minikube ip
# Acesse: http://<MINIKUBE_IP>
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

- **Order API / Worker**: processamento de pedidos
- **Payment API / Worker**: pagamentos e integrações
- **Backoffice API**: gestão e conteúdo estático (imagens)
- **Kitchen API / Worker**: operações de cozinha
- **Database**: SQL Server/Mongo conforme serviço
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
│   ├── storage.yaml               # Persistent Volume Claims
│   ├── techfood-order-api.yaml    # Order API deployment
│   ├── techfood-order-worker.yaml # Order Worker deployment
│   ├── techfood-payment-api.yaml  # Payment API deployment
│   ├── techfood-payment-worker.yaml # Payment Worker deployment
│   ├── techfood-backoffice-api.yaml # Backoffice API deployment
│   ├── techfood-kitchen-api.yaml  # Kitchen API deployment
│   ├── techfood-kitchen-worker.yaml # Kitchen Worker deployment
│   ├── techfood-admin.yaml        # Admin app deployment
│   ├── techfood-self-order.yaml   # Self-order app deployment
│   ├── techfood-monitor.yaml      # Monitor app deployment
│   ├── techfood-ingress.yaml      # Ingress configuration
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
- **Order API**: http://localhost:30000/api/order
- **Payment API**: http://localhost:30000/api/payment
- **Backoffice API**: http://localhost:30000/api/backoffice
- **Kitchen API**: http://localhost:30000/api/kitchen
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
- A aplicação é exposta via NGINX Ingress Controller
- Acesso através do hostname `techfood.local` ou diretamente via IP do Minikube

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

### Testar serviços dentro do cluster

```bash
# Testar Order API
kubectl exec -it deployment/techfood-order-api -n techfood -- curl -v http://localhost:8080/health

# Testar Backoffice API
kubectl exec -it deployment/techfood-backoffice-api -n techfood -- curl -v http://localhost:8080/health
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

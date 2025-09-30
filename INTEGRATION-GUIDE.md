# Integração API Gateway + EKS + NGINX Ingress Controller

Este documento explica como o API Gateway se conecta ao cluster EKS através do NGINX Ingress Controller.

## 🏗️ Arquitetura

```
┌─────────────┐
│   Internet  │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│   API Gateway       │ (Público - Regional)
│   (REST API)        │
└──────┬──────────────┘
       │
       │ VPC Link (Privado)
       ▼
┌─────────────────────┐
│  Network Load       │ (Interno - criado pelo Terraform)
│  Balancer (NLB)     │
│  Target Group: 80   │
└──────┬──────────────┘
       │
       │ Target Registration
       ▼
┌─────────────────────┐
│  NGINX Ingress      │ (Service LoadBalancer)
│  Controller         │ (criado pelo Helm no K8s)
│  Port: 80           │
└──────┬──────────────┘
       │
       │ Ingress Rules
       ▼
┌─────────────────────┐
│  Kubernetes         │
│  Services           │
│  (techfood-api-svc) │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Pods               │
│  (techfood-api)     │
└─────────────────────┘
```

## 🔧 Como funciona a conexão?

### 1. **Terraform cria:**
- ✅ API Gateway REST API
- ✅ VPC Link (conecta API Gateway à VPC)
- ✅ Network Load Balancer (NLB) interno
- ✅ Target Group (registra alvos na porta 80)
- ✅ Listener (porta 80, protocolo TCP)

**Arquivo:** `techfood-terraform/src/vpc-link.tf`

### 2. **Helm/K8s instala:**
- ✅ NGINX Ingress Controller (Deployment)
- ✅ Service do tipo LoadBalancer (cria um NLB automaticamente na AWS)
- ✅ Ingress Resources (regras de roteamento)

**Script:** `techfood-k8s/setup-ingress-eks.sh`

### 3. **Conexão automática:**

Quando o NGINX Ingress Controller é instalado com a annotation:
```yaml
service.beta.kubernetes.io/aws-load-balancer-target-group-arn: <ARN_DO_TG>
```

O Kubernetes automaticamente:
1. Cria um Service do tipo LoadBalancer
2. AWS cria um NLB para esse Service
3. **Registra os IPs dos nodes no Target Group do Terraform**

## 📋 Pré-requisitos

### No Terraform (já implementado):
- ✅ VPC e Subnets
- ✅ EKS Cluster
- ✅ API Gateway
- ✅ VPC Link
- ✅ Network Load Balancer
- ✅ Target Group

### No GitHub Actions (configurar):

#### Secrets necessários:
```yaml
AWS_ACCESS_KEY_ID          # Credenciais AWS
AWS_SECRET_ACCESS_KEY      # Credenciais AWS
AWS_SESSION_TOKEN          # Token de sessão (AWS Academy)
RDS_ENDPOINT               # Endpoint do RDS (output do Terraform)
RDS_USERNAME               # Usuário do banco
RDS_PASSWORD               # Senha do banco
NLB_TARGET_GROUP_ARN       # ARN do Target Group (output do Terraform)
JWT_KEY                    # Chave JWT (opcional)
MERCADO_PAGO_TOKEN         # Token Mercado Pago (opcional)
```

## 🚀 Como configurar

### Passo 1: Aplicar infraestrutura com Terraform

```bash
cd techfood-terraform/src
terraform init
terraform apply
```

**Pegue os outputs importantes:**
```bash
terraform output nlb_target_group_arn  # Copie este valor!
terraform output api_gateway_url
terraform output rds_endpoint
```

### Passo 2: Adicionar secrets no GitHub

No repositório `techfood-k8s`, vá em:
**Settings → Secrets and variables → Actions → New repository secret**

Adicione:
- `NLB_TARGET_GROUP_ARN` = `<valor do terraform output>`
- `RDS_ENDPOINT` = `<endpoint do RDS>`
- `RDS_USERNAME` = `admin` (ou seu usuário)
- `RDS_PASSWORD` = `<sua senha>`

### Passo 3: Deploy via GitHub Actions

O workflow `.github/workflows/ci-cd.yml` fará automaticamente:

1. Conectar no cluster EKS
2. Instalar Helm
3. **Instalar NGINX Ingress Controller** com annotation do Target Group
4. Aplicar manifestos K8s (deployments, services, ingress)
5. Atualizar secrets com valores dinâmicos

```yaml
# O workflow já está configurado para rodar em push
git add .
git commit -m "Deploy with NGINX Ingress"
git push origin main
```

### Passo 4: Verificar instalação

```bash
# Conectar no cluster
aws eks update-kubeconfig --name techfood-eks --region us-east-1

# Verificar NGINX Ingress
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Verificar Ingress resources
kubectl get ingress -n techfood

# Ver logs do Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=100
```

## 🧪 Testar a conexão

### 1. Via API Gateway (público):
```bash
# URL do API Gateway (output do Terraform)
GATEWAY_URL="https://abc123.execute-api.us-east-1.amazonaws.com/prod"

# Health check
curl $GATEWAY_URL/api/health

# Listar categorias
curl $GATEWAY_URL/api/categories
```

### 2. Internamente no cluster:
```bash
# Port-forward para o Ingress Controller
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80

# Testar localmente
curl http://localhost:8080/api/health
```

## 🔍 Troubleshooting

### Problema: API Gateway retorna 503 ou timeout

**Verificar:**
```bash
# 1. Target Group tem targets saudáveis?
aws elbv2 describe-target-health \
  --target-group-arn <ARN_DO_TARGET_GROUP>

# 2. NGINX Ingress está rodando?
kubectl get pods -n ingress-nginx

# 3. Service do NGINX tem IP externo?
kubectl get svc -n ingress-nginx

# 4. Ingress está configurado?
kubectl describe ingress techfood-ingress -n techfood
```

### Problema: Target Group sem targets registrados

**Solução:** Reinstalar NGINX Ingress com a annotation correta:

```bash
# Deletar instalação atual
helm uninstall ingress-nginx -n ingress-nginx

# Definir o ARN do Target Group
export TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:..."

# Reinstalar
./setup-ingress-eks.sh
```

### Problema: Ingress não roteia para o Service

**Verificar:**
```bash
# 1. Service existe e tem endpoints?
kubectl get svc -n techfood
kubectl get endpoints techfood-api-svc -n techfood

# 2. Pods estão rodando?
kubectl get pods -n techfood

# 3. Ingress aponta para o Service correto?
kubectl get ingress techfood-ingress -n techfood -o yaml
```

## 📊 Monitoramento

### Logs do NGINX Ingress:
```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --follow
```

### Métricas do Ingress:
```bash
# Port-forward para métricas
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 10254:10254

# Acessar métricas
curl http://localhost:10254/metrics
```

### CloudWatch (API Gateway + NLB):
- API Gateway: Latência, 4xx, 5xx errors
- NLB: Target health, processed bytes
- EKS: Container Insights (se habilitado)

## 🔒 Segurança

- ✅ NLB é **interno** (não acessível pela internet)
- ✅ API Gateway é o único ponto de entrada público
- ✅ VPC Link mantém tráfego na rede privada da AWS
- ✅ NGINX Ingress só aceita tráfego do NLB
- ✅ Secrets gerenciados via GitHub Secrets (não em código)

## 🔄 Fluxo de uma requisição completa

```
1. Cliente → https://api.techfood.com/api/categories
                    ↓
2. API Gateway → VPC Link → NLB (172.31.x.x:80)
                              ↓
3. NLB → Target (Node IP:NodePort)
            ↓
4. NGINX Ingress Controller (pod) → verifica regras do Ingress
                                      ↓
5. Roteamento → Service: techfood-api-svc:80
                          ↓
6. Service → Pod: techfood-api:8080
                   ↓
7. Aplicação processa → retorna resposta
                          ↓
8. Resposta segue caminho inverso → Cliente
```

## 📚 Referências

- [NGINX Ingress Controller - AWS](https://kubernetes.github.io/ingress-nginx/deploy/#aws)
- [API Gateway VPC Link](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-private-integration.html)
- [EKS Load Balancing](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html)
- [Terraform AWS VPC Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_vpc_link)

## ✅ Checklist de deploy

- [ ] Terraform aplicado (VPC, EKS, API Gateway, NLB, Target Group)
- [ ] Secrets configurados no GitHub (AWS credentials, RDS, Target Group ARN)
- [ ] Helm instalado no runner do GitHub Actions
- [ ] NGINX Ingress Controller instalado com annotation do Target Group
- [ ] Manifests K8s aplicados (Deployments, Services, Ingress)
- [ ] Target Group mostra targets saudáveis
- [ ] API Gateway responde corretamente
- [ ] Logs do Ingress Controller não mostram erros

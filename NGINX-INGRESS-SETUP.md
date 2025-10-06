# 🚀 Deploy NGINX Ingress Controller no EKS via GitHub Actions

## 📖 Resumo

Este guia explica como o **NGINX Ingress Controller** é instalado automaticamente no EKS através do GitHub Actions e como ele se conecta ao **API Gateway** via **NLB (Network Load Balancer)**.

## 🏗️ Arquitetura de Integração

```
Internet
   ↓
API Gateway (público)
   ↓
VPC Link (privado)
   ↓
NLB - Target Group (Terraform)
   ↓
NGINX Ingress Controller (K8s/Helm)
   ↓
Kubernetes Services
   ↓
Pods
```

## 🎯 Como funciona no GitHub Actions?

### Workflow automático (`.github/workflows/ci-cd.yml`):

```yaml
1. Checkout do código
2. Configurar credenciais AWS
3. Conectar ao cluster EKS
4. Instalar Helm
5. ✨ Instalar NGINX Ingress Controller ✨  ← NOVO!
6. Aplicar manifestos K8s
7. Atualizar secrets
```

### O que o script `setup-ingress-eks.sh` faz?

```bash
1. Adiciona repositório Helm do NGINX Ingress
2. Instala o NGINX Ingress Controller com configurações para AWS:
   - Service tipo LoadBalancer
   - Anotação para usar NLB interno
   - Registra automaticamente no Target Group do Terraform
3. Aguarda o controller ficar pronto
4. Exibe status e endereço do LoadBalancer
```

## 📋 Configuração necessária

### 1️⃣ No Terraform (já feito):

Execute primeiro o Terraform para criar a infraestrutura:

```bash
cd techfood-terraform/src
terraform init
terraform apply
```

**Pegue estes outputs:**
```bash
# Copie este ARN - você vai precisar!
terraform output nlb_target_group_arn

# Também úteis:
terraform output api_gateway_url
terraform output rds_endpoint
```

### 2️⃣ No GitHub Actions:

Adicione estes **Secrets** no repositório `techfood-k8s`:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Descrição | Como obter |
|------------|-----------|------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | AWS Academy → AWS Details |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | AWS Academy → AWS Details |
| `AWS_SESSION_TOKEN` | AWS Session Token | AWS Academy → AWS Details |
| `NLB_TARGET_GROUP_ARN` | ARN do Target Group | `terraform output nlb_target_group_arn` |
| `RDS_ENDPOINT` | Endpoint do RDS | `terraform output rds_endpoint` |
| `RDS_USERNAME` | Usuário do banco | Definido no Terraform |
| `RDS_PASSWORD` | Senha do banco | Definida no Terraform |
| `JWT_KEY` | Chave JWT | Gere uma chave segura |
| `MERCADO_PAGO_TOKEN` | Token MP | Painel Mercado Pago |

### 3️⃣ Fazer deploy:

```bash
# Qualquer push no repositório dispara o workflow
git add .
git commit -m "Setup NGINX Ingress integration"
git push origin main
```

O GitHub Actions irá:
- ✅ Instalar o NGINX Ingress automaticamente
- ✅ Conectar ao Target Group do Terraform
- ✅ Fazer deploy da aplicação

## 🔍 Verificar instalação

### Via GitHub Actions:

1. Acesse: **Actions** tab no GitHub
2. Clique no workflow mais recente
3. Expanda "Install NGINX Ingress Controller"
4. Verifique se mostra: `[SUCCESS] NGINX Ingress Controller installed successfully!`

### Via linha de comando:

```bash
# Conectar no cluster
aws eks update-kubeconfig --name techfood-eks --region us-east-1

# Verificar pods do Ingress
kubectl get pods -n ingress-nginx

# Verificar service do Ingress
kubectl get svc -n ingress-nginx

# Ver o LoadBalancer criado
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Verificar targets no Target Group (via AWS CLI)
aws elbv2 describe-target-health \
  --target-group-arn <seu-target-group-arn>
```

## 🧪 Testar a integração

### 1. Via API Gateway (rota pública):

```bash
# Pegar URL do API Gateway
GATEWAY_URL=$(cd ../techfood-terraform/src && terraform output -raw api_gateway_url)

# Health check
curl $GATEWAY_URL/api/health

# Listar categorias
curl $GATEWAY_URL/api/categories
```

### 2. Diretamente no Ingress (dentro do cluster):

```bash
# Port-forward
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80

# Testar
curl http://localhost:8080/api/health
```

## 🐛 Troubleshooting

### Problema: NGINX Ingress não está se registrando no Target Group

**Verificar:**
```bash
# 1. Secret NLB_TARGET_GROUP_ARN está configurado?
echo ${{ secrets.NLB_TARGET_GROUP_ARN }}  # No workflow

# 2. Service tem a annotation correta?
kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml | grep target-group

# 3. Reinstalar com o ARN correto
export TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:..."
./setup-ingress-eks.sh
```

### Problema: Target Group mostra "unhealthy"

**Verificar:**
```bash
# 1. Pods do Ingress estão rodando?
kubectl get pods -n ingress-nginx

# 2. Health check está configurado corretamente?
aws elbv2 describe-target-health --target-group-arn <arn>

# 3. Security Groups permitem tráfego?
# O Target Group usa porta 80, protocolo HTTP
# Path: /health (padrão do NGINX Ingress)
```

### Problema: API Gateway retorna 503

**Verificar:**
```bash
# 1. VPC Link está ativo?
aws apigateway get-vpc-link --vpc-link-id <id>

# 2. NLB está funcionando?
aws elbv2 describe-load-balancers --names techfood-nlb

# 3. Ingress está roteando corretamente?
kubectl describe ingress techfood-ingress -n techfood

# 4. Ver logs do Ingress Controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=100
```

## 📊 Monitoramento

### Logs do NGINX Ingress Controller:
```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --follow
```

### Métricas Prometheus:
```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 10254:10254
curl http://localhost:10254/metrics
```

### CloudWatch (via Console AWS):
- API Gateway → Métricas → Latência, 4xx, 5xx
- EC2 → Load Balancers → techfood-nlb → Monitoring
- EKS → Container Insights (se habilitado)

## 🔄 Atualizar ou Reinstalar

### Atualizar NGINX Ingress:
```bash
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --reuse-values
```

### Reinstalar completamente:
```bash
# Deletar
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx

# Reinstalar via script
export TARGET_GROUP_ARN="..."
./setup-ingress-eks.sh
```

## 📚 Arquivos importantes

| Arquivo | Descrição |
|---------|-----------|
| `.github/workflows/ci-cd.yml` | Workflow que instala NGINX + deploy |
| `setup-ingress-eks.sh` | Script de instalação para EKS |
| `setup-ingress-eks.bat` | Script de instalação para Windows |
| `setup-ingress.sh` | Script para Minikube (desenvolvimento) |
| `INTEGRATION-GUIDE.md` | Guia completo de integração |
| `src/base/techfood-ingress.yaml` | Regras de roteamento do Ingress |

## 🎓 Para saber mais

- [Guia completo de integração](./INTEGRATION-GUIDE.md)
- [NGINX Ingress Controller Docs](https://kubernetes.github.io/ingress-nginx/)
- [AWS VPC Link](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-private-integration.html)
- [EKS Load Balancing](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html)

---

## ✅ Checklist de deploy

Antes de fazer o deploy, confirme:

- [ ] Terraform aplicado com sucesso
- [ ] `terraform output nlb_target_group_arn` copiado
- [ ] Todos os Secrets configurados no GitHub
- [ ] Credenciais AWS válidas (AWS Academy renova a cada 4h!)
- [ ] Workflow `.github/workflows/ci-cd.yml` atualizado
- [ ] Scripts têm permissão de execução (`chmod +x *.sh`)

Pronto para deploy? **Faça um push e acompanhe no GitHub Actions!** 🚀

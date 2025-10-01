# 🎯 RESUMO: NGINX Ingress Controller no GitHub Actions

## ✅ O QUE FOI FEITO

### 1. Scripts de instalação criados:
- ✅ `setup-ingress-eks.sh` (Linux/Mac/GitHub Actions)
- ✅ `setup-ingress-eks.bat` (Windows)

### 2. Workflow GitHub Actions atualizado:
- ✅ `.github/workflows/ci-cd.yml`
- ✅ Agora instala automaticamente o NGINX Ingress Controller

### 3. Documentação completa:
- ✅ `INTEGRATION-GUIDE.md` - Guia técnico completo
- ✅ `NGINX-INGRESS-SETUP.md` - Guia de setup para GitHub Actions

### 4. Terraform atualizado:
- ✅ Adicionado output `nlb_target_group_arn`

---

## 🎨 ARQUITETURA FINAL

```
                    Internet
                       │
                       ▼
          ┌────────────────────────┐
          │   API Gateway          │ ← Criado pelo Terraform
          │   (REST API - Público) │
          └───────────┬────────────┘
                      │
                      │ VPC Link (Privado)
                      ▼
          ┌────────────────────────┐
          │  Network Load Balancer │ ← Criado pelo Terraform
          │  (NLB - Interno)       │
          │  Target Group: 80/TCP  │
          └───────────┬────────────┘
                      │
                      │ Targets auto-registrados
                      ▼
          ┌────────────────────────┐
          │  NGINX Ingress         │ ← Instalado pelo GitHub Actions
          │  Controller            │    via Helm + Script
          │  (Service LoadBalancer)│
          └───────────┬────────────┘
                      │
                      │ Ingress Rules
                      ▼
          ┌────────────────────────┐
          │  Kubernetes Services   │ ← Manifestos K8s
          │  (techfood-api-svc)    │
          └───────────┬────────────┘
                      │
                      ▼
          ┌────────────────────────┐
          │  Pods                  │
          │  (techfood-api)        │
          └────────────────────────┘
```

---

## 🚀 COMO USAR - PASSO A PASSO

### PASSO 1: Aplicar Terraform

```powershell
cd c:\Users\lc\Desktop\FIAP\tech-challenge\techfood-terraform\src

# Aplicar
terraform init
terraform apply

# IMPORTANTE: Copie este valor!
terraform output nlb_target_group_arn
```

**Exemplo de output:**
```
arn:aws:elasticloadbalancing:us-east-1:123456789:targetgroup/techfood-tg/abc123
```

---

### PASSO 2: Configurar Secrets no GitHub

No repo **techfood-k8s**, vá em:
**Settings → Secrets and variables → Actions → New repository secret**

Adicione estes secrets:

```
AWS_ACCESS_KEY_ID          = <da AWS Academy>
AWS_SECRET_ACCESS_KEY      = <da AWS Academy>
AWS_SESSION_TOKEN          = <da AWS Academy>
NLB_TARGET_GROUP_ARN       = <ARN copiado do terraform output>
RDS_ENDPOINT               = <terraform output rds_endpoint>
RDS_USERNAME               = admin
RDS_PASSWORD               = <sua senha do RDS>
JWT_KEY                    = <gere uma chave segura>
MERCADO_PAGO_TOKEN         = <token do Mercado Pago>
```

---

### PASSO 3: Fazer Push

```bash
cd c:\Users\lc\Desktop\FIAP\tech-challenge\techfood-k8s

git add .
git commit -m "Setup NGINX Ingress with GitHub Actions"
git push origin main
```

**O GitHub Actions fará automaticamente:**
1. ✅ Conectar no EKS
2. ✅ Instalar Helm
3. ✅ Instalar NGINX Ingress Controller
4. ✅ Registrar no Target Group do NLB
5. ✅ Aplicar manifestos K8s
6. ✅ Atualizar secrets

---

### PASSO 4: Verificar

#### Via GitHub:
1. Acesse a aba **Actions**
2. Clique no workflow mais recente
3. Veja os logs de cada step

#### Via terminal:
```powershell
# Conectar no cluster
aws eks update-kubeconfig --name techfood-eks --region us-east-1

# Verificar NGINX Ingress
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Verificar aplicação
kubectl get pods -n techfood
kubectl get ingress -n techfood
```

---

### PASSO 5: Testar

#### Via API Gateway (público):
```powershell
# Pegar URL do API Gateway
cd ..\techfood-terraform\src
$GATEWAY_URL = terraform output -raw api_gateway_url

# Testar
curl "$GATEWAY_URL/api/health"
curl "$GATEWAY_URL/api/categories"
```

#### Via kubectl port-forward:
```powershell
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80

# Em outro terminal
curl http://localhost:8080/api/health
```

---

## 🔍 COMO FUNCIONA A CONEXÃO?

### 1. Terraform cria:
```
API Gateway → VPC Link → NLB (com Target Group vazio)
```

### 2. GitHub Actions instala NGINX Ingress:
```bash
helm install ingress-nginx ... \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-target-group-arn"="ARN_DO_TG"
```

### 3. Kubernetes cria Service LoadBalancer:
```
Service (LoadBalancer) → AWS cria NLB interno → Registra IPs dos nodes no Target Group
```

### 4. Conexão estabelecida:
```
API Gateway → VPC Link → NLB (Terraform) → Target Group (com IPs dos nodes)
                                              ↓
                                    NGINX Ingress (recebe no NodePort)
                                              ↓
                                        Roteia via Ingress rules
                                              ↓
                                        Services → Pods
```

---

## 📊 MONITORAMENTO

### Logs do NGINX Ingress:
```powershell
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=100 --follow
```

### Status do Target Group:
```powershell
aws elbv2 describe-target-health --target-group-arn <arn>
```

### Métricas do API Gateway:
- Console AWS → API Gateway → seu-api → Monitoring

---

## ❓ FAQ

### P: Preciso instalar manualmente o NGINX Ingress?
**R:** Não! O GitHub Actions instala automaticamente quando você faz push.

### P: O que acontece se o Target Group ARN estiver errado?
**R:** O NGINX Ingress será instalado, mas não se registrará no Target Group. Você verá erro 503 no API Gateway.

### P: Posso testar localmente antes do deploy?
**R:** Sim, use `setup-ingress.sh` para Minikube ou `setup-ingress-eks.bat` para rodar manualmente.

### P: Como sei se está funcionando?
**R:** 
1. Veja logs do GitHub Actions (deve mostrar SUCCESS)
2. `kubectl get pods -n ingress-nginx` deve mostrar pods Running
3. API Gateway deve responder com 200 OK
4. Target Group deve mostrar targets "healthy"

### P: E se as credenciais da AWS Academy expirarem?
**R:** Atualize os secrets no GitHub (elas expiram a cada 4 horas no AWS Academy).

---

## 📚 ARQUIVOS IMPORTANTES

| Localização | Arquivo | O que faz |
|-------------|---------|-----------|
| **techfood-k8s/** | `setup-ingress-eks.sh` | Instala NGINX no EKS |
| **techfood-k8s/** | `.github/workflows/ci-cd.yml` | Workflow que roda o script |
| **techfood-k8s/** | `INTEGRATION-GUIDE.md` | Guia técnico completo |
| **techfood-k8s/** | `NGINX-INGRESS-SETUP.md` | Guia de setup GitHub Actions |
| **techfood-terraform/** | `src/vpc-link.tf` | Define NLB + Target Group |
| **techfood-terraform/** | `src/api-gateway.tf` | Define API Gateway |
| **techfood-terraform/** | `src/output.tf` | Exporta Target Group ARN |

---

## ✅ CHECKLIST FINAL

Antes de fazer deploy:

- [ ] Terraform aplicado com sucesso
- [ ] `nlb_target_group_arn` copiado
- [ ] Secrets configurados no GitHub (repo techfood-k8s)
- [ ] Credenciais AWS válidas
- [ ] Push feito no repo techfood-k8s
- [ ] GitHub Actions executando sem erros
- [ ] Pods do NGINX Ingress rodando
- [ ] API Gateway respondendo com 200 OK

---

## 🎉 PRONTO!

Agora você tem:
- ✅ Infraestrutura no Terraform
- ✅ NGINX Ingress instalado automaticamente
- ✅ Integração API Gateway → NLB → Ingress
- ✅ Deploy automatizado via GitHub Actions

**Qualquer dúvida, consulte `INTEGRATION-GUIDE.md` para detalhes técnicos!**

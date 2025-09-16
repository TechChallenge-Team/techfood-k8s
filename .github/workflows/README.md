# 🚀 GitHub Actions Workflows - TechFood Kubernetes

Este diretório contém os workflows do GitHub Actions para CI/CD da aplicação TechFood no Kubernetes.

## 📋 Workflows Disponíveis

### 1. `ci-cd.yml` - Pipeline Principal de CI/CD
**Triggers:**
- Push para `main`, `develop`, `feature/*`
- Pull requests para `main`, `develop`
- Execução manual

**Funcionalidades:**
- ✅ Validação de manifestos Kubernetes
- 🛡️ Scan de segurança com Trivy
- 🐳 Build e push de imagens Docker
- 🚀 Deploy automático para Development e Production
- 🧹 Limpeza de imagens antigas
- 📢 Notificações Slack

### 2. `pr-validation.yml` - Validação de Pull Requests
**Triggers:**
- Pull requests com mudanças em `src/`, workflows ou scripts

**Funcionalidades:**
- ✅ Validação de sintaxe YAML
- 🔍 Teste de build do Kustomize
- 🏷️ Validação de labels obrigatórias
- 🔒 Verificações básicas de segurança
- 📊 Análise de recursos
- 📖 Verificação de documentação

### 3. `manual-deploy.yml` - Deploy Manual
**Triggers:**
- Execução manual com parâmetros personalizáveis

**Funcionalidades:**
- 🎯 Deploy direcionado por ambiente
- 🏷️ Seleção de tag de imagem customizada
- 📦 Deploy seletivo de componentes
- 🧪 Health checks opcionais
- 🔄 Opções de rollback automático

## ⚙️ Configuração Necessária

### 1. Secrets do GitHub
Configure os seguintes secrets no repositório:

```bash
# Kubeconfig files (base64 encoded)
KUBECONFIG_DEVELOPMENT    # Kubeconfig para ambiente de desenvolvimento
KUBECONFIG_STAGING        # Kubeconfig para ambiente de staging (opcional)
KUBECONFIG_PRODUCTION     # Kubeconfig para ambiente de produção

# Notificações (opcional)
SLACK_WEBHOOK_URL         # URL do webhook do Slack para notificações
```

### 2. Environments do GitHub
Configure os seguintes environments com proteções adequadas:

- **development** - Sem proteções especiais
- **staging** - Revisão opcional
- **production** - Revisão obrigatória, branch `main` apenas

### 3. Configuração dos Kubeconfigs

Para cada ambiente, gere o kubeconfig e codifique em base64:

```bash
# Exemplo para desenvolvimento
kubectl config view --flatten --minify > kubeconfig-dev
cat kubeconfig-dev | base64 -w 0

# Adicione o resultado como secret KUBECONFIG_DEVELOPMENT
```

### 4. Container Registry
Os workflows usam o GitHub Container Registry (ghcr.io):

- As imagens são automaticamente taggeadas
- Permissões são gerenciadas via `GITHUB_TOKEN`
- Cleanup automático mantém apenas as 10 versões mais recentes

## 🏗️ Estrutura de Imagens

As seguintes imagens Docker são construídas:

| Componente | Dockerfile | Contexto | Registro |
|------------|------------|----------|----------|
| API | `src/TechFood.Api/Dockerfile` | `.` | `ghcr.io/{owner}/techfood-api` |
| Admin | `apps/admin/Dockerfile` | `.` | `ghcr.io/{owner}/techfood-admin` |
| Self-Order | `apps/self-order/Dockerfile` | `.` | `ghcr.io/{owner}/techfood-self-order` |
| Monitor | `apps/monitor/Dockerfile` | `.` | `ghcr.io/{owner}/techfood-monitor` |
| Nginx | `nginx/Dockerfile` | `nginx/` | `ghcr.io/{owner}/techfood-nginx` |

## 🎯 Estratégia de Tagging

### Tags Automáticas
- `latest` - Branch main (produção)
- `develop` - Branch develop
- `feature-xyz` - Branches feature/xyz
- `pr-123` - Pull requests
- `main-{sha}` - Commit específico

### Tags Manuais
No deploy manual, você pode especificar:
- Tags customizadas (`v1.2.3`)
- SHA específico
- Qualquer tag existente

## 🌍 Ambientes

### Development
- **Deploy**: Automático no push para `develop`
- **Acesso**: Port-forward `kubectl port-forward service/techfood-nginx-service 30000:30000 -n techfood`
- **Recursos**: Configuração reduzida para economizar recursos

### Production
- **Deploy**: Automático no push para `main` (com aprovação)
- **Acesso**: Via Load Balancer ou Ingress configurado
- **Recursos**: Configuração completa com HPA

## 🚀 Como Usar

### Deploy Automático
1. Faça push para `develop` → Deploy automático para Development
2. Faça merge para `main` → Deploy automático para Production (com aprovação)

### Deploy Manual
1. Vá para Actions → "Manual Deployment"
2. Selecione:
   - **Environment**: `development`, `staging`, ou `production`
   - **Image Tag**: Deixe vazio para usar padrão ou especifique
   - **Components**: `all` ou específicos (`api,nginx`)
   - **Options**: Health checks, force restart

### Exemplo de Deploy Específico
```
Environment: production
Image Tag: v1.2.3
Components: api,nginx
Skip Health Check: false
Force Restart: true
```

## 🔍 Monitoramento

### Logs dos Workflows
- Acesse Actions no GitHub
- Selecione o workflow desejado
- Visualize logs detalhados por job

### Status do Deploy
```bash
# Ver status dos pods
kubectl get pods -n techfood -o wide

# Ver status do HPA
kubectl get hpa -n techfood

# Ver eventos recentes
kubectl get events -n techfood --sort-by='.metadata.creationTimestamp'
```

### Health Checks
```bash
# Verificar API health
kubectl exec -n techfood deployment/techfood-api -- curl -f http://localhost:8080/health

# Port forward para acesso local
kubectl port-forward service/techfood-nginx-service 30000:30000 -n techfood
```

## 🔄 Rollback

### Rollback Automático
Em caso de falha no deploy, o workflow `manual-deploy.yml` mostra opções de rollback.

### Rollback Manual
```bash
# Ver histórico de deploy
kubectl rollout history deployment/techfood-api -n techfood

# Rollback para versão anterior
kubectl rollout undo deployment/techfood-api -n techfood

# Rollback para versão específica
kubectl rollout undo deployment/techfood-api --to-revision=2 -n techfood
```

## 🛡️ Segurança

### Verificações Automáticas
- Scan de vulnerabilidades com Trivy
- Verificação de secrets vazados
- Validação de configuração de segurança

### Boas Práticas Implementadas
- ✅ Uso de environments com aprovações
- ✅ Least privilege para tokens
- ✅ Secrets separados por ambiente
- ✅ Imagens multi-arch (amd64/arm64)
- ✅ Cache de build para performance

## 📞 Suporte

### Problemas Comuns

**❌ Erro "kubeconfig not found"**
```
Solução: Configure o secret KUBECONFIG_* para o ambiente
```

**❌ Erro "image not found"**
```
Solução: Verifique se o build das imagens foi concluído com sucesso
```

**❌ Deploy timeout**
```
Solução: Verifique recursos do cluster e logs dos pods
```

### Contato
- 🐛 Issues: Use o sistema de Issues do GitHub
- 💬 Discussões: Use GitHub Discussions
- 🚨 Emergências: Contate o time DevOps

## 🔗 Links Úteis

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Guide](https://kustomize.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Multi-platform Builds](https://docs.docker.com/build/building/multi-platform/)

---

📝 **Última atualização**: Esta documentação é mantida automaticamente pelos workflows.

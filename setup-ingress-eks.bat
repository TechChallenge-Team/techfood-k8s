@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Installing NGINX Ingress Controller (EKS)
echo ========================================

REM Adicionar repositório Helm do NGINX Ingress
echo [INFO] Adding NGINX Ingress Helm repository...
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

REM Verificar se TARGET_GROUP_ARN está definido
if "%TARGET_GROUP_ARN%"=="" (
  echo [WARNING] TARGET_GROUP_ARN not set. Installing without target group annotation.
  echo [WARNING] You will need to register the LoadBalancer manually to the NLB.
)

echo.
echo [INFO] Installing NGINX Ingress Controller...

REM Instalar NGINX Ingress Controller
if "%TARGET_GROUP_ARN%"=="" (
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx ^
    --namespace ingress-nginx ^
    --create-namespace ^
    --set controller.service.type=LoadBalancer ^
    --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" ^
    --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-internal"="true" ^
    --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internal" ^
    --set controller.ingressClassResource.default=true ^
    --set controller.metrics.enabled=true ^
    --set controller.podAnnotations."prometheus\.io/scrape"="true" ^
    --set controller.podAnnotations."prometheus\.io/port"="10254" ^
    --wait --timeout=5m
) else (
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx ^
    --namespace ingress-nginx ^
    --create-namespace ^
    --set controller.service.type=LoadBalancer ^
    --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" ^
    --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-internal"="true" ^
    --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internal" ^
    --set "controller.service.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-target-group-arn"="%TARGET_GROUP_ARN%" ^
    --set controller.ingressClassResource.default=true ^
    --set controller.metrics.enabled=true ^
    --set controller.podAnnotations."prometheus\.io/scrape"="true" ^
    --set controller.podAnnotations."prometheus\.io/port"="10254" ^
    --wait --timeout=5m
)

echo.
echo [INFO] Waiting for Ingress Controller to be ready...
kubectl wait --namespace ingress-nginx ^
  --for=condition=ready pod ^
  --selector=app.kubernetes.io/component=controller ^
  --timeout=300s

echo.
echo [INFO] Checking Ingress Controller status...
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

echo.
echo [SUCCESS] NGINX Ingress Controller installed successfully!
echo.
echo Next steps:
echo 1. The LoadBalancer service will create an internal NLB
echo 2. Register this NLB with the Terraform-created Target Group
echo 3. Deploy your ingress resources
echo.

REM Aguardar e obter o endereço do LoadBalancer
echo [INFO] Waiting for LoadBalancer address...
timeout /t 10 /nobreak > nul
for /f "tokens=*" %%i in ('kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath^="{.status.loadBalancer.ingress[0].hostname}"') do set LB_HOSTNAME=%%i
if not "%LB_HOSTNAME%"=="" (
  echo LoadBalancer Hostname: %LB_HOSTNAME%
) else (
  echo [WARNING] LoadBalancer address not ready yet. Check with: kubectl get svc -n ingress-nginx
)

endlocal

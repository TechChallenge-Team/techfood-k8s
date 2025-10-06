@echo off
echo ========================================
echo    Installing NGINX Ingress Controller
echo ========================================

REM Habilitar o addon do Ingress no Minikube
echo [INFO] Enabling Ingress addon on Minikube...
minikube addons enable ingress

if errorlevel 1 (
    echo [ERROR] Failed to enable Ingress addon
    exit /b 1
)

echo.
echo [INFO] Waiting for Ingress Controller to be ready...
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s

if errorlevel 1 (
    echo [ERROR] Ingress Controller failed to start
    exit /b 1
)

echo.
echo [INFO] Checking Ingress Controller status...
kubectl get pods -n ingress-nginx

echo.
echo [SUCCESS] NGINX Ingress Controller installed successfully!
echo.
echo To access your application:
echo 1. Add 'techfood.local' to your hosts file pointing to Minikube IP
echo 2. Get Minikube IP with: minikube ip
echo 3. Or access directly via Minikube IP without hostname
echo.
echo Example hosts entry (add to C:\Windows\System32\drivers\etc\hosts):
minikube ip
echo ^<MINIKUBE_IP^> techfood.local
echo.

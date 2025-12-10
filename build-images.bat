@echo off
setlocal enabledelayedexpansion
REM Script para fazer build das imagens Docker no Minikube (microservices + frontends)

echo 🐳 Fazendo build das imagens Docker para o Minikube...

REM Configura o ambiente Docker para usar o Minikube
echo 🔧 Configurando ambiente Docker do Minikube...
FOR /f "tokens=*" %%i IN ('minikube docker-env --shell cmd') DO %%i

REM Lista de imagens: tag|dockerfile|context
set IMAGES=
set IMAGES=!IMAGES! "grupotechchallenge/techfood-order-api:latest|services/order-api/Dockerfile|services/order-api"
set IMAGES=!IMAGES! "grupotechchallenge/techfood-order-worker:latest|services/order-worker/Dockerfile|services/order-worker"
set IMAGES=!IMAGES! "grupotechchallenge/techfood-payment-api:latest|services/payment-api/Dockerfile|services/payment-api"
set IMAGES=!IMAGES! "grupotechchallenge/techfood-payment-worker:latest|services/payment-worker/Dockerfile|services/payment-worker"
set IMAGES=!IMAGES! "grupotechchallenge/techfood-backoffice-api:latest|services/backoffice-api/Dockerfile|services/backoffice-api"
set IMAGES=!IMAGES! "grupotechchallenge/techfood-kitchen-api:latest|services/kitchen-api/Dockerfile|services/kitchen-api"
set IMAGES=!IMAGES! "grupotechchallenge/techfood-kitchen-worker:latest|services/kitchen-worker/Dockerfile|services/kitchen-worker"

REM Frontends e nginx
set IMAGES=!IMAGES! "techfood.admin:latest|apps/admin/Dockerfile|apps/admin"
set IMAGES=!IMAGES! "techfood.self-order:latest|apps/self-order/Dockerfile|apps/self-order"
set IMAGES=!IMAGES! "techfood.monitor:latest|apps/monitor/Dockerfile|apps/monitor"
set IMAGES=!IMAGES! "techfood.nginx:latest|nginx/Dockerfile|nginx"

for %%I in (!IMAGES!) do (
    for /f "tokens=1,2,3 delims=|" %%A in (%%~I) do (
        set "TAG=%%~A"
        set "DF=%%~B"
        set "CTX=%%~C"
        if not exist "!DF!" (
            echo ⚠️  Dockerfile nao encontrado para !TAG! em !DF!, pulando...
        ) else (
            echo 📦 Building !TAG! ...
            docker build -t !TAG! -f "!DF!" "!CTX!"
            if errorlevel 1 (
                echo ❌ Erro ao fazer build de !TAG!
                exit /b 1
            )
        )
    )
)

echo ✅ Todas as imagens foram processadas.
echo.
echo Para fazer o deploy, execute:
echo kubectl apply -k src/overlays/development/
echo.
echo Ou use o script de deploy:
echo deploy.bat
pause

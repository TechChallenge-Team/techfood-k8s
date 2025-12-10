@echo off
REM Script para fazer deploy da aplicação TechFood no Kubernetes (Windows)

echo 🚀 Iniciando deploy do TechFood no Kubernetes...

REM Verifica se o kubectl está disponível
kubectl version --client >nul 2>&1
if errorlevel 1 (
    echo ❌ kubectl não está instalado. Por favor, instale o kubectl.
    pause
    exit /b 1
)

REM Verifica se o Minikube está rodando
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    echo ❌ Cluster Kubernetes não está disponível. Verifique se o Minikube está rodando.
    echo Para iniciar o Minikube, execute: minikube start
    pause
    exit /b 1
)

REM Habilita Addons necessários
echo 📊 Habilitando Addons necessários...
minikube addons enable metrics-server
minikube addons enable ingress

REM Aguarda alguns segundos para o metrics server estar pronto
timeout /t 10 /nobreak >nul

REM Aplica os manifestos usando Kustomize
echo 📦 Aplicando manifetos do Kubernetes...
kubectl apply -k src/overlays/development/

REM Aguarda os pods estarem prontos
echo ⏳ Aguardando pods ficarem prontos...
kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=techfood-system -n techfood --timeout=300s

REM Mostra o status dos recursos
echo 📋 Status dos recursos:
kubectl get all -n techfood

REM Mostra informações sobre como acessar a aplicação
echo.
echo 🎉 Deploy concluído com sucesso!
echo.
echo Para acessar a aplicação:
echo.
echo 🔧 OPÇÃO 1 - Port Forward (Recomendado para Windows):
echo    Execute: port-forward.bat
echo    Depois acesse: http://localhost:30000
echo.
echo 🔧 OPÇÃO 2 - Minikube Service (Tunnel):
echo    Execute: start-tunnel.bat
echo    O navegador abrirá automaticamente com a URL correta
echo.
echo 🔧 OPÇÃO 3 - Manual:
echo    Execute: minikube service techfood-nginx-service -n techfood
echo    Mantenha o terminal aberto e use a URL fornecida
echo.
echo ⚠️  IMPORTANTE: No Windows com Docker driver, a porta 30000 não funciona diretamente!
echo Use uma das opções acima para criar um tunnel ou port-forward.
echo.
echo Após estabelecer a conexão, os endpoints estarão disponíveis em:
echo - Admin: http://localhost:30000/admin
echo - Self-Order: http://localhost:30000/self-order
echo - Monitor: http://localhost:30000/monitor
echo - Order API: http://localhost:30000/api/order
echo - Payment API: http://localhost:30000/api/payment
echo - Backoffice API: http://localhost:30000/api/backoffice
echo - Kitchen API: http://localhost:30000/api/kitchen
echo.
echo Para monitorar os recursos:
echo kubectl get pods -n techfood -w
echo kubectl get hpa -n techfood -w
echo.
pause

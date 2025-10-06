@echo off
REM Script de validação do deployment Kubernetes

echo 🔍 Validando deployment do TechFood no Kubernetes...

set ERRORS=0

REM Verificar se o kubectl está funcionando
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    echo ❌ Cluster Kubernetes não está disponível
    exit /b 1
)

echo ✅ Cluster Kubernetes está disponível

REM Verificar se o namespace existe
kubectl get namespace techfood >nul 2>&1
if errorlevel 1 (
    echo ❌ Namespace 'techfood' não encontrado
    set /a ERRORS+=1
) else (
    echo ✅ Namespace 'techfood' existe
)

REM Verificar pods
echo.
echo ℹ️ Verificando status dos pods...
for /f %%i in ('kubectl get pods -n techfood --no-headers 2^>nul ^| find /c /v ""') do set PODS=%%i

if %PODS% EQU 0 (
    echo ❌ Nenhum pod encontrado no namespace techfood
    set /a ERRORS+=1
) else (
    echo ✅ Encontrados %PODS% pods no namespace techfood
    
    REM Verificar se todos os pods estão rodando
    kubectl get pods -n techfood --no-headers 2>nul | find /v "Running" >nul
    if not errorlevel 1 (
        echo ⚠️ Alguns pods não estão rodando
        kubectl get pods -n techfood | find /v "Running"
    ) else (
        echo ✅ Todos os pods estão rodando
    )
)

REM Verificar services
echo.
echo ℹ️ Verificando services...
for /f %%i in ('kubectl get services -n techfood --no-headers 2^>nul ^| find /c /v ""') do set SERVICES=%%i

if %SERVICES% EQU 0 (
    echo ❌ Nenhum service encontrado
    set /a ERRORS+=1
) else (
    echo ✅ Encontrados %SERVICES% services
)

REM Verificar deployments
echo.
echo ℹ️ Verificando deployments...
for /f %%i in ('kubectl get deployments -n techfood --no-headers 2^>nul ^| find /c /v ""') do set DEPLOYMENTS=%%i

if %DEPLOYMENTS% EQU 0 (
    echo ❌ Nenhum deployment encontrado
    set /a ERRORS+=1
) else (
    echo ✅ Encontrados %DEPLOYMENTS% deployments
)

REM Verificar HPA
echo.
echo ℹ️ Verificando HPA...
for /f %%i in ('kubectl get hpa -n techfood --no-headers 2^>nul ^| find /c /v ""') do set HPAS=%%i

if %HPAS% EQU 0 (
    echo ⚠️ Nenhum HPA encontrado
) else (
    echo ✅ Encontrados %HPAS% HPAs
)

REM Verificar PVCs
echo.
echo ℹ️ Verificando PVCs...
for /f %%i in ('kubectl get pvc -n techfood --no-headers 2^>nul ^| find /c /v ""') do set PVCS=%%i

if %PVCS% EQU 0 (
    echo ⚠️ Nenhum PVC encontrado
) else (
    echo ✅ Encontrados %PVCS% PVCs
)

REM Resumo final
echo.
echo =================== RESUMO ===================
if %ERRORS% EQU 0 (
    echo ✅ Validação concluída com sucesso!
    echo.
    echo 🌐 Para acessar a aplicação:
    echo    minikube service techfood-nginx-service -n techfood
    echo.
    echo 📊 Para monitorar:
    echo    kubectl get pods -n techfood -w
    echo    kubectl get hpa -n techfood -w
) else (
    echo ❌ Validação falhou com %ERRORS% erros
    echo.
    echo 🔍 Para diagnosticar:
    echo    kubectl get all -n techfood
    echo    kubectl describe pod ^<pod-name^> -n techfood
    echo    kubectl logs ^<pod-name^> -n techfood
)
echo ==============================================
pause

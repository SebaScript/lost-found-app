# Script para configurar CORS en Firebase Storage
# Ejecutar DESPUÉS de instalar Google Cloud SDK

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "      CONFIGURACIÓN DE CORS PARA FIREBASE STORAGE         " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Verificar instalación
Write-Host "[1/5] Verificando instalación de gcloud..." -ForegroundColor Yellow
try {
    $version = gcloud version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "gcloud no está instalado"
    }
    Write-Host "✓ Google Cloud SDK instalado correctamente" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ ERROR: Google Cloud SDK no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor:" -ForegroundColor Yellow
    Write-Host "1. Instala Google Cloud SDK desde:" -ForegroundColor White
    Write-Host "   https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -ForegroundColor Cyan
    Write-Host "2. REINICIA esta terminal" -ForegroundColor White
    Write-Host "3. Ejecuta este script nuevamente" -ForegroundColor White
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Paso 2: Autenticar
Write-Host "[2/5] Autenticando con Google Cloud..." -ForegroundColor Yellow
Write-Host "Se abrirá tu navegador para iniciar sesión" -ForegroundColor White
Write-Host ""
gcloud auth login
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ ERROR: Fallo la autenticación" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}
Write-Host "✓ Autenticación exitosa" -ForegroundColor Green
Write-Host ""

# Paso 3: Configurar proyecto
Write-Host "[3/5] Configurando proyecto..." -ForegroundColor Yellow
gcloud config set project lost-found-22796
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ ERROR: No se pudo configurar el proyecto" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}
Write-Host "✓ Proyecto configurado: lost-found-22796" -ForegroundColor Green
Write-Host ""

# Paso 4: Aplicar CORS
Write-Host "[4/5] Aplicando configuración CORS..." -ForegroundColor Yellow
if (Test-Path "cors.json") {
    gsutil cors set cors.json gs://lost-found-22796.firebasestorage.app
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ ERROR: No se pudo aplicar la configuración CORS" -ForegroundColor Red
        Read-Host "Presiona Enter para salir"
        exit 1
    }
    Write-Host "✓ Configuración CORS aplicada exitosamente" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "✗ ERROR: No se encontró el archivo cors.json" -ForegroundColor Red
    Write-Host "Asegúrate de ejecutar este script desde el directorio del proyecto" -ForegroundColor Yellow
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Paso 5: Verificar
Write-Host "[5/5] Verificando configuración..." -ForegroundColor Yellow
gsutil cors get gs://lost-found-22796.firebasestorage.app
Write-Host ""
Write-Host "✓ Configuración CORS verificada" -ForegroundColor Green
Write-Host ""

# Finalización
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "           ✓ CONFIGURACIÓN COMPLETADA CON ÉXITO           " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Recarga tu aplicación Flutter Web (Ctrl + F5)" -ForegroundColor White
Write-Host "2. Sube una imagen y verifica que se vea sin errores" -ForegroundColor White
Write-Host ""
Read-Host "Presiona Enter para salir"


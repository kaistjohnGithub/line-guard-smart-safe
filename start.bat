@echo off
echo ============================================================
echo  Line Guard Smart Safe — Start All Services
echo ============================================================

echo [1/2] Starting Docker services (Frontend + Backend + DB)...
docker compose up -d
if %errorlevel% neq 0 (echo Docker failed & pause & exit /b 1)

echo.
echo [2/2] Starting Qwen AI Service on GPU...
start "Qwen AI Service" cmd /k "micromamba run -n vila-safety python tools\qwen_service.py"

echo.
echo ============================================================
echo  Services started!
echo  Frontend : http://localhost:5173
echo  Backend  : http://localhost:8000
echo  Qwen GPU : http://localhost:8001 (loading ~60s)
echo.
echo  Wait for Qwen window to show "Model ready" before uploading
echo ============================================================
timeout /t 3 >nul
start http://localhost:5173

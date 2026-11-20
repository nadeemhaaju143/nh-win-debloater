@echo off
setlocal EnableDelayedExpansion
title NH Win Debloater v0.1 - NH Digital

:: Check Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Administrative permissions required. Requesting elevation...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

echo ======================================================================
echo   NH Win Debloater v0.1
echo   Less Bloat. Better Windows.
echo   Built by NH Digital (https://nhdigital.shop)
echo ======================================================================
echo.

if exist "src\Core\Entrypoint.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "src\Core\Entrypoint.ps1"
) else (
    echo [INFO] Initializing NH Win Debloater v0.1 workspace...
    echo [INFO] Core engine modules will load from src\Core\
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'NH Win Debloater v0.1 initialized successfully.' -ForegroundColor Green; Write-Host 'Visit https://nhdigital.shop for updates and digital tools.' -ForegroundColor Cyan"
    echo.
    pause
)

exit /b

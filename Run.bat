@echo off
setlocal EnableDelayedExpansion
title NH Win Debloater - NH Digital

:: Check Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Administrative permissions required. Requesting elevation...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\" %*' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

echo ======================================================================
echo   NH Win Debloater
echo   Less Bloat. Better Windows.
echo   Built by NH Digital (https://nhdigital.shop)
echo ======================================================================
echo.

if exist "src\Core\Entrypoint.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "src\Core\Entrypoint.ps1" %*
) else (
    echo [ERROR] src\Core\Entrypoint.ps1 not found in "%~dp0".
    echo Visit https://nhdigital.shop for releases and documentation.
    pause
)

exit /b

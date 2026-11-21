@echo off
setlocal EnableDelayedExpansion
title NH Win Debloater - NH Digital

cd /d "%~dp0"

:: Check if running in DryRun preview mode (bypasses elevation requirement)
echo %* | findstr /i "\-DryRun" >nul 2>&1
if %errorlevel% equ 0 goto :Launch

:: Check Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Administrative permissions required. Requesting elevation...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~dp0Run.bat\"\" %*' -Verb RunAs"
    exit /b
)

:Launch
if exist "%~dp0src\Core\Entrypoint.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0src\Core\Entrypoint.ps1" %*
) else (
    echo [ERROR] src\Core\Entrypoint.ps1 not found in "%~dp0".
    echo Visit https://nhdigital.shop for releases and documentation.
    pause
)

exit /b

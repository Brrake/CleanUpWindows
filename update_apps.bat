@echo off
::=====================================
:: Script diagnostica e riparazione Windows (10/11) - COMPLETO
:: Richiede privilegi amministrativi
::=====================================

:: Verifica privilegi admin
>nul 2>&1 net session
if %errorlevel% neq 0 (
    echo Richiesta privilegi amministrativi...
    goto UACPrompt
) else (
    goto gotAdmin
)

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set "params=%*"
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    cd /D "%~dp0"
::=====================================
echo.
echo =====================================
echo AGGIORNAMENTO DELLE APP DI WINDOWS
echo =====================================
echo.
winget upgrade --all --accept-package-agreements --accept-source-agreements

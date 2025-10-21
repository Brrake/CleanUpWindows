@echo off
::=====================================
:: Script diagnostica e riparazione Windows (10/11) - COMPLETO
:: Richiede privilegi amministrativi
::=====================================

:: Crea cartella logs se non esiste
if not exist "%~dp0logs" mkdir "%~dp0logs"

:: Imposta variabili per logging
set "LOGFILE=%~dp0logs\DiagnosticaWindows_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%.log"
set "LOGFILE=%LOGFILE: =0%"

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
echo DIAGNOSTICA E RIPARAZIONE WINDOWS
echo =====================================
echo.
echo Log salvato in: %LOGFILE%
echo.
call :LogMessage "=== AVVIO DIAGNOSTICA ==="

::=====================================
:: PUNTO DI RIPRISTINO
::=====================================
echo =====================================
echo [0/8] Creazione punto di ripristino...
echo =====================================
echo.
call :LogMessage "Creazione punto di ripristino"
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Pre-Diagnostica Script", 100, 7 >> "%LOGFILE%" 2>&1
if %errorlevel% neq 0 (
    echo AVVISO: Impossibile creare punto di ripristino
    call :LogMessage "AVVISO: Punto di ripristino non creato"
) else (
    echo Punto di ripristino creato con successo
    call :LogMessage "Punto di ripristino creato"
)

::=====================================
:: INFORMAZIONI SISTEMA
::=====================================
echo.
echo =====================================
echo [1/8] Raccolta informazioni sistema...
echo =====================================
echo.
call :LogMessage "Generazione SystemInfo"
systeminfo > "%~dp0logs\SystemInfo_%date:~-4,4%%date:~-7,2%%date:~-10,2%.txt"
if %errorlevel% equ 0 (
    echo Informazioni sistema salvate
    call :LogMessage "SystemInfo generato con successo"
) else (
    echo ERRORE nella generazione SystemInfo
    call :LogMessage "ERRORE: SystemInfo fallito"
)

::=====================================
:: SCANSIONE FILE DI SISTEMA (SFC)
::=====================================
echo.
echo =====================================
echo [2/8] Scansione file di sistema (SFC)...
echo =====================================
echo.
call :LogMessage "Avvio SFC /scannow"
sfc /scannow
if %errorlevel% neq 0 (
    echo AVVISO: SFC ha riscontrato problemi
    call :LogMessage "SFC completato con errori: %errorlevel%"
) else (
    echo SFC completato con successo
    call :LogMessage "SFC completato con successo"
)

::=====================================
:: SCANSIONE DISCO (CHKDSK)
::=====================================
echo.
echo =====================================
echo [3/8] Scansione disco (CHKDSK)...
echo =====================================
echo.
call :LogMessage "Avvio CHKDSK scan"
chkdsk C: /scan
echo.
set /p repair=Vuoi pianificare riparazione disco al riavvio? (y/n): 
if /i "%repair%"=="y" (
    call :LogMessage "Pianificazione CHKDSK /f /r"
    echo Pianificazione scansione completa al prossimo riavvio...
    echo y | chkdsk C: /f /r
    echo Riavvio necessario per completare la scansione
    call :LogMessage "CHKDSK /f /r pianificato"
) else (
    echo Nessuna riparazione disco pianificata
    call :LogMessage "CHKDSK /f /r non pianificato"
)

::=====================================
:: SCANSIONE INTEGRITÀ IMMAGINE (DISM)
::=====================================
echo.
echo =====================================
echo [4/8] Scansione integrità immagine (DISM)...
echo =====================================
echo.
call :LogMessage "Avvio DISM /scanhealth"
dism /online /cleanup-image /scanhealth
if %errorlevel% neq 0 (
    echo AVVISO: DISM scanhealth ha riscontrato problemi
    call :LogMessage "DISM scanhealth con errori: %errorlevel%"
) else (
    echo DISM scanhealth completato
    call :LogMessage "DISM scanhealth completato"
)

echo.
set /p choice=Vuoi tentare la riparazione con DISM? (y/n): 
if /i "%choice%"=="y" (
    echo.
    echo Pulizia componenti e riparazione immagine...
    call :LogMessage "Avvio DISM cleanup e restorehealth"
    dism /online /cleanup-image /startcomponentcleanup
    dism /online /cleanup-image /restorehealth
    if %errorlevel% neq 0 (
        echo AVVISO: DISM restorehealth ha riscontrato problemi
        call :LogMessage "DISM restorehealth con errori: %errorlevel%"
    ) else (
        echo DISM restorehealth completato con successo
        call :LogMessage "DISM restorehealth completato"
    )
) else (
    echo Nessuna riparazione DISM eseguita
    call :LogMessage "DISM restorehealth non eseguito"
)

::=====================================
:: PULIZIA FILE TEMPORANEI
::=====================================
echo.
echo =====================================
echo [5/8] Pulizia file temporanei...
echo =====================================
echo.
call :LogMessage "Pulizia file temporanei"
del /f /s /q %temp%\*.* >nul 2>&1
del /f /s /q C:\Windows\Temp\*.* >nul 2>&1
echo Pulizia temporanei completata
call :LogMessage "File temporanei puliti"

::=====================================
:: RESET WINDOWS UPDATE
::=====================================
echo.
set /p wupdate=Vuoi resettare i componenti Windows Update? (y/n): 
if /i "%wupdate%"=="y" (
    echo.
    echo =====================================
    echo [6/8] Reset componenti Windows Update...
    echo =====================================
    echo.
    call :LogMessage "Reset Windows Update"
    
    :: Ferma i servizi
    net stop wuauserv >nul 2>&1
    net stop bits >nul 2>&1
    net stop cryptsvc >nul 2>&1
    net stop msiserver >nul 2>&1
    
    :: Attendi che i servizi si fermino completamente
    timeout /t 2 /nobreak >nul
    
    :: Rinomina le cartelle (invece di eliminare)
    if exist "%systemroot%\SoftwareDistribution" (
        ren "%systemroot%\SoftwareDistribution" SoftwareDistribution.old >nul 2>&1
        if %errorlevel% equ 0 (
            echo SoftwareDistribution rinominata con successo
            call :LogMessage "SoftwareDistribution rinominata"
        ) else (
            echo AVVISO: Impossibile rinominare SoftwareDistribution
            call :LogMessage "ERRORE: SoftwareDistribution non rinominata"
        )
    )
    
    if exist "%systemroot%\System32\catroot2" (
        ren "%systemroot%\System32\catroot2" catroot2.old >nul 2>&1
        if %errorlevel% equ 0 (
            echo catroot2 rinominata con successo
            call :LogMessage "catroot2 rinominata"
        ) else (
            echo AVVISO: Impossibile rinominare catroot2
            call :LogMessage "ERRORE: catroot2 non rinominata"
        )
    )
    
    :: Riavvia i servizi
    net start wuauserv >nul 2>&1
    net start bits >nul 2>&1
    net start cryptsvc >nul 2>&1
    net start msiserver >nul 2>&1
    
    echo Componenti Windows Update resettati
    call :LogMessage "Windows Update resettato completamente"
) else (
    echo [6/8] Reset Windows Update saltato
    call :LogMessage "Reset Windows Update non eseguito"
)

::=====================================
:: CONTROLLO AGGIORNAMENTI
::=====================================
echo.
set /p checkupd=Vuoi forzare il controllo aggiornamenti? (y/n): 
if /i "%checkupd%"=="y" (
    echo.
    echo =====================================
    echo [7/8] Controllo aggiornamenti Windows...
    echo =====================================
    echo.
    call :LogMessage "Controllo aggiornamenti"
    usoclient startscan
    timeout /t 5 /nobreak >nul
    echo Scansione aggiornamenti avviata
    call :LogMessage "Aggiornamenti - scansione avviata"
) else (
    echo [7/8] Controllo aggiornamenti saltato
    call :LogMessage "Controllo aggiornamenti non eseguito"
)

::=====================================
:: PULIZIA DISCO (CLEANMGR)
::=====================================
echo.
set /p cleanup=Vuoi avviare la pulizia disco? (y/n): 
if /i "%cleanup%"=="y" (
    echo.
    echo =====================================
    echo [8/8] Avvio Pulizia Disco...
    echo =====================================
    echo.
    call :LogMessage "Avvio Cleanmgr"
    cleanmgr /sageset:101
    cleanmgr /sagerun:101
    call :LogMessage "Cleanmgr completato"
) else (
    echo [8/8] Pulizia disco saltata
    call :LogMessage "Cleanmgr non eseguito"
)

::=====================================
:: CONCLUSIONE
::=====================================
echo.
echo =====================================
echo TUTTE LE OPERAZIONI SONO CONCLUSE
echo =====================================
echo.
echo Log completo salvato in: %LOGFILE%
echo Report sistema salvato in: %~dp0SystemInfo_%date:~-4,4%%date:~-7,2%%date:~-10,2%.txt
echo.
call :LogMessage "=== DIAGNOSTICA COMPLETATA ==="

pause
exit /b

::=====================================
:: FUNZIONE DI LOGGING
::=====================================
:LogMessage
echo [%date% %time%] %~1 >> "%LOGFILE%"
goto :eof

import os
import ctypes
import subprocess
import datetime
import sys
from pathlib import Path
# Get absolute path to script directory
script_dir = Path(__file__).resolve().parent

# Utility per logging
def log_message(logfile, message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(logfile, "a", encoding="utf-8") as f:
        f.write(f"[{timestamp}] {message}\n")

# Verifica privilegi amministrativi
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

# Percorsi e variabili di log
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOGS_DIR = os.path.join(SCRIPT_DIR, "logs")
os.makedirs(LOGS_DIR, exist_ok=True)

now = datetime.datetime.now()
LOGFILE = os.path.join(LOGS_DIR, f"DiagnosticaWindows_{now.strftime('%Y%m%d_%H%M')}.log")

print("=====================================")
print("DIAGNOSTICA E RIPARAZIONE WINDOWS")
print("=====================================")
print(f"Log salvato in: {LOGFILE}\n")
log_message(LOGFILE, "=== AVVIO DIAGNOSTICA ===")

# Verifica admin
if not is_admin():
    print("Richiesta privilegi amministrativi...")
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
    sys.exit()

# Punto di ripristino
print("\n[0/8] Creazione punto di ripristino...")
log_message(LOGFILE, "Creazione punto di ripristino")
result = subprocess.run(
    'wmic.exe /Namespace:\\\\root\\default Path SystemRestore Call CreateRestorePoint "Pre-Diagnostica Script", 100, 7',
    capture_output=True, text=True, cwd=SCRIPT_DIR
)
with open(LOGFILE, "a", encoding="utf-8") as f:
    f.write(result.stdout + result.stderr)
if result.returncode == 0:
    print("Punto di ripristino creato con successo")
    log_message(LOGFILE, "Punto di ripristino creato")
else:
    print("AVVISO: Impossibile creare punto di ripristino")
    log_message(LOGFILE, "AVVISO: Punto di ripristino non creato")

# Informazioni sistema
print("\n[1/8] Raccolta informazioni sistema...")
log_message(LOGFILE, "Generazione SystemInfo")
sysinfo_file = os.path.join(LOGS_DIR, f"SystemInfo_{now.strftime('%Y%m%d')}.txt")
try:
    result = subprocess.run(['systeminfo'], capture_output=True)
    output = result.stdout.decode("utf-8", errors="replace")
    with open(sysinfo_file, "w", encoding="utf-8") as f:
        f.write(output)
    if result.returncode == 0:
        print("Informazioni sistema salvate")
        log_message(LOGFILE, "SystemInfo generato con successo")
    else:
        print("ERRORE nella generazione SystemInfo")
        log_message(LOGFILE, "ERRORE: SystemInfo fallito")
except Exception as e:
    print(f"ERRORE nella generazione SystemInfo: {e}")
    log_message(LOGFILE, f"ERRORE: SystemInfo fallito: {e}")

# SFC
print("\n[2/8] Scansione file di sistema (SFC)...")
choice_sfc = input("Vuoi scansionare i file di sistema (SFC)? (y/n): ")
if choice_sfc.strip().lower() == "y":
    log_message(LOGFILE, "Avvio SFC /scannow")
    result = subprocess.run(['sfc', '/scannow'])
    if result.returncode != 0:
        print("AVVISO: SFC ha riscontrato problemi")
        log_message(LOGFILE, f"SFC completato con errori: {result.returncode}")
    else:
        print("SFC completato con successo")
        log_message(LOGFILE, "SFC completato con successo")

# CHKDSK
print("\n[3/8] Scansione disco (CHKDSK)...")
choice_chk = input("Vuoi scansionare il disco (CHKDSK)? (y/n): ")
if choice_chk.strip().lower() == "y":
    log_message(LOGFILE, "Avvio CHKDSK scan")
    subprocess.run(['chkdsk', 'C:', '/scan'])
repair = input("Vuoi pianificare riparazione disco al riavvio? (y/n): ")
if repair.strip().lower() == "y":
    log_message(LOGFILE, "Pianificazione CHKDSK /f /r")
    print("Pianificazione scansione completa al prossimo riavvio...")
    subprocess.run('echo y | chkdsk C: /f /r', shell=True)
    print("Riavvio necessario per completare la scansione")
    log_message(LOGFILE, "CHKDSK /f /r pianificato")
else:
    print("Nessuna riparazione disco pianificata")
    log_message(LOGFILE, "CHKDSK /f /r non pianificato")

# DISM
print("\n[4/8] Scansione integrità immagine (DISM)...")
log_message(LOGFILE, "Avvio DISM /scanhealth")
result = subprocess.run(['dism', '/online', '/cleanup-image', '/scanhealth'])
if result.returncode != 0:
    print("AVVISO: DISM scanhealth ha riscontrato problemi")
    log_message(LOGFILE, f"DISM scanhealth con errori: {result.returncode}")
else:
    print("DISM scanhealth completato")
    log_message(LOGFILE, "DISM scanhealth completato")

choice = input("Vuoi tentare la riparazione con DISM? (y/n): ")
if choice.strip().lower() == "y":
    print("Pulizia componenti e riparazione immagine...")
    log_message(LOGFILE, "Avvio DISM cleanup e restorehealth")
    subprocess.run(['dism', '/online', '/cleanup-image', '/startcomponentcleanup'])
    result = subprocess.run(['dism', '/online', '/cleanup-image', '/restorehealth'])
    if result.returncode != 0:
        print("AVVISO: DISM restorehealth ha riscontrato problemi")
        log_message(LOGFILE, f"DISM restorehealth con errori: {result.returncode}")
    else:
        print("DISM restorehealth completato con successo")
        log_message(LOGFILE, "DISM restorehealth completato")
else:
    print("Nessuna riparazione DISM eseguita")
    log_message(LOGFILE, "DISM restorehealth non eseguito")

# Pulizia file temporanei
print("\n[5/8] Pulizia file temporanei...")
log_message(LOGFILE, "Pulizia file temporanei")
subprocess.run(['del', '/f', '/s', '/q', os.path.join(os.environ['TEMP'], '*.*')], shell=True)
subprocess.run(['del', '/f', '/s', '/q', 'C:\\Windows\\Temp\\*.*'], shell=True)
print("Pulizia temporanei completata")
log_message(LOGFILE, "File temporanei puliti")

# Reset Windows Update
wupdate = input("Vuoi resettare i componenti Windows Update? (y/n): ")
if wupdate.strip().lower() == "y":
    print("\n[6/8] Reset componenti Windows Update...\n")
    log_message(LOGFILE, "Reset Windows Update")
    for svc in ['wuauserv', 'bits', 'cryptsvc', 'msiserver']:
        subprocess.run(['net', 'stop', svc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(['timeout', '/t', '2', '/nobreak'], stdout=subprocess.DEVNULL)
    for folder, newname in [
        (os.path.join(os.environ['SystemRoot'], 'SoftwareDistribution'), 'SoftwareDistribution.old'),
        (os.path.join(os.environ['SystemRoot'], 'System32', 'catroot2'), 'catroot2.old')
    ]:
        if os.path.exists(folder):
            result = subprocess.run(['ren', folder, newname], shell=True)
            if result.returncode == 0:
                print(f"{newname} rinominata con successo")
                log_message(LOGFILE, f"{newname} rinominata")
            else:
                print(f"AVVISO: Impossibile rinominare {newname}")
                log_message(LOGFILE, f"ERRORE: {newname} non rinominata")
    for svc in ['wuauserv', 'bits', 'cryptsvc', 'msiserver']:
        subprocess.run(['net', 'start', svc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("Componenti Windows Update resettati")
    log_message(LOGFILE, "Windows Update resettato completamente")
else:
    print("[6/8] Reset Windows Update saltato")
    log_message(LOGFILE, "Reset Windows Update non eseguito")


# Controllo aggiornamenti
checkupd = input("Vuoi forzare il controllo aggiornamenti? (y/n): ")
if checkupd.strip().lower() == "y":
    print("\n[7/8] Controllo aggiornamenti Windows...\n")
    log_message(LOGFILE, "Controllo aggiornamenti")
    subprocess.run(['usoclient', 'startscan'], stdout=subprocess.DEVNULL)
    subprocess.run(['timeout', '/t', '5', '/nobreak'], stdout=subprocess.DEVNULL)
    print("Scansione aggiornamenti avviata")
    log_message(LOGFILE, "Aggiornamenti - scansione avviata")
else:
    print("[7/8] Controllo aggiornamenti saltato")
    log_message(LOGFILE, "Controllo aggiornamenti non eseguito")

# Pulizia disco
cleanup = input("Vuoi avviare la pulizia disco? (y/n): ")
if cleanup.strip().lower() == "y":
    print("\n[8/8] Avvio Pulizia Disco...\n")
    log_message(LOGFILE, "Avvio Cleanmgr")
    subprocess.run(['cleanmgr', '/sageset:101'])
    subprocess.run(['cleanmgr', '/sagerun:101'])
    log_message(LOGFILE, "Cleanmgr completato")
else:
    print("[8/8] Pulizia disco saltata")
    log_message(LOGFILE, "Cleanmgr non eseguito")

# Conclusione
print("\n=====================================")
print("TUTTE LE OPERAZIONI SONO CONCLUSE")
print("=====================================")
print(f"Log completo salvato in: {LOGFILE}")
print(f"Report sistema salvato in: {sysinfo_file}\n")
log_message(LOGFILE, "=== DIAGNOSTICA COMPLETATA ===")
input("Premi INVIO per uscire...")
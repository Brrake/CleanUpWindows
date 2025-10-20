# 🛠️ Windows Diagnostic & Repair Tool

Script batch automatizzato per diagnostica completa, riparazione e manutenzione del sistema operativo Windows 10 e Windows 11.

## ✨ Caratteristiche

- **Diagnostica completa del sistema** con SFC (System File Checker)
- **Verifica e riparazione dell'immagine** con DISM
- **Scansione disco** con CHKDSK per errori fisici e logici
- **Pulizia automatica** di file temporanei e componenti obsoleti
- **Reset componenti Windows Update** per risolvere problemi di aggiornamento
- **Punto di ripristino automatico** prima di ogni operazione
- **Logging dettagliato** di tutte le operazioni eseguite
- **Report informazioni sistema** salvato automaticamente
- **Interfaccia interattiva** con scelta operazioni opzionali

## 📋 Requisiti

- Windows 10 o Windows 11
- Privilegi di amministratore (richiesti automaticamente)
- Spazio su disco sufficiente per log e operazioni

## 🚀 Utilizzo

1. Scarica lo script `diagnostica_windows.bat`
2. Fai click destro sul file
3. Seleziona "Esegui come amministratore"
4. Segui le istruzioni a schermo

## 📝 Operazioni Eseguite

1. Creazione punto di ripristino di sicurezza
2. Raccolta informazioni di sistema (SystemInfo)
3. Scansione e riparazione file di sistema (SFC)
4. Scansione disco per errori (CHKDSK)
5. Verifica integrità immagine Windows (DISM)
6. Pulizia file temporanei
7. Reset componenti Windows Update (opzionale)
8. Controllo aggiornamenti disponibili (opzionale)
9. Pulizia disco avanzata (opzionale)

## 📊 Output

Lo script genera automaticamente:
- File di log dettagliato con timestamp: `DiagnosticaWindows_AAAAMMGG_HHMM.log`
- Report sistema completo: `SystemInfo_AAAAMMGG.txt`

## ⚠️ Avvertenze

- Alcune operazioni richiedono il riavvio del sistema
- Il completamento può richiedere diversi minuti
- Assicurarsi di avere backup dei dati importanti
- Non interrompere lo script durante l'esecuzione

## 📜 Licenza

MIT License - Libero per uso personale e commerciale

## 🤝 Contributi

Contributi, segnalazioni di bug e richieste di funzionalità sono benvenuti!

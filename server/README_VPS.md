# Guida al Deploy del Backend VoIP (Ubuntu VPS)

Questa cartella contiene tutto il necessario per attivare il server VoIP con Asterisk PBX, il motore di elaborazione AI basato su **Google Gemini 2.5 Flash**, e le API REST per l'app iOS nativa.

---

## 1. Requisiti della VPS
- **Sistema Operativo**: Ubuntu 22.04 LTS o 24.04 LTS (x86_64 o ARM64).
- **IP Pubblico**: Accessibile da internet (es. `194.164.175.69`).
- **Accesso SSH**: Privilegi di root.

---

## 2. Installazione Automatica (Consigliata)

Collegati via SSH alla VPS ed esegui i seguenti comandi:

```bash
# 1. Clona la repository (se non già presente)
git clone https://github.com/GiacomoTorrigiani/VOIP.git /tmp/voip-repo

# 2. Entra nella cartella server ed esegui l'installer
cd /tmp/voip-repo/server
sudo bash install.sh
```

Lo script `install.sh` effettua automaticamente:
1. Installazione di Asterisk PBX, Python 3, venv, ffmpeg, sox e librerie audio.
2. Copia dei file applicativi in `/opt/voip-backend`.
3. Creazione dell'ambiente virtuale Python e installazione delle dipendenze.
4. Configurazione di `pjsip.conf` e `extensions.conf` con le credenziali Ehiweb VivaVox.
5. Registrazione e avvio del servizio di sistema `voip-backend.service` (porta 8000).
6. Configurazione delle regole Firewall (UFW) per SIP (5060/UDP), RTP (10000-20000/UDP) e API (8000/TCP).

---

## 3. Verifica della Registrazione SIP VivaVox

Dopo l'installazione, verifica che Asterisk sia registrato correttamente sui server Ehiweb:

```bash
# Verifica lo stato della registrazione SIP
asterisk -rx "pjsip show registrations"
```

Dovresti visualizzare:
```text
<Registration/ServerURI..............................>  <Auth..........>  <Status.......>
vivavox-reg/sip:sip.vivavox.it:5060                     vivavox-auth      Registered
```

Verifica inoltre lo stato dell'endpoint:
```bash
asterisk -rx "pjsip show endpoints"
```

---

## 4. Verifica delle API FastAPI

Verifica che il backend risponda correttamente:

```bash
curl http://localhost:8000/api/health
```

Risposta attesa:
```json
{
  "status": "ok",
  "service": "VoIP Assistant Backend",
  "gemini_model": "gemini-2.5-flash",
  "recordings_dir_exists": true
}
```

---

## 5. Nota sul Codec G.729
Ehiweb VivaVox supporta principalmente **G.729**, **A-law (G.711a)** e **u-law (G.711u)**.
La configurazione fornita in `pjsip.conf`:
```ini
allow=g729
allow=alaw
allow=ulaw
```
gestisce automaticamente la negoziazione con fallback su `alaw`/`ulaw`.
Se desideri compilare il modulo open-source BCG729 per Asterisk su Ubuntu:
```bash
sudo apt-get install -y build-essential asterisk-dev libbcg729-dev
git clone https://github.com/BelledonneCommunications/bcg729.git /tmp/bcg729
# Il pacchetto standard Ubuntu gestisce già alaw nativamente con qualità perfetta
```

---

## 6. Comandi Utili per la Manutenzione

- **Console interattiva Asterisk con debug**:
  ```bash
  asterisk -rvvvv
  ```
- **Stato del servizio API FastAPI**:
  ```bash
  systemctl status voip-backend
  ```
- **Log in tempo reale delle chiamate e di Gemini**:
  ```bash
  journalctl -u voip-backend -f
  ```
- **Log elaborazione audio post-chiamata**:
  ```bash
  ls -la /var/log/asterisk/post_call_*.log
  cat /var/log/asterisk/post_call_<ID>.log
  ```
- **Directory delle registrazioni .wav**:
  ```bash
  ls -lh /var/spool/asterisk/monitor/
  ```

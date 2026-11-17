#!/bin/bash
set -e

# ====================================================================
# VoIP Assistant - Script di Installazione Completo per VPS Ubuntu
# Asterisk (PJSIP VivaVox) + FastAPI + Google Gemini 2.5 Flash
# ====================================================================

echo "=========================================================="
echo " VoIP Assistant - Installazione Backend su Ubuntu VPS"
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "Per favore esegui questo script come root: sudo bash install.sh"
  exit 1
fi

echo "[1/7] Aggiornamento repository e installazione pacchetti..."
apt-get update -y
apt-get install -y \
    asterisk \
    asterisk-modules \
    ffmpeg \
    sox \
    libsox-fmt-all \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    git \
    ufw

echo "[2/7] Configurazione directory /opt/voip-backend..."
mkdir -p /opt/voip-backend
mkdir -p /opt/voip-backend/data
mkdir -p /var/spool/asterisk/monitor
mkdir -p /var/log/asterisk

# Copia file correnti nella directory di produzione se eseguito da cartella clonata
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ "$SCRIPT_DIR" != "/opt/voip-backend" ]; then
    cp -r "$SCRIPT_DIR"/* /opt/voip-backend/
fi

echo "[3/7] Creazione ambiente virtuale Python e installazione dipendenze..."
python3 -m venv /opt/voip-backend/venv
/opt/voip-backend/venv/bin/pip install --upgrade pip
/opt/voip-backend/venv/bin/pip install -r /opt/voip-backend/requirements.txt

# Rendi eseguibile lo script post-chiamata
chmod +x /opt/voip-backend/post_call_processor.py

echo "[4/7] Configurazione Asterisk PBX (pjsip.conf & extensions.conf)..."
if [ -f /etc/asterisk/pjsip.conf ]; then
    cp /etc/asterisk/pjsip.conf /etc/asterisk/pjsip.conf.bak.$(date +%s)
fi
if [ -f /etc/asterisk/extensions.conf ]; then
    cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.bak.$(date +%s)
fi

cp /opt/voip-backend/pjsip.conf /etc/asterisk/pjsip.conf
cp /opt/voip-backend/extensions.conf /etc/asterisk/extensions.conf

# Permessi corretti per utente asterisk
chown -R asterisk:asterisk /var/spool/asterisk/monitor
chown -R asterisk:asterisk /var/log/asterisk
chown -R asterisk:asterisk /opt/voip-backend
chmod 755 /opt/voip-backend/post_call_processor.py

echo "[5/7] Creazione servizio systemd per FastAPI (voip-backend.service)..."
cat << 'EOF' > /etc/systemd/system/voip-backend.service
[Unit]
Description=VoIP Assistant FastAPI Backend
After=network.target asterisk.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/voip-backend
ExecStart=/opt/voip-backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable voip-backend
systemctl restart voip-backend

echo "[6/7] Riavvio Asterisk PBX..."
systemctl enable asterisk
systemctl restart asterisk

echo "[7/7] Configurazione Firewall UFW..."
ufw allow 5060/udp comment "SIP Asterisk"
ufw allow 10000:20000/udp comment "RTP Media Audio"
ufw allow 8000/tcp comment "VoIP Assistant FastAPI"

echo "=========================================================="
echo " INSTALLAZIONE COMPLETATA CON SUCCESSO!"
echo "=========================================================="
echo ""
echo "Per verificare lo stato della registrazione SIP con Ehiweb VivaVox:"
echo "  asterisk -rx 'pjsip show registrations'"
echo "  asterisk -rx 'pjsip show endpoints'"
echo ""
echo "Per verificare lo stato del backend FastAPI:"
echo "  systemctl status voip-backend"
echo "  curl http://localhost:8000/api/health"
echo ""
echo "Per seguire i log in tempo reale:"
echo "  journalctl -u voip-backend -f"
echo "  asterisk -rvvvv"
echo "=========================================================="

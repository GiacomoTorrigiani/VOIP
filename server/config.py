import os
from pathlib import Path
from dotenv import load_dotenv

# Carica file .env se presente
load_dotenv()

BASE_DIR = Path(__file__).resolve().parent

# Gemini AI
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

# Autenticazione API REST
API_SECRET_TOKEN = os.getenv("API_SECRET_TOKEN", "TorriflixVoip2026SecureKey!")

# Numeri telefonici predefiniti
USER_PHONE = os.getenv("USER_PHONE", "3669650010")
VOIP_BRIDGE_NUMBER = os.getenv("VOIP_BRIDGE_NUMBER", "07441590208")

# Directory di registrazione Asterisk
# Su Ubuntu produzione: /var/spool/asterisk/monitor
_default_rec_dir = "/var/spool/asterisk/monitor" if os.path.exists("/var/spool/asterisk/monitor") else str(BASE_DIR / "recordings")
RECORDINGS_DIR = Path(os.getenv("RECORDINGS_DIR", _default_rec_dir))
try:
    RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)
except Exception as e:
    print(f"Warning: could not create RECORDINGS_DIR {RECORDINGS_DIR}: {e}")

# Directory per database e file di stato
_default_data_dir = "/opt/voip-backend/data" if os.path.exists("/opt/voip-backend") else str(BASE_DIR / "data")
DATA_DIR = Path(os.getenv("DATA_DIR", _default_data_dir))
try:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
except Exception as e:
    print(f"Warning: could not create DATA_DIR {DATA_DIR}: {e}")

DATABASE_PATH = DATA_DIR / "calls.db"

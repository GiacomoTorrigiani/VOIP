import sqlite3
import json
import uuid
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from config import DATABASE_PATH

def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(str(DATABASE_PATH))
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with get_connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS calls (
                id TEXT PRIMARY KEY,
                session_id TEXT UNIQUE,
                uniqueid TEXT,
                caller_number TEXT NOT NULL,
                recipient_number TEXT NOT NULL,
                recipient_name TEXT,
                timestamp TEXT NOT NULL,
                duration_seconds INTEGER DEFAULT 0,
                status TEXT NOT NULL,
                audio_path TEXT,
                transcription TEXT,
                concept_map_json TEXT,
                calendar_events_json TEXT,
                summary TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_calls_status ON calls(status)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_calls_uniqueid ON calls(uniqueid)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_calls_timestamp ON calls(timestamp DESC)")
        conn.commit()

def create_call_session(recipient_number: str, recipient_name: Optional[str], caller_number: str) -> Dict[str, Any]:
    call_id = str(uuid.uuid4())
    session_id = f"sess_{datetime.now().strftime('%Y%m%d%H%M%S')}_{call_id[:8]}"
    now_iso = datetime.now(timezone.utc).isoformat()

    with get_connection() as conn:
        conn.execute("""
            INSERT INTO calls (
                id, session_id, caller_number, recipient_number, recipient_name,
                timestamp, duration_seconds, status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, 0, 'initiated', ?, ?)
        """, (call_id, session_id, caller_number, recipient_number, recipient_name or "Destinatario", now_iso, now_iso, now_iso))
        conn.commit()

    return get_call_by_id(call_id)

def find_recent_initiated_call(caller_number: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Trova la sessione più recente avviata dall'app iOS negli ultimi 20 minuti"""
    with get_connection() as conn:
        query = "SELECT * FROM calls WHERE status = 'initiated'"
        params = []
        if caller_number:
            query += " AND (caller_number = ? OR caller_number LIKE ?)"
            clean = caller_number.replace("+", "").replace(" ", "")
            params.extend([clean, f"%{clean[-9:]}%"])
        query += " ORDER BY created_at DESC LIMIT 1"
        row = conn.execute(query, params).fetchone()
        if row:
            return _row_to_dict(row)
    return None

def get_call_by_id(call_id: str) -> Optional[Dict[str, Any]]:
    with get_connection() as conn:
        row = conn.execute("SELECT * FROM calls WHERE id = ? OR session_id = ? OR uniqueid = ?", (call_id, call_id, call_id)).fetchone()
        if row:
            return _row_to_dict(row)
    return None

def list_calls(limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
    with get_connection() as conn:
        rows = conn.execute("""
            SELECT * FROM calls
            ORDER BY timestamp DESC
            LIMIT ? OFFSET ?
        """, (limit, offset)).fetchall()
        return [_row_to_dict(r) for r in rows]

def update_call_status(call_id: str, status: str, uniqueid: Optional[str] = None, audio_path: Optional[str] = None):
    now_iso = datetime.now(timezone.utc).isoformat()
    with get_connection() as conn:
        conn.execute("""
            UPDATE calls
            SET status = ?,
                uniqueid = COALESCE(?, uniqueid),
                audio_path = COALESCE(?, audio_path),
                updated_at = ?
            WHERE id = ? OR session_id = ? OR uniqueid = ?
        """, (status, uniqueid, audio_path, now_iso, call_id, call_id, call_id))
        conn.commit()

def save_processing_results(
    call_id: str,
    transcription: str,
    concept_map: Dict[str, Any],
    calendar_events: List[Dict[str, Any]],
    duration_seconds: int,
    audio_path: Optional[str] = None,
    summary: Optional[str] = None
):
    now_iso = datetime.now(timezone.utc).isoformat()
    cmap_json = json.dumps(concept_map, ensure_ascii=False)
    events_json = json.dumps(calendar_events, ensure_ascii=False)

    with get_connection() as conn:
        conn.execute("""
            UPDATE calls
            SET status = 'completed',
                transcription = ?,
                concept_map_json = ?,
                calendar_events_json = ?,
                duration_seconds = ?,
                audio_path = COALESCE(?, audio_path),
                summary = ?,
                updated_at = ?
            WHERE id = ? OR session_id = ? OR uniqueid = ?
        """, (transcription, cmap_json, events_json, duration_seconds, audio_path, summary, now_iso, call_id, call_id, call_id))
        conn.commit()

def _row_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
    d = dict(row)
    # Parsing JSON fields
    if d.get("concept_map_json"):
        try:
            d["concept_map"] = json.loads(d["concept_map_json"])
        except Exception:
            d["concept_map"] = None
    else:
        d["concept_map"] = None

    if d.get("calendar_events_json"):
        try:
            d["calendar_events"] = json.loads(d["calendar_events_json"])
        except Exception:
            d["calendar_events"] = []
    else:
        d["calendar_events"] = []

    d["has_audio"] = bool(d.get("audio_path"))
    return d

# Inizializza automaticamente al caricamento del modulo
init_db()

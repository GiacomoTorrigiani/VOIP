import os
from pathlib import Path
from typing import Optional, List
from fastapi import FastAPI, HTTPException, Depends, Header, Query, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel

from config import API_SECRET_TOKEN, GEMINI_MODEL, RECORDINGS_DIR
import database
from processor import process_audio_file

app = FastAPI(
    title="VoIP Call Assistant API",
    description="Backend per registrazione VoIP con Asterisk, trascrizione Gemini 2.5 Flash, mappe CmapTools ed eventi Calendar",
    version="1.0.0"
)

# Configura CORS per consentire chiamate da app iOS e browser
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def verify_token(authorization: Optional[str] = Header(None), token: Optional[str] = Query(None)):
    """Verifica il Bearer Token o parametro query token"""
    received_token = None
    if authorization and authorization.startswith("Bearer "):
        received_token = authorization.split("Bearer ")[1].strip()
    elif token:
        received_token = token

    if not received_token or received_token != API_SECRET_TOKEN:
        raise HTTPException(status_code=401, detail="Token di autorizzazione non valido o mancante.")

class InitiateCallRequest(BaseModel):
    recipient_number: str
    recipient_name: Optional[str] = "Destinatario"
    caller_number: Optional[str] = "3669650010"

@app.get("/api/health")
def health_check():
    return {
        "status": "ok",
        "service": "VoIP Assistant Backend",
        "gemini_model": GEMINI_MODEL,
        "recordings_dir_exists": RECORDINGS_DIR.exists()
    }

@app.post("/api/calls/initiate", dependencies=[Depends(verify_token)])
def initiate_call(req: InitiateCallRequest):
    """
    Notifica il backend prima di avviare la chiamata dall'app iOS.
    Crea una sessione in stato 'initiated' pronta ad essere associata
    alla registrazione audio Asterisk sul numero ponte 07441590208.
    """
    session = database.create_call_session(
        recipient_number=req.recipient_number,
        recipient_name=req.recipient_name,
        caller_number=req.caller_number or "3669650010"
    )
    return {
        "status": "ok",
        "call_id": session["id"],
        "session_id": session["session_id"],
        "recipient_number": session["recipient_number"],
        "recipient_name": session["recipient_name"]
    }

@app.get("/api/calls", dependencies=[Depends(verify_token)])
def get_calls(limit: int = 50, offset: int = 0):
    """Restituisce l'elenco delle chiamate registrate ed elaborate"""
    return database.list_calls(limit=limit, offset=offset)

@app.get("/api/calls/{call_id}", dependencies=[Depends(verify_token)])
def get_call_detail(call_id: str):
    """Restituisce il dettaglio completo di una chiamata (trascrizione, mappa Cmap, eventi calendario)"""
    call = database.get_call_by_id(call_id)
    if not call:
        raise HTTPException(status_code=404, detail="Chiamata non trovata.")
    return call

@app.get("/api/calls/{call_id}/audio", dependencies=[Depends(verify_token)])
def get_call_audio(call_id: str):
    """Esegue lo streaming dell'audio della registrazione per il player iOS"""
    call = database.get_call_by_id(call_id)
    if not call or not call.get("audio_path"):
        raise HTTPException(status_code=404, detail="File audio non associato a questa chiamata.")

    audio_path = Path(call["audio_path"])
    if not audio_path.exists():
        raise HTTPException(status_code=404, detail="File audio non trovato sul disco.")

    media_type = "audio/wav"
    if audio_path.suffix.lower() == ".mp3":
        media_type = "audio/mp3"
    elif audio_path.suffix.lower() == ".m4a":
        media_type = "audio/mp4"

    return FileResponse(
        path=str(audio_path),
        media_type=media_type,
        filename=audio_path.name
    )

def _reprocess_call_task(call_id: str, audio_path: str):
    try:
        database.update_call_status(call_id, status="processing")
        call = database.get_call_by_id(call_id)
        recipient_name = call.get("recipient_name", "Destinatario") if call else "Destinatario"
        recipient_number = call.get("recipient_number", "") if call else ""
        caller_number = call.get("caller_number", "3669650010") if call else "3669650010"
        
        result = process_audio_file(
            audio_path=audio_path,
            caller_name="Giacomo",
            caller_number=caller_number,
            recipient_name=recipient_name,
            recipient_number=recipient_number
        )
        database.save_processing_results(
            call_id=call_id,
            transcription=result.get("transcription", ""),
            concept_map=result.get("concept_map", {}),
            calendar_events=result.get("calendar_events", []),
            duration_seconds=call.get("duration_seconds", 0) if call else 0,
            audio_path=audio_path,
            summary=result.get("summary", "")
        )
    except Exception as e:
        print(f"[Reprocess] Errore: {e}")
        database.update_call_status(call_id, status="error")

@app.post("/api/calls/{call_id}/reprocess", dependencies=[Depends(verify_token)])
def reprocess_call(call_id: str, background_tasks: BackgroundTasks):
    """Rielabora l'audio della chiamata con Gemini in background"""
    call = database.get_call_by_id(call_id)
    if not call or not call.get("audio_path"):
        raise HTTPException(status_code=404, detail="Chiamata o audio non trovati.")

    background_tasks.add_task(_reprocess_call_task, call_id, call["audio_path"])
    return {"status": "ok", "message": "Rielaborazione avviata in background."}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

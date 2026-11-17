#!/usr/bin/env python3
import sys
import os
from pathlib import Path

# Assicura che la cartella dello script sia in cima a sys.path
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import time
import wave
import argparse
from datetime import datetime, timezone

from config import RECORDINGS_DIR, USER_PHONE
import database
from processor import process_audio_file

def get_audio_duration(file_path: Path) -> int:
    """Calcola la durata del file .wav in secondi"""
    try:
        with wave.open(str(file_path), 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            if rate > 0:
                return int(frames / float(rate))
    except Exception as e:
        print(f"[PostProcessor] Impossibile leggere durata wave: {e}")

    # Fallback con sox o stat dimensione file (8000Hz 16bit mono = 16000 bytes/sec)
    try:
        size = file_path.stat().st_size
        return max(1, int(size / 16000))
    except Exception:
        return 0

def main():
    parser = argparse.ArgumentParser(description="Asterisk Post-Call Processor")
    parser.add_argument("--uniqueid", required=True, help="Asterisk UniqueID")
    parser.add_argument("--caller", default=USER_PHONE, help="Numero del chiamante")
    args = parser.parse_args()

    print(f"[{datetime.now().isoformat()}] --- Inizio Post-Processing per UniqueID: {args.uniqueid} (Chiamante: {args.caller}) ---")

    # Attendi che Asterisk chiuda la scrittura del file MixMonitor
    time.sleep(2)

    # Cerca il file audio
    wav_path = RECORDINGS_DIR / f"{args.uniqueid}.wav"
    if not wav_path.exists():
        # Cerca eventuali file con prefisso
        candidates = list(RECORDINGS_DIR.glob(f"*{args.uniqueid}*.wav"))
        if candidates:
            wav_path = candidates[0]
        else:
            print(f"[PostProcessor] ERRORE: File audio per UniqueID {args.uniqueid} non trovato in {RECORDINGS_DIR}")
            sys.exit(1)

    duration = get_audio_duration(wav_path)
    print(f"[PostProcessor] File audio trovato: {wav_path} (Durata stimata: {duration} s)")

    # 1. Associa la registrazione alla sessione creata dall'app iOS
    session = database.find_recent_initiated_call(args.caller)
    if session:
        call_id = session["id"]
        print(f"[PostProcessor] Associata sessione esistente dall'app: {call_id} (Destinatario: {session.get('recipient_name')})")
        database.update_call_status(call_id, status="processing", uniqueid=args.uniqueid, audio_path=str(wav_path))
    else:
        print("[PostProcessor] Nessuna sessione 'initiated' recente trovata. Creazione nuova chiamata generica.")
        new_session = database.create_call_session(
            recipient_number="Destinatario Sconosciuto",
            recipient_name="Chiamata Diretta",
            caller_number=args.caller
        )
        call_id = new_session["id"]
        database.update_call_status(call_id, status="processing", uniqueid=args.uniqueid, audio_path=str(wav_path))

    # 2. Elaborazione con Gemini 2.5 Flash / 3.5 Flash Lite
    if wav_path.stat().st_size <= 500 or duration == 0:
        print("[PostProcessor] File audio vuoto o troppo breve (< 1s). Salvataggio stato senza invio a Gemini.")
        database.save_processing_results(
            call_id=call_id,
            transcription="Nessun parlato rilevato (chiamata terminata immediatamente).",
            concept_map={"concepts": [], "linking_phrases": []},
            calendar_events=[],
            duration_seconds=duration,
            audio_path=str(wav_path),
            summary="Chiamata vuota o interrotta."
        )
        return

    try:
        print(f"[PostProcessor] Invio file a Gemini...")
        result = process_audio_file(str(wav_path))

        transcription = result.get("transcription", "")
        summary = result.get("summary", "")
        concept_map = result.get("concept_map", {})
        calendar_events = result.get("calendar_events", [])

        print(f"[PostProcessor] Elaborazione completata con successo! Trascrizione: {len(transcription)} caratteri, Eventi: {len(calendar_events)}")

        database.save_processing_results(
            call_id=call_id,
            transcription=transcription,
            concept_map=concept_map,
            calendar_events=calendar_events,
            duration_seconds=duration,
            audio_path=str(wav_path),
            summary=summary
        )
        print(f"[PostProcessor] Dati salvati nel database per la chiamata {call_id}.")

    except Exception as e:
        print(f"[PostProcessor] ERRORE durante l'elaborazione con Gemini: {e}")
        database.update_call_status(call_id, status="error")
        sys.exit(1)

if __name__ == "__main__":
    main()

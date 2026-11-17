#!/usr/bin/env python3
import sys
import os
import subprocess
from pathlib import Path

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
    try:
        with wave.open(str(file_path), 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            if rate > 0:
                return int(frames / float(rate))
    except Exception as e:
        print(f"[PostProcessor] Impossibile leggere durata wave: {e}")

    try:
        size = file_path.stat().st_size
        return max(1, int(size / 16000))
    except Exception:
        return 0

def convert_to_m4a(wav_path: Path) -> Path:
    m4a_path = wav_path.with_suffix('.m4a')
    try:
        cmd = ["ffmpeg", "-y", "-i", str(wav_path), "-c:a", "aac", "-b:a", "64k", str(m4a_path)]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        if m4a_path.exists() and m4a_path.stat().st_size > 0:
            print(f"[PostProcessor] Convertito con successo in AAC: {m4a_path}")
            return m4a_path
    except Exception as e:
        print(f"[PostProcessor] Conversione ffmpeg non riuscita: {e}")
    return wav_path

def main():
    parser = argparse.ArgumentParser(description="Asterisk Post-Call Processor")
    parser.add_argument("--uniqueid", required=True, help="Asterisk UniqueID")
    parser.add_argument("--caller", default=USER_PHONE, help="Numero del chiamante")
    args = parser.parse_args()

    print(f"[{datetime.now().isoformat()}] --- Inizio Post-Processing per UniqueID: {args.uniqueid} (Chiamante: {args.caller}) ---")

    time.sleep(2)

    wav_path = RECORDINGS_DIR / f"{args.uniqueid}.wav"
    if not wav_path.exists():
        candidates = list(RECORDINGS_DIR.glob(f"*{args.uniqueid}*.wav"))
        if candidates:
            wav_path = candidates[0]
        else:
            print(f"[PostProcessor] ERRORE: File audio per UniqueID {args.uniqueid} non trovato in {RECORDINGS_DIR}")
            sys.exit(1)

    duration = get_audio_duration(wav_path)
    print(f"[PostProcessor] File audio trovato: {wav_path} (Durata stimata: {duration} s)")

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

    # Converti in AAC m4a ottimizzato per streaming iOS
    final_audio_path = convert_to_m4a(wav_path)

    recip_name = session.get('recipient_name', 'Destinatario') if session else 'Destinatario'
    recip_num = session.get('recipient_number', '') if session else ''

    try:
        print(f"[PostProcessor] Invio file a Gemini ({final_audio_path}) per {recip_name}...")
        result = process_audio_file(
            audio_path=str(final_audio_path),
            caller_name="Giacomo",
            caller_number=args.caller,
            recipient_name=recip_name,
            recipient_number=recip_num
        )

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
            audio_path=str(final_audio_path),
            summary=summary
        )
        print(f"[PostProcessor] Dati salvati nel database per la chiamata {call_id}.")

    except Exception as e:
        print(f"[PostProcessor] ERRORE durante l'elaborazione con Gemini: {e}")
        database.update_call_status(call_id, status="error")
        sys.exit(1)

if __name__ == "__main__":
    main()

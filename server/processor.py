import os
import json
import base64
import requests
from pathlib import Path
from typing import Dict, Any, List, Optional
from config import GEMINI_API_KEY, GEMINI_MODEL

SYSTEM_PROMPT = """
Sei un assistente di intelligenza artificiale per l'analisi avanzata di telefonate aziendali e personali registrate.
Il tuo compito è ascoltare attentamente la registrazione audio della conversazione telefonica ed estrarre in formato JSON strutturato:

1. "transcription": La trascrizione integrale, accurata e fedele della conversazione. Identifica gli interlocutori (ad esempio: "Giacomo (3669650010)" per il chiamante principale e il nome del "Destinatario" se menzionato, oppure "Destinatario").
2. "summary": Una sintesi chiara e concisa in 2-3 frasi dei punti chiave discussi.
3. "concept_map": Una mappa concettuale formale secondo la teoria classica di Joseph Novak (stile CmapTools):
   - "concepts": array di nodi concettuali [{ "id": "c1", "label": "Nome Concetto" }, ...]
   - "linking_phrases": array di relazioni/parole legame [{ "from": "c1", "to": "c2", "label": "parola legame (es. definisce, richiede, concorda)" }, ...]
   - "mermaid_code": Codice sorgente Mermaid.js valido in formato 'graph TD' con nodi a rettangolo arrotondato id["Etichetta"] e frecce etichettate -->|parola legame| id2["Altro Concetto"].
   - "cytoscape_elements": Array di elementi Cytoscape.js contenente nodi ed edges pronti per il rendering.
4. "calendar_events": Array di impegni, appuntamenti, riunioni, scadenze, o richiamate concordate durante la conversazione.
   Ogni elemento deve avere:
   - "title": Titolo chiaro dell'evento (es. "Firma Contratto Preliminare", "Richiamare Mario")
   - "start_iso": Data e ora stimata in formato ISO 8601 (es. "2026-11-20T10:30:00"). Se viene citato solo il giorno o l'ora, inferisci una data ragionevole futura rispetto al contesto.
   - "end_iso": Data e ora fine stimata in formato ISO 8601 (es. 1 ora dopo l'inizio).
   - "notes": Dettagli, luogo o note importanti concordate nella chiamata.
   - "location": Eventuale luogo o "Chiamata telefonica".

RISPONDI ESCLUSIVAMENTE con un oggetto JSON valido privo di blocchi markdown ```json o testo introduttivo.
"""

USER_PROMPT = """
Analizza questo file audio registrato tramite triangolazione VoIP.
Restituisci l'oggetto JSON completo con:
- transcription
- summary
- concept_map (con concepts, linking_phrases, mermaid_code, cytoscape_elements)
- calendar_events
"""

def process_audio_file(audio_path: str) -> Dict[str, Any]:
    """
    Invia il file audio all'API Gemini (gemini-2.5-flash) ed estrae trascrizione, mappa Cmap ed eventi.
    Supporta SDK google-genai con fallback a REST API diretta.
    """
    path = Path(audio_path)
    if not path.exists():
        raise FileNotFoundError(f"File audio non trovato: {audio_path}")

    # Tentativo 1: SDK google-genai
    try:
        return _process_with_google_genai_sdk(path)
    except Exception as e_sdk:
        print(f"[Processor] Avviso: SDK google-genai non disponibile o fallito ({e_sdk}). Tentativo con REST API...")

    # Tentativo 2: REST API diretta verso generativelanguage.googleapis.com
    return _process_with_gemini_rest(path)

def _process_with_google_genai_sdk(path: Path) -> Dict[str, Any]:
    from google import genai
    from google.genai import types

    client = genai.Client(api_key=GEMINI_API_KEY)

    # Carica il file audio tramite il Files API di Gemini
    uploaded_file = client.files.upload(file=str(path))

    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=[
            uploaded_file,
            USER_PROMPT
        ],
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            response_mime_type="application/json"
        )
    )

    text = response.text or "{}"
    return _clean_and_parse_json(text)

def _process_with_gemini_rest(path: Path) -> Dict[str, Any]:
    """Fallback robusto via chiamata HTTP diretta con audio inline base64"""
    file_bytes = path.read_bytes()
    b64_audio = base64.b64encode(file_bytes).decode("utf-8")

    # Rileva MIME type
    mime_type = "audio/wav"
    if path.suffix.lower() == ".mp3":
        mime_type = "audio/mp3"
    elif path.suffix.lower() in [".m4a", ".aac"]:
        mime_type = "audio/mp4"

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}"

    payload = {
        "system_instruction": {
            "parts": [{"text": SYSTEM_PROMPT}]
        },
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": b64_audio
                        }
                    },
                    {
                        "text": USER_PROMPT
                    }
                ]
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json"
        }
    }

    resp = requests.post(url, json=payload, timeout=180)
    if resp.status_code != 200:
        raise RuntimeError(f"Errore Gemini API HTTP {resp.status_code}: {resp.text}")

    result_json = resp.json()
    candidates = result_json.get("candidates", [])
    if not candidates:
        raise RuntimeError("Nessun candidato restituito da Gemini")

    parts = candidates[0].get("content", {}).get("parts", [])
    if not parts:
        raise RuntimeError("Nessuna parte di testo nella risposta di Gemini")

    text = parts[0].get("text", "{}")
    return _clean_and_parse_json(text)

def _clean_and_parse_json(raw_text: str) -> Dict[str, Any]:
    text = raw_text.strip()
    if text.startswith("```json"):
        text = text[7:]
    elif text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    text = text.strip()

    data = json.loads(text)

    # Assicuriamo che la mappa CmapTools contenga elementi cytoscape ben formattati
    if "concept_map" in data and isinstance(data["concept_map"], dict):
        cmap = data["concept_map"]
        if "cytoscape_elements" not in cmap or not cmap["cytoscape_elements"]:
            cmap["cytoscape_elements"] = _build_cytoscape_elements(cmap)
        if "mermaid_code" not in cmap or not cmap["mermaid_code"]:
            cmap["mermaid_code"] = _build_mermaid_code(cmap)

    return data

def _build_cytoscape_elements(cmap: Dict[str, Any]) -> List[Dict[str, Any]]:
    elements = []
    concepts = cmap.get("concepts", [])
    links = cmap.get("linking_phrases", [])

    for c in concepts:
        elements.append({
            "data": {
                "id": str(c.get("id")),
                "label": str(c.get("label", "")),
                "type": "concept"
            }
        })

    for idx, l in enumerate(links):
        s = str(l.get("from") or l.get("source"))
        t = str(l.get("to") or l.get("target"))
        label = str(l.get("label") or l.get("phrase") or "")
        elements.append({
            "data": {
                "id": f"e_{s}_{t}_{idx}",
                "source": s,
                "target": t,
                "label": label
            }
        })

    return elements

def _build_mermaid_code(cmap: Dict[str, Any]) -> str:
    lines = ["graph TD"]
    concepts = cmap.get("concepts", [])
    links = cmap.get("linking_phrases", [])

    for c in concepts:
        cid = str(c.get("id"))
        lbl = str(c.get("label", "")).replace('"', "'")
        lines.append(f'  {cid}["{lbl}"]')

    for l in links:
        s = str(l.get("from") or l.get("source"))
        t = str(l.get("to") or l.get("target"))
        label = str(l.get("label") or l.get("phrase") or "").replace('"', "'")
        lines.append(f'  {s} -->|"{label}"| {t}')

    return "\n".join(lines)

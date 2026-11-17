import os
import json
import base64
import requests
import time
from pathlib import Path
from typing import Dict, Any, List, Optional
from config import GEMINI_API_KEY, GEMINI_MODEL

def build_system_prompt(caller_name: str = "Giacomo", caller_number: str = "3669650010", recipient_name: str = "Destinatario", recipient_number: str = "") -> str:
    caller_desc = f"{caller_name} ({caller_number}, voce principale / chiamante)"
    recipient_desc = f"{recipient_name} ({recipient_number})"
    if "amore" in recipient_name.lower() or "fidanzat" in recipient_name.lower():
        recipient_desc += " (voce femminile, fidanzata)"

    return f"""Sei un sistema esperto di intelligenza artificiale specializzato in trascrizione fonetica e analisi semantica avanzata di telefonate in lingua italiana.
Il tuo compito e' ascoltare con la massima fedelta' l'audio della telefonata registrata ed estrarre un oggetto JSON strutturato.

INFO INTERLOCUTORI:
- Chiamante: {caller_desc}
- Destinatario: {recipient_desc}

1. "transcription":
   - Esegui una doppia analisi integrata:
     * FASE A (Ascolto Fonetico): Decodifica con la massima precisione l'audio della conversazione in italiano colloquiale.
     * FASE B (Correzione Lessicale e Semantica Contestuale): Rianalizza l'intero contesto logico per correggere i tipici errori di decodifica fonetica della linea telefonica (es. se una parola acusticamente suona come un non-senso come "ratteo", ma il contesto della frase rende chiaro che l'interlocutore ha detto "da Dio", correggila automaticamente; se il contesto parla di mappe concettuali, correggi "GMap" in "C-Map").
     * Mantieni inalterati i modi di dire spontanei, le esclamazioni, le risate e la naturalezza del parlato reale (senza censurare e senza trasformare il parlato in un testo artificiale).
   - Distingui con la massima precisione i due interlocutori basandoti sul timbro di voce e sul contesto:
     * Voce del chiamante ({caller_name})
     * Voce dell'interlocutore ({recipient_name})
   - Formatta chiaramente come dialogo a battute con gli speaker corretti:
     "{caller_name}: ...\\n{recipient_name}: ...".

2. "summary":
   - Una sintesi chiara e concisa in 2-3 frasi dei temi reali, degli argomenti trattati e delle conclusioni o accordi emersi nella telefonata.

3. "concept_map":
   - Mappa concettuale rigorosa secondo la teoria classica di Joseph Novak (stile CmapTools).
   - REGOLA FONDAMENTALE SUI NODI (CRUCIALE):
     NON creare mai nodi banali o meta-azioni della telefonata!
     E' SEVERAMENTE VIETATO inserire nodi che descrivono l'azione tecnica di telefonare (come "Chiamata telefonica", "Smartphone", "Destinatario", "Giacomo effettua chiamata", "Riceve chiamata", "Effettua", "Giacomo").
     La mappa deve rappresentare i CONTENUTI REALI, LE IDEE, I FATTI, I RISULTATI E LE DECISIONI discusse nella conversazione!
     I concetti devono essere frasi nominali sintetiche e ricche di significato (es. "Test VoIP Assistant", "Caller ID Reale ('Jack')", "Toni DTMF (Bip Composizione)", "Mappa Concettuale (C-Map)", "Auto-tracciamento Chiamata", "Accordi Contrattuali", ecc.).
   - Struttura JSON:
     * "concepts": array di nodi [{{"id": "c1", "label": "Nome Concetto"}}, ...]
     * "linking_phrases": array di relazioni [{{"from": "c1", "to": "c2", "label": "verbo o parola legame (es. visualizza sul display, rileva acusticamente, dimostra successo di, attiva funzione)"}}, ...]
     * "mermaid_code": codice Mermaid 'graph TD' valido con nodi a rettangolo arrotondato id["Etichetta"] e frecce etichettate -->|"parola legame"| id2["Altro Concetto"].

4. "calendar_events":
   - Array di eventuali impegni, appuntamenti, promemoria o scadenze concordate durante la conversazione. Se non ci sono appuntamenti concordati, restituisci [].
   - Ogni elemento:
     * "title": Titolo chiaro dell'evento (es. "Richiamare Mario", "Incontro di Lavoro")
     * "start_iso": Data e ora stimata in formato ISO 8601 (es. "2026-11-20T10:30:00")
     * "end_iso": Data e ora fine stimata in formato ISO 8601
     * "notes": Dettagli importanti
     * "location": Luogo o "Chiamata telefonica"

5. "action_prompts":
   - Rileva se durante la conversazione uno degli interlocutori chiede di compiere un'azione, una ricerca, un'analisi, un dossier, o la stesura di un documento (ad esempio: "fammi un dossier su Mario Rossi", "ti mando il CV su WhatsApp con annotazioni", "preparami una bozza", "cercami la legge su...", "confrontami due offerte").
   - Se NON ci sono compiti operativi o richieste di lavoro, restituisci [].
   - Per OGNI richiesta rilevata, crea un prompt professionale pronto all'uso con:
     * "id": "p1", "p2", ...
     * "task_title": Titolo sintetico dell'azione (es. "Dossier Approfondito su Mario Rossi")
     * "request_context": Contesto della richiesta emersa nella chiamata (es. "Richiesto dall'interlocutore; ti inviera' il CV con annotazioni via WhatsApp")
     * "suggested_mode": "Deep Research" (per ricerche web complesse), "Analisi Documenti" (se include allegati o CV), oppure "Stesura Rapida"
     * "suggested_model": "Gemini 3.1 Pro / Advanced"
     * "prompt_text": Il testo integrale del Super-Prompt ingegnerizzato, pronto da incollare su Google Gemini, Claude o ChatGPT. Deve includere Ruolo professionale, Obiettivo, Metodologia, Sezioni richieste nel report finale, e un chiaro segnaposto [INCOLLA QUI IL DOCUMENTO / CV RICEVUTO].

RISPONDI ESCLUSIVAMENTE con un oggetto JSON valido privo di blocchi markdown ```json o testo introduttivo.
"""

USER_PROMPT = """
Trascrivi con massima fedelta' parola per parola questo audio telefonico distinguendo gli interlocutori, genera la sintesi, la mappa concettuale formale di Novak sui contenuti reali, eventuali eventi di calendario e i prompt ingegnerizzati per le azioni/richieste operative emerse.
"""

def process_audio_file(
    audio_path: str,
    caller_name: str = "Giacomo",
    caller_number: str = "3669650010",
    recipient_name: str = "Destinatario",
    recipient_number: str = ""
) -> Dict[str, Any]:
    """
    Invia il file audio all'API Gemini con istruzioni ad altissima precisione
    per trascrizione verbatim accurata e mappa concettuale Novak di contenuto.
    """
    path = Path(audio_path)
    if not path.exists():
        raise FileNotFoundError(f"File audio non trovato: {audio_path}")

    file_bytes = path.read_bytes()
    b64_audio = base64.b64encode(file_bytes).decode("utf-8")

    mime_type = "audio/wav"
    if path.suffix.lower() == ".mp3":
        mime_type = "audio/mp3"
    elif path.suffix.lower() in [".m4a", ".aac"]:
        mime_type = "audio/mp4"

    system_prompt = build_system_prompt(caller_name, caller_number, recipient_name, recipient_number)

    payload = {
        "system_instruction": {
            "parts": [{"text": system_prompt}]
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

    candidates = ["gemini-3.8-flash", "gemini-3.5-flash-lite", "gemini-2.5-flash-lite"]
    unique_candidates = list(dict.fromkeys(candidates))

    last_err_resp = None
    for model_name in unique_candidates:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={GEMINI_API_KEY}"
        for attempt in range(2):
            try:
                resp = requests.post(url, json=payload, timeout=120)
                if resp.status_code == 200:
                    result_json = resp.json()
                    items = result_json.get("candidates", [])
                    if items:
                        text_content = items[0].get("content", {}).get("parts", [{}])[0].get("text", "{}")
                        return _clean_and_parse_json(text_content)
                elif resp.status_code in [503, 429]:
                    time.sleep(2)
                    continue
                last_err_resp = resp
                break
            except Exception as e:
                print(f"[Processor] Errore richiesta per {model_name}: {e}")
                time.sleep(1)

    if last_err_resp:
        raise RuntimeError(f"Errore Gemini API HTTP {last_err_resp.status_code}: {last_err_resp.text}")
    return {}

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
        # Normalizza nodes -> concepts
        if "nodes" in cmap and "concepts" not in cmap:
            cmap["concepts"] = cmap["nodes"]
        if "edges" in cmap and "linking_phrases" not in cmap:
            cmap["linking_phrases"] = cmap["edges"]

        if "cytoscape_elements" not in cmap or not cmap["cytoscape_elements"]:
            cmap["cytoscape_elements"] = _build_cytoscape_elements(cmap)
        if "mermaid_code" not in cmap or not cmap["mermaid_code"]:
            cmap["mermaid_code"] = _build_mermaid_code(cmap)

    return data

def _build_cytoscape_elements(cmap: Dict[str, Any]) -> List[Dict[str, Any]]:
    elements = []
    concepts = cmap.get("concepts", []) or cmap.get("nodes", [])
    links = cmap.get("linking_phrases", []) or cmap.get("edges", [])

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
    concepts = cmap.get("concepts", []) or cmap.get("nodes", [])
    links = cmap.get("linking_phrases", []) or cmap.get("edges", [])

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

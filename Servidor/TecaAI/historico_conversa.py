import json
import os

HISTORICO_FILE = "historico.json"

def load_conversation_from_json():
    if os.path.exists(HISTORICO_FILE):
        with open(HISTORICO_FILE, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
                return data
            except json.JSONDecodeError:
                return []
    return []

def save_conversation_to_json(new_entries):
    history = load_conversation_from_json()
    history.extend(new_entries)
    with open(HISTORICO_FILE, "w", encoding="utf-8") as f:
        json.dump(history, f, ensure_ascii=False, indent=2)

import json
import sys
import os

REQUIRED_BITE_FIELDS = [
    'bite_id', 'title', 'module', 'chapter', 'concept', 
    'question_text', 'answer', 'explanation'
]

def validate_json_structure(file_path):
    print(f"--- Validating {os.path.basename(file_path)} ---")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"[ERROR] Failed to parse JSON: {e}")
        return False

    # Actual ABFM structure is a list
    bites = data if isinstance(data, list) else data.get('bites', [])
    
    if not bites:
        print("[ERROR] No bites found in JSON.")
        return False

    errors = 0
    for idx, bite in enumerate(bites):
        bid = bite.get('bite_id', bite.get('id', f'index_{idx}'))
        
        # Check required Bite fields
        for field in REQUIRED_BITE_FIELDS:
            if field not in bite:
                print(f"[ERROR] Bite {bid}: Missing required field '{field}'")
                errors += 1
        
        # Check micro-content length (target <= 120 words)
        concept = bite.get('concept', '')
        word_count = len(concept.split())
        if word_count > 180: # ABFM content is rich, allowing more margin
            print(f"[WARNING] Bite {bid}: Concept is long ({word_count} words).")
            
        # Check MCQ options
        q_type = bite.get('question_type', 'mcq')
        if q_type == 'mcq':
            options = bite.get('options', [])
            if len(options) < 2:
                print(f"[ERROR] Bite {bid}: MCQ must have at least 2 options.")
                errors += 1
            if bite.get('answer') not in options:
                 # Check for index (A, B, C, D) or full match
                 answer = bite.get('answer')
                 if not str(answer).startswith(('A)', 'B)', 'C)', 'D)')):
                    print(f"[WARNING] Bite {bid}: Answer '{answer}' not clearly matched in options.")

    if errors > 0:
        print(f"\n[FAIL] Validation found {errors} errors.")
        return False
    
    print(f"\n[SUCCESS] Content schema is valid ({len(bites)} units).")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python validator.py <path_to_json>")
        sys.exit(1)
        
    success = validate_json_structure(sys.argv[1])
    sys.exit(0 if success else 1)

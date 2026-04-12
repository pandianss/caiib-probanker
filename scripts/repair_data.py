import os
import django
import sys
import re

# Setup Django
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import Bite

def clean_text(s):
    if not isinstance(s, str): return s
    # Remove all occurrences of [1], [23], etc. and clean surrounding whitespace
    # Handles middle-of-sentence and end-of-sentence markers
    return re.sub(r'\s*\[\d+\]', '', s).strip()

def repair_database_fully():
    print("Starting global content repair (Footnote Removal)...")
    bites = Bite.objects.all()
    repaired_count = 0
    
    for b in bites:
        dirty = False
        
        # List of fields to clean
        fields_to_clean = [
            'title', 'concept', 'example', 'formula', 
            'question_text', 'answer', 'explanation'
        ]
        
        for field in fields_to_clean:
            original_val = getattr(b, field)
            if original_val:
                new_val = clean_text(original_val)
                if new_val != original_val:
                    setattr(b, field, new_val)
                    dirty = True
        
        # Special handling for options (JSON list)
        if b.options:
            new_options = [clean_text(opt) for opt in b.options]
            if new_options != b.options:
                b.options = new_options
                dirty = True
        
        if dirty:
            b.save()
            repaired_count += 1
            print(f"Cleaned Bite ID: {b.bite_id}")

    print(f"\nGlobal repair complete. Total bites cleaned: {repaired_count}")

if __name__ == "__main__":
    repair_database_fully()

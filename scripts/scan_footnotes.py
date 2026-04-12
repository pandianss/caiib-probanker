import os
import django
import sys
import re

# Setup Django
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import Bite

def scan_for_footnotes():
    pattern = re.compile(r'\[\d+\]')
    count = 0
    print("Scanning content for footnote markings...")
    
    for b in Bite.objects.all():
        # Check all text fields
        found = False
        content_map = {
            'title': b.title,
            'concept': b.concept,
            'example': b.example,
            'formula': b.formula,
            'question_text': b.question_text,
            'explanation': b.explanation
        }
        
        for field, text in content_map.items():
            if text and pattern.search(text):
                if count < 3:
                    print(f"--- Found in {b.bite_id} ({field}) ---")
                    print(f"Match: {pattern.findall(text)}")
                    print(f"Context: {text[:200]}...")
                found = True
        
        if found:
            count += 1

    print(f"\nTotal bites with footnote markings in content: {count}")

if __name__ == "__main__":
    scan_for_footnotes()

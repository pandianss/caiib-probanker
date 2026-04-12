import os
import django
import json
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import Bite, MarketplaceBundle, Candidate
from django.conf import settings

def seed_file(filename):
    file_path = os.path.join('curriculum', filename)
    if not os.path.exists(file_path):
        print(f"File {file_path} not found.")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        paper_code = data.get('paper_code', 'UNKNOWN')
        bites_data = data.get('bites', [])
        
        print(f"Seeding {len(bites_data)} bites for {paper_code}...")
        
        ingested_bites = []
        for b in bites_data:
            check = b.get('check_question', {})
            bite, created = Bite.objects.update_or_create(
                bite_id=b['id'],
                defaults={
                    'paper_code': paper_code,
                    'module': b.get('module') or data.get('module') or 'General',
                    'chapter': b.get('chapter') or data.get('chapter') or 'General',
                    'title': b.get('title', ''),
                    'concept': b.get('concept', ''),
                    'example': b.get('example', ''),
                    'formula': b.get('formula', ''),
                    'question_text': check.get('question', ''),
                    'question_type': check.get('type', 'mcq'),
                    'options': check.get('options') or [check.get('answer'), "None of the above"],
                    'answer': check.get('answer', ''),
                    'tolerance': check.get('tolerance', 0.0),
                    'explanation': check.get('explanation', ''),
                    'difficulty': b.get('difficulty', 'medium'),
                    'bite_type': 'numerical' if check.get('type') == 'numerical' else 'conceptual',
                    'estimated_minutes': b.get('estimated_minutes', 5),
                    'tags': b.get('tags', []),
                    'is_free': True # For the initial seed
                }
            )
            ingested_bites.append(bite)
        
        # Auto-bundle
        candidate = Candidate.objects.first() # Assign to first user as creator
        if candidate:
            bundle, _ = MarketplaceBundle.objects.get_or_create(
                paper_code=paper_code,
                defaults={
                    'title': f"{paper_code} Roadmap",
                    'description': f"Comprehensive roadmap for {paper_code}",
                    'price': 0.0,
                    'creator': candidate,
                    'status': 'verified'
                }
            )
            bundle.bites.add(*ingested_bites)

if __name__ == "__main__":
    files = ["abm_batch_1.json", "bfm_batch_1.json", "brbl_batch_1.json"]
    for f in files:
        seed_file(f)
    print("Seeding complete.")

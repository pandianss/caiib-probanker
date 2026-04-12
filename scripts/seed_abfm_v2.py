import os
import django
import json
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import Bite, MarketplaceBundle, Candidate

def seed_abfm_batch(filename):
    file_path = os.path.join('curriculum', filename)
    if not os.path.exists(file_path):
        print(f"File {file_path} not found.")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
        print(f"Seeding {len(data)} high-fidelity ABFM bites...")
        
        ingested_bites = []
        for b in data:
            bite, created = Bite.objects.update_or_create(
                bite_id=b['bite_id'],
                defaults={
                    'paper_code': b['paper_code'],
                    'module': b['module'],
                    'chapter': b['chapter'],
                    'title': b['title'],
                    'concept': b['concept'],
                    'example': b.get('example', ''),
                    'formula': b.get('formula', ''),
                    'question_text': b['question_text'],
                    'question_type': b.get('question_type', 'mcq'),
                    'options': b['options'],
                    'answer': b['answer'],
                    'tolerance': b.get('tolerance', 0.0),
                    'explanation': b['explanation'],
                    'difficulty': b.get('difficulty', 'medium'),
                    'bite_type': b.get('bite_type', 'conceptual'),
                    'estimated_minutes': b.get('estimated_minutes', 5),
                    'tags': b.get('tags', []),
                    'is_free': True
                }
            )
            ingested_bites.append(bite)
        
        # Auto-bundle assignment
        candidate = Candidate.objects.first()
        if candidate:
            bundle = MarketplaceBundle.objects.filter(paper_code='ABFM').first()
            if not bundle:
                bundle = MarketplaceBundle.objects.create(
                    paper_code='ABFM',
                    title="ABFM: Complete Learning Engine",
                    description="12-Module High-Fidelity Curriculum",
                    price=0.0,
                    creator=candidate,
                    status='verified'
                )
            bundle.bites.add(*ingested_bites)
            print(f"Success: {len(ingested_bites)} bites added to bundle.")

if __name__ == "__main__":
    import sys
    batch_file = sys.argv[1] if len(sys.argv) > 1 else 'abfm_batch_1.json'
    seed_abfm_batch(batch_file)

import os
import json
from django.core.management.base import BaseCommand
from django.conf import settings
from api.models import Bite

class Command(BaseCommand):
    help = 'Seeds CAIIB Bites from local JSON files'

    def handle(self, *args, **kwargs):
        data_dir = os.path.join(settings.BASE_DIR, 'api', 'data')
        
        if not os.path.exists(data_dir):
            self.stdout.write(self.style.ERROR(f"Data directory {data_dir} does not exist."))
            return
            
        bites_seeded = 0
        
        for filename in os.listdir(data_dir):
            if filename.endswith('_bites.json'):
                filepath = os.path.join(data_dir, filename)
                with open(filepath, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    
                paper_code = data.get('paper_code', '')
                bites = data.get('bites', [])
                total_bites = len(bites)
                free_limit = total_bites // 2 # Half of the bites are free
                
                for idx, b in enumerate(bites):
                    is_free = idx < free_limit
                    check = b.get('check_question', {})
                    Bite.objects.update_or_create(
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
                            'options': check.get('options', []),
                            'answer': check.get('answer', ''),
                            'tolerance': check.get('tolerance', 0.0),
                            'explanation': check.get('explanation', ''),
                            'difficulty': b.get('difficulty', 'medium'),
                            'bite_type': 'numerical' if check.get('type') == 'numerical' else 'conceptual',
                            'estimated_minutes': b.get('estimated_minutes', 5),
                            'tags': b.get('tags', []),
                            'is_free': is_free
                        }
                    )
                    bites_seeded += 1
                self.stdout.write(self.style.SUCCESS(f'Successfully loaded {len(bites)} bites from {filename}'))
                
        self.stdout.write(self.style.SUCCESS(f'Done! Total bites seeded: {bites_seeded}'))

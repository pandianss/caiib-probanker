from django.core.management.base import BaseCommand
from api.services.content_service import ContentService

class Command(BaseCommand):
    help = 'Seeds CAIIB content into MongoDB'

    def handle(self, *args, **options):
        content_service = ContentService()
        if content_service.use_fallback:
            self.stdout.write(self.style.WARNING('MongoDB not connected. Seeding skipped.'))
            return

        db = content_service.db
        
        # 1. Clear existing content
        db.questions.delete_many({})
        db.flashcards.delete_many({})

        # 2. Seed Numericals (ABM/BFM)
        numericals = [
            # ABM - Statistics
            {
                "paper_code": "ABM", "module": "Statistics", "type": "numerical",
                "question": "If the correlation coefficient (r) is 0.8, what is the value of the Coefficient of Determination?",
                "answer": "0.64", "explanation": "Coefficient of Determination = r^2 = 0.8^2 = 0.64."
            },
        self.db = content_service.db
        
        # 1. Clear existing content to avoid duplicates for now
        self.db.flashcards.delete_many({})
        self.db.questions.delete_many({})
        
        data_dir = os.path.join(settings.BASE_DIR, 'api', 'data')
        if not os.path.exists(data_dir):
            self.stdout.write(self.style.ERROR('Data directory not found'))
            return

        total_flashcards = 0
        total_questions = 0

        for filename in os.listdir(data_dir):
            if filename.endswith('_content.json'):
                with open(os.path.join(data_dir, filename), 'r') as f:
                    data = json.load(f)
                    
                    if 'flashcards' in data:
                        self.db.flashcards.insert_many(data['flashcards'])
                        total_flashcards += len(data['flashcards'])
                    
                    if 'questions' in data:
                        self.db.questions.insert_many(data['questions'])
                        total_questions += len(data['questions'])

        self.stdout.write(self.style.SUCCESS(
            f'Successfully seeded {total_flashcards} flashcards and {total_questions} questions from JSON repos.'
        ))

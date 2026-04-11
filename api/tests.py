from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from .models import Candidate, PaperProgress, SRSMetadata, Bite, BiteAttempt
from .services.scoring_service import ScoringService
from .services.srs_service import SRSService

class BiteServiceTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test_user', password='password')
        self.candidate = Candidate.objects.create(user=self.user)
        self.bite = Bite.objects.create(
            bite_id='B1', paper_code='ABM', module='M1', title='T1',
            concept='C1', question_text='Q1', question_type='mcq',
            answer='A', explanation='E'
        )

    def test_bite_attempt_creation(self):
        BiteAttempt.objects.create(candidate=self.candidate, bite=self.bite, user_answer='A', is_correct=True)
        self.assertEqual(self.candidate.bite_attempts.count(), 1)
        self.assertTrue(self.candidate.bite_attempts.first().is_correct)

class SRSServiceTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test_user', password='password')
        self.candidate = Candidate.objects.create(user=self.user)
        self.meta = SRSMetadata.objects.create(candidate=self.candidate, card_id='1', next_review=timezone.now())

    def test_sm2_quality_0_resets_interval(self):
        self.meta.interval = 10
        self.meta.repetition_count = 5
        SRSService().update_card(self.meta, 0) # Failed totally
        self.assertEqual(self.meta.interval, 1)
        self.assertEqual(self.meta.repetition_count, 0)
        
    def test_sm2_quality_5_grows_interval(self):
        self.meta.interval = 1
        self.meta.repetition_count = 1
        SRSService().update_card(self.meta, 5) # Perfect response
        # 1 day * default ease_factor 2.5 = 2.5 -> rounded to 3
        self.assertTrue(self.meta.interval > 1)
        self.assertEqual(self.meta.repetition_count, 2)

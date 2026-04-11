from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from .models import Candidate, ExamSession, QuestionAttempt, PaperProgress, SRSMetadata
from .services.scoring_service import ScoringService
from .services.srs_service import SRSService

class ScoringServiceTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test_user', password='password')
        self.candidate = Candidate.objects.create(user=self.user)
        self.session = ExamSession.objects.create(candidate=self.candidate, paper_code='ABM', status='STARTED')

    def test_pass_criteria_45_marks(self):
        QuestionAttempt.objects.create(session=self.session, question_id='1', is_correct=True, marks_obtained=45)
        ScoringService.calculate_session_result(self.session)
        self.assertTrue(self.session.is_pass)
        self.assertEqual(self.session.final_score, 45.0)

    def test_fail_criteria_44_marks(self):
        QuestionAttempt.objects.create(session=self.session, question_id='1', is_correct=True, marks_obtained=44)
        ScoringService.calculate_session_result(self.session)
        self.assertFalse(self.session.is_pass)
        self.assertEqual(self.session.final_score, 44.0)

    def test_aggregate_pass_criteria(self):
        # Need 5 papers with >=45 each and >=250 total
        papers = ['ABM', 'BFM', 'ABFM', 'BRBL', 'RURAL']
        scores = [50, 50, 50, 50, 50] # Total 250
        for p, s in zip(papers, scores):
            PaperProgress.objects.create(candidate=self.candidate, paper_code=p, current_score=s, is_passed=True)
            
        success, msg = ScoringService.check_aggregate_pass(self.candidate)
        self.assertTrue(success)

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

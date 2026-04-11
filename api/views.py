import os
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.utils import timezone
from django.contrib.auth.models import User
from .models import Candidate, PaperProgress, SRSMetadata, ExamSession, QuestionAttempt
from .serializers import CandidateSerializer, PaperProgressSerializer, SRSMetadataSerializer
from .services.content_service import ContentService

from .services.srs_service import SRSService
from .services.tamkot_service import TAMKOTService
from .services.scoring_service import ScoringService

content_service = ContentService()
srs_service = SRSService()
tamkot_service = TAMKOTService()
scoring_service = ScoringService()

class SyllabusView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        structure = content_service.get_syllabus_structure()
        return Response(structure)

class CandidateProgressView(APIView):
    # For now, we mock the 'user' as the first one or create one for dev
    def get(self, request):
        user, _ = User.objects.get_or_create(username='dev_user', defaults={'email': 'dev@example.com'})
        candidate, _ = Candidate.objects.get_or_create(user=user)
        serializer = CandidateSerializer(candidate)
        return Response(serializer.data)

class PaperContentView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, paper_code):
        questions = content_service.get_questions(paper_code)
        flashcards = content_service.get_flashcards(paper_code)
        return Response({
            "paper_code": paper_code,
            "questions": questions,
            "flashcards": flashcards
        })

class SelectElectiveView(APIView):
    def post(self, request):
        elective_code = request.data.get('elective_code')
        if not elective_code:
            return Response({"error": "elective_code is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        user, _ = User.objects.get_or_create(username='dev_user', defaults={'email': 'dev@example.com'})
        candidate, _ = Candidate.objects.get_or_create(user=user)
        candidate.selected_elective = elective_code
        candidate.save()
        
        return Response({"status": "elective selected", "candidate": CandidateSerializer(candidate).data})

class DueFlashcardsView(APIView):
    def get(self, request):
        user, _ = User.objects.get_or_create(username='dev_user', defaults={'email': 'dev@example.com'})
        candidate, _ = Candidate.objects.get_or_create(user=user)
        due_metadata = srs_service.get_due_cards(candidate)
        
        # Combine metadata with content from MongoDB
        response_data = []
        for meta in due_metadata:
            # In a real app, we'd batch fetch from MongoDB
            # For now, we mock some content if MongoDB is unavailable
            card_content = {"id": meta.card_id, "front": "Front of " + meta.card_id, "back": "Back"}
            response_data.append({
                "metadata": SRSMetadataSerializer(meta).data,
                "content": card_content
            })
        return Response(response_data)

class RecordReviewView(APIView):
    def post(self, request):
        card_id = request.data.get('card_id')
        quality = request.data.get('quality') # 0-5
        
        if card_id is None or quality is None:
            return Response({"error": "card_id and quality are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        user, _ = User.objects.get_or_create(username='dev_user', defaults={'email': 'dev@example.com'})
        candidate, _ = Candidate.objects.get_or_create(user=user)
        metadata, _ = SRSMetadata.objects.get_or_create(
            candidate=candidate, 
            card_id=card_id,
            defaults={'next_review': timezone.now()}
        )
        
        srs_service.update_card(metadata, int(quality))
        return Response({"status": "updated", "next_review": metadata.next_review})

class KnowledgeTracingView(APIView):
    def get(self, request):
        user, _ = User.objects.get_or_create(username='dev_user', defaults={'email': 'dev@example.com'})
        candidate, _ = Candidate.objects.get_or_create(user=user)
        progress = PaperProgressSerializer(candidate.progress.all(), many=True).data
        
        # In a real app, logs would be fetched from a UserActivity model
        # For now, we use dummy logs to demonstrate TAMKOT
        dummy_logs = [(0, 10), (1, 15), (0, 20)] # (activity_type, concept_id)
        
        passing_prob = tamkot_service.predict_passing_probability(dummy_logs)
        thresholds = tamkot_service.get_passing_thresholds(progress)
        
        return Response({
            "passing_probability": passing_prob,
            "exam_status": thresholds,
            "recommendation": "Focus on numerical problems in ABM to improve aggregate." if passing_prob < 0.6 else "Maintaining steady progress."
        })

class StartExamView(APIView):
    def post(self, request):
        paper_code = request.data.get('paper_code')
        if not paper_code:
            return Response({"error": "paper_code is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        user, _ = User.objects.get_or_create(username='dev_user', defaults={'email': 'dev@example.com'})
        candidate, _ = Candidate.objects.get_or_create(user=user)
        session = ExamSession.objects.create(
            candidate=candidate,
            paper_code=paper_code,
            status='STARTED'
        )
        
        # Get randomized questions
        questions = content_service.get_questions(paper_code)
        
        return Response({
            "session_id": session.id,
            "paper_code": paper_code,
            "questions": questions
        })

class SubmitExamView(APIView):
    def post(self, request):
        session_id = request.data.get('session_id')
        answers = request.data.get('answers') # List of {id, value}
        
        if not session_id or answers is None:
            return Response({"error": "session_id and answers are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            session = ExamSession.objects.get(id=session_id)
        except ExamSession.DoesNotExist:
            return Response({"error": "Session not found"}, status=status.HTTP_404_NOT_FOUND)
            
        # Record attempts
        for ans in answers:
            QuestionAttempt.objects.create(
                session=session,
                question_id=ans['id'],
                user_answer=ans['value'],
                is_correct=True, # Mock: everything is correct for testing
                marks_obtained=1.0 
            )
            
        scoring_service.calculate_session_result(session)
        result = scoring_service.check_aggregate_pass(session.candidate)
        
        return Response({
            "score": session.final_score,
            "is_pass": session.is_pass,
            "aggregate_status": result[1]
        })

class AdminContentAPI(APIView):
    """
    Portal for pushing real-time regulatory updates (RBI Circulars, etc.)
    In production, this would use a more robust OAuth2 scope.
    """
    def post(self, request):
        secret_key = request.headers.get('X-Admin-Secret')
        if secret_key != os.getenv('ADMIN_SECRET', 'caiib_secret_2026'):
            return Response({"error": "Unauthorized"}, status=status.HTTP_401_UNAUTHORIZED)
            
        content_type = request.data.get('type') # 'flashcard' or 'question'
        payload = request.data.get('payload')
        
        if content_service.use_fallback:
            return Response({
                "status": "mock_push_success", 
                "info": "MongoDB fallback active. Content not persisted but API response verified."
            })

        if content_type == 'flashcard':
            # Add with high priority
            payload['priority'] = 'high'
            content_service.db.flashcards.insert_one(payload)
            return Response({"status": "flashcard pushed", "id": str(payload.get('_id'))})
        elif content_type == 'question':
            content_service.db.questions.insert_one(payload)
            return Response({"status": "question pushed"})
            
        return Response({"error": "invalid type"}, status=status.HTTP_400_BAD_REQUEST)

class CaseStudyView(APIView):
    """
    Returns scenario-based case studies for a specific paper.
    Each study contains a scenario and a set of dependent questions.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, paper_code):
        case_studies = content_service.get_case_studies(paper_code)
        return Response(case_studies)

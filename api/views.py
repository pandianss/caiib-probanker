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
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        email = request.data.get('email', '')
        
        if not username or not password:
            return Response({"error": "username and password required"}, status=status.HTTP_400_BAD_REQUEST)
        
        if User.objects.filter(username=username).exists():
            return Response({"error": "user already exists"}, status=status.HTTP_400_BAD_REQUEST)
            
        user = User.objects.create_user(username=username, password=password, email=email)
        candidate = Candidate.objects.create(user=user)
        
        # Log IP consent
        if 'consent' in request.data:
            from .models import ConsentLog
            ip = request.META.get('REMOTE_ADDR')
            ConsentLog.objects.create(candidate=candidate, consent_type='TOS_DPDP_2023', ip_address=ip)
            
        return Response({"status": "user created successfully"}, status=status.HTTP_201_CREATED)

class BaseAuthenticatedView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_candidate(self, request):
        candidate, _ = Candidate.objects.get_or_create(user=request.user)
        return candidate

content_service = ContentService()
srs_service = SRSService()
tamkot_service = TAMKOTService()
scoring_service = ScoringService()

class SyllabusView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        structure = content_service.get_syllabus_structure()
        return Response(structure)

class CandidateProgressView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
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

class SelectElectiveView(BaseAuthenticatedView):
    def post(self, request):
        elective_code = request.data.get('elective_code')
        if not elective_code:
            return Response({"error": "elective_code is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        candidate = self.get_candidate(request)
        candidate.selected_elective = elective_code
        candidate.save()
        
        return Response({"status": "elective selected", "candidate": CandidateSerializer(candidate).data})

class DueFlashcardsView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
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

class RecordReviewView(BaseAuthenticatedView):
    def post(self, request):
        card_id = request.data.get('card_id')
        quality = request.data.get('quality') # 0-5
        
        if card_id is None or quality is None:
            return Response({"error": "card_id and quality are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        candidate = self.get_candidate(request)
        metadata, _ = SRSMetadata.objects.get_or_create(
            candidate=candidate,  
            card_id=card_id,
            defaults={'next_review': timezone.now()}
        )
        
        srs_service.update_card(metadata, int(quality))
        return Response({"status": "updated", "next_review": metadata.next_review})

class KnowledgeTracingView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        progress = PaperProgressSerializer(candidate.progress.all(), many=True).data
        
        from .models import UserActivity
        user_logs = UserActivity.objects.filter(candidate=candidate).order_by('timestamp').values_list('activity_type', 'concept_id')
        
        passing_prob = tamkot_service.predict_passing_probability(list(user_logs))
        thresholds = tamkot_service.get_passing_thresholds(progress)
        
        return Response({
            "passing_probability": passing_prob,
            "exam_status": thresholds,
            "recommendation": "Focus on numerical problems in ABM to improve aggregate." if passing_prob < 0.6 else "Maintaining steady progress."
        })

class StartExamView(BaseAuthenticatedView):
    def post(self, request):
        paper_code = request.data.get('paper_code')
        if not paper_code:
            return Response({"error": "paper_code is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        candidate = self.get_candidate(request)
        session = ExamSession.objects.create(
            candidate=candidate,
            paper_code=paper_code,
            status='STARTED'
        )
        
        import random
        questions = content_service.get_questions(paper_code)
        if hasattr(questions, '__iter__') and not isinstance(questions, dict):
            questions = list(questions)
            random.shuffle(questions)
        else:
            questions = list(questions)
            
        return Response({
            "session_id": session.id,
            "paper_code": paper_code,
            "questions": questions
        })

class SubmitExamView(BaseAuthenticatedView):
    def post(self, request):
        session_id = request.data.get('session_id')
        answers = request.data.get('answers') # List of {id, value}
        
        if not session_id or answers is None:
            return Response({"error": "session_id and answers are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            session = ExamSession.objects.get(id=session_id)
        except ExamSession.DoesNotExist:
            return Response({"error": "Session not found"}, status=status.HTTP_404_NOT_FOUND)
            
        questions = content_service.get_questions(session.paper_code)
        q_dict = {str(q['id']) if 'id' in q else str(q.get('_id', '')): q for q in questions}
        candidate = session.candidate
        
        for ans in answers:
            q_id = str(ans['id'])
            user_val = str(ans['value']).strip().lower()
            q_obj = q_dict.get(q_id)
            
            is_correct = False
            marks = 0.0
            
            if q_obj:
                correct_ans = str(q_obj.get('answer', '')).strip().lower()
                q_type = q_obj.get('type', 'mcq')
                
                if q_type == 'numerical':
                    try:
                        is_correct = abs(float(user_val) - float(correct_ans)) <= 0.01
                    except ValueError:
                        is_correct = False
                else:
                    is_correct = (user_val == correct_ans)
                
                marks = 1.0 if is_correct else 0.0
                
            QuestionAttempt.objects.create(
                session=session,
                question_id=ans['id'],
                user_answer=ans['value'],
                is_correct=is_correct,
                marks_obtained=marks 
            )
            
            # SRS Spaced Repetition Integration
            meta, _ = SRSMetadata.objects.get_or_create(
                candidate=candidate,
                card_id=q_id,
                defaults={'next_review': timezone.now()}
            )
            if is_correct:
                if ans.get('time_taken_seconds', 0) < 20:
                    srs_service.update_card(meta, 5)
            else:
                srs_service.update_card(meta, 1)
            
            # Log Activity
            from .models import UserActivity
            UserActivity.objects.create(
                candidate=candidate,
                activity_type=1, # Question
                concept_id=int(q_obj.get('module_id', 0)) if q_obj else 0
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

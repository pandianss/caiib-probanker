import os
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.utils import timezone
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import Candidate, PaperProgress, SRSMetadata, Bite, BiteAttempt
from .serializers import (
    CandidateSerializer, PaperProgressSerializer, SRSMetadataSerializer, 
    BiteSerializer, BiteListSerializer, BiteDetailSerializer
)
# Services are lazy-loaded within getter functions to prevent startup hangs
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        password = request.data.get('password')
        email = request.data.get('email', '').strip()
        mobile = request.data.get('mobile_number', '').strip()
        name = request.data.get('name', '').strip()
        elective = request.data.get('elective', '').strip()
        
        if not email or not mobile or not password or not name or not elective:
            return Response({"error": "All fields including elective are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        if User.objects.filter(email__iexact=email).exists():
            return Response({"error": "This email address is already registered."}, status=status.HTTP_400_BAD_REQUEST)
            
        if Candidate.objects.filter(mobile_number=mobile).exists():
            return Response({"error": "This mobile number is already registered."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            validate_password(password)
        except ValidationError as e:
            return Response({"error": " ".join(e.messages)}, status=status.HTTP_400_BAD_REQUEST)
            
        base_username = f"{email.split('@')[0]}_{mobile[-4:]}"
        username = base_username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1
            
        first_name = name.split(' ')[0] if name else ''
        last_name = ' '.join(name.split(' ')[1:]) if ' ' in name else ''
        
        user = User.objects.create_user(username=username, password=password, email=email, first_name=first_name, last_name=last_name)
        candidate = Candidate.objects.create(
            user=user, 
            mobile_number=mobile, 
            selected_elective=elective
        )
        
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

    def update_streak(self, candidate):
        from datetime import date, timedelta
        today = date.today()
        if candidate.last_study_date is None:
            candidate.study_streak = 1
        elif candidate.last_study_date == today:
            return  # Already studied today
        elif candidate.last_study_date == today - timedelta(days=1):
            candidate.study_streak += 1
        else:
            candidate.study_streak = 1  # Streak broken
        candidate.last_study_date = today
        candidate.save(update_fields=['study_streak', 'last_study_date'])

def get_srs_service():
    if not hasattr(get_srs_service, "_service"):
        from .services.srs_service import SRSService
        get_srs_service._service = SRSService()
    return get_srs_service._service

# TODO: Integrate these services into the v3 flow when ready
# Removed from import path to optimize startup speed
def get_tamkot_service(): return None
def get_scoring_service(): return None
def get_content_service(): return None

class TodaysBiteView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        
        # 1. Check SRS due
        due = SRSMetadata.objects.filter(
            candidate=candidate, 
            next_review__lte=timezone.now()
        ).order_by('next_review').first()
        
        if due:
            try:
                bite = Bite.objects.get(bite_id=due.card_id)
                srs_due_count = SRSMetadata.objects.filter(candidate=candidate, next_review__lte=timezone.now()).count()
                return Response({'bite': BiteDetailSerializer(bite).data, 'mode': 'review', 'srs_due_count': srs_due_count})
            except Bite.DoesNotExist:
                pass
        
        # 2. Find next unseen bite from weakest paper
        seen_ids = BiteAttempt.objects.filter(candidate=candidate).values_list('bite__bite_id', flat=True).distinct()
        weakest = candidate.progress.order_by('current_score').first()
        paper_filter = weakest.paper_code if weakest else candidate.selected_elective or 'ABM'
        
        bite = Bite.objects.exclude(bite_id__in=seen_ids).filter(paper_code=paper_filter).first()
        if not bite:
            bite = Bite.objects.exclude(bite_id__in=seen_ids).first()
        
        if not bite:
            return Response({'message': 'all_bites_seen', 'total_bites': Bite.objects.count()})
        
        return Response({'bite': BiteDetailSerializer(bite).data, 'mode': 'new'})

class SubmitBiteView(BaseAuthenticatedView):
    def post(self, request):
        candidate = self.get_candidate(request)
        bite_id = request.data.get('bite_id')
        user_answer = str(request.data.get('answer', '')).strip()
        time_taken = request.data.get('time_taken_seconds', 0)
        
        try:
            bite = Bite.objects.get(bite_id=bite_id)
        except Bite.DoesNotExist:
            return Response({'error': 'Bite not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Grade answer
        is_correct = False
        if bite.question_type == 'mcq':
            is_correct = user_answer.lower() == bite.answer.lower()
        elif bite.question_type == 'numerical':
            try:
                is_correct = abs(float(user_answer) - float(bite.answer)) <= bite.tolerance
            except ValueError:
                is_correct = False
        
        # SRS quality mapping: correct+fast=5, correct+slow=4, wrong=1
        if is_correct:
            srs_quality = 5 if time_taken < 30 else 4
        else:
            srs_quality = 1
        
        # Update SRS
        meta, _ = SRSMetadata.objects.get_or_create(
            candidate=candidate, card_id=bite_id,
            defaults={'next_review': timezone.now()}
        )
        get_srs_service().update_card(meta, srs_quality)
        
        # Record attempt
        attempt = BiteAttempt.objects.create(
            candidate=candidate, bite=bite,
            user_answer=user_answer, is_correct=is_correct,
            time_taken_seconds=time_taken
        )
        
        # Update paper progress score - we map mastered bites implicitly
        # Update paper progress score - idempotent calculation
        progress, _ = PaperProgress.objects.get_or_create(candidate=candidate, paper_code=bite.paper_code)
        if is_correct:
             # Only increment if this is a fresh mastery
             already_mastered = BiteAttempt.objects.filter(
                 candidate=candidate, bite=bite, is_correct=True
             ).exclude(id=attempt.id).exists()
             
             if not already_mastered:
                 progress.current_score = float(
                     BiteAttempt.objects.filter(
                         candidate=candidate,
                         bite__paper_code=bite.paper_code,
                         is_correct=True
                     ).values('bite').distinct().count()
                 )
                 progress.save()
             
        self.update_streak(candidate)
        
        return Response({
            'is_correct': is_correct,
            'correct_answer': bite.answer,
            'explanation': bite.explanation,
            'next_review': meta.next_review,
            'srs_quality': srs_quality,
        })

class CandidateProgressView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        serializer = CandidateSerializer(candidate)
        return Response(serializer.data)

class ProfileUpdateView(BaseAuthenticatedView):
    def put(self, request):
        candidate = self.get_candidate(request)
        name = request.data.get('name', '').strip()
        if name:
            first_name = name.split(' ')[0]
            last_name = ' '.join(name.split(' ')[1:]) if ' ' in name else ''
            candidate.user.first_name = first_name
            candidate.user.last_name = last_name
            candidate.user.save()
        
        mobile = request.data.get('mobile_number', '').strip()
        if mobile:
            candidate.mobile_number = mobile
            candidate.save()
            
        return Response({"status": "profile updated"})

class SelectElectiveView(BaseAuthenticatedView):
    def post(self, request):
        candidate = self.get_candidate(request)
        elective = request.data.get('elective')
        if elective:
            candidate.selected_elective = elective
            candidate.save()
            return Response({"status": "elective updated"})
        return Response({"error": "elective is required"}, status=status.HTTP_400_BAD_REQUEST)

class KnowledgeTracingView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        # In a real app, we'd fetch activity logs and pass to TAMKOT
        # For now, we return a mock probability based on mastery
        total_bites = Bite.objects.count()
        mastered = candidate.bite_attempts.filter(is_correct=True).values('bite').distinct().count()
        prob = (mastered / total_bites) if total_bites > 0 else 0.5
        
        return Response({
            "passing_probability": prob,
            "status": "KEEP_STUDYING" if prob < 0.7 else "READY_FOR_EXAM"
        })

class PaperBitesView(BaseAuthenticatedView):
    def get(self, request, paper_code):
        bites = Bite.objects.filter(paper_code=paper_code).order_by('module', 'bite_id')
        serializer = BiteListSerializer(bites, many=True)
        return Response(serializer.data)

class CandidateStatsView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        
        total_attempts = BiteAttempt.objects.filter(candidate=candidate).count()
        correct_attempts = BiteAttempt.objects.filter(candidate=candidate, is_correct=True).count()
        accuracy = round((correct_attempts / total_attempts * 100) if total_attempts > 0 else 0, 1)
        
        # Last 7 days activity
        from datetime import date, timedelta
        today = date.today()
        activity = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            studied = BiteAttempt.objects.filter(
                candidate=candidate,
                attempted_at__date=day
            ).exists()
            activity.append({'date': day.isoformat(), 'studied': studied})
        
        return Response({
            'total_attempts': total_attempts,
            'correct_attempts': correct_attempts,
            'accuracy_percent': accuracy,
            'activity_last_7_days': activity,
            'study_streak': candidate.study_streak,
        })

class MasteredBiteIdsView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        mastered_ids = list(
            BiteAttempt.objects.filter(candidate=candidate, is_correct=True)
            .values_list('bite__bite_id', flat=True)
            .distinct()
        )
        return Response({'mastered_ids': mastered_ids})

class DueBitesView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        due_metadata = SRSMetadata.objects.filter(
            candidate=candidate,
            next_review__lte=timezone.now()
        ).order_by('next_review')
        
        due_bites = []
        for meta in due_metadata[:20]:  # Cap at 20 per session for mobile performance
            try:
                bite = Bite.objects.get(bite_id=meta.card_id)
                due_bites.append(BiteDetailSerializer(bite).data)
            except Bite.DoesNotExist:
                pass
        
        return Response({
            'due_count': due_metadata.count(),
            'bites': due_bites
        })

class BiteHistoryView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        attempts = BiteAttempt.objects.filter(candidate=candidate).select_related('bite').order_by('-attempted_at')[:50]
        return Response([{
            'bite_id': a.bite.bite_id,
            'title': a.bite.title,
            'paper_code': a.bite.paper_code,
            'is_correct': a.is_correct,
            'attempted_at': a.attempted_at,
        } for a in attempts])

class DeleteAccountView(BaseAuthenticatedView):
    def post(self, request):
        user = request.user
        user.delete() # Cascade ensures Candidate is also deleted
        return Response({"status": "account deleted successfully"})

class PingView(APIView):
    permission_classes = [permissions.AllowAny]
    def get(self, request):
        return Response({"status": "pong"})



import os
import json
from django.views.generic import TemplateView
from rest_framework.parsers import MultiPartParser, FormParser
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.utils import timezone
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import (
    Candidate, PaperProgress, SRSMetadata, Bite, BiteAttempt,
    MarketplaceBundle, BundleAccess
)
from .serializers import (
    CandidateSerializer, PaperProgressSerializer, SRSMetadataSerializer, 
    BiteSerializer, BiteListSerializer, BiteDetailSerializer,
    MarketplaceBundleSerializer
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

from rest_framework.throttling import UserRateThrottle

class BaseAuthenticatedView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [UserRateThrottle]

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
# Legacy getters removed to keep codebase clean.

class TodaysBiteView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        
        # 1. Monetization: Check daily limit for FREE tier
        subscription = getattr(candidate, 'subscription', None)
        if not subscription or subscription.plan_type == 'FREE':
            limit = subscription.daily_bites_limit if subscription else 20
            today_count = BiteAttempt.objects.filter(
                candidate=candidate, 
                attempted_at__date=timezone.now().date()
            ).count()
            
            if today_count >= limit:
                return Response({
                    'status': 'LIMIT_EXCEEDED',
                    'message': f'You have reached your daily limit of {limit} bites. Upgrade to PRO for unlimited access!',
                    'limit': limit
                }, status=status.HTTP_403_FORBIDDEN)

        # 2. Check SRS due
        due = SRSMetadata.objects.filter(
            candidate=candidate, 
            next_review__lte=timezone.now()
        ).order_by('next_review').first()
        
        if due:
            try:
                bite = Bite.objects.get(bite_id=due.card_id)
                srs_due_count = SRSMetadata.objects.filter(candidate=candidate, next_review__lte=timezone.now()).count()
                return Response({'bite': BiteDetailSerializer(bite, context={'request': request}).data, 'mode': 'review', 'srs_due_count': srs_due_count})
            except Bite.DoesNotExist:
                pass
        
        # 2. Find next unseen bite from weakest paper
        seen_ids = BiteAttempt.objects.filter(candidate=candidate).values_list('bite__bite_id', flat=True).distinct()
        
        ELECTIVE_TO_PAPER_CODE = {
            'RURAL': 'RURAL',
            'HRM': 'HRM',
            'IT_DB': 'IT_DB',
            'RISK': 'RISK',
            'CENTRAL': 'CENTRAL',
        }
        elective_paper = ELECTIVE_TO_PAPER_CODE.get(candidate.selected_elective, 'ABFM')
        weakest = candidate.progress.order_by('current_score').first()
        paper_filter = weakest.paper_code if weakest else elective_paper
        
        bite = Bite.objects.exclude(bite_id__in=seen_ids).filter(paper_code=paper_filter).first()
        
        # Fallback if selected paper has no more bites but ABFM does
        if not bite and paper_filter != 'ABFM':
            bite = Bite.objects.exclude(bite_id__in=seen_ids).filter(paper_code='ABFM').first()
        
        if not bite:
            return Response({'message': 'all_bites_seen', 'total_bites': Bite.objects.count()})
        
        return Response({'bite': BiteDetailSerializer(bite, context={'request': request}).data, 'mode': 'new'})

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
        
        def clean_answer(s):
            import re
            # Only remove trailing footnote-style markers like [1], [23]
            # preserving internal spaces and word characters
            return re.sub(r'\s*\[\d+\]\.?$', '', s.strip()).lower()

        if bite.question_type == 'mcq':
            is_correct = clean_answer(user_answer) == clean_answer(bite.answer)
        elif bite.question_type == 'numerical':
            try:
                is_correct = abs(float(user_answer) - float(bite.answer)) <= bite.tolerance
            except ValueError:
                is_correct = False
        
        # SRS quality mapping: correct+fast=5, correct+slow=4, wrong=1
        self_rating = int(request.data.get('self_rating', 0)) # 0 = not provided
        if is_correct:
            # Map user confidence to SM-2 quality
            quality_map = {
                0: 5 if time_taken < 30 else 4, # legacy tie-breaker
                1: 3, # correct but unsure -> minimum passing
                2: 4, # correct, getting it -> solid
                3: 5, # correct and confident -> excellent
            }
            srs_quality = quality_map.get(self_rating, 4)
        else:
            # Map user confidence to SM-2 quality (wrong answers)
            quality_map = {
                0: 1, # wrong, no rating
                1: 0, # wrong, still unsure -> blackout
                2: 2, # wrong but now understands -> poor recall
                3: 3, # wrong but now fully gets it -> passable (shaky)
            }
            srs_quality = quality_map.get(self_rating, 1)
        
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
            'srs_status': meta.status,
        })

    def patch(self, request):
        """Accept a self_rating patch after the initial answer was submitted."""
        candidate = self.get_candidate(request)
        bite_id = request.data.get('bite_id') or request.data.get('id')
        self_rating = int(request.data.get('self_rating', 0))

        try:
            metadata = SRSMetadata.objects.get(candidate=candidate, card_id=bite_id)
        except SRSMetadata.DoesNotExist:
            return Response({'error': 'Metadata not found'}, status=404)

        # Recalculate quality incorporating the new rating
        # We check the status as a proxy for the last correctness
        is_correct = metadata.status != 'WEAK'
        
        if is_correct:
            quality_map = {0: 4, 1: 3, 2: 4, 3: 5}
        else:
            quality_map = {0: 1, 1: 0, 2: 2, 3: 3}
            
        quality = quality_map.get(self_rating, 4 if is_correct else 1)
        get_srs_service().update_card(metadata, quality)
        
        return Response({
            'srs_status': metadata.status, 
            'next_review': metadata.next_review.isoformat(),
            'srs_quality': quality
        })

class CandidateProgressView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        
        # Auto-initialize progress trackers for any paper that has bites
        active_papers = Bite.objects.values_list('paper_code', flat=True).distinct()
        for p_code in active_papers:
            PaperProgress.objects.get_or_create(candidate=candidate, paper_code=p_code)
            
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
            if Candidate.objects.filter(mobile_number=mobile).exclude(pk=candidate.pk).exists():
                return Response(
                    {"error": "This mobile number is already registered to another account."},
                    status=status.HTTP_400_BAD_REQUEST
                )
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
                due_bites.append(BiteDetailSerializer(bite, context={'request': request}).data)
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


class MarketplaceListView(BaseAuthenticatedView):
    """List all bundles that have been verified by admin."""
    def get(self, request):
        bundles = MarketplaceBundle.objects.filter(status='verified').order_by('-created_at')
        serializer = MarketplaceBundleSerializer(bundles, many=True)
        return Response(serializer.data)

class PurchaseBundleView(BaseAuthenticatedView):
    """Mock purchase logic — in production, this would verify Razorpay payment."""
    def post(self, request):
        candidate = self.get_candidate(request)
        bundle_id = request.data.get('bundle_id')
        transaction_id = request.data.get('transaction_id', 'MOCK_TXN_000')

        try:
            bundle = MarketplaceBundle.objects.get(id=bundle_id, status='verified')
        except MarketplaceBundle.DoesNotExist:
            return Response({'error': 'Verified bundle not found'}, status=status.HTTP_404_NOT_FOUND)

        # Create access
        BundleAccess.objects.get_or_create(
            candidate=candidate, 
            bundle=bundle,
            defaults={'transaction_id': transaction_id}
        )

        return Response({'status': 'purchase successful', 'bundle_id': bundle_id})

class MyOwnedBundlesView(BaseAuthenticatedView):
    """List bundles the user has already purchased."""
    def get(self, request):
        candidate = self.get_candidate(request)
        owned_access = BundleAccess.objects.filter(candidate=candidate).select_related('bundle')
        bundles = [access.bundle for access in owned_access]
        serializer = MarketplaceBundleSerializer(bundles, many=True)
        return Response(serializer.data)

class BundleBitesView(BaseAuthenticatedView):
    """List bites within a specific bundle — requires ownership or verified status."""
    def get(self, request, bundle_id):
        candidate = self.get_candidate(request)
        try:
            bundle = MarketplaceBundle.objects.get(id=bundle_id)
            # Access check removed to allow roadmap preview. 
            # Redaction of premium content is now handled by the Serializer logic.
            
            bites = Bite.objects.filter(bundle=bundle).order_by('module', 'bite_id')
            serializer = BiteListSerializer(bites, many=True)
            return Response(serializer.data)
        except MarketplaceBundle.DoesNotExist:
            return Response({'error': 'Bundle not found'}, status=status.HTTP_404_NOT_FOUND)

class DeleteAccountView(BaseAuthenticatedView):
    def post(self, request):
        user = request.user
        user.delete() # Cascade ensures Candidate is also deleted
        return Response({"status": "account deleted successfully"})

class PingView(APIView):
    permission_classes = [permissions.AllowAny]
    def get(self, request):
        return Response({"status": "pong"})


from django.contrib.admin.views.decorators import staff_member_required
from django.utils.decorators import method_decorator

@method_decorator(staff_member_required, name='dispatch')
class IngestPortalView(TemplateView):
    template_name = 'api/ingest_portal.html'

class IngestUploadAPIView(APIView):
    permission_classes = [permissions.AllowAny] # We use custom secret key auth
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        secret = request.data.get('secret')
        # Simple secret check (matches setting or default)
        if secret != getattr(settings, 'ADMIN_SECRET', 'dev_secret'):
            return Response({'error': 'Unauthorized: Invalid Admin Secret'}, status=status.HTTP_401_UNAUTHORIZED)

        file_obj = request.FILES.get('file')
        if not file_obj:
            return Response({'error': 'No file uploaded'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            import io
            # Parse JSON with explicit UTF-8 encoding to support high-fidelity symbols (Σ, X̄, etc)
            content_str = file_obj.read().decode('utf-8')
            data = json.loads(content_str)
            paper_code = request.data.get('paper_code')
            if paper_code == 'AUTO' or not paper_code:
                paper_code = data.get('paper_code', 'UNKNOWN')
            
            # Normalize paper_code to standard short codes if descriptive
            if 'ABFM' in paper_code.upper(): paper_code = 'ABFM'
            elif 'ABM' in paper_code.upper(): paper_code = 'ABM'
            elif 'BFM' in paper_code.upper(): paper_code = 'BFM'
            elif 'BRBL' in paper_code.upper(): paper_code = 'BRBL'
            
            bites = data.get('bites', [])
            total_bites = len(bites)
            free_limit = total_bites // 2
            
            ingested_count = 0
            ingested_bites = []

            for idx, b in enumerate(bites):
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
                        'options': check.get('options') or ([check.get('answer'), "None of the above"] if check.get('type') != 'numerical' else []),
                        'answer': check.get('answer', ''),
                        'tolerance': check.get('tolerance', 0.0),
                        'explanation': check.get('explanation', ''),
                        'difficulty': b.get('difficulty', 'medium'),
                        'bite_type': 'numerical' if check.get('type') == 'numerical' else 'conceptual',
                        'estimated_minutes': b.get('estimated_minutes', 5),
                        'tags': b.get('tags', []),
                        'is_free': idx < free_limit
                    }
                )
                ingested_bites.append(bite)
                ingested_count += 1

            # Auto-bundle sync if requested
            bundle_id = None
            if request.data.get('auto_bundle') == 'true':
                candidate = Candidate.objects.filter(user__is_superuser=True).first() or Candidate.objects.first()
                bundle, _ = MarketplaceBundle.objects.get_or_create(
                    paper_code=paper_code,
                    defaults={
                        'title': f"{paper_code} Comprehensive Roadmap",
                        'description': f"Full curriculum roadmap for {paper_code} subject.",
                        'price': 399.0,
                        'creator': candidate,
                        'status': 'verified'
                    }
                )
                bundle.bites.set(ingested_bites)
                bundle_id = bundle.id

            return Response({
                'count': ingested_count,
                'paper_code': paper_code,
                'bundle_id': bundle_id,
                'status': 'success'
            })

        except Exception as e:
            return Response({'error': f'Ingestion failed: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

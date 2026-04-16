from rest_framework import serializers
from .models import (
    Candidate, PaperProgress, SRSMetadata, Bite, 
    MarketplaceBundle, BundleAccess
)

class MarketplaceBundleSerializer(serializers.ModelSerializer):
    creator_name = serializers.CharField(source='creator.user.username', read_only=True)
    bite_count = serializers.SerializerMethodField()

    class Meta:
        model = MarketplaceBundle
        fields = [
            'id', 'title', 'description', 'price', 'creator', 'creator_name', 
            'paper_code', 'status', 'bite_count', 'created_at'
        ]

    def get_bite_count(self, obj):
        return obj.bites.count()

class PaperProgressSerializer(serializers.ModelSerializer):
    total_bites = serializers.SerializerMethodField()
    mastered = serializers.FloatField(source='current_score') # aliasing current_score for ease of UI ingestion

    class Meta:
        model = PaperProgress
        fields = ['paper_code', 'mastered', 'total_bites', 'is_passed', 'last_activity']

    def get_total_bites(self, obj):
        return Bite.objects.filter(paper_code=obj.paper_code).count()

class SRSMetadataSerializer(serializers.ModelSerializer):
    class Meta:
        model = SRSMetadata
        fields = ['card_id', 'interval', 'ease_factor', 'next_review', 'repetition_count']

class BiteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bite
        fields = '__all__'

class BiteBaseSerializer(serializers.ModelSerializer):
    def to_representation(self, instance):
        ret = super().to_representation(instance)
        request = self.context.get('request')
        
        # Default access and locking status
        ret['is_locked'] = False
        
        # If bite is not free, check for bundle access
        if not instance.is_free:
            has_access = False
            if request and request.user.is_authenticated:
                candidate = getattr(request.user, 'candidate', None)
                if candidate:
                    # 1. Check if user owns the bundle this bite belongs to
                    if instance.bundle and BundleAccess.objects.filter(candidate=candidate, bundle=instance.bundle).exists():
                        has_access = True
                    # 2. Check for Tier based access (PRO or ELITE)
                    subscription = getattr(candidate, 'subscription', None)
                    if subscription and subscription.plan_type in ['PRO', 'ELITE'] and subscription.is_active:
                        has_access = True
                    # 3. Check if user is the creator
                    if instance.bundle and instance.bundle.creator == candidate:
                        has_access = True
            
            if not has_access:
                # Redact high-fidelity study content
                ret['concept'] = "🔒 Premium Content: Upgrade to PRO or purchase the bundle to unlock."
                if 'example' in ret: ret['example'] = "Locked"
                if 'formula' in ret: ret['formula'] = "Locked"
                if 'explanation' in ret: ret['explanation'] = "Locked"
                if 'question_text' in ret: ret['question_text'] = "🔒 This question is locked."
                if 'options' in ret: ret['options'] = []
                ret['is_locked'] = True
        
        return ret

class BiteListSerializer(BiteBaseSerializer):
    """Used for Library listing — lightweight but includes gated concept & question."""
    class Meta:
        model = Bite
        fields = [
            'id', 'bite_id', 'paper_code', 'module', 'chapter',
            'title', 'concept', 'question_text', 'question_type', 'options',
            'difficulty', 'bite_type', 'estimated_minutes', 'tags', 'is_free', 'bundle'
        ]

class BiteDetailSerializer(BiteBaseSerializer):
    """Full detail — used only when user starts a bite session."""
    class Meta:
        model = Bite
        fields = [
            'id', 'bite_id', 'paper_code', 'module', 'chapter',
            'title', 'concept', 'example', 'formula',
            'question_text', 'question_type', 'options',
            'difficulty', 'bite_type', 'estimated_minutes', 'is_free', 'bundle'
        ]

class CandidateSerializer(serializers.ModelSerializer):
    progress = PaperProgressSerializer(many=True, read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    total_attempts = serializers.SerializerMethodField()
    correct_attempts = serializers.SerializerMethodField()
    
    class Meta:
        model = Candidate
        fields = [
            'id', 'user', 'first_name', 'last_name', 'email', 'mobile_number', 
            'selected_elective', 'study_streak', 'last_study_date',
            'attempts_count', 'total_attempts', 'correct_attempts',
            'start_date', 'progress'
        ]

    def get_total_attempts(self, obj):
        from .models import BiteAttempt
        return BiteAttempt.objects.filter(candidate=obj).count()

    def get_correct_attempts(self, obj):
        from .models import BiteAttempt
        return BiteAttempt.objects.filter(candidate=obj, is_correct=True).count()

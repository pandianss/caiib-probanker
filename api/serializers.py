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

class BiteListSerializer(serializers.ModelSerializer):
    """Safe for Library listing — no answer fields."""
    class Meta:
        model = Bite
        fields = [
            'id', 'bite_id', 'paper_code', 'module', 'chapter',
            'title', 'difficulty', 'bite_type', 'estimated_minutes', 'tags', 'is_free'
        ]

class BiteDetailSerializer(serializers.ModelSerializer):
    """Full detail — used only when user starts a bite session."""
    class Meta:
        model = Bite
        fields = [
            'id', 'bite_id', 'paper_code', 'module', 'chapter',
            'title', 'concept', 'example', 'formula',
            'question_text', 'question_type', 'options',
            'difficulty', 'bite_type', 'estimated_minutes', 'is_free', 'bundle'
        ]

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        request = self.context.get('request')
        
        # If bite is not free, check for bundle access
        if not instance.is_free:
            has_access = False
            if request and request.user.is_authenticated:
                candidate = getattr(request.user, 'candidate', None)
                if candidate:
                    # Check if user owns the bundle this bite belongs to
                    if instance.bundle and BundleAccess.objects.filter(candidate=candidate, bundle=instance.bundle).exists():
                        has_access = True
                    # Check if user is the creator
                    if instance.bundle and instance.bundle.creator == candidate:
                        has_access = True
            
            if not has_access:
                # Redact high-fidelity study content
                ret['concept'] = "🔒 Premium Content: Purchase the bundle to unlock full curriculum bites."
                ret['example'] = "Locked"
                ret['formula'] = "Locked"
                ret['is_locked'] = True
            else:
                ret['is_locked'] = False
        else:
            ret['is_locked'] = False
            
        return ret

class CandidateSerializer(serializers.ModelSerializer):
    progress = PaperProgressSerializer(many=True, read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    
    class Meta:
        model = Candidate
        fields = [
            'id', 'user', 'first_name', 'last_name', 'email', 'mobile_number', 
            'selected_elective', 'study_streak', 'last_study_date',
            'attempts_count', 'start_date', 'progress'
        ]

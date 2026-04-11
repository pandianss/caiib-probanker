from rest_framework import serializers
from .models import Candidate, PaperProgress, SRSMetadata, Bite

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

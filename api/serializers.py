from rest_framework import serializers
from .models import Candidate, PaperProgress, SRSMetadata

class PaperProgressSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaperProgress
        fields = ['paper_code', 'current_score', 'is_passed', 'last_activity']

class SRSMetadataSerializer(serializers.ModelSerializer):
    class Meta:
        model = SRSMetadata
        fields = ['card_id', 'interval', 'ease_factor', 'next_review', 'repetition_count']

class CandidateSerializer(serializers.ModelSerializer):
    progress = PaperProgressSerializer(many=True, read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    
    class Meta:
        model = Candidate
        fields = ['id', 'user', 'first_name', 'last_name', 'email', 'mobile_number', 'selected_elective', 'attempts_count', 'start_date', 'progress']

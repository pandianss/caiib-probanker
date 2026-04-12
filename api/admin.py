from django.contrib import admin
from .models import (
    Candidate, Bite, BiteAttempt, PaperProgress, SRSMetadata, 
    MarketplaceBundle, BundleAccess, ConsentLog
)

@admin.register(Bite)
class BiteAdmin(admin.ModelAdmin):
    list_display = ['bite_id', 'paper_code', 'module', 'title', 'difficulty', 'question_type', 'is_free']
    list_filter = ['paper_code', 'difficulty', 'question_type', 'is_free']
    search_fields = ['title', 'concept', 'bite_id']
    ordering = ['paper_code', 'bite_id']

@admin.register(BiteAttempt)
class BiteAttemptAdmin(admin.ModelAdmin):
    list_display = ['candidate', 'bite', 'is_correct', 'time_taken_seconds', 'attempted_at']
    list_filter = ['is_correct', 'attempted_at']
    search_fields = ['candidate__user__username', 'bite__title']

@admin.register(Candidate)
class CandidateAdmin(admin.ModelAdmin):
    list_display = ['user', 'selected_elective', 'study_streak', 'last_study_date']
    search_fields = ['user__username', 'user__email', 'mobile_number']

@admin.register(PaperProgress)
class PaperProgressAdmin(admin.ModelAdmin):
    list_display = ['candidate', 'paper_code', 'current_score', 'is_passed', 'last_activity']
    list_filter = ['paper_code', 'is_passed']

@admin.register(SRSMetadata)
class SRSMetadataAdmin(admin.ModelAdmin):
    list_display = ['candidate', 'card_id', 'next_review', 'interval', 'repetition_count']
    search_fields = ['card_id', 'candidate__user__username']

@admin.register(MarketplaceBundle)
class MarketplaceBundleAdmin(admin.ModelAdmin):
    list_display = ['title', 'paper_code', 'price', 'status', 'creator']
    list_filter = ['status', 'paper_code']

@admin.register(BundleAccess)
class BundleAccessAdmin(admin.ModelAdmin):
    list_display = ['candidate', 'bundle', 'transaction_id', 'purchased_at']

@admin.register(ConsentLog)
class ConsentLogAdmin(admin.ModelAdmin):
    list_display = ['candidate', 'consent_type', 'ip_address', 'timestamp']

from django.contrib import admin

from .models import (
    Candidate, Bite, BiteAttempt, PaperProgress, SRSMetadata, ConsentLog, 
    MarketplaceBundle, BundleAccess
)

@admin.register(MarketplaceBundle)
class MarketplaceBundleAdmin(admin.ModelAdmin):
    list_display = ['title', 'price', 'creator', 'paper_code', 'status', 'created_at']
    list_filter = ['status', 'paper_code']
    actions = ['verify_bundle']

    def verify_bundle(self, request, queryset):
        queryset.update(status='verified')
    verify_bundle.short_description = "Approve and verify selected bundles for sale"

@admin.register(BundleAccess)
class BundleAccessAdmin(admin.ModelAdmin):
    list_display = ['candidate', 'bundle', 'purchased_at', 'transaction_id']
    readonly_fields = ['candidate', 'bundle', 'purchased_at', 'transaction_id']

@admin.register(Bite)
class BiteAdmin(admin.ModelAdmin):
    list_display = ['bite_id', 'paper_code', 'module', 'title', 'difficulty', 'bundle']
    list_filter = ['paper_code', 'difficulty', 'question_type', 'bundle']
    search_fields = ['title', 'concept', 'bite_id']

@admin.register(BiteAttempt)
class BiteAttemptAdmin(admin.ModelAdmin):
    list_display = ['candidate', 'bite', 'is_correct', 'time_taken_seconds', 'attempted_at']
    list_filter = ['is_correct']

@admin.register(Candidate)
class CandidateAdmin(admin.ModelAdmin):
    list_display = ['user', 'mobile_number', 'selected_elective', 'study_streak', 'last_study_date']
    search_fields = ['user__username', 'mobile_number']

admin.site.register(PaperProgress)
admin.site.register(SRSMetadata)
admin.site.register(ConsentLog)

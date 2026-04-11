from django.contrib import admin

from .models import Candidate, Bite, BiteAttempt, PaperProgress, SRSMetadata, ConsentLog

@admin.register(Bite)
class BiteAdmin(admin.ModelAdmin):
    list_display = ['bite_id', 'paper_code', 'module', 'title', 'difficulty', 'question_type']
    list_filter = ['paper_code', 'difficulty', 'question_type']
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

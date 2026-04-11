from django.urls import path
from .views import (
    SyllabusView, CandidateProgressView, PaperContentView, 
    SelectElectiveView, DueFlashcardsView, RecordReviewView,
    KnowledgeTracingView, StartExamView, SubmitExamView,
    AdminContentAPI, CaseStudyView
)

urlpatterns = [
    path('syllabus/', SyllabusView.as_view(), name='syllabus'),
    path('progress/', CandidateProgressView.as_view(), name='progress'),
    path('content/<str:paper_code>/', PaperContentView.as_view(), name='paper-content'),
    path('select-elective/', SelectElectiveView.as_view(), name='select-elective'),
    path('srs/due/', DueFlashcardsView.as_view(), name='srs-due'),
    path('srs/review/', RecordReviewView.as_view(), name='srs-review'),
    path('knowledge-tracing/', KnowledgeTracingView.as_view(), name='knowledge-tracing'),
    path('exam/submit/', SubmitExamView.as_view(), name='exam-submit'),
    path('admin/push/', AdminContentAPI.as_view(), name='admin-push'),
    path('case-studies/<str:paper_code>/', CaseStudyView.as_view(), name='case-studies'),
]

from django.urls import path
from .views import (
    CandidateProgressView, SelectElectiveView,
    KnowledgeTracingView, TodaysBiteView, PaperBitesView, SubmitBiteView,
    RegisterView, TokenObtainPairView, TokenRefreshView, ProfileUpdateView,
    DeleteAccountView, PingView
)

urlpatterns = [
    path('auth/register/', RegisterView.as_view(), name='auth-register'),
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('progress/', CandidateProgressView.as_view(), name='progress'),
    path('profile/update/', ProfileUpdateView.as_view(), name='profile-update'),
    path('select-elective/', SelectElectiveView.as_view(), name='select-elective'),
    path('knowledge-tracing/', KnowledgeTracingView.as_view(), name='knowledge-tracing'),
    path('bites/today/', TodaysBiteView.as_view(), name='bites-today'),
    path('bites/submit/', SubmitBiteView.as_view(), name='submit-bite'),
    path('bites/<str:paper_code>/', PaperBitesView.as_view(), name='paper-bites'),
    path('auth/delete/', DeleteAccountView.as_view(), name='delete-account'),
    path('ping/', PingView.as_view(), name='ping'),
]

from django.urls import path
from .views import (
    CandidateProgressView, SelectElectiveView,
    KnowledgeTracingView, TodaysBiteView, PaperBitesView, SubmitBiteView,
    RegisterView, TokenObtainPairView, TokenRefreshView, ProfileUpdateView,
    DeleteAccountView, PingView, CandidateStatsView, MasteredBiteIdsView,
    DueBitesView, BiteHistoryView,
    MarketplaceListView, PurchaseBundleView, MyOwnedBundlesView, BundleBitesView,
    IngestPortalView, IngestUploadAPIView
)

urlpatterns = [
    path('auth/register/', RegisterView.as_view(), name='auth-register'),
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('progress/', CandidateProgressView.as_view(), name='progress'),
    path('profile/update/', ProfileUpdateView.as_view(), name='profile-update'),
    path('select-elective/', SelectElectiveView.as_view(), name='select-elective'),
    path('stats/', CandidateStatsView.as_view(), name='candidate-stats'),
    path('knowledge-tracing/', KnowledgeTracingView.as_view(), name='knowledge-tracing'),
    path('marketplace/', MarketplaceListView.as_view(), name='marketplace-list'),
    path('marketplace/purchase/', PurchaseBundleView.as_view(), name='marketplace-purchase'),
    path('marketplace/my-bundles/', MyOwnedBundlesView.as_view(), name='marketplace-my-bundles'),
    path('marketplace/bundle/<int:bundle_id>/bites/', BundleBitesView.as_view(), name='bundle-bites'),
    path('admin/ingest/', IngestPortalView.as_view(), name='ingest-portal'),
    path('admin/ingest/upload/', IngestUploadAPIView.as_view(), name='ingest-upload'),
    path('bites/today/', TodaysBiteView.as_view(), name='bites-today'),
    path('bites/mastered/', MasteredBiteIdsView.as_view(), name='mastered-bites'),
    path('bites/due/', DueBitesView.as_view(), name='due-bites'),
    path('bites/history/', BiteHistoryView.as_view(), name='bite-history'),
    path('bites/submit/', SubmitBiteView.as_view(), name='submit-bite'),
    path('bites/<str:paper_code>/', PaperBitesView.as_view(), name='paper-bites'),
    path('auth/delete/', DeleteAccountView.as_view(), name='delete-account'),
    path('ping/', PingView.as_view(), name='ping'),
]

# CAIIB ProBanker — Bug Fix Prompt

You are an expert Django + Flutter developer reviewing the `caiib-probanker` codebase. The following bugs have been identified by static analysis. Apply all fixes precisely as described, preserving all existing logic unless explicitly instructed otherwise.

---

## BUG 1 — CRITICAL: `BiteDetailSerializer` never receives request context → premium bites permanently locked for ALL users

**File:** `api/views.py`
**Root cause:** `BiteDetailSerializer` is instantiated without `context={'request': request}` in two views. Its `to_representation()` method calls `self.context.get('request')`, which always returns `None`, so `has_access` is always `False` — meaning every non-free bite is always redacted for every user, including paying ones.

**Fix — `TodaysBiteView.get()`:**

Find the two `BiteDetailSerializer(bite).data` calls inside `TodaysBiteView.get()` and add the request context to both.

```python
# BEFORE (inside the `if due:` block):
return Response({'bite': BiteDetailSerializer(bite).data, 'mode': 'review', 'srs_due_count': srs_due_count})

# AFTER:
return Response({'bite': BiteDetailSerializer(bite, context={'request': request}).data, 'mode': 'review', 'srs_due_count': srs_due_count})
```

```python
# BEFORE (at the bottom of TodaysBiteView.get()):
return Response({'bite': BiteDetailSerializer(bite).data, 'mode': 'new'})

# AFTER:
return Response({'bite': BiteDetailSerializer(bite, context={'request': request}).data, 'mode': 'new'})
```

**Fix — `DueBitesView.get()`:**

```python
# BEFORE:
due_bites.append(BiteDetailSerializer(bite).data)

# AFTER:
due_bites.append(BiteDetailSerializer(bite, context={'request': request}).data)
```

---

## BUG 2 — CRITICAL: Elective codes don't match any `Bite.paper_code` → elective users always get ABFM bites instead of their subject

**Files:** `api/views.py` (`TodaysBiteView`), `api/models.py` (`Candidate`)

**Root cause:** `Candidate.selected_elective` stores values like `'RURAL'`, `'HRM'`, `'IT_DB'`, `'RISK'`, `'CENTRAL'`. `TodaysBiteView` uses this value directly as a `paper_code` filter on `Bite.objects`. No bites are ingested with these codes — they use `ABFM`, `ABM`, `BFM`, `BRBL`. The fallback to `'ABFM'` always fires, so the elective selection is silently ignored.

**Fix — `TodaysBiteView.get()` in `api/views.py`:**

Add an elective-to-paper-code mapping immediately before the `paper_filter` assignment:

```python
# BEFORE:
weakest = candidate.progress.order_by('current_score').first()
paper_filter = weakest.paper_code if weakest else candidate.selected_elective or 'ABFM'

# AFTER:
ELECTIVE_TO_PAPER_CODE = {
    'RURAL': 'RURAL',   # Update these values to match your actual ingested paper_codes
    'HRM': 'HRM',
    'IT_DB': 'IT_DB',
    'RISK': 'RISK',
    'CENTRAL': 'CENTRAL',
}
elective_paper = ELECTIVE_TO_PAPER_CODE.get(candidate.selected_elective, 'ABFM')
weakest = candidate.progress.order_by('current_score').first()
paper_filter = weakest.paper_code if weakest else elective_paper
```

> **NOTE for content team:** The mapping values (`'RURAL'`, `'HRM'`, etc.) must match the exact `paper_code` strings used when ingesting elective content via `IngestUploadAPIView`. Update the map to reflect actual ingested codes if they differ. Alternatively, normalise elective codes in `IngestUploadAPIView` by extending its `paper_code` normalisation block to handle elective subjects.

---

## BUG 3 — MEDIUM: `AuthProvider.checkToken()` treats an expired token as valid → app-wide silent loading failure on restart

**File:** `mobile/lib/main.dart`

**Root cause:** `checkToken()` calls `_apiService.getToken()`, which simply reads the raw JWT from secure storage with no expiry check. An expired stored token causes `isAuthenticated = true` to be set; the `MainShell` is rendered, but every subsequent API call (which correctly uses `_getValidToken()`) either refreshes or returns `null`. If refresh fails (network unavailable, refresh token also expired), all data loads return `null` and the dashboard enters a permanent loading state with no redirect to login.

**Fix — `AuthProvider` in `mobile/lib/main.dart`:**

Replace `checkToken()` to use the internal `_getValidToken()` logic and log out on failure.

```dart
// BEFORE:
Future<void> checkToken() async {
  final token = await _apiService.getToken();
  if (token != null) {
    isAuthenticated = true;
    notifyListeners();
  }
}

// AFTER:
Future<void> checkToken() async {
  // Validate and, if needed, refresh the token on startup
  final token = await _apiService.getValidTokenForStartup();
  if (token != null) {
    isAuthenticated = true;
  } else {
    isAuthenticated = false;
    await _apiService.clearSession(); // Ensure stale tokens are purged
  }
  notifyListeners();
}
```

Then add the following public helper to `ApiService` in `mobile/lib/services/api_service.dart`:

```dart
/// Public wrapper around _getValidToken() for use during app startup.
Future<String?> getValidTokenForStartup() async => await _getValidToken();
```

---

## BUG 4 — MEDIUM: `ProfileUpdateView` silently crashes on duplicate mobile number

**File:** `api/views.py`

**Root cause:** `ProfileUpdateView.put()` sets `candidate.mobile_number = mobile` and calls `candidate.save()` with no check for uniqueness. If another `Candidate` already has that mobile number, the DB raises an `IntegrityError`, causing an unhandled 500 response.

**Fix — `ProfileUpdateView.put()` in `api/views.py`:**

```python
# BEFORE:
mobile = request.data.get('mobile_number', '').strip()
if mobile:
    candidate.mobile_number = mobile
    candidate.save()

# AFTER:
mobile = request.data.get('mobile_number', '').strip()
if mobile:
    if Candidate.objects.filter(mobile_number=mobile).exclude(pk=candidate.pk).exists():
        return Response(
            {"error": "This mobile number is already registered to another account."},
            status=status.HTTP_400_BAD_REQUEST
        )
    candidate.mobile_number = mobile
    candidate.save()
```

---

## BUG 5 — MEDIUM: `IngestPortalView` HTML admin portal is publicly accessible

**File:** `api/views.py`

**Root cause:** `IngestPortalView` extends `TemplateView` directly with no authentication guard. Anyone who discovers the `/api/admin/ingest/` URL can view the admin portal HTML. (The upload endpoint itself is protected by an `ADMIN_SECRET` check, but the portal page should not be publicly visible.)

**Fix — `api/views.py`:**

```python
# BEFORE:
class IngestPortalView(TemplateView):
    template_name = 'api/ingest_portal.html'

# AFTER:
from django.contrib.admin.views.decorators import staff_member_required
from django.utils.decorators import method_decorator

@method_decorator(staff_member_required, name='dispatch')
class IngestPortalView(TemplateView):
    template_name = 'api/ingest_portal.html'
```

Alternatively, if Django admin login is not configured, add a simple secret-based redirect at the top of `IngestPortalView.get()`:

```python
class IngestPortalView(TemplateView):
    template_name = 'api/ingest_portal.html'

    def get(self, request, *args, **kwargs):
        secret = request.GET.get('secret')
        if secret != getattr(settings, 'ADMIN_SECRET', 'dev_secret'):
            from django.http import HttpResponseForbidden
            return HttpResponseForbidden("Access denied.")
        return super().get(request, *args, **kwargs)
```

---

## BUG 6 — MINOR: Duplicate import block mid-file in `views.py`

**File:** `api/views.py`

**Root cause:** `MarketplaceBundle`, `BundleAccess`, and `MarketplaceBundleSerializer` are imported in a second `from .models import ...` / `from .serializers import ...` block placed halfway through the file. This is a maintenance hazard — if a view above the second block ever needs these symbols, it will fail with `NameError`.

**Fix:** Remove the duplicate import block (lines beginning with `from .models import (` and `from .serializers import (` the second time they appear) and merge those symbols into the first import block at the top of the file.

**Merged top-of-file imports should be:**

```python
from .models import (
    Candidate, PaperProgress, SRSMetadata, Bite, BiteAttempt,
    MarketplaceBundle, BundleAccess
)
from .serializers import (
    CandidateSerializer, PaperProgressSerializer, SRSMetadataSerializer,
    BiteSerializer, BiteListSerializer, BiteDetailSerializer,
    MarketplaceBundleSerializer
)
```

Then delete the duplicate block that currently appears just before the `MarketplaceListView` class definition.

---

## BUG 7 — MINOR: `SRSMetadata` model comment has a typo ("MognoDB")

**File:** `api/models.py`

```python
# BEFORE:
card_id = models.CharField(max_length=100)  # Refers to MognoDB document ID

# AFTER:
card_id = models.CharField(max_length=100)  # Refers to MongoDB document ID
```

---

## Summary of Changes

| # | Severity | File | Description |
|---|----------|------|-------------|
| 1 | Critical | `api/views.py` | Pass `context={'request': request}` to `BiteDetailSerializer` in `TodaysBiteView` (×2) and `DueBitesView` |
| 2 | Critical | `api/views.py`, `api/models.py` | Add elective→paper_code mapping in `TodaysBiteView`; ensure ingested elective bites use matching codes |
| 3 | Medium | `mobile/lib/main.dart`, `mobile/lib/services/api_service.dart` | `checkToken()` must validate/refresh token expiry, not just check presence |
| 4 | Medium | `api/views.py` | Add mobile number uniqueness check in `ProfileUpdateView` before saving |
| 5 | Medium | `api/views.py` | Add `staff_member_required` (or secret gate) to `IngestPortalView` |
| 6 | Minor | `api/views.py` | Merge duplicate mid-file import block into top-level imports |
| 7 | Minor | `api/models.py` | Fix typo `MognoDB` → `MongoDB` in `SRSMetadata.card_id` comment |

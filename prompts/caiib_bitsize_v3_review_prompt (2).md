# AI Prompt: CAIIB Bitsize — Full Codebase Review & Improvement Plan

## Current State Summary

This is CAIIB Bitsize v3 — a Flutter + Django REST Framework microlearning app for the CAIIB banking exam. The Bite model, BiteScreen 3-phase flow, Library, Review, and Stats screens are all implemented. The branding pivot is complete.

Read this entire prompt before writing any code. Work through each section in priority order.

---

## PART 1 — CRITICAL BACKEND BUGS (Fix First)

### Bug 1 — PostgreSQL database is silently dead

`core/settings.py` defines DATABASES twice:

```python
# Line 1 — correct production config
DATABASES = {
    'default': env.db('DATABASE_URL', default=f"postgres://...")
}

# Line 2 — immediately overwrites the above, ALWAYS wins
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```

The SQLite block silently wins every time — including in production. The PostgreSQL config is dead code.

**Fix:** Use an environment flag to switch:

```python
if env.bool('USE_SQLITE', default=False):
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }
else:
    DATABASES = {
        'default': env.db('DATABASE_URL')
    }
```

Set `USE_SQLITE=True` in your local `.env` only. Remove the inline fallback default from `env.db()` — a missing `DATABASE_URL` in production should crash loudly, not silently use SQLite.

### Bug 2 — ADMIN_SECRET check runs before DEBUG is defined

```python
# settings.py — current order:
SECRET_KEY = env(...)

from django.core.exceptions import ImproperlyConfigured
if not os.environ.get('ADMIN_SECRET') and not DEBUG:  # ERROR: DEBUG not yet assigned
    pass

if 'ADMIN_SECRET' not in os.environ:
    raise ImproperlyConfigured(...)  # This runs even in dev, making the app unbootable without it

DEBUG = env.bool('DEBUG', default=True)
```

Two problems: `DEBUG` is referenced before it's assigned. And `ImproperlyConfigured` is raised unconditionally — if you're doing local dev without an `.env`, the app won't start at all.

**Fix:**

```python
DEBUG = env.bool('DEBUG', default=True)
SECRET_KEY = env('SECRET_KEY', default='django-insecure-...' if DEBUG else None)

if not DEBUG and 'ADMIN_SECRET' not in os.environ:
    raise ImproperlyConfigured("ADMIN_SECRET must be set in production.")
ADMIN_SECRET = os.environ.get('ADMIN_SECRET', 'dev_secret_not_for_production')
```

### Bug 3 — SubmitBiteView double-counts correct bites

```python
# views.py SubmitBiteView
if is_correct:
    progress.current_score += 1.0  # No guard against repeat attempts
    progress.save()
```

If a user answers the same bite correctly twice (comes back through SRS), `current_score` increments twice. The serializer aliases `current_score` as `mastered` — so the mastery count is inflated.

**Fix — count distinct correct bites:**

```python
if is_correct:
    # Only increment if this is the FIRST correct attempt for this bite
    already_mastered = BiteAttempt.objects.filter(
        candidate=candidate, bite=bite, is_correct=True
    ).exists()
    if not already_mastered:
        progress.current_score = float(
            BiteAttempt.objects.filter(
                candidate=candidate,
                bite__paper_code=bite.paper_code,
                is_correct=True
            ).values('bite').distinct().count()
        )
        progress.save()
```

This makes `current_score` always equal to the count of uniquely mastered bites for that paper — idempotent regardless of re-attempts.

### Bug 4 — BiteSerializer exposes correct answers in the Library API

```python
# serializers.py
class BiteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bite
        fields = '__all__'  # Sends 'answer', 'tolerance', 'explanation' to any authenticated user
```

`PaperBitesView` returns full bite objects including the answer. A user browsing the Library can read all answers without going through BiteScreen. This breaks the integrity of the knowledge check.

**Fix — create two serializers:**

```python
class BiteListSerializer(serializers.ModelSerializer):
    """Safe for Library listing — no answer fields."""
    class Meta:
        model = Bite
        fields = [
            'id', 'bite_id', 'paper_code', 'module', 'chapter',
            'title', 'difficulty', 'bite_type', 'estimated_minutes', 'tags'
        ]

class BiteDetailSerializer(serializers.ModelSerializer):
    """Full detail — used only when user starts a bite session."""
    class Meta:
        model = Bite
        fields = [
            'id', 'bite_id', 'paper_code', 'module', 'chapter',
            'title', 'concept', 'example', 'formula',
            'question_text', 'question_type', 'options',
            'difficulty', 'bite_type', 'estimated_minutes'
            # NOTE: 'answer', 'tolerance', 'explanation' are intentionally excluded
            # They are only returned by SubmitBiteView after the user submits
        ]
```

Use `BiteListSerializer` in `PaperBitesView` and `TodaysBiteView`.
Use `BiteDetailSerializer` in the bite response.
Keep `answer` and `explanation` only in `SubmitBiteView`'s response payload.

### Bug 5 — CORS is fully open

```python
# settings.py
CORS_ALLOW_ALL_ORIGINS = True
```

This allows any website to make authenticated requests to your API. Fine for local dev, dangerous in production.

**Fix:**

```python
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True
else:
    CORS_ALLOWED_ORIGINS = env.list('CORS_ALLOWED_ORIGINS', default=[])
```

### Bug 6 — JWT refresh token config is contradictory

```python
SIMPLE_JWT = {
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),   # Very short
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,              # Blacklist does nothing when rotation is off
}
```

With `ROTATE_REFRESH_TOKENS=False`, the blacklist setting has no effect. Also, 1-day refresh tokens mean users must log in again every day.

**Fix:**

```python
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'AUTH_HEADER_TYPES': ('Bearer',),
}
```

Add `'rest_framework_simplejwt.token_blacklist'` to `INSTALLED_APPS` and run migrations.

### Bug 7 — Dead models and dead services

The following are defined but never called from any view:

**Dead models** (have migrations, take up schema space, confuse new developers):
- `UserActivity` — logged nowhere
- `SubscriptionPlan` — no payment flow implemented
- `ExamSession` / `QuestionAttempt` — removed from views but no migration drops them (migration 0006 removes QuestionAttempt but check if ExamSession still exists)

**Dead services** — these files are lazy-imported but never actually called:
- `services/content_service.py` — MongoDB content loading, replaced by Bite model
- `services/tamkot_service.py` — untrained PyTorch model, unused
- `services/payment_service.py` — Razorpay mock, unused
- `services/scoring_service.py` — old exam-based scoring, unused

**Action:** Do not delete these yet — leave them as stubs with a `# TODO: integrate` comment, but stop loading them at import time. Remove `get_content_service`, `get_tamkot_service`, `get_scoring_service`, `get_payment_service` from `views.py` entirely. The lazy-loader pattern is good architecture but these aren't used anywhere.

### Bug 8 — SRSMetadata.card_id stale comment

```python
card_id = models.CharField(max_length=100)  # Refers to MognoDB document ID
```

"MongoDB" is misspelled and the comment is from 3 versions ago. Update:

```python
card_id = models.CharField(max_length=100)  # Refers to Bite.bite_id (e.g. 'bfm_bite_001')
```

### Bug 9 — EmailOrUsernameModelBackend is a timing oracle

```python
# backends.py
users = User.objects.filter(Q(username=username) | Q(email=username))
for user in users:
    if user.check_password(password):
        return user
```

This iterates matching users in a loop and checks passwords one by one, which leaks information via response timing (more users = longer response). Also, if two accounts share a username/email combination (edge case), both are checked.

**Fix:**

```python
def authenticate(self, request, username=None, password=None, **kwargs):
    try:
        user = User.objects.get(Q(username=username) | Q(email__iexact=username))
    except User.MultipleObjectsReturned:
        user = User.objects.filter(Q(username=username) | Q(email__iexact=username)).first()
    except User.DoesNotExist:
        User().check_password(password)  # Constant-time dummy check to prevent timing attack
        return None
    if user.check_password(password) and self.user_can_authenticate(user):
        return user
    return None
```

### Bug 10 — No stats API endpoint; Stats screen uses hardcoded mocks

`StatsScreen` shows hardcoded `accuracy = 87` and `reviewedTotal = masteredTotal + 12`. There's no backend endpoint for these.

**Add a new endpoint:**

```python
# views.py
class CandidateStatsView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        
        total_attempts = BiteAttempt.objects.filter(candidate=candidate).count()
        correct_attempts = BiteAttempt.objects.filter(candidate=candidate, is_correct=True).count()
        accuracy = round((correct_attempts / total_attempts * 100) if total_attempts > 0 else 0, 1)
        
        # Last 7 days activity
        from datetime import date, timedelta
        today = date.today()
        activity = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            studied = BiteAttempt.objects.filter(
                candidate=candidate,
                attempted_at__date=day
            ).exists()
            activity.append({'date': day.isoformat(), 'studied': studied})
        
        return Response({
            'total_attempts': total_attempts,
            'correct_attempts': correct_attempts,
            'accuracy_percent': accuracy,
            'activity_last_7_days': activity,
            'study_streak': candidate.study_streak,
        })
```

```python
# urls.py
path('stats/', CandidateStatsView.as_view(), name='candidate-stats'),
```

### Bug 11 — django.contrib.admin has no models registered

```python
# admin.py
from django.contrib import admin
# empty
```

Register all models for easy debugging in the admin panel:

```python
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
    list_display = ['user', 'selected_elective', 'study_streak', 'last_study_date']

admin.site.register(PaperProgress)
admin.site.register(SRSMetadata)
admin.site.register(ConsentLog)
```

### Bug 12 — Missing settings entries

Add these missing Django settings:

```python
# settings.py
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

STATIC_ROOT = BASE_DIR / 'staticfiles'

# Logging — currently there is none
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {'class': 'logging.StreamHandler'},
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
    'loggers': {
        'django': {'handlers': ['console'], 'level': 'INFO', 'propagate': False},
        'api': {'handlers': ['console'], 'level': 'DEBUG', 'propagate': False},
    },
}
```

---

## PART 2 — CONTENT GAPS (Critical for App Value)

### Problem: Only 20 bites exist across the entire app

Current bite counts:
```
ABM              →  5 bites   (need 40+)
BFM              →  6 bites   (need 40+)
ABFM             →  3 bites   (need 30+)
BRBL             →  3 bites   (need 40+)
elective_risk    →  3 bites   (need 30+)
elective_rural   →  MISSING
elective_hrm     →  MISSING
elective_itdb    →  MISSING
elective_central →  MISSING
TOTAL            → 20 bites
```

An app with 20 bites total is unusable — users exhaust content in one session. This is the most important content work.

**Create the following JSON files. Each must follow this exact schema:**

```json
{
  "paper_code": "ABM",
  "bites": [
    {
      "id": "abm_bite_006",
      "module": "Statistics & Numericals",
      "chapter": "Correlation Analysis",
      "title": "Understanding Karl Pearson's Coefficient",
      "concept": "Karl Pearson's Coefficient of Correlation (r) measures the strength and direction of the linear relationship between two variables. It ranges from -1 (perfect negative) to +1 (perfect positive). A value of 0 indicates no linear correlation.",
      "example": "If r = 0.85 between credit scores and loan repayment rates, it indicates a strong positive relationship — higher credit scores tend to predict better repayment.",
      "formula": "r = Σ(X-X̄)(Y-Ȳ) / √[Σ(X-X̄)² × Σ(Y-Ȳ)²]",
      "difficulty": "medium",
      "estimated_minutes": 5,
      "tags": ["ABM", "Statistics", "medium", "numerical"],
      "check_question": {
        "type": "mcq",
        "question": "If Karl Pearson's coefficient r = -0.9, what does this indicate?",
        "options": [
          "Strong positive correlation",
          "Weak negative correlation",
          "Strong negative correlation",
          "No correlation"
        ],
        "answer": "Strong negative correlation",
        "explanation": "r = -0.9 is close to -1, indicating a strong negative linear relationship between the two variables."
      }
    }
  ]
}
```

**Target bite counts and priority topics by paper:**

**ABM (target: 40 bites)** — prioritise:
- Correlation, Regression, Standard Deviation (numericals — highest weightage)
- GDP, GNP, Fiscal Deficit, Monetary Policy
- NPA classification, Provisioning norms (Substandard, Doubtful, Loss)
- RAROC, Risk-Adjusted Returns
- Lorenz Curve, Gini Coefficient
- Basel III — Tier 1, Tier 2 capital (overlap with BFM, reinforce)
- Priority Sector Lending limits
- HR: Maslow's hierarchy, Herzberg, McGregor X/Y

**BFM (target: 40 bites)** — prioritise:
- Nostro/Vostro/Loro definitions (already 1 bite — expand)
- Forex cross rates, forward rates, LIBOR/MIBOR
- Modified Duration, Macaulay Duration, Convexity
- Basel III: CRAR, CET1, AT1, Tier 2, CCB, CCCB, LCR, NSFR
- Pillar 1, 2, 3 — what each covers
- ALM: Gap Analysis, Duration Gap
- VaR: definition, limitations
- FEMA, FETERS, AD Categories

**ABFM (target: 30 bites)** — prioritise:
- NPV, IRR, Payback Period (all numerical)
- WACC calculation
- Capital structure theories (MM theorem)
- EVA (Economic Value Added)
- Mergers and Acquisitions — EV/EBITDA, P/E multiples
- Convertible debentures, warrants
- Lease vs Buy analysis

**BRBL (target: 40 bites)** — prioritise:
- RBI Act 1934 — key sections (Section 17, 42, 45)
- Banking Regulation Act 1949 — key sections
- Negotiable Instruments Act — types, crossing, dishonour
- SARFAESI Act — sections, process, eligible assets
- PMLA — reporting obligations, 5-year retention
- KYC norms — CDD, EDD, Periodic Update
- Contract Act — essentials, void/voidable
- Limitation Act — timelines for suits
- DRT, DRAT process

**Elective files to create** (30 bites each):

`elective_rural_bites.json` (paper_code: "RURAL"):
- Priority Sector Lending: agriculture, MSE, housing sub-targets
- NABARD: role, refinancing, RIDF
- KCC (Kisan Credit Card): features, limits
- SHG-Bank Linkage programme
- Crop Insurance (PMFBY)
- Land reforms, tenancy laws basics

`elective_hrm_bites.json` (paper_code: "HRM"):
- Industrial Disputes Act: strikes, lockouts, retrenchment
- Payment of Gratuity Act: formula, limits
- ESI Act: contribution rates, benefits
- Compensation: CTC structure, Variable Pay
- Training ROI (Kirkpatrick model)
- Performance Appraisal: 360°, MBO, Bell curve
- Talent management, succession planning

`elective_itdb_bites.json` (paper_code: "IT_DB"):
- Payment systems: RTGS, NEFT, IMPS — settlement, timing
- UPI architecture: VPA, 2FA
- NPCI: products and role
- Cybersecurity: phishing, ransomware, social engineering
- ISO 27001 basics
- Blockchain: consensus, use in banking
- Cloud computing: IaaS, PaaS, SaaS
- RBI guidelines on Digital Lending

`elective_central_bites.json` (paper_code: "CENTRAL"):
- Monetary policy: CRR, SLR, Repo, Reverse Repo, MSF
- Open Market Operations
- Inflation targeting: MPC, MPCF
- Liquidity Adjustment Facility
- NBFC regulation
- Payment and Settlement Systems Act 2007
- Financial inclusion: Jan Dhan, PMJDY

---

## PART 3 — FLUTTER BUGS & IMPROVEMENTS

### Flutter Bug 1 — AuthProvider.checkToken() is never called

```dart
// main.dart
class AuthProvider extends ChangeNotifier {
  Future<void> checkToken() async { ... } // defined but never called
```

On every app launch, `isAuthenticated` starts `false`, so logged-in users always see the login screen. The app doesn't check if a valid JWT is already stored.

**Fix — call `checkToken()` on startup:**

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.checkToken(); // Check stored JWT before first frame
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Flutter Bug 2 — JWT token expires silently; no refresh logic

`ACCESS_TOKEN_LIFETIME` is 60 minutes. After that, all API calls return 401 and the `catch` block silently returns `null`. The user sees an empty dashboard with no error.

**Fix — add token refresh to `ApiService`:**

```dart
// services/api_service.dart

Future<String?> _getValidToken() async {
  final token = await getToken();
  if (token == null) return null;
  
  // Decode JWT to check expiry (manual base64 decode — no package needed)
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final data = jsonDecode(payload);
    final exp = data['exp'] as int;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    
    if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)))) {
      // Token expiring soon — attempt refresh
      return await _refreshToken();
    }
    return token;
  } catch (_) {
    return token; // Parsing failed — use as-is
  }
}

Future<String?> _refreshToken() async {
  final refreshToken = await _storage.read(key: 'jwt_refresh');
  if (refreshToken == null) return null;
  
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'jwt', value: data['access']);
      return data['access'];
    }
  } catch (_) {}
  
  // Refresh failed — session expired
  await clearSession();
  return null;
}
```

Store refresh token on login:
```dart
Future<bool> login(String username, String password) async {
  // ...existing code...
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await _storage.write(key: 'jwt', value: data['access']);
    await _storage.write(key: 'jwt_refresh', value: data['refresh']); // ADD THIS
    return true;
  }
}
```

Replace all `getToken()` calls in API methods with `_getValidToken()`. When `_getValidToken()` returns null (expired and refresh failed), set `AuthProvider.isAuthenticated = false` to redirect to login.

### Flutter Bug 3 — Dashboard greeting is hardcoded "Good morning"

```dart
// dashboard_screen.dart
Text('Good morning, $firstName', ...)
```

**Fix:**

```dart
String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// In build():
Text('${_getGreeting()}, $firstName', ...)
```

### Flutter Bug 4 — Dashboard profile IconButton does nothing

```dart
// dashboard_screen.dart
IconButton(icon: const Icon(Icons.person_outline), onPressed: () {})
```

Profile is now in the Stats tab. Either remove this button, or navigate to tab index 3:

```dart
// In MainShell, expose a method or use a shared index notifier
// Simplest fix: just remove the icon from the dashboard AppBar entirely
// since the nav bar already has Stats (which links to Profile)
actions: const [], // remove
```

### Flutter Bug 5 — Library search icon does nothing

```dart
// library_screen.dart
actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})]
```

**Fix — implement simple search:**

```dart
bool _isSearching = false;
String _searchQuery = '';

// When search icon tapped:
setState(() => _isSearching = true);

// Show a TextField in the AppBar when searching:
appBar: AppBar(
  title: _isSearching
    ? TextField(
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'Search bites...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.white54)),
        onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
      )
    : const Text('Library'),
  actions: [
    IconButton(
      icon: Icon(_isSearching ? Icons.close : Icons.search),
      onPressed: () => setState(() { _isSearching = !_isSearching; _searchQuery = ''; }),
    ),
  ],
),

// In the bite list builder, add filter:
final filteredBites = _searchQuery.isEmpty
    ? _bites
    : _bites.where((b) =>
        (b['title'] ?? '').toLowerCase().contains(_searchQuery) ||
        (b['module'] ?? '').toLowerCase().contains(_searchQuery)
      ).toList();
```

### Flutter Bug 6 — Library shows no mastery indicators

When browsing the Library, there is no visual difference between a bite you've mastered and one you've never seen. Users can't track their progress while browsing.

**Fix — pass mastered bite IDs to the Library and mark them:**

Backend: Add a `GET /api/bites/mastered/` endpoint that returns a list of `bite_id`s the candidate has answered correctly at least once:

```python
# views.py
class MasteredBiteIdsView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        mastered_ids = list(
            BiteAttempt.objects.filter(candidate=candidate, is_correct=True)
            .values_list('bite__bite_id', flat=True)
            .distinct()
        )
        return Response({'mastered_ids': mastered_ids})

# urls.py
path('bites/mastered/', MasteredBiteIdsView.as_view(), name='mastered-bites'),
```

Flutter: fetch mastered IDs in `LibraryScreen.initState()` and show a checkmark or teal border on mastered bite tiles.

### Flutter Bug 7 — ReviewScreen only shows 1 bite and has a broken flow

`ReviewScreen` calls `getTodaysBite()` which returns only ONE bite. After the user reviews that bite and comes back, the screen calls `getTodaysBite()` again — which may now return `mode: 'new'` instead of `mode: 'review'`. The screen then shows "Queue Empty" even though more reviews may be pending.

**Fix — add a dedicated `GET /api/bites/due/` endpoint:**

```python
# views.py
class DueBitesView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        due_metadata = SRSMetadata.objects.filter(
            candidate=candidate,
            next_review__lte=timezone.now()
        ).order_by('next_review')
        
        due_bites = []
        for meta in due_metadata[:20]:  # Cap at 20 per session
            try:
                bite = Bite.objects.get(bite_id=meta.card_id)
                due_bites.append(BiteDetailSerializer(bite).data)
            except Bite.DoesNotExist:
                pass
        
        return Response({
            'due_count': due_metadata.count(),
            'bites': due_bites
        })

# urls.py
path('bites/due/', DueBitesView.as_view(), name='due-bites'),
```

In `ReviewScreen`, fetch the full due list. Show a counter "X of N reviewed" and advance through the queue automatically after each submission — no back-and-forth with the dashboard:

```dart
// review_screen.dart — new state
List<Map<String, dynamic>> _dueBites = [];
int _currentIndex = 0;
int _reviewedCount = 0;

// After BiteScreen.pop():
.then((_) {
  setState(() {
    _reviewedCount++;
    _currentIndex++;
  });
  if (_currentIndex >= _dueBites.length) {
    // Show completion screen
  }
})
```

### Flutter Bug 8 — Stats screen accuracy and activity are mocked

```dart
// stats_screen.dart
final accuracy = 87; // Mocked
final reviewedTotal = masteredTotal + 12; // Mocked
// Activity heatmap: entry.key >= 4 (hardcoded last 3 days)
```

**Fix — call the new `GET /api/stats/` endpoint** (defined in Backend Bug 10) and populate from real data:

```dart
// In StatsScreen or ProgressProvider:
Map<String, dynamic>? _stats;

Future<void> _fetchStats() async {
  _stats = await ApiService().getStats();
  setState(() {});
}

// ApiService
Future<Map<String, dynamic>?> getStats() async {
  final token = await _getValidToken();
  final response = await http.get(
    Uri.parse('$_baseUrl/stats/'),
    headers: {'Authorization': 'Bearer $token'},
  ).timeout(const Duration(seconds: 10));
  if (response.statusCode == 200) return jsonDecode(response.body);
  return null;
}
```

Replace the mocked values:
```dart
final accuracy = _stats?['accuracy_percent'] ?? 0;
final totalAttempts = _stats?['total_attempts'] ?? 0;
final activity = _stats?['activity_last_7_days'] as List? ?? [];

// In the heatmap row:
...activity.asMap().entries.map((entry) {
  final isActive = entry.value['studied'] == true;
  // ...
})
```

### Flutter Bug 9 — BiteScreen ResultPhase has no "Next Bite" button

After completing a bite, the only option is "Back to Dashboard". The user then sees the dashboard, taps "Start Learning" again, and waits for a new bite to load. This breaks flow for users who want to chain multiple bites.

**Fix — add a "Next Bite" button in `_ResultPhase`:**

```dart
// _ResultPhase widget, below "Back to Dashboard" button:
const SizedBox(height: 12),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6366F1),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    onPressed: () async {
      // Pop this BiteScreen and immediately push a new one
      Navigator.pop(context);
      // The dashboard will call _fetchTodaysBite again, but we can also
      // pass a callback or use a navigation result to auto-start next:
    },
    child: const Text('Next Bite →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
  ),
),
```

To avoid going back to the dashboard between bites, use a `Navigator.pushReplacement` approach from `BiteScreen` itself when the user taps "Next Bite":

```dart
// In BiteScreen state, add:
void _goToNextBite() async {
  final nextBiteData = await ApiService().getTodaysBite();
  if (mounted && nextBiteData != null && nextBiteData['bite'] != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BiteScreen(bite: nextBiteData['bite'])),
    );
  } else if (mounted) {
    Navigator.pop(context); // No more bites — go back to dashboard
  }
}
```

Pass `_goToNextBite` as a callback to `_ResultPhase`.

### Flutter Bug 10 — NumericalKeypad has white background clashing with dark theme

```dart
// numerical_keypad.dart
decoration: BoxDecoration(
  color: Colors.white,  // White background inside a dark screen
  ...
)
```

**Fix:**

```dart
color: const Color(0xFF161B22), // surfaceDark

// Key tiles:
color: const Color(0xFF21262D), // surfaceElevated instead of Colors.grey[100]

// Text in keys:
style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),

// DONE button:
style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
```

### Flutter Bug 11 — ApiService default URL breaks on Android device

```dart
final String _baseUrl = const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api'  // Loopback — won't work on Android device
);
```

`127.0.0.1` only works on iOS simulator and Windows. Android emulator needs `10.0.2.2`. Physical device needs the machine's LAN IP.

**Fix the default to cover the most common dev case:**

```dart
final String _baseUrl = const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api', // Android emulator → host machine
);
```

For iOS simulator or physical device, always pass `--dart-define=API_BASE_URL=http://192.168.x.x:8000/api`.

Add a comment with the run command:
```dart
// Run with: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

### Flutter Bug 12 — Register screen has no password confirmation field

A user who miskeys their password during registration is locked out with no recovery path (no reset flow exists).

**Add a confirm password field:**

```dart
// register_screen.dart
final _confirmPasswordController = TextEditingController();

// In build(), after the password field:
const SizedBox(height: 16),
TextField(
  controller: _confirmPasswordController,
  obscureText: true,
  decoration: const InputDecoration(
    labelText: 'Confirm Password',
    prefixIcon: Icon(Icons.lock_outline),
  ),
),

// In _handleRegister(), before the API call:
if (_passwordController.text != _confirmPasswordController.text) {
  setState(() => errorMessage = 'Passwords do not match.');
  return;
}
```

### Flutter Bug 13 — Register error message is always generic

```dart
// register_screen.dart
setState(() { errorMessage = 'Registration failed. Username may exist.'; });
```

The API returns specific error messages: "This email address is already registered.", "This mobile number is already registered.", validation errors. These are discarded.

**Fix — parse the API error:**

```dart
// ApiService.register() — return error string instead of bool
Future<Map<String, dynamic>> register(...) async {
  try {
    final response = await http.post(...);
    if (response.statusCode == 201) return {'success': true};
    final body = jsonDecode(response.body);
    return {'success': false, 'error': body['error'] ?? 'Registration failed.'};
  } catch (e) {
    return {'success': false, 'error': 'Network error. Please check your connection.'};
  }
}

// In _handleRegister():
final result = await _apiService.register(...);
if (result['success'] == true) {
  // ...
} else {
  setState(() => errorMessage = result['error'] ?? 'Registration failed.');
}
```

### Flutter Bug 14 — VerticalPathIndicator height is hardcoded

```dart
// library_screen.dart VerticalPathIndicator
Container(width: 2, height: 60, color: ...)
```

If any bite card wraps to more than one line (long title), the 60px line won't reach the next dot. Use a `LayoutBuilder` or `IntrinsicHeight` approach, or simply remove the connector lines and rely on the dot only. The dots alone are sufficient navigation indicators.

### Flutter Bug 15 — Missing packages in pubspec.yaml

```yaml
# These are needed but missing:
flutter_local_notifications: ^18.0.0  # Daily "time to review" reminders
shared_preferences: ^2.3.0            # Store local settings like notification prefs
```

Add them to `pubspec.yaml` under `dependencies:`.

---

## PART 4 — ARCHITECTURE IMPROVEMENTS

### Arch 1 — Add a `BiteHistoryView` endpoint

The Library shows all bites but there's no way for the user to see their personal attempt history — what they got right/wrong and when.

```python
# views.py
class BiteHistoryView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        attempts = BiteAttempt.objects.filter(candidate=candidate).select_related('bite')[:50]
        return Response([{
            'bite_id': a.bite.bite_id,
            'title': a.bite.title,
            'paper_code': a.bite.paper_code,
            'is_correct': a.is_correct,
            'attempted_at': a.attempted_at,
        } for a in attempts])

# urls.py
path('bites/history/', BiteHistoryView.as_view(), name='bite-history'),
```

### Arch 2 — TodaysBiteView has an N+1 risk

```python
seen_ids = BiteAttempt.objects.filter(candidate=candidate).values_list('bite__bite_id', flat=True)
```

This is a lazy QuerySet. When passed to `Bite.objects.exclude(bite_id__in=seen_ids)`, Django generates a subquery — which is actually fine. But add `.distinct()` to prevent duplicates if a user attempted the same bite multiple times:

```python
seen_ids = BiteAttempt.objects.filter(candidate=candidate).values_list('bite__bite_id', flat=True).distinct()
```

### Arch 3 — Migrate ProgressProvider.dueCount to use the new /bites/due/ endpoint

Currently `dueCount` in `ProgressProvider` is always set to 0:

```dart
// main.dart
dueCount = 0; // always reset
```

The dashboard gets `srsDueCount` from `_todaysBite?['srs_due_count']` — only available when mode is 'review'. When mode is 'new', `srsDueCount` is 0 even if there are genuinely 5 review bites waiting.

**Fix:** Fetch `GET /api/bites/due/` in `fetchDashboardData()` and store the count:

```dart
Future<void> fetchDashboardData() async {
  isLoading = true;
  notifyListeners();
  candidateData = await _apiService.getProgress();
  tracingData = await _apiService.getKnowledgeTracing();
  final due = await _apiService.getDueBites();
  dueCount = (due?['due_count'] as int?) ?? 0;
  isLoading = false;
  notifyListeners();
}
```

### Arch 4 — Knowledge tracing endpoint is fetched but result is unused

`ProgressProvider.tracingData` is populated from `GET /api/knowledge-tracing/` on every dashboard load. But nothing in the dashboard, stats, or any screen reads `tracingData`. It's a wasted API call on every app open.

**Remove it from `fetchDashboardData()` for now.** Add it back when the TAMKOT model is trained and the probability is meaningful.

```dart
// main.dart ProgressProvider.fetchDashboardData()
// REMOVE this line:
tracingData = await _apiService.getKnowledgeTracing();
```

---

## PART 5 — TESTS TO ADD

`api/tests.py` has 2 tests — bite creation and SRS SM-2. These are good. Add:

```python
class SubmitBiteViewTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='tester', password='pass123test')
        self.client.force_authenticate(user=self.user)  # Use DRF test client
        self.bite = Bite.objects.create(
            bite_id='brbl_bite_001', paper_code='BRBL', module='NI Act',
            title='Test Bite', concept='c', question_text='q',
            question_type='mcq', options=['A','B','C','D'], answer='A', explanation='e'
        )

    def test_correct_mcq_answer(self):
        # ...

    def test_wrong_mcq_answer_does_not_increment_score(self):
        # ...

    def test_duplicate_correct_attempt_does_not_double_count(self):
        # Submit the same correct answer twice; score should still be 1
        # ...

    def test_numerical_answer_within_tolerance(self):
        bite = Bite.objects.create(bite_id='bfm_n_001', question_type='numerical', answer='4.63', tolerance=0.05, ...)
        # Submit '4.65' — should be correct (within 0.05 tolerance)
        # ...

class StreakUpdateTest(TestCase):
    def test_streak_increments_on_consecutive_days(self): ...
    def test_streak_resets_after_gap(self): ...
    def test_streak_does_not_double_increment_same_day(self): ...

class TodaysBiteViewTest(TestCase):
    def test_returns_srs_due_bite_first(self): ...
    def test_returns_unseen_bite_when_no_srs_due(self): ...
    def test_returns_all_seen_message_when_complete(self): ...
```

---

## PART 6 — PRIORITY TABLE

| # | Area | Item | Severity |
|---|------|------|----------|
| 1 | Backend | Fix double DATABASES definition — SQLite silently wins | 🔴 Critical |
| 2 | Backend | Fix ADMIN_SECRET check — runs before DEBUG, blocks dev startup | 🔴 Critical |
| 3 | Backend | Fix SubmitBiteView double-counting correct attempts | 🔴 Critical |
| 4 | Flutter | AuthProvider.checkToken() never called — users re-login on every launch | 🔴 Critical |
| 5 | Content | Only 20 bites exist — app is unusable beyond one session | 🔴 Critical |
| 6 | Backend | BiteSerializer exposes correct answers in Library API | 🔴 Critical |
| 7 | Flutter | JWT expires silently — no refresh, no re-login prompt | 🟠 High |
| 8 | Flutter | ReviewScreen broken flow — "Queue Empty" after first review | 🟠 High |
| 9 | Flutter | Stats screen accuracy and activity are hardcoded mocks | 🟠 High |
| 10 | Backend | Add `/api/stats/` endpoint for real accuracy + activity data | 🟠 High |
| 11 | Backend | Fix JWT SIMPLE_JWT config — contradictory rotation/blacklist | 🟠 High |
| 12 | Backend | CORS open in production | 🟠 High |
| 13 | Flutter | Register error message always generic — parse API response | 🟡 Medium |
| 14 | Flutter | BiteScreen has no "Next Bite" button — breaks flow | 🟡 Medium |
| 15 | Flutter | NumericalKeypad is white on dark background | 🟡 Medium |
| 16 | Flutter | Dashboard greeting hardcoded "Good morning" | 🟡 Medium |
| 17 | Flutter | Library: no mastery indicators on bite tiles | 🟡 Medium |
| 18 | Flutter | Library: search button does nothing | 🟡 Medium |
| 19 | Backend | Register missing password confirmation field | 🟡 Medium |
| 20 | Backend | EmailOrUsernameBackend timing oracle | 🟡 Medium |
| 21 | Backend | Register has duplicate `elective =` line | 🟡 Medium |
| 22 | Backend | admin.py is empty — register all models | 🟡 Medium |
| 23 | Backend | Dead services still imported — remove lazy loaders | 🟢 Low |
| 24 | Backend | SRSMetadata stale comment ("MongoDB") | 🟢 Low |
| 25 | Flutter | ProgressProvider fetches knowledge-tracing but result is unused | 🟢 Low |
| 26 | Flutter | VerticalPathIndicator height hardcoded 60px | 🟢 Low |
| 27 | Flutter | Dashboard profile IconButton does nothing | 🟢 Low |
| 28 | Backend | Add LOGGING config, DEFAULT_AUTO_FIELD, STATIC_ROOT | 🟢 Low |
| 29 | Tests | Add SubmitBiteView, Streak, TodaysBiteView test cases | 🟢 Low |
| 30 | Flutter | Add flutter_local_notifications to pubspec | 🟢 Low |

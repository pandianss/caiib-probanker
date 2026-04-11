# AI Prompt: CAIIB ProBanker — Full Code Review & Dashboard Overhaul

## Project State Summary

You are working on **CAIIB ProBanker** — a Flutter + Django REST Framework exam-prep app for the CAIIB banking certification exam.

**Stack:**
- Backend: Django 4.x + DRF + JWT (`simplejwt`) + PostgreSQL + MongoDB (JSON fallback)
- Mobile: Flutter (Dart), Provider state management, `google_fonts`, `http`, `flutter_secure_storage`
- ML: PyTorch LSTM (TAMKOT knowledge tracing), SuperMemo-2 SRS
- Theme: Dark-only, navy `#020617` bg, teal `#14B8A6` primary, gold `#F59E0B` secondary

**What has been built since v1:**
- Real JWT auth (Register + Login) — backend complete, Flutter screens exist
- `BaseAuthenticatedView` pattern is used across all backend views
- `UserActivity`, `ConsentLog`, `SubscriptionPlan` models added and migrated
- `study_streak`, `last_study_date`, `mobile_number` on Candidate
- `ProfileScreen` (edit name), `ElectiveSelector`, `SyllabusScreen`, `CaseStudyScreen`
- `SpacedRepetitionScreen` with SM-2 grading UI (6-button 0–5 row)
- `FlashcardScreen` (separate stub, hardcoded content)
- `ExamModeScreen` with virtual calculator and custom numerical keypad (hardcoded mock questions)
- `ProbabilityGauge` widget (animated arc, CustomPainter)
- `PaperProgressCard` widget

---

## SECTION 1 — DASHBOARD OVERHAUL (PRIMARY FOCUS)

The dashboard is the user's home screen and the most critical screen in the app. It currently has these serious problems:

### Problem 1: Streak counter is hardcoded
```dart
// dashboard_screen.dart line ~75
Text('3 Day Streak', style: ...)
```
The streak is a string literal. The backend has `study_streak` and `last_study_date` on the `Candidate` model and the serializer returns this data. Wire it up.

**Fix:**
```dart
final streak = provider.candidateData?['study_streak'] ?? 0;
// Display:
Text('$streak Day${streak == 1 ? '' : 's'} Streak')
```

### Problem 2: No bottom navigation bar — the app is structurally broken
There is no `BottomNavigationBar` or `NavigationBar` anywhere in the app. The user lands on the dashboard and has no visible way to go to Study, Exams, or SRS Review. The only navigation is a profile `IconButton` in the AppBar. This is the single most important structural fix.

**Fix — Add a `MainShell` widget and use it as the app's home:**

```dart
// lib/screens/shell/main_shell.dart

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    SyllabusScreen(),       // renamed "Study" tab
    SpacedRepetitionScreen(), // renamed "Review" tab
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF14B8A6).withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology), label: 'Review'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

In `main.dart`, replace `home: DashboardScreen()` with `home: MainShell()`. Remove the `ProfileScreen` push from the dashboard AppBar's IconButton — it's now in the nav bar.

### Problem 3: ProbabilityGauge dominates the screen but carries no real meaning
The gauge shows TAMKOT probability which is from an untrained PyTorch model with random weights. It always outputs a near-random value. It takes up a 200×200 CustomPaint box at the very top. Users stare at a meaningless number.

**Fix — Replace with an Aggregate Progress Card:**

Remove the `ProbabilityGauge` widget from the dashboard entirely for now (keep the widget file, it may be useful later when TAMKOT is trained). Replace the gauge container with a redesigned **Aggregate Score Card**:

```dart
Widget _buildAggregateCard(BuildContext context, List<dynamic> progressMap, int streak) {
  final double aggregate = progressMap.fold(0.0, (sum, p) => sum + (p['current_score'] as num).toDouble());
  final double aggregatePercent = aggregate / 500.0;
  final bool aggregatePassing = aggregate >= 250;
  final int papersCleared = progressMap.where((p) => (p['current_score'] as num) >= 45).length;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: aggregatePassing
            ? [const Color(0xFF0F766E), const Color(0xFF1E293B)]
            : [const Color(0xFF1E3A5F), const Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('CAIIB Aggregate', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: aggregatePassing ? const Color(0xFF14B8A6).withOpacity(0.2) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                aggregatePassing ? 'ON TRACK' : 'NEEDS WORK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: aggregatePassing ? const Color(0xFF14B8A6) : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              aggregate.toStringAsFixed(0),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8, left: 4),
              child: Text(' / 500', style: TextStyle(fontSize: 18, color: Colors.white38)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: aggregatePercent,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              aggregatePassing ? const Color(0xFF14B8A6) : const Color(0xFFF59E0B),
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatChip(label: '$papersCleared/5', sublabel: 'Papers Cleared'),
            const SizedBox(width: 12),
            _StatChip(label: '${(aggregatePercent * 100).toStringAsFixed(0)}%', sublabel: 'Aggregate'),
            const SizedBox(width: 12),
            _StatChip(label: '${250 - aggregate > 0 ? (250 - aggregate).toStringAsFixed(0) : "0"}', sublabel: 'Marks to Pass'),
          ],
        ),
      ],
    ),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String sublabel;
  const _StatChip({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            Text(sublabel, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}
```

### Problem 4: PaperProgressCard has no tap action and no CTA buttons
Cards render correctly but tapping them does nothing. There is no button to start an exam or study flashcards for that paper.

**Fix — Add `onTap` and action buttons to `PaperProgressCard`:**

```dart
// paper_progress_card.dart — replace the Card's child Column children

// At the bottom of the card, after the LinearProgressIndicator, add:
const SizedBox(height: 16),
Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.style_outlined, size: 16),
        label: const Text('Flashcards'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF14B8A6),
          side: const BorderSide(color: Color(0xFF14B8A6), width: 1),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onFlashcardsTap,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow_rounded, size: 16),
        label: const Text('Mock Exam'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: onExamTap,
      ),
    ),
  ],
),
```

Update the `PaperProgressCard` constructor to accept `VoidCallback? onFlashcardsTap` and `VoidCallback? onExamTap`.

In `dashboard_screen.dart`, pass:
```dart
PaperProgressCard(
  paperCode: paperDef['code']!,
  title: paperDef['name']!,
  currentScore: score.toDouble(),
  onFlashcardsTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => SpacedRepetitionScreen(paperCode: paperDef['code']!),
  )),
  onExamTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => ExamModeScreen(paperCode: paperDef['code']!),
  )),
)
```

### Problem 5: No "Today's Action" / SRS due count banner
The user has no idea how many flashcards are due. The backend has `GET /api/srs/due/` and the count is available.

**Fix — Add a "Due Today" banner below the greeting, above the aggregate card:**

```dart
Widget _buildDueTodayBanner(BuildContext context, int dueCount) {
  if (dueCount == 0) return const SizedBox.shrink();
  return GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => const SpacedRepetitionScreen(),
    )),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$dueCount flashcard${dueCount == 1 ? '' : 's'} due for review today',
              style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFF59E0B), size: 20),
        ],
      ),
    ),
  );
}
```

Add `dueCount` to `ProgressProvider`:
```dart
int dueCount = 0;

Future<void> fetchDashboardData() async {
  // ... existing fetches ...
  final due = await _apiService.getDueCards();
  dueCount = (due as List?)?.length ?? 0;
  // ...
}
```

Add `getDueCards()` to `ApiService`:
```dart
Future<List<dynamic>?> getDueCards() async {
  final token = await getToken();
  if (token == null) return null;
  final response = await http.get(
    Uri.parse('$_baseUrl/srs/due/'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) return jsonDecode(response.body);
  return null;
}
```

### Problem 6: Dashboard section header "Your Papers" needs exam history link
Add a `TextButton` next to "Your Papers" that opens a past-attempts sheet.

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Your Papers', style: Theme.of(context).textTheme.titleLarge),
    TextButton(
      onPressed: () => _showExamHistorySheet(context),
      child: const Text('History', style: TextStyle(color: Color(0xFF14B8A6))),
    ),
  ],
),
```

### Problem 7: Greeting section height waste
The "Welcome back / [name]" and streak chip are fine. But there is a `const SizedBox(height: 32)` before the aggregate card which makes the screen feel top-heavy on small devices. Reduce to 16.

### Problem 8: The AppBar is generic and has no back-navigation context
`title: const Text("PROBANKER")` is fine. But the `AppBar` should not show a `person` icon anymore once the bottom nav is added (Profile is tab 3). Remove the actions entirely from the dashboard AppBar or repurpose that slot:

```dart
actions: [
  // Show notification bell if there are due cards
  if (dueCount > 0)
    Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () { /* go to SRS */ },
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
],
```

---

## SECTION 2 — SCREEN-LEVEL BUGS & STUBS

### Bug 1: ExamScreen and ResultScreen are empty stubs
```dart
// exam_screen.dart
return const Scaffold(body: Center(child: Text('Exam Screen')));

// result_screen.dart
return const Scaffold(body: Center(child: Text('Result Screen')));
```
These are completely unimplemented. `ExamModeScreen` exists and is the real implementation. **Delete `exam_screen.dart` and `result_screen.dart`. Replace all navigation references with `ExamModeScreen`.**

### Bug 2: ExamModeScreen uses 2 hardcoded mock questions
```dart
final List<Map<String, dynamic>> _questions = [
  {"id": "q1", "type": "mcq", "question": "Which describes Narrow Banking?", ...},
  {"id": "q2", "type": "numerical", "question": "Calculate current yield...", ...}
];
```
The backend's `GET /api/exam/start/` returns real questions. Wire it up:

```dart
// In ExamModeScreen, add state:
List<Map<String, dynamic>> _questions = [];
int? _sessionId;
bool _isLoading = true;

@override
void initState() {
  super.initState();
  _loadExam();
}

Future<void> _loadExam() async {
  final result = await ApiService().startExam(widget.paperCode);
  if (result != null && mounted) {
    setState(() {
      _sessionId = result['session_id'];
      _questions = List<Map<String, dynamic>>.from(result['questions']);
      _isLoading = false;
    });
  }
}
```

Add to `ApiService`:
```dart
Future<Map<String, dynamic>?> startExam(String paperCode) async {
  final token = await getToken();
  if (token == null) return null;
  final response = await http.post(
    Uri.parse('$_baseUrl/exam/start/'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    body: jsonEncode({'paper_code': paperCode}),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  }
  return null;
}

Future<Map<String, dynamic>?> submitExam(int sessionId, List<Map<String, dynamic>> answers) async {
  final token = await getToken();
  if (token == null) return null;
  final response = await http.post(
    Uri.parse('$_baseUrl/exam/submit/'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    body: jsonEncode({'session_id': sessionId, 'answers': answers}),
  );
  if (response.statusCode == 200) return jsonDecode(response.body);
  return null;
}
```

### Bug 3: FlashcardScreen has hardcoded GDP deflator content
```dart
// flashcard_screen.dart
'A measure of the level of prices...' // hardcoded
'What is the GDP Deflator?' // hardcoded
```
`FlashcardScreen` and `SpacedRepetitionScreen` serve the same purpose and should be merged. **Delete `flashcard_screen.dart`. Route everything to `SpacedRepetitionScreen`.** Update the `SpacedRepetitionScreen` to accept an optional `paperCode` parameter so it can filter due cards by paper.

### Bug 4: SRS grading is inconsistent across screens
`SpacedRepetitionScreen` uses a 6-button (0–5) horizontal row labeled: Blackout, Failed, Difficulty, Good, Bright, Perfect.

`FlashcardScreen` uses 3 circular buttons: Hard (1), Good (3), Easy (5).

Since `FlashcardScreen` is being deleted, standardize on the 3-button approach inside `SpacedRepetitionScreen`. It is cleaner UX for banking exam candidates. Replace the 6 small buttons with:

```dart
// In _buildGradingBar, replace List.generate with:
Row(
  children: [
    _GradeButton(label: 'Missed', sublabel: 'Reset card', quality: 1, color: const Color(0xFFEF4444)),
    const SizedBox(width: 10),
    _GradeButton(label: 'Hard', sublabel: 'Review soon', quality: 3, color: const Color(0xFFF59E0B)),
    const SizedBox(width: 10),
    _GradeButton(label: 'Got it', sublabel: 'Schedule later', quality: 5, color: const Color(0xFF14B8A6)),
  ],
)

// Each _GradeButton is an Expanded OutlinedButton with label + sublabel
```

### Bug 5: `ApiService._baseUrl` is `127.0.0.1` — won't work on Android device
```dart
final String _baseUrl = 'http://127.0.0.1:8000/api';
```
On Android emulator, `10.0.2.2` maps to the host. On a physical Android device, neither works. Use an environment-injectable constant:

```dart
// lib/config/app_config.dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api', // Android emulator default
  );
}
```

Pass `--dart-define=API_BASE_URL=http://192.168.x.x:8000/api` during build/run.

### Bug 6: ExamModeScreen timer is hardcoded
```dart
Text('119:54', style: ... Colors.redAccent ...)
```
The timer is a static string. Add a real countdown:

```dart
late Timer _timer;
int _remainingSeconds = 7200; // 2 hours = CAIIB exam duration

@override
void initState() {
  super.initState();
  _timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (_remainingSeconds > 0) {
      setState(() => _remainingSeconds--);
    } else {
      _timer.cancel();
      _submitExam(); // auto-submit on timeout
    }
  });
}

String get _timerDisplay {
  final m = _remainingSeconds ~/ 60;
  final s = _remainingSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
```

Display color: red when `_remainingSeconds < 300` (5 minutes), amber when `< 900` (15 min), white otherwise.

### Bug 7: MCQ options in ExamModeScreen have no selected state
```dart
onPressed: () {},  // does nothing, no selection tracking
```
Add a `Map<int, String> _selectedAnswers` to track user picks and update the button style:

```dart
final Map<int, String> _selectedAnswers = {};

// In _buildMCQOptions:
OutlinedButton(
  style: OutlinedButton.styleFrom(
    backgroundColor: _selectedAnswers[_currentIndex] == opt
        ? const Color(0xFF14B8A6).withOpacity(0.15)
        : Colors.transparent,
    side: BorderSide(
      color: _selectedAnswers[_currentIndex] == opt
          ? const Color(0xFF14B8A6)
          : Colors.grey.withOpacity(0.3),
      width: _selectedAnswers[_currentIndex] == opt ? 2 : 1,
    ),
    ...
  ),
  onPressed: () => setState(() => _selectedAnswers[_currentIndex] = opt),
  child: ...
)
```

---

## SECTION 3 — BACKEND REMAINING ISSUES

### Backend Bug 1: Exam submit still marks all answers correct
```python
# views.py SubmitExamView
is_correct=True, marks_obtained=1.0  # mock — hardcoded!
```
Fetch questions from `content_service`, build a lookup dict, compare against submitted answers. For MCQ use case-insensitive strip match. For numerical, use `abs(float(submitted) - float(correct)) < 0.01`.

### Backend Bug 2: `elective` is duplicated in `RegisterView`
```python
elective = request.data.get('elective', '').strip()
elective = request.data.get('elective', '').strip()  # duplicated line
```
Remove the duplicate line.

### Backend Bug 3: `PaperProgress.paper_code` choices don't include elective codes
```python
PAPER_CHOICES = [
  ('ABM', ...), ('BFM', ...), ('ABFM', ...), ('BRBL', ...), ('ELECTIVE', ...)
]
```
The actual elective codes stored are `RURAL`, `HRM`, `IT_DB`, `RISK`, `CENTRAL`. But the model only knows `ELECTIVE`. Either remove `choices=` restriction from `paper_code` field (recommended, since it is a FK reference not a true choice set), or expand the choices to include all real elective codes:

```python
paper_code = models.CharField(max_length=20)  # Remove choices= constraint
```

Then add a migration.

### Backend Bug 4: `ScoringService.check_aggregate_pass` divides incorrectly
```python
aggregate = sum(p.current_score for p in all_progress)
is_aggregate_pass = aggregate >= 250  # 50% of 500
```
But the condition above this says `all_progress.count() < 5` — meaning it returns `False` if fewer than 5 papers are submitted. The CAIIB has 4 compulsory + 1 elective = 5 papers. However, a candidate can attempt papers in different exam sittings. The check should be: "have all 5 been attempted at least once?" regardless of session. This logic is correct in spirit but the error message says "5 papers" while `PaperProgress` might store elective codes that don't match the count. Ensure the progress update in `ScoringService.calculate_session_result` uses the actual elective code not `'ELECTIVE'`.

### Backend Bug 5: `CandidateSerializer` must include `study_streak` and `mobile_number`
Check `serializers.py` — if `study_streak` is not in `fields`, the Flutter dashboard will always show 0.

```python
class CandidateSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    progress = PaperProgressSerializer(many=True, read_only=True)
    
    class Meta:
        model = Candidate
        fields = [
            'id', 'first_name', 'last_name', 'email', 'mobile_number',
            'selected_elective', 'study_streak', 'last_study_date',
            'attempts_count', 'start_date', 'progress'
        ]
```

### Backend Bug 6: Study streak is never updated
`study_streak` and `last_study_date` fields exist on the model but no view updates them. Add a helper method to `BaseAuthenticatedView`:

```python
def update_streak(self, candidate):
    from datetime import date, timedelta
    today = date.today()
    if candidate.last_study_date is None:
        candidate.study_streak = 1
    elif candidate.last_study_date == today:
        return  # Already studied today
    elif candidate.last_study_date == today - timedelta(days=1):
        candidate.study_streak += 1
    else:
        candidate.study_streak = 1  # Streak broken
    candidate.last_study_date = today
    candidate.save(update_fields=['study_streak', 'last_study_date'])
```

Call `self.update_streak(candidate)` inside `SubmitExamView.post()` and `RecordReviewView.post()`.

---

## SECTION 4 — NEW FEATURE: ResultScreen (replace the stub)

`result_screen.dart` is currently `const Text('Result Screen')`. Implement it properly. It should be pushed from `ExamModeScreen` after `submitExam` returns:

```dart
// result_screen.dart

class ResultScreen extends StatelessWidget {
  final double score;
  final bool isPaper Pass;
  final String paperCode;
  final Map<String, dynamic> aggregateStatus;

  const ResultScreen({
    super.key,
    required this.score,
    required this.isPaperPass,
    required this.paperCode,
    required this.aggregateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPass = isPaperPass;
    final Color resultColor = isPass ? const Color(0xFF14B8A6) : const Color(0xFFEF4444);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, __) => Transform.scale(
                  scale: v,
                  child: Icon(
                    isPass ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: resultColor,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isPass ? 'Paper Cleared!' : 'Not Cleared',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: resultColor),
              ),
              const SizedBox(height: 8),
              Text(paperCode, style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 32),
              // Score display
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text('${score.toStringAsFixed(1)}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('out of 100', style: TextStyle(color: Colors.white38)),
                    const SizedBox(height: 8),
                    Text(
                      isPass ? 'Minimum 45 required — Passed ✓' : 'Minimum 45 required — ${(45 - score).toStringAsFixed(0)} marks short',
                      style: TextStyle(color: resultColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Aggregate section
              Text(
                aggregateStatus['aggregate_status']?.toString() ?? '',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Text('Dashboard'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ExamModeScreen(paperCode: paperCode),
                        ));
                      },
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## SECTION 5 — PUBSPEC ADDITIONS

Add to `pubspec.yaml` under `dependencies:`:

```yaml
flutter_local_notifications: ^18.0.0   # SRS due reminders
percent_indicator: ^4.2.3               # Optional: cleaner arc gauges
```

---

## SUMMARY TABLE — Ordered by Priority

| # | Area | Item | Severity |
|---|------|------|----------|
| 1 | Dashboard | Add `MainShell` with `NavigationBar` — app has no nav | 🔴 Critical |
| 2 | Dashboard | Wire streak from API (currently hardcoded `"3 Day Streak"`) | 🔴 Critical |
| 3 | Dashboard | Replace gauge with Aggregate Progress Card | 🔴 Critical |
| 4 | Dashboard | Add SRS due-today banner | 🟠 High |
| 5 | Dashboard | Add Flashcard + Mock Exam buttons to PaperProgressCard | 🟠 High |
| 6 | Exam | ExamModeScreen: load real questions from API | 🔴 Critical |
| 7 | Exam | ExamModeScreen: implement real countdown timer | 🟠 High |
| 8 | Exam | ExamModeScreen: track MCQ selected state visually | 🟠 High |
| 9 | Exam | Delete stub `ExamScreen` and `ResultScreen`, implement real `ResultScreen` | 🟠 High |
| 10 | Backend | Fix `SubmitExamView` — stop marking everything correct | 🔴 Critical |
| 11 | Backend | Remove duplicate `elective` line in `RegisterView` | 🟡 Medium |
| 12 | Backend | Fix `PaperProgress.paper_code` choices to include real elective codes | 🟡 Medium |
| 13 | Backend | Call `update_streak()` from exam submit and SRS review | 🟡 Medium |
| 14 | Backend | Ensure `CandidateSerializer` includes `study_streak` | 🟡 Medium |
| 15 | SRS | Merge `FlashcardScreen` into `SpacedRepetitionScreen` | 🟡 Medium |
| 16 | SRS | Replace 6-button grading row with 3-button (Missed/Hard/Got it) | 🟡 Medium |
| 17 | Network | Fix `ApiService._baseUrl` — use `AppConfig` with `--dart-define` | 🟠 High |
| 18 | Dashboard | Remove Profile IconButton from AppBar (now in nav bar) | 🟢 Low |
| 19 | Dashboard | Add exam history `TextButton` beside "Your Papers" header | 🟢 Low |
| 20 | Dashboard | Reduce `SizedBox(height: 32)` above aggregate card to 16 | 🟢 Low |

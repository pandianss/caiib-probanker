# AI Prompt: Rebrand & Redesign "CAIIB ProBanker" → "CAIIB Bitsize"

## The Big Idea

Rename and redesign the app from **CAIIB ProBanker** to **CAIIB Bitsize**. This is not just a name change — it is a product philosophy shift.

**Old philosophy:** Study when you can, take full mock exams, track aggregate scores.

**New philosophy:** Every day you get a small, focused portion of CAIIB content delivered in under 10 minutes. Bite. Learn. Done. Come back tomorrow.

The model is closer to Duolingo or Morning Brew than to a test-prep portal. The CAIIB syllabus is dense (ABM, BFM, ABFM, BRBL + elective), but every single topic can be broken into atomic, digestible units. The app's job is to surface one unit per session, reinforce it through spaced repetition, and build cumulative mastery over weeks.

---

## PART 1 — BRANDING

### App Name
`CAIIB Bitsize` — two words, consistent casing. Tagline: **"One bite at a time."**

### Color Palette — Replace
The current dark navy + teal palette feels like a fintech dashboard. Bitsize should feel warm, motivating, and approachable — like a smart study companion, not a Bloomberg terminal.

Remove:
```
backgroundDark: #020617  (too cold, near-black)
primaryNavy:    #0F172A
secondaryTeal:  #14B8A6
```

Replace with:

```dart
// lib/theme/app_theme.dart — new palette

static const Color backgroundDark  = Color(0xFF0D1117); // softer near-black with warm undertone
static const Color surfaceDark      = Color(0xFF161B22); // card surface
static const Color surfaceElevated  = Color(0xFF21262D); // elevated cards
static const Color primaryIndigo    = Color(0xFF6366F1); // indigo — knowledge, depth
static const Color accentAmber      = Color(0xFFFBBF24); // amber — energy, streaks
static const Color accentEmerald    = Color(0xFF10B981); // emerald — success, mastery
static const Color errorRose        = Color(0xFFF43F5E); // rose — wrong answers
static const Color textPrimary      = Color(0xFFE6EDF3);
static const Color textMuted        = Color(0xFF8B949E);
```

The indigo primary signals "knowledge" rather than "finance". Amber keeps the streak/reward energy. Emerald replaces teal for pass states.

### Logo / App Icon Concept
A small square tile (like a puzzle piece or Scrabble tile) with the letters **"Bi"** in a bold rounded font, and a subtle graduation mortarboard incorporated. Provide this as a description to a designer / image-gen tool — do not hardcode an icon file.

### Typography — Keep `google_fonts` but change the pairing
```dart
// Display / Headlines
GoogleFonts.plusJakartaSans(...)   // replaces Outfit — more modern, slightly playful

// Body text
GoogleFonts.inter(...)             // keep — excellent readability
```

Update `AppTheme.darkTheme` text theme accordingly.

---

## PART 2 — CONTENT ARCHITECTURE PIVOT

The most important change is how content is structured. Currently the app has:

```
Paper → Questions (list) + Flashcards (list)
```

**Bitsize replaces this with:**

```
Paper → Module → Bite
```

A **Bite** is an atomic learning unit. It has:
- A title (max 8 words, e.g. "What is Modified Duration?")
- A concept block (2–4 sentences of explanation)
- One illustrative example or formula
- One check question (MCQ or numerical, 1 question only)
- Tags: `[paper_code, module, difficulty: easy|medium|hard, type: conceptual|numerical|regulatory]`
- An estimated read time: always 3–7 minutes

Think of it as the intersection of a flashcard and a micro-lesson.

### New JSON Schema for Bites

Replace `bfm_content.json`, `abm_content.json`, etc. with `bfm_bites.json` format:

```json
{
  "paper_code": "BFM",
  "module": "Treasury & ALM",
  "bites": [
    {
      "id": "bfm_bite_001",
      "title": "What is Modified Duration?",
      "concept": "Modified Duration measures how sensitive a bond's price is to a 1% change in interest rates. It is derived from Macaulay Duration by dividing by (1 + yield). A bond with Modified Duration of 5 will fall roughly 5% in price if rates rise by 1%.",
      "example": "If MD = 4.5 and yield rises by 0.5%, the approximate price change = –4.5 × 0.5% = –2.25%.",
      "formula": "Modified Duration = Macaulay Duration / (1 + Yield)",
      "check_question": {
        "type": "numerical",
        "question": "A bond has Macaulay Duration of 5 years and YTM of 8%. What is its Modified Duration?",
        "answer": "4.63",
        "tolerance": 0.05,
        "explanation": "MD = 5 / (1 + 0.08) = 5 / 1.08 = 4.63 years."
      },
      "tags": ["BFM", "Treasury & ALM", "medium", "numerical"],
      "estimated_minutes": 5
    }
  ]
}
```

Create bite files for all 4 compulsory papers plus each elective:
- `abm_bites.json` — 40+ bites (statistics, macroeconomics, HR, credit mgmt)
- `bfm_bites.json` — 40+ bites (forex, Basel, treasury, ALM)
- `abfm_bites.json` — 30+ bites (capital budgeting, WACC, valuation, M&A)
- `brbl_bites.json` — 40+ bites (RBI Act, NI Act, SARFAESI, KYC/AML)
- `elective_rural_bites.json`, `elective_hrm_bites.json`, `elective_risk_bites.json`, `elective_itdb_bites.json`, `elective_central_bites.json`

Each file must have at least 30 bites at launch. Prioritise the topics that appear most frequently in past CAIIB papers.

### Backend Model Change

Replace `questions` and `flashcards` collections/JSON with a unified `Bite` model:

```python
# api/models.py — add

class Bite(models.Model):
    DIFFICULTY_CHOICES = [('easy','Easy'), ('medium','Medium'), ('hard','Hard')]
    TYPE_CHOICES = [('conceptual','Conceptual'), ('numerical','Numerical'), ('regulatory','Regulatory')]

    bite_id       = models.CharField(max_length=50, unique=True)  # e.g. bfm_bite_001
    paper_code    = models.CharField(max_length=20)
    module        = models.CharField(max_length=100)
    title         = models.CharField(max_length=200)
    concept       = models.TextField()
    example       = models.TextField(blank=True)
    formula       = models.CharField(max_length=300, blank=True)
    question_text = models.TextField()
    question_type = models.CharField(max_length=20, choices=[('mcq','MCQ'),('numerical','Numerical')])
    options       = models.JSONField(null=True, blank=True)       # for MCQ only
    answer        = models.CharField(max_length=200)
    tolerance     = models.FloatField(default=0.0)               # for numerical
    explanation   = models.TextField()
    difficulty    = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='medium')
    bite_type     = models.CharField(max_length=20, choices=TYPE_CHOICES, default='conceptual')
    estimated_minutes = models.IntegerField(default=5)
    tags          = models.JSONField(default=list)
    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['paper_code', 'module', 'bite_id']
```

Add a `management/commands/seed_bites.py` that loads all `*_bites.json` files and upserts into the `Bite` table using `update_or_create(bite_id=...)`.

### New API Endpoints

Replace the old content endpoints:

```python
# api/urls.py — replace paper-content and exam/* with:

path('bites/today/',           TodaysBiteView.as_view(),    name='bites-today'),
path('bites/<str:paper_code>/', PaperBitesView.as_view(),   name='paper-bites'),
path('bites/submit/',          SubmitBiteView.as_view(),    name='submit-bite'),
path('bites/history/',         BiteHistoryView.as_view(),   name='bite-history'),
```

**`TodaysBiteView` (GET)** — The heart of the app. Returns the next unlearned or due-for-review bite for the user. Priority order:
1. SRS due bites (overdue first)
2. Weakest paper's next unseen bite
3. Random unseen bite from selected elective

```python
class TodaysBiteView(BaseAuthenticatedView):
    def get(self, request):
        candidate = self.get_candidate(request)
        
        # 1. Check SRS due
        due = SRSMetadata.objects.filter(
            candidate=candidate, 
            next_review__lte=timezone.now()
        ).order_by('next_review').first()
        
        if due:
            try:
                bite = Bite.objects.get(bite_id=due.card_id)
                return Response({'bite': BiteSerializer(bite).data, 'mode': 'review', 'srs_due_count': SRSMetadata.objects.filter(candidate=candidate, next_review__lte=timezone.now()).count()})
            except Bite.DoesNotExist:
                pass
        
        # 2. Find next unseen bite from weakest paper
        seen_ids = BiteAttempt.objects.filter(candidate=candidate).values_list('bite__bite_id', flat=True)
        weakest = candidate.progress.order_by('current_score').first()
        paper_filter = weakest.paper_code if weakest else candidate.selected_elective or 'ABM'
        
        bite = Bite.objects.exclude(bite_id__in=seen_ids).filter(paper_code=paper_filter).first()
        if not bite:
            bite = Bite.objects.exclude(bite_id__in=seen_ids).first()
        
        if not bite:
            return Response({'message': 'all_bites_seen', 'total_bites': Bite.objects.count()})
        
        return Response({'bite': BiteSerializer(bite).data, 'mode': 'new'})
```

**`SubmitBiteView` (POST)** — User submits their answer to the bite's check question. Body: `{bite_id, answer, time_taken_seconds}`. Returns: `{is_correct, explanation, next_review_date, srs_quality}`.

```python
class SubmitBiteView(BaseAuthenticatedView):
    def post(self, request):
        candidate = self.get_candidate(request)
        bite_id = request.data.get('bite_id')
        user_answer = str(request.data.get('answer', '')).strip()
        time_taken = request.data.get('time_taken_seconds', 0)
        
        try:
            bite = Bite.objects.get(bite_id=bite_id)
        except Bite.DoesNotExist:
            return Response({'error': 'Bite not found'}, status=404)
        
        # Grade answer
        is_correct = False
        if bite.question_type == 'mcq':
            is_correct = user_answer.lower() == bite.answer.lower()
        elif bite.question_type == 'numerical':
            try:
                is_correct = abs(float(user_answer) - float(bite.answer)) <= bite.tolerance
            except ValueError:
                is_correct = False
        
        # SRS quality mapping: correct+fast=5, correct+slow=4, wrong=1
        if is_correct:
            srs_quality = 5 if time_taken < 30 else 4
        else:
            srs_quality = 1
        
        # Update SRS
        meta, _ = SRSMetadata.objects.get_or_create(
            candidate=candidate, card_id=bite_id,
            defaults={'next_review': timezone.now()}
        )
        SRSService.update_card(meta, srs_quality)
        
        # Record attempt
        BiteAttempt.objects.create(
            candidate=candidate, bite=bite,
            user_answer=user_answer, is_correct=is_correct,
            time_taken_seconds=time_taken
        )
        
        # Update paper progress score
        self._update_paper_score(candidate, bite.paper_code)
        self.update_streak(candidate)
        
        return Response({
            'is_correct': is_correct,
            'correct_answer': bite.answer,
            'explanation': bite.explanation,
            'next_review': meta.next_review,
            'srs_quality': srs_quality,
        })
```

Add `BiteAttempt` model:

```python
class BiteAttempt(models.Model):
    candidate        = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='bite_attempts')
    bite             = models.ForeignKey(Bite, on_delete=models.CASCADE)
    user_answer      = models.CharField(max_length=300)
    is_correct       = models.BooleanField()
    time_taken_seconds = models.IntegerField(default=0)
    attempted_at     = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-attempted_at']
```

---

## PART 3 — FLUTTER UI OVERHAUL

### 3.1 — New App Entry

```dart
// main.dart — update title and theme
MaterialApp(
  title: 'CAIIB Bitsize',
  theme: AppTheme.darkTheme,   // with new palette
  ...
)
```

### 3.2 — New Dashboard Screen

The dashboard is the first thing users see every day. Its entire job is to answer one question: **"What should I do right now?"**

The new layout (top to bottom, single scroll column):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Good morning, Priya  🔥 7 days
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ┌─────────────────────────────┐
  │   TODAY'S BITE              │   ← Hero card — most prominent element
  │   BFM · Treasury & ALM      │
  │                             │
  │   "What is Modified         │
  │    Duration?"               │
  │                             │
  │   ⏱ 5 min  •  Medium       │
  │                             │
  │   [ START TODAY'S BITE  →]  │
  └─────────────────────────────┘

  ┌───────────┐ ┌───────────┐
  │ 12        │ │ 3         │   ← two stat chips
  │ Bites     │ │ Due for   │
  │ Mastered  │ │ Review    │
  └───────────┘ └───────────┘

  YOUR PROGRESS
  ┌─────────────────────────────┐
  │ ABM  ████████░░░░  32%  12 bites
  │ BFM  ██████░░░░░░  24%   9 bites
  │ ABFM ████░░░░░░░░  16%   6 bites
  │ BRBL ██████████░░  40%  15 bites
  │ HRM  ███░░░░░░░░░  12%   4 bites
  └─────────────────────────────┘

  CONTINUE STUDYING            [See All]
  ┌──────────────────────────────┐
  │  Basel III — Pillar 1       │  ← recently studied, tap to resume
  │  BFM · 3 min ago            │
  └──────────────────────────────┘
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Implement the "Today's Bite" hero card:**

```dart
// lib/widgets/todays_bite_card.dart

class TodaysBiteCard extends StatelessWidget {
  final Map<String, dynamic> bite;
  final String mode; // 'new' or 'review'
  final VoidCallback onStart;

  const TodaysBiteCard({
    super.key,
    required this.bite,
    required this.mode,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReview = mode == 'review';
    final Color accentColor = isReview ? const Color(0xFFFBBF24) : const Color(0xFF6366F1);

    return GestureDetector(
      onTap: onStart,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isReview
                ? [const Color(0xFF451A03), const Color(0xFF161B22)]
                : [const Color(0xFF1E1B4B), const Color(0xFF161B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isReview ? '🔁 REVIEW DUE' : '✨ TODAY\'S BITE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
                const Spacer(),
                Text(
                  bite['paper_code'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bite['title'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              bite['module'] ?? '',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8B949E)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  '${bite['estimated_minutes'] ?? 5} min',
                  style: TextStyle(fontSize: 13, color: accentColor),
                ),
                const SizedBox(width: 16),
                _DifficultyDot(difficulty: bite['difficulty'] ?? 'medium'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: onStart,
                child: Text(
                  isReview ? 'Review Now' : 'Start Learning',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyDot extends StatelessWidget {
  final String difficulty;
  const _DifficultyDot({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = difficulty == 'easy'
        ? const Color(0xFF10B981)
        : difficulty == 'hard'
            ? const Color(0xFFF43F5E)
            : const Color(0xFFFBBF24);
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(difficulty[0].toUpperCase() + difficulty.substring(1),
            style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
```

**Progress bars section (replaces PaperProgressCard):**

```dart
// lib/widgets/paper_bite_progress.dart
// Shows: paper name, bite count mastered, linear progress bar
// Much more compact — 5 papers fit in a single card without scrolling

class PaperBiteProgressList extends StatelessWidget {
  final List<Map<String, dynamic>> papers; // [{code, name, mastered, total}]

  const PaperBiteProgressList({super.key, required this.papers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: papers.map((p) => _PaperRow(paper: p)).toList(),
      ),
    );
  }
}

class _PaperRow extends StatelessWidget {
  final Map<String, dynamic> paper;
  const _PaperRow({required this.paper});

  @override
  Widget build(BuildContext context) {
    final int mastered = paper['mastered'] ?? 0;
    final int total    = paper['total'] ?? 1;
    final double pct   = mastered / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(paper['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              Text('$mastered / $total bites', style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3.3 — New Core Screen: `BiteScreen`

This is the most important new screen. It replaces both `ExamModeScreen` and `FlashcardScreen` as the primary study interaction. It has three sequential phases:

**Phase 1 — Learn** (concept + example + formula):
```dart
// Scrollable card with:
// - Badge: paper code + module
// - Title (large, bold)
// - Concept text (readable body, good line height)
// - Formula block (monospace, indigo background)
// - Example block (amber left border)
// - "I've read this" CTA → advances to Phase 2
```

**Phase 2 — Check** (1 question):
```dart
// - Question text
// - If MCQ: tappable option cards (same selection state fix as before)
// - If numerical: custom keypad (reuse NumericalKeypad widget)
// - Timer bar at top (counts up, not a countdown — no pressure)
// - "Submit Answer" CTA
```

**Phase 3 — Result** (feedback, SRS info):
```dart
// - ✓ or ✗ with animation (TweenAnimationBuilder scale)
// - Correct answer revealed if wrong
// - Explanation text
// - "Next review in X days" chip
// - Two buttons:
//   [Back to Dashboard]    [Next Bite →]
//   (Next Bite only shown if another unseen bite exists in the same paper)
```

Full widget structure:

```dart
// lib/screens/bite/bite_screen.dart

enum BitePhase { learn, check, result }

class BiteScreen extends StatefulWidget {
  final Map<String, dynamic> bite;
  const BiteScreen({super.key, required this.bite});

  @override
  State<BiteScreen> createState() => _BiteScreenState();
}

class _BiteScreenState extends State<BiteScreen> {
  BitePhase _phase = BitePhase.learn;
  String? _selectedAnswer;
  bool? _isCorrect;
  Map<String, dynamic>? _resultData;
  int _startTime = 0;

  void _advanceToCheck() {
    _startTime = DateTime.now().millisecondsSinceEpoch;
    setState(() => _phase = BitePhase.check);
  }

  Future<void> _submitAnswer() async {
    final elapsed = ((DateTime.now().millisecondsSinceEpoch - _startTime) / 1000).round();
    final result = await ApiService().submitBite(
      biteId: widget.bite['id'],
      answer: _selectedAnswer ?? '',
      timeTakenSeconds: elapsed,
    );
    if (result != null && mounted) {
      setState(() {
        _isCorrect = result['is_correct'];
        _resultData = result;
        _phase = BitePhase.result;
      });
      // Refresh dashboard provider in background
      context.read<ProgressProvider>().fetchDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _phase == BitePhase.learn
              ? _LearnPhase(bite: widget.bite, onDone: _advanceToCheck)
              : _phase == BitePhase.check
                  ? _CheckPhase(
                      bite: widget.bite,
                      selectedAnswer: _selectedAnswer,
                      onSelect: (a) => setState(() => _selectedAnswer = a),
                      onSubmit: _submitAnswer,
                    )
                  : _ResultPhase(
                      bite: widget.bite,
                      isCorrect: _isCorrect!,
                      resultData: _resultData!,
                    ),
        ),
      ),
    );
  }
}
```

Add `submitBite` to `ApiService`:

```dart
Future<Map<String, dynamic>?> submitBite({
  required String biteId,
  required String answer,
  required int timeTakenSeconds,
}) async {
  final token = await getToken();
  if (token == null) return null;
  final response = await http.post(
    Uri.parse('$_baseUrl/bites/submit/'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    body: jsonEncode({'bite_id': biteId, 'answer': answer, 'time_taken_seconds': timeTakenSeconds}),
  );
  if (response.statusCode == 200) return jsonDecode(response.body);
  return null;
}

Future<Map<String, dynamic>?> getTodaysBite() async {
  final token = await getToken();
  if (token == null) return null;
  final response = await http.get(
    Uri.parse('$_baseUrl/bites/today/'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) return jsonDecode(response.body);
  return null;
}
```

### 3.4 — Bottom Navigation Update

The nav bar changes to reflect the new product:

```dart
NavigationBar(
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home_outlined),      selectedIcon: Icon(Icons.home),      label: 'Home'),
    NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Library'),   // browse all bites by paper/module
    NavigationDestination(icon: Icon(Icons.psychology_outlined),selectedIcon: Icon(Icons.psychology), label: 'Review'),   // SRS due queue
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Stats'),    // replaces Profile tab — stats are more useful
  ],
)
```

Profile is accessed from a `person` icon in the Home AppBar (or a settings button inside Stats).

### 3.5 — Library Screen (new)

Browse all bites organized by paper → module. Allows the user to study out of sequence when they want to focus on a specific topic.

```dart
// lib/screens/library/library_screen.dart

// Structure:
// AppBar: "Library"  [Search icon]
// FilterChips: [All] [ABM] [BFM] [ABFM] [BRBL] [Your Elective]
// Grouped ListView:
//   Section: "Treasury & ALM" (8 bites)
//     BiteListTile: "What is Modified Duration?" • Medium • ✓ Mastered
//     BiteListTile: "Macaulay vs Modified Duration" • Hard • ○ Not seen
//   Section: "Risk Management — Basel" (6 bites)
//     ...

class BiteListTile extends StatelessWidget {
  final Map<String, dynamic> bite;
  final bool isMastered;
  
  // Tapping navigates to BiteScreen(bite: bite)
}
```

Add API method:
```dart
Future<List<dynamic>?> getBitesByPaper(String paperCode) async {
  // GET /api/bites/{paper_code}/
}
```

### 3.6 — Stats Screen (replaces standalone Profile)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Stats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔥  7 Day Streak
  
  ┌──────────┬──────────┬──────────┐
  │  46      │  38      │  87%     │
  │ Mastered │ Reviewed │ Accuracy │
  └──────────┴──────────┴──────────┘

  ACTIVITY (last 7 days)
  Mon Tue Wed Thu Fri Sat Sun
  ●   ●   ●   ●   ○   ●   ●      (dot = studied that day)

  MASTERY BY PAPER
  ABM  ████████░░  32%
  BFM  ██████░░░░  24%
  ...

  ─────────────────────────────────
  [My Profile]     [Change Elective]
  ─────────────────────────────────
```

---

## PART 4 — FILES TO DELETE / RENAME

| Action | File |
|--------|------|
| DELETE | `lib/screens/exam/exam_screen.dart` (empty stub) |
| DELETE | `lib/screens/exam/result_screen.dart` (empty stub) |
| DELETE | `lib/screens/study/flashcard_screen.dart` (hardcoded, redundant) |
| DELETE | `lib/screens/exam_mode_screen.dart` (replaced by BiteScreen) |
| DELETE | `lib/widgets/paper_progress_card.dart` (replaced by PaperBiteProgressList) |
| DELETE | `lib/widgets/probability_gauge.dart` (gauge removed — TAMKOT not trained) |
| RENAME | `lib/screens/srs_screen.dart` → keep as `lib/screens/review/review_screen.dart` |
| RENAME | `lib/screens/home/dashboard_screen.dart` → keep, full rewrite above |
| RENAME | `api/data/bfm_content.json` → `api/data/bfm_bites.json` (schema change) |
| KEEP | `lib/widgets/virtual_calculator.dart` (used inside BiteScreen check phase) |
| KEEP | `lib/widgets/numerical_keypad.dart` (used inside BiteScreen check phase) |
| KEEP | `lib/widgets/flashcard_widget.dart` (repurpose for Review screen cards) |
| KEEP | All auth screens — no changes needed |
| KEEP | `lib/screens/profile/` — minor updates only |

---

## PART 5 — APPBAR & COPY CHANGES

Replace all remaining instances of "PROBANKER" in the codebase:

```bash
# Search and replace
grep -r "PROBANKER\|ProBanker\|probanker" mobile/lib/ --include="*.dart"
```

Replace with:
- `"PROBANKER"` → `"BITSIZE"`
- `"CAIIB ProBanker"` → `"CAIIB Bitsize"`
- `"probanker"` (package names) → `"caiib_bitsize"`

Update `pubspec.yaml`:
```yaml
name: caiib_bitsize
description: "CAIIB Bitsize — Learn one bite at a time."
```

Update `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="CAIIB Bitsize"
```

---

## PART 6 — PRIORITY ORDER

| # | What | Why |
|---|------|-----|
| 1 | Create `Bite` and `BiteAttempt` models + migrate | Everything else depends on this |
| 2 | Write `seed_bites.py` + create all `*_bites.json` files | No content = no app |
| 3 | Build `TodaysBiteView` and `SubmitBiteView` backend | Core loop |
| 4 | Build `BiteScreen` (3 phases: Learn → Check → Result) | Core loop |
| 5 | Rewrite `DashboardScreen` with new layout + `TodaysBiteCard` | First impression |
| 6 | Update branding: name, palette, font | Identity |
| 7 | Build `LibraryScreen` | Browsability |
| 8 | Build `StatsScreen` | Retention / motivation |
| 9 | Update `ReviewScreen` (SRS queue) to use Bite model | SRS still core |
| 10 | Delete obsolete files | Code hygiene |
| 11 | Fix `ApiService._baseUrl` → `AppConfig` | Device testing |
| 12 | Add `flutter_local_notifications` for daily bite reminder | Habit forming |

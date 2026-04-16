# CAIIB ProBanker — Pedagogical & UX Overhaul Prompt

## Project Context

You are working on **CAIIB ProBanker**, a Flutter + Django REST Framework exam-prep app for the CAIIB (Certified Associate of the Indian Institute of Bankers) banking certification.

**Stack:**
- Backend: Django 4.x + DRF + JWT (`simplejwt`) + PostgreSQL
- Mobile: Flutter (Dart), Riverpod state management, `google_fonts`, `flutter_markdown`
- SRS: SuperMemo-2 algorithm in `api/services/srs_service.py`
- Theme: Dark-only, `#0D1117` background, indigo primary `#6366F1`, emerald accent `#10B981`
- Core learning unit: a **Bite** = `{title, concept, formula, example, question_text, question_type, options, answer, explanation}`

The app's fundamental learning loop lives in:
- `mobile/lib/screens/bite/bite_screen.dart` — orchestrates the three phases
- `mobile/lib/providers/bite_session_provider.dart` — state machine (`learn → check → result`)
- `mobile/lib/widgets/bite/bite_card.dart` — renders the concept phase
- `mobile/lib/widgets/quiz/question_card.dart` — renders the question phase
- `mobile/lib/widgets/quiz/explanation_card.dart` — renders the result phase
- `mobile/lib/screens/review/review_screen.dart` — SRS review session entry point
- `api/services/srs_service.py` — SM-2 quality scoring

---

## Overview of Problems Being Fixed

The following issues break the pedagogical contract with the learner. They are grouped by impact:

| # | Problem | Impact |
|---|---------|--------|
| P1 | After a wrong answer, the user cannot re-read the original concept | High — violates error-correction loop |
| P2 | The explanation card never shows the question text again | High — user has lost context by the time explanation appears |
| P3 | SRS quality is binary (correct=4, wrong=1) — the 0–5 SM-2 scale is wasted | High — SRS interval scheduling is imprecise |
| P4 | No re-attempt mechanism — wrong = "Next Bite →" immediately | High — learner moves on before consolidating |
| P5 | Concept is always shown before question — no retrieval priming | Medium — misses the testing effect / desirable difficulty |
| P6 | `StatsScreen` uses hardcoded placeholder values | High — destroys credibility and user trust |
| P7 | The concept page is a passive wall of text; "I'VE READ THIS" has no engagement | Medium — users tap through without reading |
| P8 | Review mode (`ReviewScreen` → `BiteScreen`) is visually identical to new-bite mode | Medium — no sense of "this is something I struggled with before" |
| P9 | No within-session re-insertion of failed bites | Medium — a single session should cycle weak items |
| P10 | Explanation card lacks actionable scaffolding for wrong answers | Low-medium — "Learning Opportunity" heading is tepid |

---

## SECTION 1 — Core State Machine Overhaul (`bite_session_provider.dart`)

### 1A — Add New Phases to `BitePhase` Enum

The current enum `{ learn, check, result }` is too coarse. Add two new phases:

```dart
enum BitePhase {
  learn,       // concept / formula / example — same as before
  check,       // question posed to user — same as before
  result,      // explanation shown — same as before
  revisit,     // NEW: user chose "Review Concept Again" from result screen
  reattempt,   // NEW: user chose "Try Again" from result screen (wrong answer only)
}
```

### 1B — Extend `BiteSessionState`

```dart
class BiteSessionState {
  final BitePhase phase;
  final String? selectedAnswer;
  final bool? isCorrect;
  final Map<String, dynamic>? resultData;
  final bool isLoading;
  final int startTime;
  final int attemptCount;        // NEW: how many times user has attempted this bite
  final int? selfRating;         // NEW: 1–3 confidence rating chosen by user after result
  final bool isReviewMode;       // NEW: true when this bite came from the SRS due queue

  BiteSessionState({
    this.phase = BitePhase.learn,
    this.selectedAnswer,
    this.isCorrect,
    this.resultData,
    this.isLoading = false,
    this.startTime = 0,
    this.attemptCount = 0,
    this.selfRating,
    this.isReviewMode = false,
  });

  BiteSessionState copyWith({ ... }); // extend accordingly
}
```

### 1C — Add New Notifier Methods

```dart
class BiteSessionNotifier extends StateNotifier<BiteSessionState> {

  // Existing methods: advanceToCheck(), selectAnswer(), submitAnswer(), reset()

  /// Called when user taps "Review Concept Again" from result screen.
  void goToRevisit() {
    state = state.copyWith(phase: BitePhase.revisit);
  }

  /// Called when user taps "Try Again" from result screen (only available after wrong answer).
  void goToReattempt() {
    state = state.copyWith(
      phase: BitePhase.reattempt,
      selectedAnswer: null,
      startTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Called when user taps "Return to Explanation" from revisit screen.
  void returnToResult() {
    state = state.copyWith(phase: BitePhase.result);
  }

  /// Called from result screen when user taps a self-confidence rating button.
  /// rating: 1 = "Still unsure", 2 = "Getting it", 3 = "Confident"
  void submitSelfRating(int rating) {
    state = state.copyWith(selfRating: rating);
  }

  void setReviewMode(bool isReview) {
    state = state.copyWith(isReviewMode: isReview);
  }
}
```

**In `submitAnswer()`:** increment `attemptCount` before the API call:

```dart
Future<void> submitAnswer(String biteId) async {
  if (state.selectedAnswer == null) return;
  state = state.copyWith(isLoading: true, attemptCount: state.attemptCount + 1);
  // ... rest unchanged
}
```

---

## SECTION 2 — BiteScreen Orchestration (`bite_screen.dart`)

### 2A — Wire Up New Phases in `_buildPhase()`

```dart
Widget _buildPhase(BuildContext context, WidgetRef ref, BiteSessionState session) {
  switch (session.phase) {
    case BitePhase.learn:
      return BiteCard(
        title: bite['title'] ?? '',
        content: bite['concept'] ?? '',
        formula: bite['formula'],
        example: bite['example'],
        isReviewMode: session.isReviewMode,
        previouslyWeak: bite['srs_status'] == 'WEAK', // NEW: pass SRS status
      );

    case BitePhase.revisit:
      // Same content as learn, but with a "return" banner at top
      return BiteCard(
        title: bite['title'] ?? '',
        content: bite['concept'] ?? '',
        formula: bite['formula'],
        example: bite['example'],
        isReviewMode: session.isReviewMode,
        isRevisitMode: true, // NEW flag — shows "You're re-reading this because you got it wrong"
      );

    case BitePhase.check:
    case BitePhase.reattempt: // reattempt renders same widget as check
      return QuestionCard(
        question: bite['question_text'] ?? '',
        type: bite['question_type'] ?? 'mcq',
        options: bite['options'] as List<dynamic>? ?? [],
        selectedAnswer: session.selectedAnswer,
        onSelect: (a) => ref.read(biteSessionProvider.notifier).selectAnswer(a),
        isReattempt: session.phase == BitePhase.reattempt, // NEW: shows "Try Again" badge
        attemptNumber: session.attemptCount + 1,
      );

    case BitePhase.result:
      return ExplanationCard(
        isCorrect: session.isCorrect ?? false,
        correctAnswer: session.resultData?['correct_answer'] ?? '',
        explanation: session.resultData?['explanation'] ?? '',
        nextReviewText: _formatNextReview(session.resultData?['next_review']),
        questionText: bite['question_text'] ?? '',   // NEW: pass question text
        conceptTitle: bite['title'] ?? '',            // NEW: pass concept title
        selfRating: session.selfRating,              // NEW: for confidence buttons
        onSelfRate: (r) => ref.read(biteSessionProvider.notifier).submitSelfRating(r),
        onReviewConcept: () => ref.read(biteSessionProvider.notifier).goToRevisit(),
        onTryAgain: session.isCorrect == false       // "Try Again" only if wrong
            ? () => ref.read(biteSessionProvider.notifier).goToReattempt()
            : null,
      );
  }
}
```

### 2B — Rewrite `_buildActionArea()` to Handle All Phases

```dart
Widget _buildActionArea(BuildContext context, WidgetRef ref, BiteSessionState session) {
  if (bite['is_locked'] == true) return const SizedBox.shrink();

  switch (session.phase) {

    case BitePhase.learn:
      return _singleButton(
        context,
        label: "I'VE READ THIS — TEST ME",
        icon: Icons.arrow_forward_rounded,
        onPressed: () => ref.read(biteSessionProvider.notifier).advanceToCheck(),
      );

    case BitePhase.revisit:
      // After re-reading the concept, go to explanation — NOT back to question
      return _singleButton(
        context,
        label: "BACK TO EXPLANATION",
        icon: Icons.arrow_back_rounded,
        onPressed: () => ref.read(biteSessionProvider.notifier).returnToResult(),
      );

    case BitePhase.check:
    case BitePhase.reattempt:
      return _singleButton(
        context,
        label: session.isLoading ? "CHECKING..." : "CHECK ANSWER",
        onPressed: (session.selectedAnswer != null && !session.isLoading)
            ? () => ref.read(biteSessionProvider.notifier)
                .submitAnswer(bite['bite_id'] ?? bite['id'].toString())
            : null,
      );

    case BitePhase.result:
      // "NEXT BITE" is only enabled after a self-rating is provided (or if correct)
      final canProceed = session.isCorrect == true || session.selfRating != null;
      return _singleButton(
        context,
        label: canProceed ? "NEXT BITE →" : "RATE YOUR CONFIDENCE TO CONTINUE",
        onPressed: canProceed ? () => _goToNextBite(context, ref) : null,
        dimmed: !canProceed,
      );
  }
}

Widget _singleButton(BuildContext context, {
  required String label,
  IconData? icon,
  VoidCallback? onPressed,
  bool dimmed = false,
}) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
    ),
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label),
        style: onPressed == null || dimmed
            ? ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white38,
              )
            : null,
      ),
    ),
  );
}
```

### 2C — Pass `isReviewMode` When Constructing `BiteScreen`

In `ReviewScreen._startOrContinueSession()`:

```dart
await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => BiteScreen(
    bite: _dueBites[_currentIndex],
    isReviewMode: true,  // NEW
  )),
);
```

In `BiteScreen`, add:

```dart
class BiteScreen extends ConsumerWidget {
  final Map<String, dynamic> bite;
  final bool isReviewMode;
  const BiteScreen({super.key, required this.bite, this.isReviewMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On first build, inform provider of mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isReviewMode) {
        ref.read(biteSessionProvider.notifier).setReviewMode(true);
      }
    });
    // ...
  }
}
```

---

## SECTION 3 — Redesigned `ExplanationCard` Widget

This is the most important UI change. The card must now show: (1) the question again, (2) an empathetic but active wrong-answer scaffold, (3) confidence self-rating buttons, and (4) contextual CTAs.

**Full replacement for `mobile/lib/widgets/quiz/explanation_card.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/markdown_config.dart';

class ExplanationCard extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final String nextReviewText;
  final String questionText;        // NEW
  final String conceptTitle;        // NEW
  final int? selfRating;            // NEW: null = not yet rated
  final ValueChanged<int> onSelfRate;  // NEW
  final VoidCallback onReviewConcept;  // NEW
  final VoidCallback? onTryAgain;   // NEW: null if not applicable

  const ExplanationCard({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.nextReviewText,
    required this.questionText,
    required this.conceptTitle,
    required this.onSelfRate,
    required this.onReviewConcept,
    this.selfRating,
    this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    final markdownStyle = AppMarkdownStyle.getStyle(context);
    final statusColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status banner ─────────────────────────────────────────────────
        _StatusBanner(isCorrect: isCorrect, statusColor: statusColor),
        const SizedBox(height: 24),

        // ── Question recap ─────────────────────────────────────────────────
        // Always show the question text so the explanation has context.
        _QuestionRecap(questionText: questionText),
        const SizedBox(height: 20),

        // ── Correct answer (wrong attempts only) ───────────────────────────
        if (!isCorrect) ...[
          _CorrectAnswerChip(correctAnswer: correctAnswer, statusColor: statusColor),
          const SizedBox(height: 20),
        ],

        // ── Explanation ────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCorrect ? 'WHY THIS IS CORRECT' : 'LET\'S UNDERSTAND THIS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B949E), letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              MarkdownBody(data: explanation, styleSheet: markdownStyle),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Action row (wrong only): Review Concept / Try Again ────────────
        if (!isCorrect) ...[
          _ActionRow(
            onReviewConcept: onReviewConcept,
            onTryAgain: onTryAgain,
            conceptTitle: conceptTitle,
          ),
          const SizedBox(height: 24),
        ],

        // ── Self-confidence rating (always shown) ─────────────────────────
        // Required to unlock "NEXT BITE" on wrong answers.
        // Optional but encouraged on correct answers.
        _ConfidenceRater(
          isCorrect: isCorrect,
          currentRating: selfRating,
          onRate: onSelfRate,
        ),
        const SizedBox(height: 20),

        // ── SRS schedule chip ─────────────────────────────────────────────
        _SRSChip(nextReviewText: nextReviewText),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool isCorrect;
  final Color statusColor;
  const _StatusBanner({required this.isCorrect, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
            color: statusColor, size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            isCorrect ? 'Correct — well done!' : 'Not quite — let\'s lock this in',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.bold, color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionRecap extends StatelessWidget {
  final String questionText;
  const _QuestionRecap({required this.questionText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE QUESTION WAS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.bold,
            color: const Color(0xFF8B949E), letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Text(
            questionText,
            style: GoogleFonts.inter(
              fontSize: 15, color: const Color(0xFFE6EDF3), height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _CorrectAnswerChip extends StatelessWidget {
  final String correctAnswer;
  final Color statusColor;
  const _CorrectAnswerChip({required this.correctAnswer, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check, color: Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        Text(
          'Correct answer: ',
          style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF8B949E), fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            correctAnswer,
            style: GoogleFonts.inter(
              fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onReviewConcept;
  final VoidCallback? onTryAgain;
  final String conceptTitle;
  const _ActionRow({
    required this.onReviewConcept,
    required this.onTryAgain,
    required this.conceptTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: const Text('Review Concept'),
            onPressed: onReviewConcept,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (onTryAgain != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              onPressed: onTryAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConfidenceRater extends StatelessWidget {
  final bool isCorrect;
  final int? currentRating;
  final ValueChanged<int> onRate;

  const _ConfidenceRater({
    required this.isCorrect,
    required this.currentRating,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final isRated = currentRating != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCorrect
              ? 'HOW CONFIDENT WAS THAT?'
              : 'HOW WELL DO YOU UNDERSTAND IT NOW?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.bold,
            color: const Color(0xFF8B949E), letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _RatingButton(
              label: 'Still unsure',
              emoji: '😕',
              value: 1,
              selected: currentRating == 1,
              onTap: () => onRate(1),
            ),
            const SizedBox(width: 8),
            _RatingButton(
              label: 'Getting it',
              emoji: '🤔',
              value: 2,
              selected: currentRating == 2,
              onTap: () => onRate(2),
            ),
            const SizedBox(width: 8),
            _RatingButton(
              label: 'Confident',
              emoji: '💪',
              value: 3,
              selected: currentRating == 3,
              onTap: () => onRate(3),
            ),
          ],
        ),
        if (!isRated && !isCorrect) ...[
          const SizedBox(height: 8),
          Text(
            'Rate your understanding to continue',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFFF43F5E),
            ),
          ),
        ],
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String emoji;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label, required this.emoji, required this.value,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6366F1).withOpacity(0.2)
                : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6366F1)
                  : Colors.white.withOpacity(0.08),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: selected ? Colors.white : const Color(0xFF8B949E),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SRSChip extends StatelessWidget {
  final String nextReviewText;
  const _SRSChip({required this.nextReviewText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFFBBF24)),
              const SizedBox(width: 6),
              Text(
                nextReviewText,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8B949E),
                  fontWeight: FontWeight.w600, fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## SECTION 4 — Redesigned `BiteCard` with Revisit Mode

**Update `mobile/lib/widgets/bite/bite_card.dart`:**

Add two new parameters:

```dart
class BiteCard extends StatelessWidget {
  final String title;
  final String content;
  final String? formula;
  final String? example;
  final bool isReviewMode;     // NEW: true when this is an SRS review bite
  final bool isRevisitMode;    // NEW: true when user hit "Review Concept" from result
  final bool previouslyWeak;   // NEW: true when SRS status == 'WEAK'

  const BiteCard({
    super.key,
    required this.title,
    required this.content,
    this.formula,
    this.example,
    this.isReviewMode = false,
    this.isRevisitMode = false,
    this.previouslyWeak = false,
  });
```

At the very top of `build()`, before the title, insert a contextual banner:

```dart
// Contextual banner logic
Widget? banner;
if (isRevisitMode) {
  banner = _ContextBanner(
    icon: Icons.replay_rounded,
    text: 'Re-reading this to reinforce your understanding',
    color: const Color(0xFF6366F1),
  );
} else if (isReviewMode && previouslyWeak) {
  banner = _ContextBanner(
    icon: Icons.flag_rounded,
    text: 'You previously struggled with this — pay close attention',
    color: const Color(0xFFF43F5E),
  );
} else if (isReviewMode) {
  banner = _ContextBanner(
    icon: Icons.psychology_outlined,
    text: 'Spaced review — strengthen your memory',
    color: const Color(0xFFFBBF24),
  );
}
```

Add the `_ContextBanner` widget to the file:

```dart
class _ContextBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _ContextBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              style: GoogleFonts.inter(
                fontSize: 13, color: color.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## SECTION 5 — Backend: SRS Quality Score Mapped from Self-Rating

### 5A — Update `submit_bite` API Endpoint (`api/views.py`)

The endpoint `POST /api/bites/<bite_id>/submit/` currently derives SM-2 quality as binary: `4` if correct, `1` if wrong. Update it to accept an optional `self_rating` (1–3) from the client and map it to the SM-2 0–5 scale.

Find the `SubmitBiteView` (or equivalent) in `api/views.py` and apply:

```python
# BEFORE (approximate):
quality = 4 if is_correct else 1
SRSService.update_card(metadata, quality)

# AFTER:
self_rating = int(request.data.get('self_rating', 0))  # 0 = not provided

if is_correct:
    # Map user confidence to SM-2 quality
    quality_map = {
        0: 4,  # correct, no rating → neutral good
        1: 3,  # correct but unsure (got lucky) → minimum passing quality
        2: 4,  # correct, getting it → solid
        3: 5,  # correct and confident → excellent
    }
    quality = quality_map.get(self_rating, 4)
else:
    # Wrong answer
    quality_map = {
        0: 1,  # wrong, no rating → near-blackout
        1: 0,  # wrong, still unsure → complete blackout
        2: 2,  # wrong but now understands → poor recall
        3: 3,  # wrong but now fully gets it → passable (borderline)
    }
    quality = quality_map.get(self_rating, 1)

SRSService.update_card(metadata, quality)
```

### 5B — Update API Response to Include `srs_status`

In `SubmitBiteView`, include the updated status in the response so the client can display the next review schedule with the correct label:

```python
return Response({
    'is_correct': is_correct,
    'correct_answer': bite.answer,
    'explanation': bite.explanation,
    'next_review': metadata.next_review.isoformat(),
    'srs_status': metadata.status,   # 'NEW', 'LEARNING', 'WEAK', 'MASTERED'
    'xp_earned': xp_earned,
})
```

### 5C — Update `submitAnswer()` in `bite_session_provider.dart`

Pass `self_rating` to the API when submitting (note: the first submit happens before the rating is entered; send rating in a **separate PATCH call** triggered by `submitSelfRating()`):

Add a new method to `BiteSessionNotifier`:

```dart
/// Called once user taps a confidence button. Sends the rating to the backend.
Future<void> submitSelfRating(int rating) async {
  state = state.copyWith(selfRating: rating);
  final biteId = state.resultData?['bite_id'];
  if (biteId != null) {
    await _apiService.patchSelfRating(biteId: biteId.toString(), selfRating: rating);
  }
}
```

Add to `ApiService` (`mobile/lib/services/api_service.dart`):

```dart
Future<void> patchSelfRating({required String biteId, required int selfRating}) async {
  final token = await _getValidToken();
  if (token == null) return;
  await http.patch(
    Uri.parse('$_baseUrl/api/bites/$biteId/submit/'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    body: jsonEncode({'self_rating': selfRating}),
  );
}
```

Add the `PATCH` handler to the bite submit view:

```python
def patch(self, request, bite_id):
    """Accept a self_rating patch after the initial answer was submitted."""
    self_rating = int(request.data.get('self_rating', 0))
    candidate = request.user.candidate
    try:
        metadata = SRSMetadata.objects.get(candidate=candidate, card_id=bite_id)
    except SRSMetadata.DoesNotExist:
        return Response({'error': 'Not found'}, status=404)

    # Recalculate quality incorporating the new rating
    is_correct = metadata.status != 'WEAK'  # Use stored status as proxy
    quality_map_correct = {0: 4, 1: 3, 2: 4, 3: 5}
    quality_map_wrong   = {0: 1, 1: 0, 2: 2, 3: 3}
    quality = (quality_map_correct if is_correct else quality_map_wrong).get(self_rating, 4)

    SRSService.update_card(metadata, quality)
    return Response({'status': metadata.status, 'next_review': metadata.next_review.isoformat()})
```

---

## SECTION 6 — Fix `StatsScreen` (Remove All Hardcoded Values)

**File:** `mobile/lib/screens/stats/stats_screen.dart`

The screen currently has `'7 Day Streak'`, `'124 Mastered'`, `'88%'` hardcoded. These destroy credibility. Rewrite to pull from the progress API.

```dart
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  Map<String, dynamic>? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getProgress();
    if (mounted) setState(() { _progress = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final candidate = _progress?['candidate'] as Map<String, dynamic>? ?? {};
    final papers = (_progress?['papers'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final streak = candidate['study_streak'] as int? ?? 0;
    final mastered = candidate['mastered_count'] as int? ?? 0;
    final totalAttempts = candidate['total_attempts'] as int? ?? 0;
    final correctAttempts = candidate['correct_attempts'] as int? ?? 0;
    final accuracy = totalAttempts > 0
        ? '${((correctAttempts / totalAttempts) * 100).toStringAsFixed(0)}%'
        : '—';

    // Build the screen using real data: streak, mastered, accuracy, papers
    // ... (rest of the UI build using these variables)
  }
}
```

> **Backend note:** Ensure `GET /api/progress/` returns `total_attempts` and `correct_attempts` fields derived from `BiteAttempt.objects.filter(candidate=candidate)`. Add these aggregations to `ProgressView` in `api/views.py`:
>
> ```python
> from django.db.models import Count, Q
> attempts = BiteAttempt.objects.filter(candidate=candidate)
> total = attempts.count()
> correct = attempts.filter(is_correct=True).count()
> ```
> Include `total_attempts: total, correct_attempts: correct` in the serialized response.

---

## SECTION 7 — Within-Session Re-insertion of Weak Bites (`ReviewScreen`)

When a user completes a bite in review mode with `selfRating == 1` ("Still unsure"), that bite should be appended to the end of the current session queue so the user encounters it again before finishing.

**Update `ReviewScreen._startOrContinueSession()`:**

```dart
void _startOrContinueSession() async {
  if (_currentIndex >= _dueBites.length) return;
  final result = await Navigator.push<Map<String, dynamic>?>(
    context,
    MaterialPageRoute(builder: (_) => BiteScreen(
      bite: _dueBites[_currentIndex],
      isReviewMode: true,
    )),
  );

  if (mounted) {
    setState(() {
      // If the user rated themselves "Still unsure" (selfRating == 1),
      // re-append the bite to the queue (but only once per session).
      final requeue = result?['requeue'] == true;
      final alreadyQueued = _requeuedIds.contains(_dueBites[_currentIndex]['bite_id']);
      if (requeue && !alreadyQueued) {
        _requeuedIds.add(_dueBites[_currentIndex]['bite_id']);
        _dueBites.add(_dueBites[_currentIndex]);
      }
      _currentIndex++;
      if (_currentIndex >= _dueBites.length) _sessionComplete = true;
    });
  }
}

final Set<String> _requeuedIds = {};
```

**In `BiteScreen._goToNextBite()`**, pass the self-rating back:

```dart
void _goToNextBite(BuildContext context, WidgetRef ref) async {
  final session = ref.read(biteSessionProvider);
  Navigator.pop(context, {
    'requeue': session.selfRating == 1,
  });
}
```

---

## SECTION 8 — `QuestionCard` — Add Reattempt Badge and Attempt Counter

**Update `mobile/lib/widgets/quiz/question_card.dart`:**

Add these parameters:

```dart
class QuestionCard extends StatelessWidget {
  final String question;
  final String type;
  final List<dynamic> options;
  final String? selectedAnswer;
  final Function(String) onSelect;
  final bool isReattempt;      // NEW
  final int attemptNumber;     // NEW: 1 = first attempt, 2 = second, etc.
  // ...
```

At the top of `build()`, before the question body, insert:

```dart
if (isReattempt)
  Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF6366F1).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1), size: 14),
        const SizedBox(width: 8),
        Text(
          'Attempt #$attemptNumber — you\'ve reviewed the concept. Try again!',
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF6366F1), fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
```

---

## SECTION 9 — Review Session Completion Screen Enhancement

The current completion state shows a generic "Session Complete!" message. Update `_buildCompletionState()` in `ReviewScreen` to show a meaningful summary:

```dart
Widget _buildCompletionState() {
  final total = _dueBites.length - _requeuedIds.length; // original due count
  final requeued = _requeuedIds.length; // how many were "still unsure"

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.done_all, size: 80, color: Color(0xFF10B981)),
          const SizedBox(height: 24),
          Text('Session Complete!',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          // Summary stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SummaryChip(value: '$total', label: 'Reviewed'),
              const SizedBox(width: 12),
              _SummaryChip(value: '$requeued', label: 'Still shaky'),
              const SizedBox(width: 12),
              _SummaryChip(value: '${total - requeued}', label: 'Locked in'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            requeued > 0
                ? 'You\'re still building confidence on $requeued bite${requeued > 1 ? "s" : ""}. They\'ll resurface soon.'
                : 'All bites reinforced. Your spaced-repetition schedule has been updated.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## SECTION 10 — Summary Checklist

Apply all changes in this order to avoid import errors:

- [ ] **1. `bite_session_provider.dart`** — Add `BitePhase.revisit`, `BitePhase.reattempt`; extend `BiteSessionState`; add `goToRevisit()`, `goToReattempt()`, `returnToResult()`, `submitSelfRating()`, `setReviewMode()` methods
- [ ] **2. `explanation_card.dart`** — Full replacement per Section 3
- [ ] **3. `bite_card.dart`** — Add `isReviewMode`, `isRevisitMode`, `previouslyWeak` params; add `_ContextBanner` widget
- [ ] **4. `question_card.dart`** — Add `isReattempt`, `attemptNumber` params; render reattempt badge
- [ ] **5. `bite_screen.dart`** — Wire new phases in `_buildPhase()`; rewrite `_buildActionArea()`; add `isReviewMode` constructor param
- [ ] **6. `review_screen.dart`** — Pass `isReviewMode: true`; implement re-insertion logic; update completion state
- [ ] **7. `api/views.py` (SubmitBiteView)** — Map `self_rating` to SM-2 quality; add `PATCH` handler; include `srs_status` in response
- [ ] **8. `api_service.dart`** — Add `patchSelfRating()` method
- [ ] **9. `api/views.py` (ProgressView)** — Add `total_attempts`, `correct_attempts` to response
- [ ] **10. `stats_screen.dart`** — Remove all hardcoded values; fetch from real API

---

## Pedagogical Principles Applied

| Principle | Where Applied |
|-----------|--------------|
| **Error-correction loop** | "Review Concept" CTA in ExplanationCard (Sections 3 & 5) |
| **Contextualised feedback** | Question text shown again in ExplanationCard (Section 3) |
| **Metacognitive calibration** | Confidence self-rating buttons; rating gates "Next Bite" (Sections 3 & 5) |
| **Spaced repetition fidelity** | Self-rating mapped to SM-2 0–5 scale, not binary (Section 5) |
| **Contextual priming** | BiteCard banners distinguish new / review / weak / revisit modes (Section 4) |
| **Within-session consolidation** | "Still unsure" bites re-inserted into session queue (Section 7) |
| **Credibility & data integrity** | StatsScreen removed all hardcoded values (Section 6) |
| **Desirable difficulty** | Reattempt mode lets user test themselves again after studying (Section 2) |

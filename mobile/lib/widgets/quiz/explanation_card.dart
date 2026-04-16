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

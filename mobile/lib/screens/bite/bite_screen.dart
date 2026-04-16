import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bite_session_provider.dart';
import '../../widgets/bite/bite_card.dart';
import '../../widgets/quiz/question_card.dart';
import '../../widgets/quiz/explanation_card.dart';
import '../../widgets/common/locked_content_overlay.dart';
import '../../services/api_service.dart';

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

    final session = ref.watch(biteSessionProvider);
    final isLocked = bite['is_locked'] == true;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          bite['paper_code'] ?? '',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _buildPhase(context, ref, session),
                    ),
                  ),
                ),
                _buildActionArea(context, ref, session),
              ],
            ),
          ),
          if (isLocked)
            const Center(
              child: LockedContentOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildPhase(BuildContext context, WidgetRef ref, BiteSessionState session) {
    switch (session.phase) {
      case BitePhase.learn:
        return BiteCard(
          title: bite['title'] ?? '',
          content: bite['concept'] ?? '',
          formula: bite['formula'],
          example: bite['example'],
          isReviewMode: session.isReviewMode,
          previouslyWeak: bite['srs_status'] == 'WEAK',
        );

      case BitePhase.revisit:
        return BiteCard(
          title: bite['title'] ?? '',
          content: bite['concept'] ?? '',
          formula: bite['formula'],
          example: bite['example'],
          isReviewMode: session.isReviewMode,
          isRevisitMode: true,
        );

      case BitePhase.check:
      case BitePhase.reattempt:
        return QuestionCard(
          question: bite['question_text'] ?? '',
          type: bite['question_type'] ?? 'mcq',
          options: bite['options'] as List<dynamic>? ?? [],
          selectedAnswer: session.selectedAnswer,
          onSelect: (a) => ref.read(biteSessionProvider.notifier).selectAnswer(a),
          isReattempt: session.phase == BitePhase.reattempt,
          attemptNumber: session.attemptCount + 1,
        );

      case BitePhase.result:
        return ExplanationCard(
          isCorrect: session.isCorrect ?? false,
          correctAnswer: session.resultData?['correct_answer'] ?? '',
          explanation: session.resultData?['explanation'] ?? '',
          nextReviewText: _formatNextReview(session.resultData?['next_review']),
          questionText: bite['question_text'] ?? '',
          conceptTitle: bite['title'] ?? '',
          selfRating: session.selfRating,
          onSelfRate: (r) => ref.read(biteSessionProvider.notifier).submitSelfRating(r),
          onReviewConcept: () => ref.read(biteSessionProvider.notifier).goToRevisit(),
          onTryAgain: session.isCorrect == false 
              ? () => ref.read(biteSessionProvider.notifier).goToReattempt()
              : null,
        );
    }
  }

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

  void _goToNextBite(BuildContext context, WidgetRef ref) async {
    final session = ref.read(biteSessionProvider);
    final nextBiteData = await ApiService().getTodaysBite();
    
    if (context.mounted) {
      // Return result to support within-session requeue logic in ReviewScreen
      Navigator.pop(context, {
        'requeue': session.selfRating == 1,
        'has_next': nextBiteData != null && nextBiteData['bite'] != null,
      });

      // If we are in TodaysBite flow (not Review flow), we navigate automatically
      if (!isReviewMode && nextBiteData != null && nextBiteData['bite'] != null) {
        ref.read(biteSessionProvider.notifier).reset();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BiteScreen(bite: nextBiteData['bite'])),
        );
      }
    }
  }

  String _formatNextReview(String? dateStr) {
    if (dateStr == null) return "Scheduled for later";
    final date = DateTime.parse(dateStr);
    final diff = date.difference(DateTime.now()).inDays;
    if (diff <= 0) return "Review due today";
    if (diff == 1) return "Review tomorrow";
    return "Review in $diff days";
  }
}

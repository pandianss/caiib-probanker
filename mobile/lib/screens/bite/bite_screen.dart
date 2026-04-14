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
  const BiteScreen({super.key, required this.bite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        );
      case BitePhase.check:
        return QuestionCard(
          question: bite['question_text'] ?? '',
          type: bite['question_type'] ?? 'mcq',
          options: bite['options'] as List<dynamic>? ?? [],
          selectedAnswer: session.selectedAnswer,
          onSelect: (a) => ref.read(biteSessionProvider.notifier).selectAnswer(a),
        );
      case BitePhase.result:
        return ExplanationCard(
          isCorrect: session.isCorrect ?? false,
          correctAnswer: session.resultData?['correct_answer'] ?? '',
          explanation: session.resultData?['explanation'] ?? '',
          nextReviewText: _formatNextReview(session.resultData?['next_review']),
        );
    }
  }

  Widget _buildActionArea(BuildContext context, WidgetRef ref, BiteSessionState session) {
    if (bite['is_locked'] == true) return const SizedBox.shrink();

    String btnText = "";
    VoidCallback? onPressed;

    if (session.phase == BitePhase.learn) {
      btnText = "I'VE READ THIS";
      onPressed = () => ref.read(biteSessionProvider.notifier).advanceToCheck();
    } else if (session.phase == BitePhase.check) {
      btnText = session.isLoading ? "CHECKING..." : "CHECK ANSWER";
      onPressed = (session.selectedAnswer != null && !session.isLoading)
          ? () => ref.read(biteSessionProvider.notifier).submitAnswer(bite['bite_id'] ?? bite['id'].toString())
          : null;
    } else {
      btnText = "NEXT BITE →";
      onPressed = () => _goToNextBite(context, ref);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(btnText),
        ),
      ),
    );
  }

  void _goToNextBite(BuildContext context, WidgetRef ref) async {
    final nextBiteData = await ApiService().getTodaysBite();
    if (context.mounted && nextBiteData != null && nextBiteData['bite'] != null) {
      // Reset session state for the new bite
      ref.read(biteSessionProvider.notifier).reset();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BiteScreen(bite: nextBiteData['bite'])),
      );
    } else if (context.mounted) {
      Navigator.pop(context);
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

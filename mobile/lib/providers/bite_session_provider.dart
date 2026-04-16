import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

enum BitePhase {
  learn,       // concept / formula / example
  check,       // question posed to user
  result,      // explanation shown
  revisit,     // NEW: user chose "Review Concept Again" from result screen
  reattempt,   // NEW: user chose "Try Again" from result screen (wrong answer only)
}

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

  BiteSessionState copyWith({
    BitePhase? phase,
    String? selectedAnswer,
    bool? isCorrect,
    Map<String, dynamic>? resultData,
    bool? isLoading,
    int? startTime,
    int? attemptCount,
    int? selfRating,
    bool? isReviewMode,
  }) {
    return BiteSessionState(
      phase: phase ?? this.phase,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      resultData: resultData ?? this.resultData,
      isLoading: isLoading ?? this.isLoading,
      startTime: startTime ?? this.startTime,
      attemptCount: attemptCount ?? this.attemptCount,
      selfRating: selfRating ?? this.selfRating,
      isReviewMode: isReviewMode ?? this.isReviewMode,
    );
  }
}

class BiteSessionNotifier extends StateNotifier<BiteSessionState> {
  final ApiService _apiService = ApiService();

  BiteSessionNotifier() : super(BiteSessionState());

  void advanceToCheck() {
    state = state.copyWith(
      phase: BitePhase.check,
      startTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void selectAnswer(String answer) {
    state = state.copyWith(selectedAnswer: answer);
  }

  Future<void> submitAnswer(String biteId) async {
    if (state.selectedAnswer == null) return;
    
    state = state.copyWith(isLoading: true, attemptCount: state.attemptCount + 1);
    final elapsed = ((DateTime.now().millisecondsSinceEpoch - state.startTime) / 1000).round();
    
    final result = await _apiService.submitBite(
      biteId: biteId,
      answer: state.selectedAnswer!,
      timeTakenSeconds: elapsed,
    );

    if (result != null) {
      state = state.copyWith(
        isCorrect: result['is_correct'],
        resultData: result,
        phase: BitePhase.result,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

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
  Future<void> submitSelfRating(int rating) async {
    state = state.copyWith(selfRating: rating);
    final biteId = state.resultData?['bite_id'] ?? state.resultData?['id'].toString();
    if (biteId != null) {
      final res = await _apiService.patchSelfRating(biteId: biteId, selfRating: rating);
      if (res != null) {
        state = state.copyWith(
          resultData: {
            ...state.resultData!,
            'srs_status': res['srs_status'],
            'next_review': res['next_review'],
          }
        );
      }
    }
  }

  void setReviewMode(bool isReview) {
    state = state.copyWith(isReviewMode: isReview);
  }

  void reset() {
    state = BiteSessionState();
  }
}

final biteSessionProvider = StateNotifierProvider.autoDispose<BiteSessionNotifier, BiteSessionState>((ref) {
  return BiteSessionNotifier();
});

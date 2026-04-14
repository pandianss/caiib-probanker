import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

enum BitePhase { learn, check, result }

class BiteSessionState {
  final BitePhase phase;
  final String? selectedAnswer;
  final bool? isCorrect;
  final Map<String, dynamic>? resultData;
  final bool isLoading;
  final int startTime;

  BiteSessionState({
    this.phase = BitePhase.learn,
    this.selectedAnswer,
    this.isCorrect,
    this.resultData,
    this.isLoading = false,
    this.startTime = 0,
  });

  BiteSessionState copyWith({
    BitePhase? phase,
    String? selectedAnswer,
    bool? isCorrect,
    Map<String, dynamic>? resultData,
    bool? isLoading,
    int? startTime,
  }) {
    return BiteSessionState(
      phase: phase ?? this.phase,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      resultData: resultData ?? this.resultData,
      isLoading: isLoading ?? this.isLoading,
      startTime: startTime ?? this.startTime,
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
    
    state = state.copyWith(isLoading: true);
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
      // Error handling would go here (e.g., event for UI to show snackbar)
    }
  }

  void reset() {
    state = BiteSessionState();
  }
}

final biteSessionProvider = StateNotifierProvider.autoDispose<BiteSessionNotifier, BiteSessionState>((ref) {
  return BiteSessionNotifier();
});

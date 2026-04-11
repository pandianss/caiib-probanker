import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../widgets/virtual_calculator.dart';
import '../../widgets/numerical_keypad.dart';

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
    
    // We must use 'bite_id' (string) not 'id' (int) for SRS tracking
    final biteIdStr = widget.bite['bite_id'] ?? widget.bite['id'].toString();
    
    final result = await ApiService().submitBite(
      biteId: biteIdStr,
      answer: _selectedAnswer ?? '',
      timeTakenSeconds: elapsed,
    );

    if (result != null && mounted) {
      setState(() {
        _isCorrect = result['is_correct'];
        _resultData = result;
        _phase = BitePhase.result;
      });
      context.read<ProgressProvider>().fetchDashboardData();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to check answer. Please check your connection.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _goToNextBite() async {
    final nextBiteData = await ApiService().getTodaysBite();
    if (mounted && nextBiteData != null && nextBiteData['bite'] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BiteScreen(bite: nextBiteData['bite'])),
      );
    } else if (mounted) {
      Navigator.pop(context); // No more bites — go back
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(widget.bite['paper_code'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        centerTitle: true,
      ),
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
                      isCorrect: _isCorrect ?? false,
                      resultData: _resultData ?? {},
                      onNext: _goToNextBite,
                    ),
        ),
      ),
    );
  }
}

class _LearnPhase extends StatelessWidget {
  final Map<String, dynamic> bite;
  final VoidCallback onDone;

  const _LearnPhase({required this.bite, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bite['title'] ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
          const SizedBox(height: 24),
          Text(bite['concept'] ?? '', style: const TextStyle(fontSize: 18, color: Color(0xFFE6EDF3), height: 1.6)),
          const SizedBox(height: 24),
          if ((bite['formula'] ?? '').isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3))),
              child: Text(bite['formula'], style: const TextStyle(fontFamily: 'monospace', fontSize: 16, color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 16),
          if ((bite['example'] ?? '').isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12), border: const Border(left: BorderSide(color: Color(0xFFFBBF24), width: 4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('EXAMPLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
                   const SizedBox(height: 8),
                   Text(bite['example'], style: const TextStyle(fontSize: 16, color: Color(0xFF8B949E), height: 1.5)),
                ]
              ),
            ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: onDone,
              child: const Text('I\'ve read this', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPhase extends StatelessWidget {
  final Map<String, dynamic> bite;
  final String? selectedAnswer;
  final Function(String) onSelect;
  final VoidCallback onSubmit;

  const _CheckPhase({required this.bite, this.selectedAnswer, required this.onSelect, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final isNumerical = bite['question_type'] == 'numerical';
    final options = bite['options'] as List<dynamic>? ?? [];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline, color: Color(0xFF8B949E), size: 20),
                    SizedBox(width: 8),
                    Text('KNOWLEDGE CHECK', style: TextStyle(color: Color(0xFF8B949E), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(bite['question_text'] ?? '', style: const TextStyle(fontSize: 22, color: Colors.white, height: 1.4)),
                const SizedBox(height: 32),
                if (!isNumerical)
                  ...options.map((opt) {
                    final isSelected = selectedAnswer == opt;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => onSelect(opt),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(opt, style: TextStyle(fontSize: 16, color: isSelected ? Colors.white : const Color(0xFFE6EDF3))),
                        ),
                      ),
                    );
                  }).toList(),
                if (isNumerical)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                        child: Text(selectedAnswer ?? 'Tap keypad to enter answer...', style: TextStyle(fontSize: 24, color: selectedAnswer == null ? const Color(0xFF8B949E) : Colors.white)),
                      ),
                      const SizedBox(height: 24),
                      NumericalKeypad(
                        onKeyPress: (key) {
                           if (key == 'C') { onSelect(''); }
                           else if (key == 'DEL') { if ((selectedAnswer ?? '').isNotEmpty) onSelect(selectedAnswer!.substring(0, selectedAnswer!.length - 1)); }
                           else { onSelect((selectedAnswer ?? '') + key); }
                        }
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            border: Border(top: BorderSide(color: Colors.black26)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: selectedAnswer != null && selectedAnswer!.isNotEmpty ? const Color(0xFF6366F1) : const Color(0xFF21262D), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: selectedAnswer != null && selectedAnswer!.isNotEmpty ? onSubmit : null,
              child: const Text('Check Answer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultPhase extends StatelessWidget {
  final Map<String, dynamic> bite;
  final bool isCorrect;
  final Map<String, dynamic> resultData;
  final VoidCallback onNext;

  const _ResultPhase({required this.bite, required this.isCorrect, required this.resultData, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    
    // Parse next review date to days
    String nextReviewText = "Scheduled for later";
    if (resultData['next_review'] != null) {
        final DateTime d = DateTime.parse(resultData['next_review']);
        final int days = d.difference(DateTime.now()).inDays;
        if (days <= 0) nextReviewText = 'Review due today';
        else if (days == 1) nextReviewText = 'Review tomorrow';
        else nextReviewText = 'Review in $days days';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, val, child) {
              return Transform.scale(scale: val, child: Icon(icon, color: color, size: 100));
            },
          ),
          const SizedBox(height: 24),
          Text(isCorrect ? "Nailed it!" : "Not quite.", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCorrect) ...[
                  const Text('CORRECT ANSWER:', style: TextStyle(fontSize: 12, color: Color(0xFF8B949E), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(resultData['correct_answer'] ?? '', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                ],
                const Text('EXPLANATION:', style: TextStyle(fontSize: 12, color: Color(0xFF8B949E), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(resultData['explanation'] ?? '', style: const TextStyle(fontSize: 16, color: Color(0xFFE6EDF3), height: 1.5)),
              ]
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF21262D), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sync, size: 16, color: Color(0xFF8B949E)),
                const SizedBox(width: 8),
                Text(nextReviewText, style: const TextStyle(color: Color(0xFF8B949E), fontWeight: FontWeight.w500)),
              ]
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), 
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.symmetric(vertical: 16), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              onPressed: onNext,
              child: const Text('Next Bite →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done for now', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6))),
            ),
          ),
        ],
      ),
    );
  }
}

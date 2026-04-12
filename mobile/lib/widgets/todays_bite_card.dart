import 'package:flutter/material.dart';

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

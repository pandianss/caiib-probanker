import 'package:flutter/material.dart';

class PaperProgressCard extends StatelessWidget {
  final String paperCode;
  final String title;
  final double currentScore;

  const PaperProgressCard({
    super.key, 
    required this.paperCode, 
    required this.title, 
    required this.currentScore
  });

  @override
  Widget build(BuildContext context) {
    bool isPassed = currentScore >= 45.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    paperCode,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${currentScore.toStringAsFixed(1)} / 100',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isPassed ? const Color(0xFF14B8A6) : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: currentScore / 100.0,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPassed ? const Color(0xFF14B8A6) : const Color(0xFFF59E0B),
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

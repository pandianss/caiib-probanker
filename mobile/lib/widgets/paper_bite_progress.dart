import 'package:flutter/material.dart';

class PaperBiteProgressList extends StatelessWidget {
  final List<dynamic> papers;

  const PaperBiteProgressList({super.key, required this.papers});

  @override
  Widget build(BuildContext context) {
    if (papers.isEmpty) { return const SizedBox.shrink(); }
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
  final dynamic paper;
  const _PaperRow({required this.paper});

  @override
  Widget build(BuildContext context) {
    final double masteredDouble = paper['mastered'] ?? 0.0;
    final int mastered = masteredDouble.toInt();
    final int total = paper['total_bites'] ?? 1;
    final double pct = total == 0 ? 0.0 : (mastered / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(paper['paper_code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
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

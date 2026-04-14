import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/markdown_config.dart';

class ExplanationCard extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final String nextReviewText;

  const ExplanationCard({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.nextReviewText,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final markdownStyle = AppMarkdownStyle.getStyle(context);

    return Column(
      children: [
        Icon(
          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: statusColor,
          size: 80,
        ),
        const SizedBox(height: 16),
        Text(
          isCorrect ? "Perfectly Correct!" : "Learning Opportunity",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCorrect) ...[
                Text(
                  'CORRECT ANSWER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B949E),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  correctAnswer,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 24),
              ],
              Text(
                'WHY THIS IS CORRECT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B949E),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: explanation,
                styleSheet: markdownStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              Text(
                nextReviewText,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8B949E),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/markdown_config.dart';

class BiteCard extends StatelessWidget {
  final String title;
  final String content;
  final String? formula;
  final String? example;
  final bool isReviewMode;     // NEW: true when this is an SRS review bite
  final bool isRevisitMode;    // NEW: true when user hit "Review Concept" from result
  final bool previouslyWeak;   // NEW: true when SRS status == 'WEAK'

  const BiteCard({
    super.key,
    required this.title,
    required this.content,
    this.formula,
    this.example,
    this.isReviewMode = false,
    this.isRevisitMode = false,
    this.previouslyWeak = false,
  });

  @override
  Widget build(BuildContext context) {
    final markdownStyle = AppMarkdownStyle.getStyle(context);

    // Contextual banner logic
    Widget? banner;
    if (isRevisitMode) {
      banner = const _ContextBanner(
        icon: Icons.replay_rounded,
        text: 'Re-reading this to reinforce your understanding',
        color: Color(0xFF6366F1),
      );
    } else if (isReviewMode && previouslyWeak) {
      banner = const _ContextBanner(
        icon: Icons.flag_rounded,
        text: 'You previously struggled with this — pay close attention',
        color: Color(0xFFF43F5E),
      );
    } else if (isReviewMode) {
      banner = const _ContextBanner(
        icon: Icons.psychology_outlined,
        text: 'Spaced review — strengthen your memory',
        color: Color(0xFFFBBF24),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (banner != null) banner,
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        MarkdownBody(
          data: content,
          styleSheet: markdownStyle,
        ),
        if (formula != null && formula!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
              ),
            ),
            child: Text(
              formula!,
              textAlign: TextAlign.center,
              style: GoogleFonts.firaCode(
                fontSize: 18,
                color: const Color(0xFF818CF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        if (example != null && example!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REAL-WORLD EXAMPLE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                MarkdownBody(
                  data: example!,
                  styleSheet: markdownStyle.copyWith(
                    p: markdownStyle.p?.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF8B949E),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ContextBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _ContextBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              style: GoogleFonts.inter(
                fontSize: 13, color: color.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

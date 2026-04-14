import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/markdown_config.dart';

class BiteCard extends StatelessWidget {
  final String title;
  final String content;
  final String? formula;
  final String? example;

  const BiteCard({
    super.key,
    required this.title,
    required this.content,
    this.formula,
    this.example,
  });

  @override
  Widget build(BuildContext context) {
    final markdownStyle = AppMarkdownStyle.getStyle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

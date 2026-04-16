import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/markdown_config.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final String type; // mcq, numerical, match, assertion_reason, fitb
  final List<dynamic> options;
  final String? selectedAnswer;
  final Function(String) onSelect;
  final bool isReattempt;
  final int attemptNumber;

  const QuestionCard({
    super.key,
    required this.question,
    required this.type,
    required this.options,
    this.selectedAnswer,
    required this.onSelect,
    this.isReattempt = false,
    this.attemptNumber = 1,
  });

  @override
  Widget build(BuildContext context) {
    final markdownStyle = AppMarkdownStyle.getStyle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isReattempt)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1), size: 14),
                const SizedBox(width: 8),
                Text(
                  'Attempt #$attemptNumber — you\'ve reviewed the concept. Try again!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFF8B949E), size: 18),
            const SizedBox(width: 8),
            Text(
              'KNOWLEDGE CHECK',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF8B949E),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MarkdownBody(
          data: question,
          styleSheet: markdownStyle.copyWith(
            p: markdownStyle.p?.copyWith(
              fontSize: 22,
              color: Colors.white,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (type == 'mcq' || type == 'assertion_reason')
          _buildOptionsList(context),
        if (type == 'numerical' || type == 'fitb')
          _buildInputField(context),
        if (type == 'match')
          _buildMatchInterface(context),
      ],
    );
  }

  Widget _buildOptionsList(BuildContext context) {
    return Column(
      children: options.map((opt) {
        final isSelected = selectedAnswer == opt;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onSelect(opt.toString()),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor.withOpacity(0.15) 
                    : const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      opt.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isSelected ? Colors.white : const Color(0xFFE6EDF3),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, 
                        color: Theme.of(context).primaryColor, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputField(BuildContext context) {
    // Shared container for Numerical and FITB
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        (selectedAnswer == null || selectedAnswer!.isEmpty) 
            ? 'Tap to enter answer...' 
            : selectedAnswer!,
        style: GoogleFonts.inter(
          fontSize: 24,
          color: (selectedAnswer == null || selectedAnswer!.isEmpty) 
              ? const Color(0xFF8B949E) 
              : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMatchInterface(BuildContext context) {
    return const Center(
      child: Text(
        "Match Interface Coming in Phase 4.2",
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}

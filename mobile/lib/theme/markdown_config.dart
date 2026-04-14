import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class AppMarkdownStyle {
  static MarkdownStyleSheet getStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MarkdownStyleSheet(
      p: GoogleFonts.inter(
        color: isDark ? const Color(0xFFE6EDF3) : Colors.black87,
        fontSize: 15,
        height: 1.6,
      ),
      strong: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF6366F1), // Vibrant Indigo
        fontWeight: FontWeight.bold,
        backgroundColor: const Color(0xFF6366F1).withOpacity(0.1), // Subtle highlight background
      ),
      h1: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 2.0,
      ),
      h2: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.8,
      ),
      listBullet: GoogleFonts.inter(
        color: const Color(0xFF6366F1),
      ),
      blockSpacing: 16.0,
      listIndent: 24.0,
    );
  }
}

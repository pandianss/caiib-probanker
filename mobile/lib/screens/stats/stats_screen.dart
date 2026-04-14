import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../profile/profile_screen.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: In production, we would have a dedicated StatsProvider
    // Using placeholder values to maintain the premium look
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      '7 Day Streak', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCompactStat('124', 'Mastered'),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                    _buildCompactStat('452', 'Reviewed'),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                    _buildCompactStat('88%', 'Accuracy'),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              Text(
                'MASTERY BY PAPER', 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, 
                  color: const Color(0xFF8B949E), 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.5
                )
              ),
              const SizedBox(height: 24),
              _buildPaperProgress("ABFM (2026 Curriculum)", 0.65),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF6366F1)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Other papers (ABM, BFM, BRBL) will be enabled once your study modules are ready.",
                        style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  }, 
                  icon: Icon(Icons.person_outline, color: Theme.of(context).primaryColor), 
                  label: const Text('Manage Profile', style: TextStyle(color: Colors.white70))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperProgress(String code, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
             Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.05),
          color: const Color(0xFF6366F1),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildCompactStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
      ],
    );
  }
}

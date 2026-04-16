import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../profile/profile_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  Map<String, dynamic>? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getProgress();
    if (mounted) {
      setState(() {
        _progress = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final streak = _progress?['study_streak'] as int? ?? 0;
    final mastered = _progress?['mastered_count'] as int? ?? 0; // assuming this field is added or derived
    final totalAttempts = _progress?['total_attempts'] as int? ?? 0;
    final correctAttempts = _progress?['correct_attempts'] as int? ?? 0;
    
    final accuracy = totalAttempts > 0
        ? '${((correctAttempts / totalAttempts) * 100).toStringAsFixed(0)}%'
        : '—';

    final papers = (_progress?['progress'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        '$streak Day Streak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                      _buildCompactStat('$correctAttempts', 'Mastered'),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                      _buildCompactStat('$totalAttempts', 'Reviewed'),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                      _buildCompactStat(accuracy, 'Accuracy'),
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
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (papers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'No paper progress data available yet.',
                        style: TextStyle(color: Color(0xFF8B949E)),
                      ),
                    ),
                  )
                else
                  ...papers.map((p) {
                    final code = p['paper_code'] as String? ?? 'Unknown';
                    final masteredCount = p['mastered'] as double? ?? 0.0;
                    final totalBites = p['total_bites'] as int? ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildPaperProgress(
                        code,
                        totalBites > 0 ? masteredCount / totalBites : 0.0,
                      ),
                    );
                  }).toList(),
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
                          "Your performance stats are calculated in real-time based on your study sessions.",
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
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                    icon: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                    label: const Text('Manage Profile', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
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
            Text("${(progress * 100).toInt()}%",
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
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
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
      ],
    );
  }
}

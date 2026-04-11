import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../widgets/paper_bite_progress.dart';
import '../profile/profile_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final candidateData = provider.candidateData;
    final progressMap = candidateData?['progress'] as List<dynamic>? ?? [];
    
    final streak = candidateData?['study_streak'] ?? 0;
    
    int masteredTotal = 0;
    int itemsTotal = 0;
    for (var p in progressMap) {
      masteredTotal += (p['mastered'] as num? ?? 0).toInt();
      itemsTotal += (p['total_bites'] as int? ?? 1);
    }
    
    // We don't track raw "Accuracy" or "Reviewed" exactly yet without another API call,
    // so we approximate or use placeholders for the demo.
    final accuracy = 87; // Mocked
    final reviewedTotal = masteredTotal + 12; // Mocked

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
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
              // Heatmap / Streak
              Center(
                child: Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text('$streak Day Streak', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 3-way metric box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCompactStat('$masteredTotal', 'Mastered'),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                    _buildCompactStat('$reviewedTotal', 'Reviewed'),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                    _buildCompactStat('$accuracy%', 'Accuracy'),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              const Text('ACTIVITY (LAST 7 DAYS)', style: TextStyle(fontSize: 13, color: Color(0xFF8B949E), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M','T','W','T','F','S','S'].asMap().entries.map((entry) {
                  // Mock heatmap (last 3 days active)
                  final isActive = entry.key >= 4; 
                  return Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF161B22),
                          shape: BoxShape.circle,
                        ),
                        child: isActive ? const Icon(Icons.check, size: 16, color: Colors.white) : const SizedBox(),
                      ),
                      const SizedBox(height: 8),
                      Text(entry.value, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : const Color(0xFF8B949E))),
                    ],
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 48),
              const Text('MASTERY BY PAPER', style: TextStyle(fontSize: 13, color: Color(0xFF8B949E), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              PaperBiteProgressList(papers: progressMap),
              
              const SizedBox(height: 48),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    }, 
                    icon: const Icon(Icons.person_outline, color: Color(0xFF6366F1)), 
                    label: const Text('My Profile', style: TextStyle(color: Color(0xFFE6EDF3)))
                  ),
                  TextButton.icon(
                    onPressed: () => _showElectiveDialog(context, provider), 
                    icon: const Icon(Icons.settings_outlined, color: Color(0xFF6366F1)), 
                    label: const Text('Change Elective', style: TextStyle(color: Color(0xFFE6EDF3)))
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showElectiveDialog(BuildContext context, ProgressProvider provider) {
    final electives = {
      'RURAL': 'Rural Banking',
      'HRM': 'Human Resources Management',
      'IT_DB': 'Information Tech & Digital',
      'RISK': 'Risk Management',
      'CENTRAL': 'Central Banking',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Elective Paper', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...electives.entries.map((e) => ListTile(
                leading: Radio<String>(
                  value: e.key,
                  groupValue: provider.candidateData?['selected_elective'],
                  onChanged: (val) async {
                    Navigator.pop(context);
                    if (val != null) {
                      final success = await provider.updateElective(val);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'Elective updated to ${e.value}' : 'Failed to update elective'))
                        );
                      }
                    }
                  },
                ),
                title: Text(e.value, style: const TextStyle(color: Color(0xFFE6EDF3))),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await provider.updateElective(e.key);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Elective updated to ${e.value}' : 'Failed to update elective'))
                    );
                  }
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../widgets/todays_bite_card.dart';
import '../../widgets/paper_bite_progress.dart';
import '../bite/bite_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _todaysBite;
  bool _isLoadingBite = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().fetchDashboardData();
      _fetchTodaysBite();
    });
  }

  Future<void> _fetchTodaysBite() async {
    final biteData = await ApiService().getTodaysBite();
    if (mounted) {
      setState(() {
        _todaysBite = biteData;
        _isLoadingBite = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final isLoading = provider.isLoading || _isLoadingBite;
    final candidateData = provider.candidateData;
    final progressMap = candidateData?['progress'] as List<dynamic>? ?? [];
    
    final firstName = candidateData?['first_name'] ?? 'Candidate';
    final streak = candidateData?['study_streak'] ?? 0;
    
    int masteredTotal = 0;
    for (var p in progressMap) {
      masteredTotal += (p['mastered'] as num? ?? 0).toInt();
    }
    
    final srsDueCount = _todaysBite?['srs_due_count'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("BITSIZE", style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Good morning, $firstName',
                                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBBF24).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🔥 ', style: TextStyle(fontSize: 16)),
                                    Text('$streak days', style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          if (_todaysBite != null && _todaysBite!['bite'] != null)
                            TodaysBiteCard(
                              bite: _todaysBite!['bite'],
                              mode: _todaysBite!['mode'] ?? 'new',
                              onStart: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => BiteScreen(bite: _todaysBite!['bite'])
                                )).then((_) {
                                  _fetchTodaysBite();
                                });
                              },
                            )
                          else
                            _buildAllCaughtUpCard(),

                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              _buildStatChip('$masteredTotal', 'Bites Mastered', const Color(0xFF10B981)),
                              const SizedBox(width: 16),
                              _buildStatChip('$srsDueCount', 'Due for Review', const Color(0xFFFBBF24)),
                            ],
                          ),

                          const SizedBox(height: 32),
                          const Text('YOUR PROGRESS', style: TextStyle(fontSize: 13, color: Color(0xFF8B949E), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 16),
                          PaperBiteProgressList(papers: progressMap),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAllCaughtUpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 48),
          SizedBox(height: 16),
          Text("You're all caught up!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 8),
          Text("No more bites due for review right now. Check back later or browse the Library.", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8B949E))),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
          ],
        ),
      ),
    );
  }
}

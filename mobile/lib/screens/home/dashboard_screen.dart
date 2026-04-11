import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../widgets/probability_gauge.dart';
import '../../widgets/paper_progress_card.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final isLoading = provider.isLoading;
    final prob = (provider.tracingData?['passing_probability'] ?? 0.0) as double;
    final progressMap = provider.candidateData?['progress'] as List<dynamic>? ?? [];
    final firstName = provider.candidateData?['first_name'] ?? 'Candidate';

    final List<Map<String, String>> corePapers = [
      {'code': 'ABM', 'name': 'Advanced Bank Management'},
      {'code': 'BFM', 'name': 'Bank Financial Management'},
      {'code': 'ABFM', 'name': 'Advanced Business & Financial Management'},
      {'code': 'BRBL', 'name': 'Banking Regulations and Business Laws'},
    ];

    final selectedElective = provider.candidateData?['selected_elective'] as String?;
    final electiveCode = (selectedElective != null && selectedElective.isNotEmpty) ? selectedElective : 'HRM'; // Fallback for legacy registered candidates
    
    String electiveName = 'Elective Paper';
    if (electiveCode == 'RURAL') electiveName = 'Rural Banking';
    if (electiveCode == 'HRM') electiveName = 'Human Resources Management';
    if (electiveCode == 'IT_DB') electiveName = 'Information Tech & Digital';
    if (electiveCode == 'RISK') electiveName = 'Risk Management';
    if (electiveCode == 'CENTRAL') electiveName = 'Central Banking';
    
    corePapers.add({'code': electiveCode, 'name': electiveName});

    return Scaffold(
      appBar: AppBar(
        title: const Text("PROBANKER"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ProfileScreen())
              );
            },
          )
        ]
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              firstName,
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 4),
                              Text('3 Day Streak', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Glassmorphic Gauge Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Center(
                        child: isLoading 
                           ? const CircularProgressIndicator()
                           : ProbabilityGauge(probability: prob),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Your Papers',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: isLoading 
                 ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                 : SliverList(
                     delegate: SliverChildBuilderDelegate(
                       (context, index) {
                         if (index >= corePapers.length) return const SizedBox(height: 40);
                         final paperDef = corePapers[index];
                         
                         // Search progressMap for scores if DB has an entry
                         final progressData = progressMap.firstWhere(
                           (p) => p['paper_code'] == paperDef['code'], 
                           orElse: () => null
                         );
                         final score = progressData != null ? (progressData['current_score'] ?? 0.0) : 0.0;
                         
                         return Padding(
                           padding: const EdgeInsets.only(bottom: 16.0),
                           child: PaperProgressCard(
                             paperCode: paperDef['code']!, 
                             title: paperDef['name']!, 
                             currentScore: score.toDouble()
                           ),
                         );
                       },
                       childCount: corePapers.length + 1,
                     ),
                   ),
            ),
          ],
        ),
      ),
    );
  }
}

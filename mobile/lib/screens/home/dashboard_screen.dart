import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/todays_bite_card.dart';
import '../bite/bite_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _todaysBite;
  bool _isLoadingBite = true;

  @override
  void initState() {
    super.initState();
    _fetchTodaysBite();
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
    final subState = ref.watch(subscriptionProvider);
    // Note: We would ideally have a dedicated DashboardProvider, but using subState as a placeholder
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchTodaysBite();
            await ref.read(subscriptionProvider.notifier).refresh();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsRow(context),
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "CONTINUE LEARNING"),
                    const SizedBox(height: 16),
                    _isLoadingBite 
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSessionCard(context),
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "ACTIVE SYLLABUS"),
                    const SizedBox(height: 16),
                    _buildModuleGrid(context),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back,",
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8B949E),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Banker", // In production, pull firstName from a user provider
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: const Icon(Icons.person_outline, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(context, "STREAK", "7 Days", Icons.local_fire_department, Colors.orangeAccent),
        const SizedBox(width: 16),
        _buildStatCard(context, "XP", "1,240", Icons.bolt, Colors.blueAccent),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B949E),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF8B949E),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context) {
    if (_todaysBite == null || _todaysBite!['bite'] == null) {
      return _buildCaughtUpCard(context);
    }

    final bite = _todaysBite!['bite'];
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bite['paper_code'] ?? 'ABFM',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text("Next Up", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  bite['title'] ?? 'Loading next concept...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "High-yield curriculum content for your CAIIB preparation.",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(
                 builder: (_) => BiteScreen(bite: bite)
               )).then((_) => _fetchTodaysBite());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text("START TODAY'S SESSION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                   SizedBox(width: 8),
                   Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaughtUpCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_outlined, color: Colors.greenAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            "All Caught Up!",
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            "You've mastered all current bites. Check back later for new content.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    // Shared grid for displaying progress by paper
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildModuleItem("ABFM", 0.65),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Additional modules for ABM and BFM will be unlocked soon.",
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleItem(String code, double progress) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Module A", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

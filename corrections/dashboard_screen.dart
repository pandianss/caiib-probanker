import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../bite/bite_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _todaysBite;
  Map<String, dynamic>? _progress;
  bool _isLoading = true;

  static const Map<String, String> _paperNames = {
    'ABM': 'Adv. Bank Management',
    'BFM': 'Bank Financial Mgmt',
    'ABFM': 'Adv. Banking & Finance',
    'PPB': 'Principles of Banking',
    'AFB': 'Accounting & Finance',
    'LRAB': 'Legal & Regulatory',
    'RURAL': 'Rural Banking',
    'HRM': 'Human Resources',
    'IT_DB': 'IT & Digital Banking',
    'RISK': 'Risk Management',
    'CENTRAL': 'Central Banking',
  };

  // Map each paper to a display color for progress bars
  static const Map<String, Color> _paperColors = {
    'ABM': AppTheme.primaryIndigo,
    'BFM': Color(0xFF8B5CF6),
    'ABFM': AppTheme.accentEmerald,
    'PPB': AppTheme.primaryIndigo,
    'AFB': Color(0xFF8B5CF6),
    'LRAB': AppTheme.accentEmerald,
    'RURAL': AppTheme.accentEmerald,
    'HRM': Color(0xFFFB923C),
    'IT_DB': Color(0xFF22D3EE),
    'RISK': AppTheme.errorRose,
    'CENTRAL': Color(0xFF8B5CF6),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService().getTodaysBite(),
      ApiService().getProgress(),
    ]);
    if (mounted) {
      setState(() {
        _todaysBite = results[0] as Map<String, dynamic>?;
        _progress = results[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final papers = (_progress?['papers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final candidate = _progress?['candidate'] as Map<String, dynamic>?;

    final firstName = candidate?['first_name'] as String? ?? 'Banker';
    final streak = candidate?['study_streak'] as int? ?? 0;
    final xp = candidate?['xp_points'] as int? ?? 0;
    final mastered = candidate?['mastered_count'] as int? ?? 0;
    final cert = candidate?['certification'] as String? ?? 'CAIIB';
    final elective = candidate?['selected_elective'] as String?;
    final certLabel = elective != null ? '$cert · ${_paperNames[elective] ?? elective}' : cert;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryIndigo,
          backgroundColor: AppTheme.surfaceDark,
          onRefresh: () async { await _loadData(); await ref.read(subscriptionProvider.notifier).refresh(); },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, firstName, certLabel),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsRow(streak, xp, mastered),
                    const SizedBox(height: 28),
                    _buildSectionLabel('CONTINUE LEARNING'),
                    const SizedBox(height: 12),
                    _isLoading
                        ? _buildSkeletonCard(height: 160)
                        : _buildSessionCard(context),
                    const SizedBox(height: 28),
                    _buildSectionLabel('PAPER PROGRESS'),
                    const SizedBox(height: 12),
                    _isLoading
                        ? _buildSkeletonCard(height: 180)
                        : _buildPaperProgress(papers),
                    const SizedBox(height: 28),
                    _buildSectionLabel('EXAM COUNTDOWN'),
                    const SizedBox(height: 12),
                    _buildExamCountdown(cert),
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

  // ── Sliver Header ─────────────────────────────────────────────────────────────

  Widget _buildSliverHeader(BuildContext context, String firstName, String certLabel) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(firstName,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryIndigo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.3)),
                    ),
                    child: Text(certLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppTheme.primaryIndigo, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Center(
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'B',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(int streak, int xp, int mastered) {
    return Row(
      children: [
        _buildStatCard(label: 'STREAK', value: '$streak days', iconColor: const Color(0xFFFB923C),
            icon: Icons.local_fire_department_rounded),
        const SizedBox(width: 10),
        _buildStatCard(label: 'XP TODAY', value: xp.toString(), iconColor: AppTheme.primaryIndigo,
            icon: Icons.bolt_rounded),
        const SizedBox(width: 10),
        _buildStatCard(label: 'MASTERED', value: mastered.toString(), iconColor: AppTheme.accentEmerald,
            icon: Icons.verified_rounded),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color iconColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 14),
                const SizedBox(width: 6),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppTheme.textMuted, letterSpacing: 1.5));
  }

  // ── Session Card ─────────────────────────────────────────────────────────────

  Widget _buildSessionCard(BuildContext context) {
    if (_todaysBite == null || _todaysBite!['bite'] == null) {
      return _buildCaughtUpCard();
    }
    final bite = _todaysBite!['bite'] as Map<String, dynamic>;
    final paperCode = bite['paper_code'] as String? ?? '';
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryIndigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryIndigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(paperCode,
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppTheme.primaryIndigo)),
                    ),
                    const Spacer(),
                    Text('Next up',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(bite['title'] as String? ?? 'Loading...',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 19, fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary, height: 1.25)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(bite['bite_type'] as String? ?? 'Conceptual',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
                    const SizedBox(width: 12),
                    Icon(Icons.timer_outlined, size: 12, color: Colors.white60),
                    const SizedBox(width: 3),
                    Text('${bite['estimated_minutes'] ?? 5} min',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BiteScreen(bite: bite))).then((_) => _loadData());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("START TODAY'S SESSION",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.bold,
                          color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaughtUpCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_outlined, color: AppTheme.accentEmerald, size: 44),
          const SizedBox(height: 14),
          Text('All Caught Up!',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text("You've mastered today's bites. Come back tomorrow for new content.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  // ── Paper Progress ────────────────────────────────────────────────────────────

  Widget _buildPaperProgress(List<Map<String, dynamic>> papers) {
    if (papers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('No paper data available yet.',
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: papers.asMap().entries.map((entry) {
          final i = entry.key;
          final paper = entry.value;
          final code = paper['paper_code'] as String? ?? '';
          final score = (paper['current_score'] as num?)?.toDouble() ?? 0.0;
          final progress = (score / 100).clamp(0.0, 1.0);
          final name = _paperNames[code] ?? code;
          final color = _paperColors[code] ?? AppTheme.primaryIndigo;
          return Padding(
            padding: EdgeInsets.only(bottom: i < papers.length - 1 ? 16 : 0),
            child: _buildPaperRow(code: code, name: name, progress: progress, color: color),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaperRow({
    required String code,
    required String name,
    required double progress,
    required Color color,
  }) {
    final pct = (progress * 100).toInt();
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(code.length > 4 ? code.substring(0, 4) : code,
                style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text('$pct%',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.06),
                  color: color,
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Exam Countdown ────────────────────────────────────────────────────────────

  Widget _buildExamCountdown(String cert) {
    // In production, calculate from user's onboarding goal / server data
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryIndigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEXT $cert SESSION',
              style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: AppTheme.primaryIndigo, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCountdownUnit('147', 'days left'),
              _buildCountdownDivider(),
              _buildCountdownUnit('3', 'papers'),
              _buildCountdownDivider(),
              _buildCountdownUnit('30 min', 'daily goal'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1, color: Colors.white.withOpacity(0.06),
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text('November 2026 session · At your current pace, you\'re on track.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildCountdownDivider() {
    return Container(
      width: 1, height: 36,
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ── Skeleton Loader ────────────────────────────────────────────────────────────

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

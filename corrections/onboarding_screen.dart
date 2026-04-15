import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

class _Certification {
  final String code;
  final String name;
  final String fullName;
  final String desc;
  final String emoji;
  final List<_Paper> mandatoryPapers;
  final bool hasElective;

  const _Certification({
    required this.code,
    required this.name,
    required this.fullName,
    required this.desc,
    required this.emoji,
    required this.mandatoryPapers,
    this.hasElective = false,
  });
}

class _Paper {
  final String code;
  final String name;
  final String topics;
  const _Paper({required this.code, required this.name, required this.topics});
}

class _Elective {
  final String code;
  final String name;
  final String desc;
  final String emoji;
  const _Elective({required this.code, required this.name, required this.desc, required this.emoji});
}

const _certifications = [
  _Certification(
    code: 'CAIIB',
    name: 'CAIIB',
    fullName: 'Certified Associate of Indian Institute of Bankers',
    desc: 'Advanced banking certification for officers & above',
    emoji: '🏦',
    mandatoryPapers: [
      _Paper(code: 'ABM', name: 'Advanced Bank Management', topics: 'Economics · HRM · Strategic Mgmt · BRM'),
      _Paper(code: 'BFM', name: 'Bank Financial Management', topics: 'Forex · Treasury · Balance Sheet · Risk'),
    ],
    hasElective: true,
  ),
  _Certification(
    code: 'JAIIB',
    name: 'JAIIB',
    fullName: 'Junior Associate of Indian Institute of Bankers',
    desc: 'Foundation banking certification for all officers',
    emoji: '📚',
    mandatoryPapers: [
      _Paper(code: 'PPB', name: 'Principles & Practices of Banking', topics: 'Banking Regulations · KYC · Operations'),
      _Paper(code: 'AFB', name: 'Accounting & Finance for Bankers', topics: 'Accounts · Financial Statements · Taxation'),
      _Paper(code: 'LRAB', name: 'Legal & Regulatory Aspects of Banking', topics: 'NI Act · SARFAESI · FEMA · IBC'),
    ],
    hasElective: false,
  ),
  _Certification(
    code: 'ABFM',
    name: 'ABFM Diploma',
    fullName: 'Advanced Banking & Finance Management',
    desc: 'Specialised diploma in banking finance',
    emoji: '📊',
    mandatoryPapers: [
      _Paper(code: 'ABFM', name: 'Advanced Banking & Finance', topics: 'Credit · Investment · Risk · Regulatory'),
    ],
    hasElective: false,
  ),
  _Certification(
    code: 'DBF',
    name: 'DBF Certificate',
    fullName: 'Diploma in Banking & Finance',
    desc: 'Entry-level IIBF certification',
    emoji: '💳',
    mandatoryPapers: [
      _Paper(code: 'DBF1', name: 'Principles of Banking', topics: 'Banking Basics · Accounts · Operations'),
      _Paper(code: 'DBF2', name: 'Finance & Accounts', topics: 'Financial Markets · Accounts · Taxation'),
    ],
    hasElective: false,
  ),
];

const _electives = [
  _Elective(code: 'RURAL', name: 'Rural Banking', desc: 'Agriculture, NABARD & Regional Growth', emoji: '🌾'),
  _Elective(code: 'HRM', name: 'Human Resources', desc: 'Org Behaviour & People Management', emoji: '👥'),
  _Elective(code: 'IT_DB', name: 'IT & Digital Banking', desc: 'Fintech, Cyber Security & Digital', emoji: '💻'),
  _Elective(code: 'RISK', name: 'Risk Management', desc: 'Credit, Market & Operational Risk', emoji: '⚖️'),
  _Elective(code: 'CENTRAL', name: 'Central Banking', desc: 'Monetary Policy & Regulatory Framework', emoji: '🏛️'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _step = 0;
  String? _selectedCertCode;
  String? _selectedElectiveCode;
  String _selectedGoal = 'steady'; // light | steady | intense
  int _attemptNumber = 1;
  bool _isSubmitting = false;

  _Certification? get _selectedCert =>
      _certifications.where((c) => c.code == _selectedCertCode).firstOrNull;

  int get _totalSteps => _selectedCert?.hasElective == true ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 1 && _selectedCertCode == null) return;
    if (_step == 2 && _selectedCert?.hasElective == true && _selectedElectiveCode == null) return;
    _fadeCtrl.reset();
    setState(() => _step++);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  void _prevStep() {
    if (_step == 0) return;
    _fadeCtrl.reset();
    setState(() => _step--);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  Future<void> _submit() async {
    if (_selectedCertCode == null) return;
    setState(() => _isSubmitting = true);
    // Submit certification, elective, and goal to API
    final elective = _selectedCert?.hasElective == true ? _selectedElectiveCode : null;
    final success = await ApiService().updateOnboarding(
      certification: _selectedCertCode!,
      elective: elective,
      dailyGoal: _selectedGoal,
      attemptNumber: _attemptNumber,
    );
    if (success && mounted) {
      ref.read(subscriptionProvider.notifier).refresh();
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildCertificationPage(),
                  if (_selectedCert?.hasElective == true) _buildElectivePage(),
                  _buildGoalPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    if (_step == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prevStep,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildStepIndicator()),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final total = _totalSteps;
    return Row(
      children: List.generate(total, (i) {
        final bool isDone = i < _step - 1;
        final bool isActive = i == _step - 1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              decoration: BoxDecoration(
                color: isDone
                    ? AppTheme.accentEmerald
                    : isActive
                        ? AppTheme.primaryIndigo
                        : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Page 0: Welcome ─────────────────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryIndigo, Color(0xFF818CF8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('PB',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Master Banking Exams,\nOne Bite at a Time',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 30, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Intelligent, spaced-repetition learning for CAIIB, JAIIB & IIBF certifications.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textMuted, height: 1.6),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: ['CAIIB', 'JAIIB', 'ABFM Diploma', 'DBF Certificate']
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(tag,
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                      ))
                  .toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _nextStep,
                child: Text('GET STARTED',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: GoogleFonts.inter(color: AppTheme.textMuted)),
                GestureDetector(
                  onTap: () {/* navigate to login */},
                  child: Text('Sign in',
                      style: GoogleFonts.inter(color: AppTheme.primaryIndigo, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Certification ────────────────────────────────────────────────────

  Widget _buildCertificationPage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHOOSE CERTIFICATION',
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Text('Which exam are you\npreparing for?',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.2)),
            const SizedBox(height: 8),
            Text('We\'ll personalise your study roadmap based on your selection.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _certifications.map((cert) {
                  final isSelected = _selectedCertCode == cert.code;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCertCode = cert.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryIndigo.withOpacity(0.1)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryIndigo
                                : Colors.white.withOpacity(0.05),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryIndigo.withOpacity(0.2)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text(cert.emoji, style: const TextStyle(fontSize: 20))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cert.name,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16, fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(cert.desc,
                                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                    color: AppTheme.accentEmerald, shape: BoxShape.circle),
                                child: const Icon(Icons.check, size: 14, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _selectedCertCode != null ? _nextStep : null,
                child: const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 2: Papers + Elective (CAIIB only) ──────────────────────────────────

  Widget _buildElectivePage() {
    final cert = _selectedCert;
    if (cert == null) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cert.code} · YOUR PAPERS',
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Text('Mandatory subjects',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: cert.mandatoryPapers.map((paper) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: AppTheme.primaryIndigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(paper.code,
                              style: GoogleFonts.inter(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryIndigo)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(paper.name,
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text(paper.topics,
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Text('CHOOSE YOUR ELECTIVE',
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text('Select your third paper. You can change it later.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _electives.map((el) {
                  final isSelected = _selectedElectiveCode == el.code;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedElectiveCode = el.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryIndigo.withOpacity(0.1)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryIndigo : Colors.white.withOpacity(0.05),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(el.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(el.name,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14, fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary)),
                                  Text(el.desc,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                    color: AppTheme.accentEmerald, shape: BoxShape.circle),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _selectedElectiveCode != null ? _nextStep : null,
                child: const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 3: Study Goal ────────────────────────────────────────────────────────

  Widget _buildGoalPage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STUDY GOAL',
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Text('Set your exam date\n& daily target',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.2)),
            const SizedBox(height: 8),
            Text('We\'ll schedule content to keep you on track.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            _buildCountdownBanner(),
            const SizedBox(height: 20),
            Text('DAILY STUDY TARGET',
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            ...[
              ('light', 'Light · 15 min/day', '5 bites · good for busy schedules'),
              ('steady', 'Steady · 30 min/day', '10 bites · recommended pace'),
              ('intense', 'Intensive · 60 min/day', '20 bites · fast-track preparation'),
            ].map((g) => _buildGoalOption(g.$1, g.$2, g.$3)),
            const SizedBox(height: 20),
            Text('PREVIOUS ATTEMPTS',
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Row(
              children: [1, 2, 3].map((n) {
                final label = n == 3 ? '3rd+' : n == 2 ? '2nd' : '1st';
                final isSelected = _attemptNumber == n;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _attemptNumber = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryIndigo.withOpacity(0.1)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryIndigo : Colors.white.withOpacity(0.05),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text('$label attempt',
                              style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: isSelected ? AppTheme.primaryIndigo : AppTheme.textMuted)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('START LEARNING'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryIndigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEXT SESSION',
                  style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: AppTheme.primaryIndigo, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text('~147 days',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('November 2026 session',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryIndigo, size: 32),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String key, String title, String subtitle) {
    final isSelected = _selectedGoal == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedGoal = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryIndigo.withOpacity(0.08) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primaryIndigo : Colors.white.withOpacity(0.05),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text(subtitle,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.radio_button_checked, color: AppTheme.accentEmerald, size: 20)
              else
                Icon(Icons.radio_button_off, color: Colors.white.withOpacity(0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

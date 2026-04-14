import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String? _selectedElective;
  bool _isSubmitting = false;

  final List<Map<String, String>> _electives = [
    {'code': 'RURAL', 'name': 'Rural Banking', 'desc': 'Focus on agriculture and regional growth.'},
    {'code': 'HRM', 'name': 'Human Resources', 'desc': 'Master organizational behavior & management.'},
    {'code': 'IT_DB', 'name': 'IT & Digital Banking', 'desc': 'The future of fintech and cyber security.'},
    {'code': 'RISK', 'name': 'Risk Management', 'desc': 'Core credit, market, and operational risk.'},
    {'code': 'CENTRAL', 'name': 'Central Banking', 'desc': 'Monetary policy and regulatory framework.'},
  ];

  Future<void> _submit() async {
    if (_selectedElective == null) return;
    setState(() => _isSubmitting = true);

    final success = await ApiService().updateElective(_selectedElective!);
    if (success && mounted) {
      // Refresh user state to reflect elective selection
      ref.read(subscriptionProvider.notifier).refresh();
      // Go to home (Navigation handled by GoRouter based on state in production)
      // For now, we manually pop or navigate if needed, but GoRouter redirect is better.
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                "Choose Your Elective",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Select your CAIIB elective subject to customize your learning roadmap.",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF8B949E),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: _electives.length,
                  itemBuilder: (context, index) {
                    final e = _electives[index];
                    final isSelected = _selectedElective == e['code'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedElective = e['code']),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Theme.of(context).primaryColor.withOpacity(0.1) 
                                : const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.white.withOpacity(0.05),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e['name']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : const Color(0xFFE6EDF3),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e['desc']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF8B949E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedElective != null && !_isSubmitting ? _submit : null,
                  child: Text(_isSubmitting ? "SETTING UP..." : "GET STARTED"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/srs_provider.dart';
import 'topic_detail_screen.dart';
import 'srs_screen.dart';
import 'admin_panel_screen.dart';
import 'case_study_screen.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  String? _expandedPaperCode;

  final List<Map<String, dynamic>> _papers = [
    {
      "code": "ABM", 
      "name": "Advanced Bank Management", 
      "color": Colors.blue[700],
      "modules": ["Statistics & Numericals", "Macroeconomics", "HRM", "Credit Management"]
    },
    {
      "code": "BFM", 
      "name": "Bank Financial Management", 
      "color": Colors.indigo[700],
      "modules": ["Forex & FEMA", "Risk Management", "Treasury & ALM", "Basel"]
    },
    {
      "code": "ABFM", 
      "name": "Advanced Business & Financial Management", 
      "color": Colors.teal[700],
      "modules": ["Capital Budgeting", "Valuation", "Hybrid Finance", "M&A"]
    },
    {
      "code": "BRBL", 
      "name": "Banking Regulations and Business Laws", 
      "color": Colors.amber[800],
      "modules": ["RBI Act", "BR Act", "SARFAESI", "KYC/AML"]
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SRSProvider>(context, listen: false).fetchDueCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('CAIIB Mastery', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 20, color: Colors.grey),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSRSBanner(),
            const SizedBox(height: 24),
            Text(
              'Compulsory Papers',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ..._papers.map((paper) => _buildPaperCard(paper)).toList(),
            const SizedBox(height: 24),
            Text(
              'Elective Choice',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildElectiveSelector(),
            const SizedBox(height: 32),
            Text(
              'Exam Lab',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _buildExamCard(
                    context,
                    title: 'Full Mock',
                    subtitle: '100 marks / 120 mins',
                    icon: Icons.timer_outlined,
                    color: Colors.deepPurpleAccent,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _buildExamCard(
                    context,
                    title: 'Case Lab',
                    subtitle: 'Scenario Focus (50m)',
                    icon: Icons.biotech_outlined,
                    color: Colors.tealAccent.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CaseStudyScreen(
                            caseStudy: {
                              "topic": "Forex Bill Realization",
                              "scenario": "An Indian exporter, M/s ABC Exports, has submitted a bill for USD 100,000 to their bank for realization on 10th May 2026. The inter-bank USD/INR spot rate is 83.20/25. The 1-month forward premium is 10/12 points. The bank requires an exchange margin of 0.15% on the buying rate. The transit period for the bill is 25 days (round up to 1 month for forward premium application). The customer wants the funds credited to their CC account today.",
                              "questions": [
                                {
                                  "id": "1",
                                  "question": "What is the base Spot Buying rate the bank will use?",
                                  "options": ["83.20", "83.25", "83.30", "83.15"],
                                  "answer": "83.20",
                                  "explanation": "In bid/ask notation (83.20/25), the bank buys at the lower rate."
                                },
                                {
                                  "id": "2",
                                  "question": "Calculate final rate after 10 points premium and 0.15% margin.",
                                  "options": ["83.0762", "83.3258", "83.1990", "83.4560"],
                                  "answer": "83.0762",
                                  "explanation": "83.20 + 0.0010 (Premium) - 0.1248 (Margin) = 83.0762"
                                }
                              ]
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSRSBanner() {
    return Consumer<SRSProvider>(
      builder: (context, srs, child) {
        final count = srs.dueCards.length;
        if (count == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SpacedRepetitionScreen())),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blueAccent.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mastery Recall Due', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$count cards need your attention today', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaperCard(Map<String, dynamic> paper) {
    bool isExpanded = _expandedPaperCode == paper['code'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded ? Colors.white : null,
        gradient: isExpanded ? null : LinearGradient(
          colors: [paper['color'], paper['color'].withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: (isExpanded ? Colors.black12 : paper['color'].withOpacity(0.3)), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              paper['code'],
              style: GoogleFonts.outfit(
                color: isExpanded ? Colors.black : Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 18
              ),
            ),
            subtitle: Text(
              paper['name'],
              style: GoogleFonts.outfit(
                color: isExpanded ? Colors.grey[600] : Colors.white.withOpacity(0.9), 
                fontSize: 14
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
              color: isExpanded ? Colors.black : Colors.white
            ),
            onTap: () {
              setState(() {
                _expandedPaperCode = isExpanded ? null : paper['code'];
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: (paper['modules'] as List<String>).map((module) => 
                  ListTile(
                    title: Text(module, style: GoogleFonts.outfit(fontSize: 15)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TopicDetailScreen(
                            paperCode: paper['code'],
                            moduleName: module,
                          ),
                        ),
                      );
                    },
                  )
                ).toList(),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildElectiveSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: const Icon(Icons.school_outlined, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose your Elective', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                Text('Rural, HRM, IT, Risk, or Central', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }
}

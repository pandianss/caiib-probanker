import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicDetailScreen extends StatelessWidget {
  final String paperCode;
  final String moduleName;

  const TopicDetailScreen({
    super.key,
    required this.paperCode,
    required this.moduleName,
  });

  @override
  Widget build(BuildContext context) {
    // Dummy content based on Paper/Module
    final items = _getSampleContent(paperCode, moduleName);

    return Scaffold(
      appBar: AppBar(
        title: Text('$paperCode: $moduleName', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildContentItem(item);
        },
      ),
    );
  }

  Widget _buildContentItem(Map<String, String> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item['type'] == 'numerical' ? Icons.calculate_outlined : Icons.tips_and_updates_outlined,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  item['type']?.toUpperCase() ?? 'KNOWLEDGE',
                  style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['question'] ?? item['front'] ?? '',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Divider(height: 32),
            Text(
              'Correct Answer:',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              item['answer'] ?? item['back'] ?? '',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.green[700], fontWeight: FontWeight.bold),
            ),
            if (item['explanation'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: Text(
                  item['explanation']!,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.blue[800]),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getSampleContent(String paper, String module) {
    if (paper == 'ABM' && module.contains('Statistics')) {
      return [
        {
          "type": "numerical",
          "question": "Calculate the range of the following data: 10, 25, 15, 40, 30",
          "answer": "30",
          "explanation": "Range = Maximum - Minimum = 40 - 10 = 30."
        },
        {
          "type": "concept",
          "front": "What is the P-Value in hypothesis testing?",
          "back": "The probability of obtaining sample results at least as extreme as those observed, assuming the null hypothesis is true."
        }
      ];
    }
    return [
      {"type": "concept", "front": "Focus Area: $module", "back": "Study this module thoroughly for $paper exam."}
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/virtual_calculator.dart';
import '../widgets/numerical_keypad.dart';

class ExamModeScreen extends StatefulWidget {
  final String paperCode;
  
  const ExamModeScreen({super.key, required this.paperCode});

  @override
  State<ExamModeScreen> createState() => _ExamModeScreenState();
}

class _ExamModeScreenState extends State<ExamModeScreen> {
  int _currentIndex = 0;
  final TextEditingController _numericalController = TextEditingController();
  bool _showCalculator = false;

  // Mocked questions for UI logic
  final List<Map<String, dynamic>> _questions = [
    {
      "id": "q1",
      "type": "mcq",
      "question": "Which of the following describes 'Narrow Banking'?",
      "options": ["High risk lending", "Investment in liquid assets", "Retail focus only", "Cross-border trade"],
      "answer": "Investment in liquid assets"
    },
    {
      "id": "q2",
      "type": "numerical",
      "question": "Calculate the current yield if the coupon is 8% and the market price is 95.",
      "answer": "8.42"
    }
  ];

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.paperCode} Mock Exam', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => setState(() => _showCalculator = !_showCalculator),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('119:54', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(value: (_currentIndex + 1) / _questions.length, backgroundColor: Colors.grey[200]),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question ${_currentIndex + 1} of ${_questions.length}', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text(currentQuestion['question'], style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 32),
                      if (currentQuestion['type'] == 'mcq')
                        ..._buildMCQOptions(currentQuestion['options'])
                      else
                        _buildNumericalInput(),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
          if (_showCalculator)
            Positioned(
              right: 16,
              top: 16,
              child: SizedBox(
                width: 280,
                child: VirtualCalculator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMCQOptions(List<String> options) {
    return Column(
      children: options.map((opt) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {},
          child: Text(opt, style: GoogleFonts.outfit(color: Colors.black87)),
        ),
      )).toList(),
    );
  }

  Widget _buildNumericalInput() {
    return Column(
      children: [
        TextField(
          controller: _numericalController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Enter numerical answer',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => NumericalKeypad(
                controller: _numericalController,
                onSubmitted: () => Navigator.pop(ctx),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Use the virtual keypad to enter the exact decimal value.', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
            child: const Text('PREVIOUS'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () {
              if (_currentIndex < _questions.length - 1) {
                setState(() => _currentIndex++);
              } else {
                // Submit logic
              }
            },
            child: Text(_currentIndex < _questions.length - 1 ? 'NEXT' : 'SUBMIT EXAM'),
          ),
        ],
      ),
    );
  }
}

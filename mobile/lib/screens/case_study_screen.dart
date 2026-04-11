import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CaseStudyScreen extends StatefulWidget {
  final Map<String, dynamic> caseStudy;

  const CaseStudyScreen({super.key, required this.caseStudy});

  @override
  State<CaseStudyScreen> createState() => _CaseStudyScreenState();
}

class _CaseStudyScreenState extends State<CaseStudyScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _userAnswers = {};
  bool _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    final questions = widget.caseStudy['questions'] as List;
    final currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Case Study: ${widget.caseStudy['topic']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_currentQuestionIndex + 1} / ${questions.length}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Sticky Scenario Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 16, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text('SCENARIO', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.caseStudy['scenario'],
                  style: GoogleFonts.outfit(fontSize: 14, height: 1.5, color: Colors.black87),
                ),
              ],
            ),
          ),
          
          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentQuestion['question'],
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),
                  ..._buildOptions(currentQuestion['options'] as List, currentQuestion['answer']),
                  if (_isSubmitted) _buildExplanation(currentQuestion['explanation']),
                ],
              ),
            ),
          ),
          
          _buildBottomNav(questions.length),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(List options, String correctAnswer) {
    return options.map((opt) {
      final isSelected = _userAnswers[_currentQuestionIndex] == opt;
      final isCorrect = _isSubmitted && opt == correctAnswer;
      final isWrong = _isSubmitted && isSelected && opt != correctAnswer;

      Color borderColor = Colors.grey[200]!;
      Color bgColor = Colors.transparent;
      if (isSelected) borderColor = Colors.blueAccent;
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green[50]!;
      }
      if (isWrong) {
        borderColor = Colors.redAccent;
        bgColor = Colors.red[50]!;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            backgroundColor: bgColor,
            side: BorderSide(color: borderColor, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitted ? null : () {
            setState(() {
              _userAnswers[_currentQuestionIndex] = opt;
            });
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  opt,
                  style: GoogleFonts.outfit(
                    color: Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  ),
                ),
              ),
              if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 20),
              if (isWrong) const Icon(Icons.error, color: Colors.redAccent, size: 20),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildExplanation(String explanation) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EXPLANATION', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Text(explanation, style: GoogleFonts.outfit(fontSize: 13, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int totalQuestions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentQuestionIndex > 0)
            TextButton(
              onPressed: () => setState(() => _currentQuestionIndex--),
              child: const Text('BACK'),
            )
          else
            const SizedBox.shrink(),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () {
              if (_currentQuestionIndex < totalQuestions - 1) {
                setState(() => _currentQuestionIndex++);
              } else if (!_isSubmitted) {
                setState(() => _isSubmitted = true);
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              _currentQuestionIndex < totalQuestions - 1 
                ? 'NEXT' 
                : (_isSubmitted ? 'FINISH' : 'SUBMIT CASE'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../bite/bite_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _dueBites = [];
  int _currentIndex = 0;
  int _totalDue = 0;
  bool _sessionComplete = false;

  @override
  void initState() {
    super.initState();
    _fetchDueBites();
  }

  Future<void> _fetchDueBites() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getDueBites();
    if (mounted) {
      setState(() {
        _dueBites = List<Map<String, dynamic>>.from(data?['bites'] ?? []);
        _totalDue = data?['due_count'] ?? 0;
        _isLoading = false;
        _sessionComplete = _dueBites.isEmpty;
      });
    }
  }

  void _startOrContinueSession() async {
    if (_currentIndex < _dueBites.length) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BiteScreen(bite: _dueBites[_currentIndex])),
      );
      
      if (mounted) {
        setState(() {
          _currentIndex++;
          if (_currentIndex >= _dueBites.length) {
            _sessionComplete = true;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaced Review'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _sessionComplete
                ? _buildCompletionState()
                : _buildSessionState(),
      ),
    );
  }

  Widget _buildCompletionState() {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(32.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Icon(Icons.done_all, size: 80, color: Color(0xFF10B981)),
             const SizedBox(height: 24),
             const Text('Session Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
             const SizedBox(height: 12),
             const Text(
               'You have strengthened your memory for all due bites in this session. Return tomorrow to keep the streak alive!', 
               textAlign: TextAlign.center, 
               style: TextStyle(color: Color(0xFF8B949E), fontSize: 16)
             ),
             const SizedBox(height: 48),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF21262D),
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.1)))
                 ),
                 onPressed: () => Navigator.pop(context),
                 child: const Text('Back to Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               ),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildSessionState() {
     final remaining = _dueBites.length - _currentIndex;

     return Padding(
       padding: const EdgeInsets.all(24.0),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Container(
             padding: const EdgeInsets.all(32),
             decoration: BoxDecoration(
               color: const Color(0xFFFBBF24).withOpacity(0.1),
               shape: BoxShape.circle,
               border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.2), width: 4)
             ),
             child: const Icon(Icons.psychology, size: 64, color: Color(0xFFFBBF24)),
           ),
           const SizedBox(height: 40),
           Text('$remaining Bites to Review', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
           const SizedBox(height: 12),
           Text(
             'Progress: $_currentIndex of ${_dueBites.length} in this queue', 
             style: const TextStyle(color: Color(0xFF8B949E), fontSize: 16)
           ),
           const SizedBox(height: 16),
           const Text(
             'These bites are due for review based on your previous performance. Let\'s refresh your knowledge!', 
             textAlign: TextAlign.center, 
             style: TextStyle(color: Color(0xFF8B949E), height: 1.5)
           ),
           const SizedBox(height: 48),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFFFBBF24),
                 foregroundColor: const Color(0xFF451A03),
                 padding: const EdgeInsets.symmetric(vertical: 20),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 elevation: 8,
                 shadowColor: const Color(0xFFFBBF24).withOpacity(0.4)
               ),
               onPressed: _startOrContinueSession,
               child: Text(
                 _currentIndex == 0 ? 'START SESSION' : 'CONTINUE SESSION', 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)
               ),
             ),
           ),
           if (_currentIndex > 0)
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: const Text('Finish later', style: TextStyle(color: Color(0xFF8B949E))),
             ),
         ],
       ),
     );
  }
}

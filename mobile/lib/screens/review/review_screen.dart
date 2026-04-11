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
  Map<String, dynamic>? _nextReviewBite;

  @override
  void initState() {
    super.initState();
    _fetchNextReview();
  }

  Future<void> _fetchNextReview() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getTodaysBite();
    if (mounted) {
      if (data != null && data['mode'] == 'review') {
        setState(() {
          _nextReviewBite = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _nextReviewBite = null; // No reviews due
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Queue'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _nextReviewBite == null
                ? _buildEmptyState()
                : _buildReviewQueueData(),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(32.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Icon(Icons.done_all, size: 64, color: Color(0xFF10B981)),
             const SizedBox(height: 24),
             const Text('Queue Empty', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
             const SizedBox(height: 12),
             const Text('You have reviewed all due bites for today. Great job keeping your memory fresh!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8B949E))),
           ],
         ),
       ),
     );
  }

  Widget _buildReviewQueueData() {
     final bite = _nextReviewBite!['bite'];
     final dueCount = _nextReviewBite!['srs_due_count'] ?? 1;

     return Padding(
       padding: const EdgeInsets.all(24.0),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Icon(Icons.psychology, size: 64, color: Color(0xFFFBBF24)),
           const SizedBox(height: 24),
           Text('$dueCount Bites Due', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
           const SizedBox(height: 12),
           const Text('These bites are ready for spaced repetition review to strengthen your long-term retention.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8B949E))),
           const SizedBox(height: 48),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFFFBBF24),
                 foregroundColor: const Color(0xFF451A03),
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
               ),
               onPressed: () {
                 Navigator.push(context, MaterialPageRoute(
                   builder: (_) => BiteScreen(bite: bite)
                 )).then((_) => _fetchNextReview());
               },
               child: const Text('Start Review Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             ),
           ),
         ],
       ),
     );
  }
}

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
  final Set<String> _requeuedIds = {}; // NEW: track items already requeued

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
    if (_currentIndex >= _dueBites.length) return;

    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => BiteScreen(
        bite: _dueBites[_currentIndex],
        isReviewMode: true,  // NEW
      )),
    );
      
    if (mounted) {
      setState(() {
        // If the user rated themselves "Still unsure" (selfRating == 1),
        // re-append the bite to the queue (but only once per session).
        final requeue = result?['requeue'] == true;
        final biteId = _dueBites[_currentIndex]['bite_id'] ?? _dueBites[_currentIndex]['id'].toString();
        final alreadyQueued = _requeuedIds.contains(biteId);

        if (requeue && !alreadyQueued) {
          _requeuedIds.add(biteId);
          _dueBites.add(_dueBites[_currentIndex]);
        }
        _currentIndex++;
        if (_currentIndex >= _dueBites.length) {
          _sessionComplete = true;
        }
      });
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
    final total = _dueBites.length - _requeuedIds.length; // original due count
    final requeued = _requeuedIds.length; // how many were "still unsure"

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.done_all, size: 80, color: Color(0xFF10B981)),
            const SizedBox(height: 24),
            const Text('Session Complete!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            // Summary stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SummaryChip(value: '$total', label: 'Reviewed'),
                const SizedBox(width: 12),
                _SummaryChip(value: '$requeued', label: 'Still shaky'),
                const SizedBox(width: 12),
                _SummaryChip(value: '${total - requeued}', label: 'Locked in'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              requeued > 0
                  ? 'You\'re still building confidence on $requeued bite${requeued > 1 ? "s" : ""}. They\'ll resurface soon.'
                  : 'All bites reinforced. Your spaced-repetition schedule has been updated.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21262D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dashboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.2), width: 4)),
            child: const Icon(Icons.psychology, size: 64, color: Color(0xFFFBBF24)),
          ),
          const SizedBox(height: 40),
          Text('$remaining Bites to Review',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text('Progress: $_currentIndex of ${_dueBites.length} in this queue',
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 16)),
          const SizedBox(height: 16),
          const Text(
              'These bites are due for review based on your previous performance. Let\'s refresh your knowledge!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8B949E), height: 1.5)),
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
                  shadowColor: const Color(0xFFFBBF24).withOpacity(0.4)),
              onPressed: _startOrContinueSession,
              child: Text(_currentIndex == 0 ? 'START SESSION' : 'CONTINUE SESSION',
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
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

class _SummaryChip extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E))),
        ],
      ),
    );
  }
}

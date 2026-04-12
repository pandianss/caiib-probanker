import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../library/library_screen.dart'; // Reuse BiteScreen if possible, or create specialized one

class BundleRoadmapScreen extends StatefulWidget {
  final int bundleId;
  final String title;
  final bool isOwned;
  final double price;

  const BundleRoadmapScreen({
    super.key,
    required this.bundleId,
    required this.title,
    this.isOwned = false,
    this.price = 0.0,
  });

  @override
  State<BundleRoadmapScreen> createState() => _BundleRoadmapScreenState();
}

class _BundleRoadmapScreenState extends State<BundleRoadmapScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bites = [];
  List<String> _masteredIds = [];

  @override
  void initState() {
    super.initState();
    _fetchRoadmapData();
  }

  Future<void> _fetchRoadmapData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.getBitesByBundle(widget.bundleId),
      _apiService.getMasteredBiteIds(),
    ]);

    if (mounted) {
      setState(() {
        _bites = results[0] as List<dynamic>? ?? [];
        _masteredIds = results[1] as List<String>? ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bites.isEmpty
              ? const Center(child: Text('This roadmap is empty.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  itemCount: _bites.length,
                  itemBuilder: (context, index) {
                    final bite = _bites[index];
                    final isMastered = _masteredIds.contains(bite['bite_id']);
                    final isLast = index == _bites.length - 1;
                    final bool isLocked = !widget.isOwned && (bite['is_free'] == false);

                    return _buildRoadmapNode(bite, isMastered, isLast, index + 1, isLocked);
                  },
                ),
    );
  }

  Widget _buildRoadmapNode(dynamic bite, bool isMastered, bool isLast, int step, bool isLocked) {
    return Column(
      children: [
        Row(
          children: [
            Column(
              children: [
                _buildCircleIndicator(isMastered, step, isLocked),
                if (!isLast) _buildConnector(),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: GestureDetector(
                onTap: () {
                   final bool isFree = bite['is_free'] ?? false;
                   final bool isLocked = !widget.isOwned && !isFree;

                   if (isLocked) {
                     _showPurchaseDialog();
                   } else {
                     // Navigate to study this bite
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Starting Step $step: ${bite['title']}')),
                     );
                   }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMastered 
                        ? AppTheme.primaryIndigo.withOpacity(0.5) 
                        : (bite['is_free'] == false && !widget.isOwned ? Colors.red.withOpacity(0.2) : Colors.white10)
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Step $step', style: TextStyle(color: AppTheme.primaryIndigo.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          if (bite['is_free'] == false && !widget.isOwned)
                            const Icon(Icons.lock_outline, size: 14, color: Colors.orangeAccent),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(bite['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(bite['chapter'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIndicator(bool isMastered, int step, bool isLocked) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isMastered ? AppTheme.primaryIndigo : AppTheme.surfaceDark,
        shape: BoxShape.circle,
        border: Border.all(color: isMastered ? Colors.transparent : (isLocked ? Colors.white10 : Colors.white24), width: 2),
        boxShadow: isMastered ? [BoxShadow(color: AppTheme.primaryIndigo.withOpacity(0.3), blurRadius: 10)] : [],
      ),
      child: Center(
        child: isLocked
            ? const Icon(Icons.lock_outline, color: Colors.white38, size: 18)
            : isMastered
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Premium Content', style: TextStyle(color: Colors.white)),
        content: Text(
          'This bite is part of the premium curriculum. Unlock the full roadmap for ₹${widget.price} to continue.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo),
            onPressed: () async {
              Navigator.pop(context);
              final success = await _apiService.purchaseBundle(widget.bundleId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase successful!'), backgroundColor: Colors.green),
                );
                _fetchRoadmapData();
              }
            },
            child: const Text('Unlock Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 2,
      height: 60,
      color: Colors.white10,
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'bundle_roadmap_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bundles = [];
  List<int> _ownedBundleIds = [];

  @override
  void initState() {
    super.initState();
    _fetchMarketplaceData();
  }

  Future<void> _fetchMarketplaceData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.getMarketplaceBundles(),
      _apiService.getMyOwnedBundles(),
    ]);

    if (mounted) {
      setState(() {
        _bundles = results[0] as List<dynamic>? ?? [];
        final owned = results[1] as List<dynamic>? ?? [];
        _ownedBundleIds = owned.map((b) => b['id'] as int).toList();
        _isLoading = false;
      });
    }
  }

  void _navigateToRoadmap(dynamic bundle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BundleRoadmapScreen(
          bundleId: bundle['id'],
          title: bundle['title'],
          isOwned: _ownedBundleIds.contains(bundle['id']),
          price: (bundle['price'] as num).toDouble(),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(int bundleId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Unlock $title?', style: const TextStyle(color: Colors.white)),
        content: const Text('This will grant you permanent access to this high-yield roadmap.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Purchase'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.purchaseBundle(bundleId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully unlocked $title!'), backgroundColor: Colors.green),
        );
        _fetchMarketplaceData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Knowledge Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primaryIndigo, AppTheme.backgroundDark],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_bundles.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No verified roadmaps available yet.', style: TextStyle(color: Colors.white70))))
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bundle = _bundles[index];
                    final isOwned = _ownedBundleIds.contains(bundle['id']);
                    return _buildBundleCard(bundle, isOwned);
                  },
                  childCount: _bundles.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBundleCard(dynamic bundle, bool isOwned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primaryIndigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(bundle['paper_code'], style: const TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Text('₹${bundle['price']}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(bundle['title'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(bundle['description'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppTheme.primaryIndigo),
                    const SizedBox(width: 4),
                    Text(bundle['creator_name'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.book_outlined, size: 16, color: AppTheme.primaryIndigo),
                    const SizedBox(width: 4),
                    Text('${bundle['bite_count']} Bites', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _navigateToRoadmap(bundle),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isOwned ? Colors.green.withOpacity(0.1) : AppTheme.primaryIndigo,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  isOwned ? 'OWNED' : 'UNLOCK ACCESS',
                  style: TextStyle(color: isOwned ? Colors.green : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'bundle_roadmap_screen.dart';

// ─── Pricing Data ─────────────────────────────────────────────────────────────

class _Plan {
  final String key;
  final String name;
  final int price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final Color accent;

  const _Plan({
    required this.key,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.isPopular = false,
    required this.accent,
  });
}

const _plans = [
  _Plan(
    key: 'free',
    name: 'Free',
    price: 0,
    period: 'forever',
    features: ['5 bites / day', '1 paper access', 'Basic review'],
    accent: AppTheme.textMuted,
  ),
  _Plan(
    key: 'pro',
    name: 'Pro',
    price: 299,
    period: '/month',
    features: ['Unlimited bites', 'All 3 papers', 'SRS review', 'Stats & analytics'],
    isPopular: true,
    accent: AppTheme.primaryIndigo,
  ),
  _Plan(
    key: 'elite',
    name: 'Elite',
    price: 599,
    period: '/month',
    features: ['Everything in Pro', 'Expert bundles', 'Priority support', 'Offline mode'],
    accent: const Color(0xFFFBBF24),
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _bundles = [];
  List<int> _ownedBundleIds = [];
  String _activePlan = 'free'; // from server in production

  static const _tabs = ['All', 'CAIIB', 'JAIIB', 'ABFM', 'My Library'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService().getMarketplaceBundles(),
      ApiService().getMyOwnedBundles(),
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

  List<dynamic> get _filteredBundles {
    final tab = _tabController.index;
    if (tab == 0) return _bundles;
    if (tab == 4) return _bundles.where((b) => _ownedBundleIds.contains(b['id'])).toList();
    final cert = _tabs[tab];
    return _bundles.where((b) {
      final code = (b['paper_code'] as String? ?? '').toUpperCase();
      return code.startsWith(cert) || _paperBelongsToCert(code, cert);
    }).toList();
  }

  bool _paperBelongsToCert(String paperCode, String cert) {
    const caiibPapers = {'ABM', 'BFM', 'RURAL', 'HRM', 'IT_DB', 'RISK', 'CENTRAL'};
    const jaiibPapers = {'PPB', 'AFB', 'LRAB'};
    if (cert == 'CAIIB') return caiibPapers.contains(paperCode);
    if (cert == 'JAIIB') return jaiibPapers.contains(paperCode);
    return false;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildSliverHeader(subState.tier),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((_) => _buildBundleList()).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(String currentTier) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Knowledge Store',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('Unlock expert roadmaps · Go Pro for unlimited access',
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPlanCards(currentTier),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('FEATURED ROADMAPS',
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Plan Cards ────────────────────────────────────────────────────────────────

  Widget _buildPlanCards(String currentTier) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _buildPlanCard(_plans[i], currentTier),
      ),
    );
  }

  Widget _buildPlanCard(_Plan plan, String currentTier) {
    final isActive = currentTier.toUpperCase() == plan.key.toUpperCase();
    final isPopular = plan.isPopular;

    return GestureDetector(
      onTap: () => _showUpgradeSheet(plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPopular ? plan.accent.withOpacity(0.1) : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPopular ? plan.accent : Colors.white.withOpacity(0.06),
            width: isPopular ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.name,
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: plan.accent, letterSpacing: 1.2)),
                const Spacer(),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('POPULAR',
                        style: GoogleFonts.inter(
                            fontSize: 7, fontWeight: FontWeight.w700, color: const Color(0xFF1A1200))),
                  ),
                if (isActive && !isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentEmerald.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('ACTIVE',
                        style: GoogleFonts.inter(
                            fontSize: 7, fontWeight: FontWeight.w700, color: AppTheme.accentEmerald)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: plan.price == 0 ? 'Free' : '₹${plan.price}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  if (plan.price > 0)
                    TextSpan(
                      text: plan.period,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plan.features
                    .take(3)
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check, size: 11, color: plan.accent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(f,
                                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeSheet(_Plan plan) {
    if (plan.price == 0) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _UpgradeSheet(plan: plan),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return SizedBox(
      height: 44,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: AppTheme.primaryIndigo.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.3)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
        labelColor: AppTheme.primaryIndigo,
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelColor: AppTheme.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
        onTap: (_) => setState(() {}),
      ),
    );
  }

  // ── Bundle List ────────────────────────────────────────────────────────────────

  Widget _buildBundleList() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: 3,
        itemBuilder: (_, __) => _buildBundleSkeleton(),
      );
    }
    final bundles = _filteredBundles;
    if (bundles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('No roadmaps available here yet.',
                style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: bundles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final b = bundles[i];
        final isOwned = _ownedBundleIds.contains(b['id'] as int?);
        return _buildBundleCard(b, isOwned);
      },
    );
  }

  Widget _buildBundleCard(dynamic bundle, bool isOwned) {
    final paperCode = bundle['paper_code'] as String? ?? '';
    final price = (bundle['price'] as num?)?.toDouble() ?? 0.0;
    final biteCount = bundle['bite_count'] as int? ?? 0;
    final rating = bundle['rating'] as double?;
    final creatorName = bundle['creator_name'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BundleRoadmapScreen(
            bundleId: bundle['id'] as int,
            title: bundle['title'] as String,
            isOwned: isOwned,
            price: price,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOwned
                ? AppTheme.accentEmerald.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPaperChip(paperCode),
                      if (isOwned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentEmerald.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('OWNED',
                              style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: AppTheme.accentEmerald)),
                        )
                      else
                        Text('₹${price.toInt()}',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(bundle['title'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 17, fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary, height: 1.25)),
                  const SizedBox(height: 6),
                  Text(bundle['description'] as String? ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textMuted, height: 1.5),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 13, color: AppTheme.primaryIndigo),
                      const SizedBox(width: 4),
                      Text(creatorName,
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(width: 16),
                      Icon(Icons.menu_book_outlined, size: 13, color: AppTheme.primaryIndigo),
                      const SizedBox(width: 4),
                      Text('$biteCount Bites',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      if (rating != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.star_rounded, size: 13, color: const Color(0xFFFBBF24)),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isOwned
                    ? AppTheme.accentEmerald.withOpacity(0.08)
                    : AppTheme.primaryIndigo,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isOwned ? 'VIEW ROADMAP' : 'UNLOCK ACCESS',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.bold,
                          color: isOwned ? AppTheme.accentEmerald : Colors.white,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Icon(isOwned ? Icons.arrow_forward_rounded : Icons.lock_open_rounded,
                        size: 15,
                        color: isOwned ? AppTheme.accentEmerald : Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryIndigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(code,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryIndigo)),
    );
  }

  Widget _buildBundleSkeleton() {
    return Container(
      height: 200, margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(20)),
    );
  }
}

// ─── Upgrade Bottom Sheet ─────────────────────────────────────────────────────

class _UpgradeSheet extends StatefulWidget {
  final _Plan plan;
  const _UpgradeSheet({required this.plan});

  @override
  State<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<_UpgradeSheet> {
  bool _annual = false;
  bool _isPurchasing = false;

  int get _price {
    if (_annual) return (widget.plan.price * 10).toInt(); // 2 months free annually
    return widget.plan.price;
  }

  Future<void> _initiatePurchase() async {
    setState(() => _isPurchasing = true);
    // In production: initiate Razorpay flow via payment_service
    await ApiService().initiateSubscription(
      planKey: widget.plan.key,
      annual: _annual,
    );
    if (mounted) {
      setState(() => _isPurchasing = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Upgrade to ${widget.plan.name}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const Spacer(),
              Icon(Icons.workspace_premium_rounded, color: widget.plan.accent, size: 26),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                          color: widget.plan.accent.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(Icons.check, size: 13, color: widget.plan.accent),
                    ),
                    const SizedBox(width: 12),
                    Text(f,
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text('Annual billing',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Save 17%',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppTheme.accentEmerald)),
                ),
                const Spacer(),
                Switch(
                  value: _annual,
                  onChanged: (v) => setState(() => _annual = v),
                  activeColor: AppTheme.primaryIndigo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _isPurchasing ? null : _initiatePurchase,
              style: ElevatedButton.styleFrom(backgroundColor: widget.plan.accent),
              child: _isPurchasing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Subscribe for ₹$_price${_annual ? '/year' : '/month'}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Cancel anytime · Powered by Razorpay',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }
}

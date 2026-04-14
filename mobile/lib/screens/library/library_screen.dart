import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../bite/bite_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _selectedPaper = 'ABFM';
  bool _isLoading = false;
  List<dynamic> _bites = [];
  List<String> _masteredIds = [];
  bool _isSearching = false;
  String _searchQuery = '';

  List<String> _getAvailablePapers() {
    // Ideally pull from a dedicated provider
    return ['ABM', 'BFM', 'ABFM', 'BRBL'].toSet().toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchBitesAndMastery();
  }

  Future<void> _fetchBitesAndMastery() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService().getBitesByPaper(_selectedPaper),
      ApiService().getMasteredBiteIds(),
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
    final filteredBites = _searchQuery.isEmpty
        ? _bites
        : _bites.where((b) =>
            (b['title'] ?? '').toLowerCase().contains(_searchQuery) ||
            (b['module'] ?? '').toLowerCase().contains(_searchQuery) ||
            (b['chapter'] ?? '').toLowerCase().contains(_searchQuery)
          ).toList();

    final List<Widget> linearItems = [];
    final Map<String, Map<String, List<dynamic>>> structured = {};
    for (var bite in filteredBites) {
       final module = bite['module'] ?? 'General';
       final chapter = bite['chapter'] ?? 'General';
       if (!structured.containsKey(module)) structured[module] = {};
       if (!structured[module]!.containsKey(chapter)) structured[module]![chapter] = [];
       structured[module]![chapter]!.add(bite);
    }

    for (var modName in structured.keys) {
      linearItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Text(
            modName.toUpperCase(), 
            style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)
          ),
        )
      );

      final chaptersMap = structured[modName]!;
      for (var chapName in chaptersMap.keys) {
        if (chapName != 'General') {
          linearItems.add(
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16, top: 4),
              child: Text(chapName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          );
        }

        final bites = chaptersMap[chapName]!;
        for (var bite in bites) {
          final isMastered = _masteredIds.contains(bite['bite_id']);
          linearItems.add(
            Card(
              color: const Color(0xFF161B22),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
                side: BorderSide(color: isMastered ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white.withOpacity(0.05))
              ),
              child: ListTile(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => BiteScreen(bite: bite)));
                  _fetchBitesAndMastery();
                },
                title: Text(bite['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                trailing: isMastered 
                  ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                  : const Icon(Icons.chevron_right, color: Color(0xFF8B949E)),
              ),
            ),
          );
        }
      }
    }

    final papers = _getAvailablePapers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search), 
            onPressed: () {}
          )
        ]
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  "CURRENT SYLLABUS: ABFM (2026)",
                  style: TextStyle(
                    color: Color(0xFF6366F1), 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12, 
                    letterSpacing: 1.5
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : filteredBites.isEmpty 
                      ? const Center(child: Text("No bites found."))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: linearItems,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

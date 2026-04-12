import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../bite/bite_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedPaper = 'ABM';
  bool _isLoading = false;
  List<dynamic> _bites = [];
  List<String> _masteredIds = [];
  bool _isSearching = false;
  String _searchQuery = '';

  List<String> _getAvailablePapers(BuildContext context) {
    final provider = context.read<ProgressProvider>();
    final elective = provider.candidateData?['selected_elective'] as String? ?? 'RISK';
    return ['ABM', 'BFM', 'ABFM', 'BRBL', elective].toSet().toList();
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

    // 1. Prepare linear items
    final List<Widget> linearItems = [];
    
    // Flatten the nesting: Module -> Chapter -> Bites
    final Map<String, Map<String, List<dynamic>>> structured = {};
    for (var bite in filteredBites) {
       final module = bite['module'] ?? 'General';
       final chapter = bite['chapter'] ?? 'General';
       if (!structured.containsKey(module)) structured[module] = {};
       if (!structured[module]!.containsKey(chapter)) structured[module]![chapter] = [];
       structured[module]![chapter]!.add(bite);
    }

    final modules = structured.keys.toList();
    for (var modName in modules) {
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
      final chapters = chaptersMap.keys.toList();
      for (var chapName in chapters) {
        if (chapName != 'General') {
          linearItems.add(
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16, top: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3))),
                    child: const Icon(Icons.menu_book, size: 16, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(chapName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          );
        }

        final bites = chaptersMap[chapName]!;
        for (var bite in bites) {
          final isMastered = _masteredIds.contains(bite['bite_id']);
          linearItems.add(
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VerticalPathIndicator(isLast: bites.last == bite, isMastered: isMastered),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: const Color(0xFF161B22),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), 
                        side: BorderSide(color: isMastered ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white.withOpacity(0.05))
                      ),
                      child: ListTile(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => BiteScreen(bite: bite)));
                          _fetchBitesAndMastery(); // Refresh mastery on return
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(bite['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                              Row(
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text(bite['difficulty']?.toString().toUpperCase() ?? 'MEDIUM', style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                        ),
                        trailing: isMastered 
                          ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                          : const Icon(Icons.chevron_right, color: Color(0xFF8B949E)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    final papers = _getAvailablePapers(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Search bites...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.white54)),
              onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
            )
          : const Text('Library'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search), 
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            })
          )
        ]
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isSearching)
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: papers.length,
                  itemBuilder: (context, index) {
                    final p = papers[index];
                    final isSelected = p == _selectedPaper;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF8B949E), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF161B22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1))),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedPaper = p);
                            _fetchBitesAndMastery();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : filteredBites.isEmpty 
                      ? const Center(child: Text("No bites found.", style: TextStyle(color: Colors.grey)))
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

class VerticalPathIndicator extends StatelessWidget {
  final bool isLast;
  final bool isMastered;
  const VerticalPathIndicator({super.key, required this.isLast, this.isMastered = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            color: isMastered ? const Color(0xFF10B981) : const Color(0xFF6366F1).withOpacity(0.5), 
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 2)
          ),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 50, // Reduced to avoid overlap/gaps, dots are main guides
            color: isMastered ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFF6366F1).withOpacity(0.1),
          ),
      ],
    );
  }
}

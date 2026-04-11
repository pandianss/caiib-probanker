import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/srs_provider.dart';
import '../widgets/flashcard_widget.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SRSProvider>(context, listen: false).fetchDueCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Mastery Recall', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<SRSProvider>(
        builder: (context, srs, child) {
          if (srs.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (srs.dueCards.isEmpty) {
            return _buildEmptyState();
          }

          final currentCard = srs.dueCards.first;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAILY DUE: ${srs.dueCards.length}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                    ),
                    const Icon(Icons.psychology_outlined, color: Colors.blueAccent),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FlashcardWidget(
                    key: ValueKey(currentCard.id),
                    front: currentCard.front,
                    back: currentCard.back,
                  ),
                ),
              ),
              _buildGradingBar(context, currentCard.id),
              const SizedBox(height: 48),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
          const SizedBox(height: 24),
          Text(
            'Session Complete!',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You are caught up with all regulatory cards.',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Dashboard'),
          )
        ],
      ),
    );
  }

  Widget _buildGradingBar(BuildContext context, String cardId) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Text(
            'How well did you recall this?',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              final labels = ['Blackout', 'Failed', 'Difficulty', 'Good', 'Bright', 'Perfect'];
              final colors = [
                Colors.black, 
                Colors.redAccent, 
                Colors.orangeAccent, 
                Colors.blueAccent, 
                Colors.greenAccent[700], 
                Colors.teal[600]
              ];
              
              return GestureDetector(
                onTap: () {
                  Provider.of<SRSProvider>(context, listen: false).recordReview(cardId, index);
                },
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors[index]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors[index]!.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          index.toString(),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colors[index]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                    )
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

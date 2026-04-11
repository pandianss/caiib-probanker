import 'package:flutter/material.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  bool isFlipped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaced Repetition'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFlipped = !isFlipped;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    decoration: BoxDecoration(
                      color: isFlipped ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isFlipped ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          isFlipped 
                              ? 'A measure of the level of prices of all new, domestically produced, final goods and services in an economy. Calculated as (Nominal GDP / Real GDP) x 100.'
                              : 'What is the GDP Deflator?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: isFlipped ? 20 : 28,
                            color: isFlipped ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Action Bar
            AnimatedOpacity(
              opacity: isFlipped ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQualityButton(context, "Hard", 1, Colors.redAccent),
                    _buildQualityButton(context, "Good", 3, Colors.orangeAccent),
                    _buildQualityButton(context, "Easy", 5, Colors.tealAccent),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQualityButton(BuildContext context, String label, int rating, Color color) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // Rate the card
            setState(() { isFlipped = false; });
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(
              rating.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

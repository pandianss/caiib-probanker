import 'package:flutter/material.dart';

import 'dart:math';

class ProbabilityGauge extends StatefulWidget {
  final double probability;
  const ProbabilityGauge({super.key, required this.probability});

  @override
  State<ProbabilityGauge> createState() => _ProbabilityGaugeState();
}

class _ProbabilityGaugeState extends State<ProbabilityGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0.0, end: widget.probability).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(covariant ProbabilityGauge oldWidget) {
    if (oldWidget.probability != widget.probability) {
       _animation = Tween<double>(begin: oldWidget.probability, end: widget.probability).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
       );
       _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _GaugePainter(_animation.value),
          child: SizedBox(
             width: 200,
             height: 200,
             child: Center(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(
                     '${(_animation.value * 100).toInt()}%',
                     style: Theme.of(context).textTheme.displayLarge?.copyWith(
                       color: const Color(0xFF14B8A6),
                       fontWeight: FontWeight.bold
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text('Pass Probability', style: Theme.of(context).textTheme.bodyMedium),
                 ],
               )
             )
          )
        );
      }
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double probability;
  _GaugePainter(this.probability);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    
    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
      
    // Needs sweeping gradient based on prob
    final sweepGradient = SweepGradient(
      colors: const [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF14B8A6)],
      stops: const [0.0, 0.45, 0.9],
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
    ).createShader(Rect.fromCircle(center: center, radius: radius));
      
    final progressPaint = Paint()
      ..shader = sweepGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
      
    // Draw background (A full circle for gauge)
    canvas.drawArc(
       Rect.fromCircle(center: center, radius: radius),
       -pi * 1.25, 
       pi * 1.5, // Total span
       false, 
       bgPaint
    );
    
    // Draw Progress
    canvas.drawArc(
       Rect.fromCircle(center: center, radius: radius),
       -pi * 1.25, 
       (pi * 1.5) * probability, 
       false, 
       progressPaint
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.probability != probability;
  }
}

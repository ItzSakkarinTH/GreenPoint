import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class LoadingRingPainter extends CustomPainter {
  final double rotationAngle;
  final Color baseColor;

  LoadingRingPainter(this.rotationAngle, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Outer rotating gradient track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = baseColor.withOpacity(0.1);
    canvas.drawCircle(center, radius, trackPaint);

    // First rotating arc
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = baseColor;
    
    // Draw rotating arc 1
    canvas.drawArc(rect, rotationAngle, 1.3, false, paint1);

    // Second rotating arc (semi-transparent, opposite side)
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = baseColor.withOpacity(0.5);
    
    canvas.drawArc(rect, rotationAngle + math.pi, 0.9, false, paint2);

    // Orbiting dot that moves along the ring
    final orbitAngle = rotationAngle * 1.6; // Speed offset
    final dotX = center.dx + radius * math.cos(orbitAngle);
    final dotY = center.dy + radius * math.sin(orbitAngle);
    
    final dotPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(dotX, dotY), 4.5, dotPaint);

    // Subtle glowing shadow under orbiting dot
    final dotGlow = Paint()
      ..color = baseColor.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(dotX, dotY), 7, dotGlow);
  }

  @override
  bool shouldRepaint(covariant LoadingRingPainter oldDelegate) => true;
}

class PremiumLoadingOverlay extends StatefulWidget {
  final String message;

  const PremiumLoadingOverlay({
    super.key,
    required this.message,
  });

  @override
  State<PremiumLoadingOverlay> createState() => _PremiumLoadingOverlayState();
}

class _PremiumLoadingOverlayState extends State<PremiumLoadingOverlay> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _textFadeController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Spinning rotation controller
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 2. Pulse controller for central icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Text fade controller for breathing loading text
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _textOpacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color greenThemeColor = Color(0xFF2E7D32);

    return Stack(
      children: [
        // 1. Glassmorphism frosted background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ),
        
        // 2. Central elegant loading card
        Center(
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: greenThemeColor.withOpacity(0.1),
                  blurRadius: 25,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Custom spinner + pulsing leaf icon
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating custom ring
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(80, 80),
                            painter: LoadingRingPainter(
                              _rotationController.value * 2 * math.pi,
                              greenThemeColor,
                            ),
                          );
                        },
                      ),
                      
                      // Central pulsing leaf icon
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: greenThemeColor.withOpacity(0.15),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded, // Leaf icon representing green points
                            color: greenThemeColor,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                // Breathing loading text
                AnimatedBuilder(
                  animation: _textOpacityAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacityAnimation.value,
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

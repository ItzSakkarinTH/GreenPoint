import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LeafParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double angle;
  double spin;
  Color color;
  double opacity;

  LeafParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.angle,
    required this.spin,
    required this.color,
    required this.opacity,
  });
}

class LeafBurstPainter extends CustomPainter {
  final List<LeafParticle> particles;
  final double progress;

  LeafBurstPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    for (var p in particles) {
      // Calculate current position based on velocity and progress
      final currentX = center.dx + p.x + p.vx * progress * 160;
      final currentY = center.dy + p.y + p.vy * progress * 160 + (progress * progress * 60); // gravity effect
      final currentAngle = p.angle + p.spin * progress * 2 * math.pi;
      final currentOpacity = (p.opacity * (1.0 - progress)).clamp(0.0, 1.0);

      paint.color = p.color.withOpacity(currentOpacity);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentAngle);

      // Draw leaf shape
      final path = Path();
      path.moveTo(0, -p.size / 2);
      path.quadraticBezierTo(-p.size / 2, -p.size / 4, -p.size / 6, 0);
      path.quadraticBezierTo(-p.size / 2, p.size / 4, 0, p.size / 2);
      path.quadraticBezierTo(p.size / 2, p.size / 4, p.size / 6, 0);
      path.quadraticBezierTo(p.size / 2, -p.size / 4, 0, -p.size / 2);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LeafBurstPainter oldDelegate) => true;
}

class GlowingRaysPainter extends CustomPainter {
  final double angle;
  final Color color;

  GlowingRaysPainter(this.angle, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const numRays = 8;
    const rayAngle = (2 * math.pi) / numRays;

    for (int i = 0; i < numRays; i++) {
      final startAngle = i * rayAngle + angle;
      
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          rayAngle / 3, // Ray width
          false,
        )
        ..close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GlowingRaysPainter oldDelegate) => true;
}

class RedeemSuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onConfirm;

  const RedeemSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'ตกลง',
    this.onConfirm,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'ตกลง',
    VoidCallback? onConfirm,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return RedeemSuccessDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onConfirm: onConfirm,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<RedeemSuccessDialog> createState() => _RedeemSuccessDialogState();
}

class _RedeemSuccessDialogState extends State<RedeemSuccessDialog> with TickerProviderStateMixin {
  late AnimationController _raysController;
  late AnimationController _burstController;
  late AnimationController _iconScaleController;
  late AnimationController _contentFadeController;
  
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _contentSlideAnimation;

  final List<LeafParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 1. Rotating rays background controller
    _raysController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 2. Leaf burst controller
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 3. Elastic icon scale controller
    _iconScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScaleAnimation = CurvedAnimation(
      parent: _iconScaleController,
      curve: Curves.elasticOut,
    );

    // 4. Content fade-in & slide-up controller
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentFadeController, curve: Curves.easeOut),
    );
    _contentSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentFadeController, curve: Curves.easeOutBack),
    );

    // Initialize leaf particles
    _generateParticles();

    // Trigger animations in sequence
    _startAnimationSequence();
  }

  void _generateParticles() {
    final colors = [
      const Color(0xFF2E7D32), // primaryGreen
      const Color(0xFF4CAF50), // Light Green
      const Color(0xFF81C784), // Pale Green
      const Color(0xFFA5D6A7), // Soft Green
      const Color(0xFFC8E6C9), // Very Light Green
      const Color(0xFF8D6E63), // earthTone
    ];

    for (int i = 0; i < 25; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 1.0 + _random.nextDouble() * 2.5;
      
      _particles.add(
        LeafParticle(
          x: 0,
          y: 0,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 1.0, // slight upward bias
          size: 10.0 + _random.nextDouble() * 14.0,
          angle: _random.nextDouble() * 2 * math.pi,
          spin: -1.0 + _random.nextDouble() * 2.0,
          color: colors[_random.nextInt(colors.length)],
          opacity: 0.8 + _random.nextDouble() * 0.2,
        ),
      );
    }
  }

  void _startAnimationSequence() async {
    // Phase 1: Spring up the checkmark icon
    _iconScaleController.forward();
    
    // Phase 2: Wait slightly then trigger leaf burst explosion
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      _burstController.forward();
    }

    // Phase 3: Fade in the text and confirm button
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      _contentFadeController.forward();
    }
  }

  @override
  void dispose() {
    _raysController.dispose();
    _burstController.dispose();
    _iconScaleController.dispose();
    _contentFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: math.min(MediaQuery.of(context).size.width * 0.85, 340),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.15),
                blurRadius: 25,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Beautiful animated icon area
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Rotating sunburst rays
                    AnimatedBuilder(
                      animation: _raysController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(180, 180),
                          painter: GlowingRaysPainter(
                            _raysController.value * 2 * math.pi,
                            const Color(0xFFE8F5E9).withOpacity(0.8),
                          ),
                        );
                      },
                    ),
                    
                    // 2. Leaf burst particle explosion
                    AnimatedBuilder(
                      animation: _burstController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(180, 180),
                          painter: LeafBurstPainter(_particles, _burstController.value),
                        );
                      },
                    ),

                    // 3. Central glowing circle background
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // 4. Elastic checkmark / gift box icon
                    ScaleTransition(
                      scale: _iconScaleAnimation,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32), // primaryGreen
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded, // giftbox icon for rewards
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Animated text contents
              AnimatedBuilder(
                animation: _contentFadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentFadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _contentSlideAnimation.value),
                      child: Column(
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // OK Confirm Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                if (widget.onConfirm != null) {
                                  widget.onConfirm!();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                widget.buttonText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

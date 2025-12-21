import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Water-on-Mirror Overlay Widget - Creates a smooth, reflective, transparent layer
/// Like water on a mirror - clean, smooth, and reflective
class ShinyOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const ShinyOverlay({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ShinyOverlay> createState() => _ShinyOverlayState();
}

class _ShinyOverlayState extends State<ShinyOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Slower, smoother animation for water-like effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        // Original content (the mirror)
        widget.child,
        // Water-like transparent layer with smooth reflection
        // Like water on mirror - smooth, clean, reflective
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _WaterMirrorPainter(_animation.value),
                size: Size.infinite,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Custom painter for water-on-mirror effect
/// Creates smooth, reflective, transparent layers like water on a mirror
class _WaterMirrorPainter extends CustomPainter {
  final double animationValue;

  _WaterMirrorPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Base water layer - very subtle, transparent
    final basePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.7),
        [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.015),
          Colors.white.withValues(alpha: 0.025),
          Colors.white.withValues(alpha: 0.015),
          Colors.transparent,
        ],
        [0.0, 0.3, 0.5, 0.7, 1.0],
      )
      ..blendMode = BlendMode.overlay;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Smooth reflective sweep (like light on water)
    final sweepPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * (0.3 + animationValue * 0.4), 0),
        Offset(size.width * (0.7 + animationValue * 0.4), size.height),
        [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.03),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        [0.0, 0.25, 0.4, 0.5, 0.6, 0.75, 1.0],
      )
      ..blendMode = BlendMode.screen;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sweepPaint);

    // Subtle horizontal reflection layers (like water ripples)
    for (int i = 0; i < 3; i++) {
      final rippleY = size.height * (0.2 + i * 0.3) + 
                     (animationValue * 20 * (i % 2 == 0 ? 1 : -1));
      final ripplePaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, rippleY),
          size.width * 0.8,
          [
            Colors.white.withValues(alpha: 0.02),
            Colors.transparent,
          ],
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.overlay;

      canvas.drawRect(
        Rect.fromLTWH(0, rippleY - 50, size.width, 100),
        ripplePaint,
      );
    }

    // Edge reflections (like light catching water edges)
    final edgePaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.width * 0.15, size.height * 0.15),
        [
          Colors.white.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        [0.0, 1.0],
      )
      ..blendMode = BlendMode.overlay;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.2, size.height * 0.2),
      edgePaint,
    );

    final edgePaint2 = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width, size.height),
        Offset(size.width * 0.85, size.height * 0.85),
        [
          Colors.white.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        [0.0, 1.0],
      )
      ..blendMode = BlendMode.overlay;

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.8,
        size.height * 0.8,
        size.width * 0.2,
        size.height * 0.2,
      ),
      edgePaint2,
    );
  }

  @override
  bool shouldRepaint(_WaterMirrorPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}


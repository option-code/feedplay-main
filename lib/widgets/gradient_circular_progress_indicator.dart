import 'package:flutter/material.dart';
import 'dart:math' as math;

class GradientCircularProgressIndicator extends StatefulWidget {
  final double radius;
  final double strokeWidth;
  final List<Color> colors;
  final Duration duration;

  const GradientCircularProgressIndicator({
    super.key,
    this.radius = 24.0,
    this.strokeWidth = 4.0,
    required this.colors,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<GradientCircularProgressIndicator> createState() =>
      _GradientCircularProgressIndicatorState();
}

class _GradientCircularProgressIndicatorState
    extends State<GradientCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientCircularProgressPainter(
            progress: _controller.value,
            strokeWidth: widget.strokeWidth,
            colors: widget.colors,
          ),
          size: Size.fromRadius(widget.radius),
        );
      },
    );
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: colors,
      stops: List.generate(colors.length, (index) => index / colors.length),
      transform: GradientRotation(math.pi * 2 * progress),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - strokeWidth / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from the top
      math.pi * 2, // Draw a full circle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.colors != colors;
  }
}

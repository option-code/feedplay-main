import 'dart:math';
import 'package:flutter/material.dart';

class TwinkleParticles extends StatefulWidget {
  final int count;
  final Size area;
  final Color color;

  const TwinkleParticles({
    super.key,
    this.count = 16,
    this.area = const Size(220, 140),
    this.color = const Color(0xFF8B5CF6),
  });

  @override
  State<TwinkleParticles> createState() => _TwinkleParticlesState();
}

class _TwinkleParticlesState extends State<TwinkleParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _particles = List.generate(widget.count, (i) {
      // Random position and phase
      final dx = rnd.nextDouble() * widget.area.width;
      final dy = rnd.nextDouble() * widget.area.height;
      final phase = rnd.nextDouble();
      final size = 3.0 + rnd.nextDouble() * 3.0;
      return _Particle(Offset(dx, dy), phase, size);
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.area.width,
      height: widget.area.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(children: [
            for (final p in _particles)
              Positioned(
                left: p.position.dx,
                top: p.position.dy,
                child: Opacity(
                  // Twinkle using a phased sine wave
                  opacity: (0.5 + 0.5 *
                          sin(2 * pi * (_controller.value + p.phase)))
                      .clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.9 + 0.2 *
                        sin(2 * pi * (_controller.value + p.phase)),
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _Particle {
  final Offset position;
  final double phase;
  final double size;
  _Particle(this.position, this.phase, this.size);
}
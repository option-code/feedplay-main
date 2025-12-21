import 'package:flutter/material.dart';

import '../utils/blink_sound.dart' as blink_sound;

class BlinkingStars extends StatefulWidget {
  final int count;
  final double size;
  final Color color;
  final bool playSound;

  const BlinkingStars({
    super.key,
    this.count = 5,
    this.size = 28,
    this.color = const Color(0xFFFBBF24),
    this.playSound = true,
  });

  @override
  State<BlinkingStars> createState() => _BlinkingStarsState();
}

class _BlinkingStarsState extends State<BlinkingStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _opacityAnimations;
  late final List<Animation<double>> _scaleAnimations;
  late final List<double> _intervalEnds;
  final Set<int> _beepedIndices = <int>{};
  double _lastValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )
      ..repeat(reverse: true)
      ..addStatusListener((status) {
        // Reset per-cycle beeps when we return to the start
        if (status == AnimationStatus.dismissed) {
          _beepedIndices.clear();
        }
      })
      ..addListener(() {
        if (!widget.playSound) return;
        final v = _controller.value;
        final forward = v >= _lastValue;
        _lastValue = v;
        // Trigger a tiny beep when each star reaches the end of its interval
        if (forward) {
          for (int i = 0; i < widget.count; i++) {
            if (!_beepedIndices.contains(i) && v >= _intervalEnds[i]) {
              blink_sound.playBlink();
              _beepedIndices.add(i);
            }
          }
        }
      });

    // Create staggered opacity animations so each star blinks at a different time
    _opacityAnimations = List.generate(widget.count, (index) {
      final start = (index / widget.count).clamp(0.0, 1.0);
      final end = ((index + 1) / widget.count).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeInOut),
      );
    });
    _scaleAnimations = List.generate(widget.count, (index) {
      final start = (index / widget.count).clamp(0.0, 1.0);
      final end = ((index + 1) / widget.count).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.9, end: 1.15).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
    _intervalEnds = List.generate(
      widget.count,
      (index) => ((index + 1) / widget.count).clamp(0.0, 1.0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.count, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FadeTransition(
            opacity: _opacityAnimations[index],
            child: ScaleTransition(
              scale: _scaleAnimations[index],
              child: Icon(
                Icons.star,
                color: widget.color,
                size: widget.size,
              ),
            ),
          ),
        );
      }),
    );
  }
}
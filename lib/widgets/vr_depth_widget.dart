import 'package:flutter/material.dart';
import '../main.dart';

/// VR Depth Widget - Makes elements appear to float out of the screen
/// Creates 3D depth effect like VR where elements pop out
class VRDepthWidget extends StatelessWidget {
  final Widget child;
  final double depth;
  final bool enableGlow;

  const VRDepthWidget({
    super.key,
    required this.child,
    this.depth = 1.0,
    this.enableGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Multiple shadow layers for realistic VR depth
        if (enableGlow) ...[
          // Outer glow shadow (farthest)
          Transform.translate(
            offset: Offset(0, 4 * depth),
            child: Container(
              margin: EdgeInsets.all(8 * depth),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4 * depth),
                    blurRadius: 30 * depth,
                    spreadRadius: 8 * depth,
                    offset: Offset(0, 12 * depth),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3 * depth),
                    blurRadius: 50 * depth,
                    spreadRadius: 12 * depth,
                    offset: Offset(0, 20 * depth),
                  ),
                ],
              ),
            ),
          ),
          // Mid shadow layer
          Transform.translate(
            offset: Offset(0, 2 * depth),
            child: Container(
              margin: EdgeInsets.all(4 * depth),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5 * depth),
                    blurRadius: 20 * depth,
                    spreadRadius: 4 * depth,
                    offset: Offset(0, 8 * depth),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Actual content with transform for depth
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..setTranslationRaw(0.0, 0.0, depth * 10) // Z-axis translation using setTranslationRaw
            ..multiply(Matrix4.diagonal3Values(1.0 + (depth * 0.02), 1.0 + (depth * 0.02), 1.0 + (depth * 0.02))), // Uniform scale for depth
          alignment: FractionalOffset.center,
          child: child,
        ),
      ],
    );
  }
}

/// VR Card - Enhanced card with VR depth effect
class VRCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const VRCard({
    super.key,
    required this.child,
    this.elevation = 8.0,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final defaultShadow = [
      // Deep shadow (farthest from screen)
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.6),
        blurRadius: elevation * 4,
        spreadRadius: elevation * 0.5,
        offset: Offset(0, elevation * 1.5),
      ),
      // Mid shadow
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: elevation * 2.5,
        spreadRadius: elevation * 0.3,
        offset: Offset(0, elevation),
      ),
      // Close shadow (near screen)
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: elevation * 1.5,
        spreadRadius: elevation * 0.2,
        offset: Offset(0, elevation * 0.5),
      ),
      // Colored glow for VR effect
      BoxShadow(
        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        blurRadius: elevation * 3,
        spreadRadius: elevation * 0.4,
        offset: Offset(0, elevation * 1.2),
      ),
    ];

    // Get appColors from theme extension
    final appColors = Theme.of(context).extension<AppColors>();
    
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? (appColors?.cardBackground ?? const Color(0xFF1A1F2E)).withValues(alpha: 0.9),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: child,
    );
  }
}


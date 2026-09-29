import 'package:flutter/material.dart';

/// A subtle white crosshatch pattern painter.
/// Draws thin 45° and -45° diagonal lines with very low opacity
/// to add visual texture without competing with content.
class CrossHatchPatternPainter extends CustomPainter {
  final double lineSpacing;
  final double strokeWidth;
  final double opacity;

  CrossHatchPatternPainter({
    this.lineSpacing = 18.0,
    this.strokeWidth = 0.5,
    this.opacity = 0.04,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Calculate how many lines we need to cover the entire canvas
    // For diagonal lines, we need to extend beyond the canvas bounds
    final double maxDimension = size.width + size.height;

    // Draw lines at 45° (top-left to bottom-right)
    for (double i = -maxDimension; i < maxDimension; i += lineSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Draw lines at -45° (top-right to bottom-left)
    for (double i = -maxDimension; i < maxDimension; i += lineSpacing) {
      canvas.drawLine(
        Offset(i + size.height, 0),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CrossHatchPatternPainter oldDelegate) {
    return oldDelegate.lineSpacing != lineSpacing ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.opacity != opacity;
  }
}

/// A widget that paints a subtle crosshatch pattern behind its child.
/// 
/// Usage:
/// ```dart
/// CrossHatchPatternOverlay(
///   child: YourScreenContent(),
/// )
/// ```
class CrossHatchPatternOverlay extends StatelessWidget {
  final Widget child;
  final double lineSpacing;
  final double strokeWidth;
  final double opacity;

  const CrossHatchPatternOverlay({
    super.key,
    required this.child,
    this.lineSpacing = 18.0,
    this.strokeWidth = 0.5,
    this.opacity = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The pattern is painted *behind* the content, in its own layer, so
        // content repaints (timers, scrolling, hovers) never repaint the
        // hundreds of diagonal lines — and vice versa.
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                isComplex: false,
                willChange: false,
                painter: CrossHatchPatternPainter(
                  lineSpacing: lineSpacing,
                  strokeWidth: strokeWidth,
                  opacity: opacity,
                ),
              ),
            ),
          ),
        ),
        // The actual screen content
        child,
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ambient_provider.dart';
import '../../core/theme/app_colors.dart';

class AppBorderWrapper extends ConsumerWidget {
  final Widget child;

  const AppBorderWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambientColor = ref.watch(ambientColorProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The main content
          Padding(
            padding: const EdgeInsets.all(4.0), // Give space for the border
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: child,
            ),
          ),
          
          // The glowing border
          IgnorePointer(
            child: CustomPaint(
              painter: _GradientBorderPainter(
                gradient: AppColors.getAdaptiveGradient(ambientColor),
                strokeWidth: 3.0,
                glowColor: ambientColor,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final LinearGradient gradient;
  final double strokeWidth;
  final Color glowColor;

  _GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Multi-stop gradient for the border (including Green, Yellow/Jauge, Red)
    const borderGradient = LinearGradient(
      colors: [
        Color(0xFFFF2E93), // Fuchsia
        Color(0xFF9D44FF), // Purple
        Color(0xFF007BFF), // Blue
        Color(0xFF00D2FF), // Cyan
        Color(0xFF00FF00), // Green (Vert)
        Color(0xFFFFFF00), // Yellow (Jauge)
        Color(0xFFFF0000), // Red (Rouge)
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = borderGradient.createShader(rect);

    // Draw the glow
    final glowPaint = Paint()
      ..strokeWidth = strokeWidth + 1
      ..style = PaintingStyle.stroke
      ..color = glowColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(strokeWidth / 2), const Radius.circular(30)),
      glowPaint,
    );

    // Draw the gradient border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(strokeWidth / 2), const Radius.circular(30)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient || oldDelegate.glowColor != glowColor;
  }
}

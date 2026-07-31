import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EyeLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const EyeLogo({
    super.key, 
    this.size = 120,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showGlow ? BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPurple.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ) : null,
      child: CustomPaint(
        painter: _EyePainter(),
      ),
    );
  }
}

class _EyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height * 0.7;

    // 1. Draw the outer eye shape (eyelids)
    final eyePath = Path();
    eyePath.moveTo(0, center.dy);
    eyePath.quadraticBezierTo(width / 2, center.dy - height / 1.5, width, center.dy);
    eyePath.quadraticBezierTo(width / 2, center.dy + height / 1.5, 0, center.dy);
    eyePath.close();

    const borderGradient = LinearGradient(
      colors: [
        Color(0xFFFF9F00), // Orange
        Color(0xFFFF2E93), // Fuchsia
        Color(0xFF9D44FF), // Purple
        Color(0xFF00D2FF), // Cyan
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final borderPaint = Paint()
      ..shader = borderGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(eyePath, borderPaint);

    // 2. Draw the white part (sclera) - clipped
    canvas.save();
    canvas.clipPath(eyePath);
    
    final scleraPaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawPath(eyePath, scleraPaint);

    // 3. Draw the Iris
    final irisRadius = size.width * 0.28;
    const irisGradient = RadialGradient(
      colors: [
        Color(0xFF00D2FF), // Cyan center
        Color(0xFF007BFF), // Blue
        Color(0xFF9D44FF), // Purple
        Color(0xFFFF2E93), // Fuchsia edge
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    );

    final irisPaint = Paint()..shader = irisGradient.createShader(Rect.fromCircle(center: center, radius: irisRadius));
    canvas.drawCircle(center, irisRadius, irisPaint);

    // 4. Draw Iris Texture (lines)
    final texturePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    for (var i = 0; i < 30; i++) {
      final angle = (i * 12) * math.pi / 180;
      final start = Offset(
        center.dx + math.cos(angle) * (irisRadius * 0.4),
        center.dy + math.sin(angle) * (irisRadius * 0.4),
      );
      final end = Offset(
        center.dx + math.cos(angle) * irisRadius,
        center.dy + math.sin(angle) * irisRadius,
      );
      canvas.drawLine(start, end, texturePaint);
    }

    // 5. Draw Pupil
    final pupilRadius = irisRadius * 0.45;
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(center, pupilRadius, pupilPaint);

    // 6. Draw Reflections
    final reflectionPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    // Main reflection
    canvas.drawCircle(
      Offset(center.dx - pupilRadius * 0.4, center.dy - pupilRadius * 0.4),
      pupilRadius * 0.25,
      reflectionPaint,
    );
    // Smaller reflection
    canvas.drawCircle(
      Offset(center.dx + pupilRadius * 0.5, center.dy + pupilRadius * 0.2),
      pupilRadius * 0.1,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

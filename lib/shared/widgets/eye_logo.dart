import 'package:flutter/material.dart';

class EyeLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const EyeLogo({
    super.key, 
    this.size = 100,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _CinematicEyePainter(),
        ),
      ),
    );
  }
}

class _CinematicEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Blue Button Background (Radial Gradient)
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF00D2FF), // Bright Cyan center
          Color(0xFF007BFF), // Deep Blue middle
          Color(0xFF002F6C), // Dark Navy edges
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius * 0.9, bgPaint);

    // 2. Glowing Outer Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    canvas.drawCircle(center, radius * 0.9, ringPaint);
    
    // Outer Glow Shadow
    final glowPaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius * 0.9, glowPaint);

    // 3. White Eye Almond Shape
    final eyePath = Path();
    final eyeWidth = size.width * 0.65;
    final eyeHeight = size.height * 0.35;
    
    eyePath.moveTo(center.dx - eyeWidth / 2, center.dy);
    eyePath.quadraticBezierTo(center.dx, center.dy - eyeHeight, center.dx + eyeWidth / 2, center.dy);
    eyePath.quadraticBezierTo(center.dx, center.dy + eyeHeight, center.dx - eyeWidth / 2, center.dy);
    eyePath.close();

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(eyePath, whitePaint);

    // 4. "Skip Next" Icon in center
    final iconSize = size.width * 0.18;
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Triangle (Play)
    final trianglePath = Path();
    trianglePath.moveTo(center.dx - iconSize * 0.4, center.dy - iconSize * 0.5);
    trianglePath.lineTo(center.dx + iconSize * 0.2, center.dy);
    trianglePath.lineTo(center.dx - iconSize * 0.4, center.dy + iconSize * 0.5);
    trianglePath.close();
    canvas.drawPath(trianglePath, iconPaint);

    // Vertical Bar (Next)
    final barRect = Rect.fromCenter(
      center: Offset(center.dx + iconSize * 0.45, center.dy),
      width: iconSize * 0.15,
      height: iconSize * 0.9,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(2)), iconPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

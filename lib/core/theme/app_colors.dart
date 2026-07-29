import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF05050D);
  static const Color surface = Color(0xFF12131C);
  static const Color outline = Color(0xFF232538);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A5BA);
  
  static const Color neonFuchsia = Color(0xFFFF2E93);
  static const Color neonPurple = Color(0xFF9D44FF);
  static const Color neonBlue = Color(0xFF007BFF);
  static const Color neonCyan = Color(0xFF00D2FF);

  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonFuchsia, neonPurple, neonBlue, neonCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient verticalNeonGradient = LinearGradient(
    colors: [neonFuchsia, neonCyan],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient getAdaptiveGradient(Color ambientColor) {
    return LinearGradient(
      colors: [neonFuchsia, neonPurple, ambientColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

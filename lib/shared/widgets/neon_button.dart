import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final bool isSecondary;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: isSecondary ? null : AppColors.neonGradient,
        color: isSecondary ? AppColors.surface : null,
        borderRadius: BorderRadius.circular(30), // Rounded corners as per image
        boxShadow: isSecondary ? [] : [
          BoxShadow(
            color: AppColors.neonFuchsia.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

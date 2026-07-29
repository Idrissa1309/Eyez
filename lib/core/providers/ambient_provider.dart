import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

final ambientColorProvider = StateProvider<Color>((ref) {
  return AppColors.neonCyan; // Default color
});

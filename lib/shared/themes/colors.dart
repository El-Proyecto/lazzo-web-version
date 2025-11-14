import 'package:flutter/material.dart';

// uso: Theme.of(ctx).colorScheme.primary / BrandColors.bg2
class BrandColors {
  // Background colors
  static const bg1 = Color(0xFF121212),
      bg2 = Color(0xFF1F1F1F),
      bg3 = Color(0xFF2B2B2B);

  // Text colors
  static const text1 = Color(0xFFF2F2F2),
      text2 = Color(0xFFA6A6A6),
      border = Color(0xFF404040);

  // Event mode colors
  static const planning = Color(0xFF169C3E),
      living = Color(0xFF8A38F5),
      recap = Color(0xFFFF751A);

  // Status colors
  static const cantVote = Color(0xFFFF3B30);
  static const warning =
      Color(0xFFFFB800); // Yellow warning

  // Notification banner colors (semantic aliases)
  static const notificationSuccess = planning; // Green for success
  static const notificationError = cantVote; // Red for errors
  static const notificationWarning = warning; // Yellow for warnings
  static const notificationInfo = bg2; // Neutral info
  static const notificationNeutral = bg2; // Neutral notifications
}

final colorSchemeDark = const ColorScheme.dark(
  primary: BrandColors.planning,
  secondary: BrandColors.planning,
  tertiary: BrandColors.recap,
  surface: BrandColors.bg1,
  onSurface: BrandColors.text1,
);

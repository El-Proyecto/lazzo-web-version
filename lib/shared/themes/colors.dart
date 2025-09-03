import 'package:flutter/material.dart';
// uso: Theme.of(ctx).colorScheme.primary / BrandColors.bg2
class BrandColors{
  static const bg1=Color(0xFF121212), bg2=Color(0xFF1F1F1F), bg3=Color(0xFF2B2B2B);
  static const text1=Color(0xFFF2F2F2), text2=Color(0xFFA6A6A6), border=Color(0xFF404040);
  static const planning=Color(0xFF169C3E), living=Color(0xFF8A38F5), recap=Color(0xFFFF751A);
}
final colorSchemeDark=ColorScheme.dark(
  primary:BrandColors.living, secondary:BrandColors.planning, tertiary:BrandColors.recap,
  surface:BrandColors.bg1, onSurface:BrandColors.text1);

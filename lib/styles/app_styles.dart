import 'package:flutter/material.dart';

class AppColors {
  static const Color background1 = Color(0xFF121212);
  static const Color background2 = Color(0xFF1F1F1F);
  static const Color background3 = Color(0xFF2B2B2B);

  static const Color text1 = Color(0xFFF2F2F2);
  static const Color text2 = Color(0xFFA6A6A6);

  static const Color border1 = Color(0xFF404040);

  static const Color green = Color(0xFF32D445);
  static const Color purple = Color(0xFF8A38F5);
  static const Color orange = Color(0xFFFF751A);

  // Adiciona mais cores conforme precisares
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    color: AppColors.text1,
    fontSize: 64,
    fontStyle: FontStyle.italic,
    fontFamily: 'Public Sans',
    fontWeight: FontWeight.w700,
    height: 0.44,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppColors.text2,
    fontSize: 11,
    fontStyle: FontStyle.italic,
    fontFamily: 'Public Sans',
    fontWeight: FontWeight.w700,
    height: 2.55,
    letterSpacing: 2,
  );

  static const TextStyle centerText = TextStyle(
    color: AppColors.text1,
    fontSize: 32,
    fontStyle: FontStyle.italic,
    fontFamily: 'Public Sans',
    fontWeight: FontWeight.w700,
    height: 0.88,
  );
  // Adiciona mais estilos conforme precisares

  static const TextStyle enterCodeTitle = TextStyle(
    color: AppColors.text1,
    fontSize: 32,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  static const TextStyle subtitleMuted = TextStyle(
    color: AppColors.text2,
    fontSize: 22,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.27,
  );

  static const TextStyle subtitleStrong = TextStyle(
    color: AppColors.text1,
    fontSize: 22,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.27,
  );
}

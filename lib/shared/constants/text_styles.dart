import 'package:flutter/material.dart';

// uso: AppText.dropdownTitle.copyWith(color:Theme.of(ctx).colorScheme.onBackground)
class AppText {
  static const _f = 'Roboto';
  static TextStyle get dropdownTitle => const TextStyle(
    fontFamily: _f,
    fontWeight: FontWeight.w400,
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: 0,
  );
  static TextStyle get labelLarge => const TextStyle(
    fontFamily: _f,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.5,
  );
  static TextStyle get labelLargeEmph => const TextStyle(
    fontFamily: _f,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.5,
  );
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: _f,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.5,
  );
  static TextStyle get titleMediumEmph => const TextStyle(
    fontFamily: _f,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.15,
  );
  static TextStyle get headlineMedium => const TextStyle(
    fontFamily: _f,
    fontWeight: FontWeight.w500,
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: 0,
  );
  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: _f,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.25,
  );
  static TextStyle get bodyMediumEmph => const TextStyle(
    fontFamily: _f,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.25,
  );
}

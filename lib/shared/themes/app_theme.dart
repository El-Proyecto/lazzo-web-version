import 'package:flutter/material.dart';
import 'colors.dart';

// uso: theme: buildDarkTheme()
ThemeData buildDarkTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: colorSchemeDark,
  scaffoldBackgroundColor: BrandColors.bg1,
  dividerColor: BrandColors.border,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);

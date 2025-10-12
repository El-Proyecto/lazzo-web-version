// lib/app.dart
import 'package:flutter/material.dart';
import 'package:app/routes/app_router.dart';
import 'package:app/shared/themes/app_theme.dart';

class LazzoApp extends StatelessWidget {
  const LazzoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      initialRoute: AppRouter.event, // Start at event page to test navigation
      routes: AppRouter.routes,
      // onGenerateRoute: ... (se precisares mais tarde)
    );
  }
}

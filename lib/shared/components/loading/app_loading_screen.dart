import 'package:flutter/material.dart';
import 'package:lazzo/shared/themes/colors.dart';

/// Loading screen exibida durante cold start da app
/// Mostra apenas o ícone da app com background preto
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      body: Center(
        child: Image.asset(
          'assets/app_icon_background.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}

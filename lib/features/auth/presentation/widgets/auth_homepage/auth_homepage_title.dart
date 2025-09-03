import 'package:flutter/material.dart';
import '/../../../styles/app_styles.dart';

class AuthHomepageTitle extends StatelessWidget {
  const AuthHomepageTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 343,
      height: 60,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 343,
              height: 50,
              child: Text(
                'GATHERIN ',
                style: AppTextStyles.title, // Usa o style global
              ),
            ),
          ),
          Positioned(
            left: 90,
            top: 40,
            child: SizedBox(
              width: 162,
              height: 20,
              child: Text(
                'Plan better, live better',
                style: AppTextStyles.subtitle, // Usa o style global
              ),
            ),
          ),
        ],
      ),
    );
  }
}
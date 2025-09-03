import 'package:flutter/material.dart';

import '../widgets/auth_homepage/swipe_to_start.dart';
import '../widgets/auth_homepage/auth_homepage_center_text.dart';
import '../widgets/auth_homepage/auth_homepage_title.dart';
import '../../../../styles/app_styles.dart'; // ajusta se o teu path for diferente

class AuthHomepage extends StatelessWidget {
  const AuthHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background1,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Título no topo
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: const AuthHomepageTitle(),
              ),
            ),

            // Texto central
            const Align(
              alignment: Alignment.center,
              child: AuthHomepageCenterText(),
            ),

            // Swipe e CTA em baixo
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),

                  // 👉 Swipe: continua fluxo de REGISTO
                  SwipeToStart(
                    onStart: () {
                      Navigator.of(context).pushNamed(
                        '/phone',
                        arguments: {'flow': 'register'},
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppColors.text2,
                          fontSize: 13,
                        ),
                      ),

                      // 👉 Sign in: vai para a página de LOGIN
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/login',
                            arguments: {'flow': 'login'},
                          );
                        },
                        child: Text(
                          'Sign in',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

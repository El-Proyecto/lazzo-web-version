import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../shared/themes/colors.dart';
import '../../../../../shared/constants/text_styles.dart';

class WelcomeAccountCreated extends StatelessWidget {
  const WelcomeAccountCreated({
    super.key,
    this.icon = FontAwesomeIcons.circleCheck,
    this.iconColor = BrandColors.planning,
    this.iconSize = 192,
    this.title = 'Welcome to Gathering!',
    this.subtitle = 'Your Account Has Been Created!',
    this.body =
        "You're all set to start creating amazing memories with your friends and family.",
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // “imagem” como ícone
          SizedBox(
            width: 192,
            height: 192,
            child: Center(
              child: Icon(
                icon,
                size: iconSize, // 192 cabe bem na largura; ajusta se precisares
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Texts(title: title, subtitle: subtitle, body: body),
        ],
      ),
    );
  }
}

class _Texts extends StatelessWidget {
  const _Texts({
    required this.title,
    required this.subtitle,
    required this.body,
  });
  final String title, subtitle, body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.headlineMedium.copyWith(color: BrandColors.text1),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppText.subtitleMuted.copyWith(color: BrandColors.text2),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 362,
          child: Text(
            "You're all set to start creating amazing memories with your friends and family.",
            textAlign: TextAlign.center,
            style: AppText.titleMediumEmph.copyWith(color: BrandColors.text2),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FeatureCardsList extends StatelessWidget {
  const FeatureCardsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          FeatureCard.icon(
            title: 'Create Events',
            subtitle: 'Plan and organize memorable gatherings',
            iconData: FontAwesomeIcons.calendarDays,
            iconPadding: EdgeInsets.all(8),
          ),
          SizedBox(height: 16),
          FeatureCard.icon(
            title: 'Share Moments',
            subtitle: 'Capture and share photos from your events\n\n',
            iconData: FontAwesomeIcons.camera,
            iconPadding: EdgeInsets.all(6),
          ),
          SizedBox(height: 16),
          FeatureCard.icon(
            title: 'Connect',
            subtitle: 'Stay connected with your social circle\n\n',
            iconData: FontAwesomeIcons.userGroup,
            iconPadding: EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            fixedWidth: 370, // no Figma este card tinha width 370
          ),

          // Exemplo se quiseres a versão por imagem:
          // FeatureCard.image(
          //   title: 'Discover',
          //   subtitle: 'Find new friends and events',
          //   imageUrl: 'https://placehold.co/30x30',
          // ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  // --- Ícone FontAwesome ---
  const FeatureCard.icon({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconData,
    this.iconColor = const Color(0xFFF2F2F2),
    this.iconPadding = const EdgeInsets.all(8),
    this.fixedWidth,
  })  : imageUrl = null;

  // --- Imagem por URL ---
  const FeatureCard.image({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.iconPadding = const EdgeInsets.all(8),
    this.fixedWidth,
  })  : iconData = null,
        iconColor = null;

  final String title;
  final String subtitle;

  // Fonte A — Ícone
  final IconData? iconData;
  final Color? iconColor;

  // Fonte B — Imagem
  final String? imageUrl;

  // Layout
  final EdgeInsets iconPadding;
  final double? fixedWidth;

  @override
  Widget build(BuildContext context) {
    final Widget leading = iconData != null
        ? FaIcon(iconData!, size: 30, color: iconColor)
        : Image.network(imageUrl!, width: 30, height: 30, fit: BoxFit.cover);

    return Container(
      width: fixedWidth ?? double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: const Color(0xFF1E1E1E), // Background-2
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F282828),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // badge 50x50
          Container(
            width: 50,
            height: 50,
            padding: iconPadding,
            decoration: ShapeDecoration(
              color: const Color(0xFF2B2B2B), // Background-3
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x3F282828),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(child: leading),
          ),

          const SizedBox(width: 16),

          // textos dinâmicos
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF2F2F2), // Text-1
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    height: 1.43,
                    letterSpacing: 0.10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFA5A5A5), // Text-2
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

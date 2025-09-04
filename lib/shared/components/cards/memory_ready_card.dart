import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

class MemoryReadyCard extends StatelessWidget {
  final String emoji;              // ex.: '🐟'
  final String title;              // ex.: 'Pescaria com o Zé'
  final String message;            // default abaixo
  final VoidCallback? onTap;

  const MemoryReadyCard({
    super.key,
    required this.emoji,
    required this.title,
    this.message = 'Your Event Memory is Ready!',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screenH)
          .copyWith(top: Gaps.between), // margem de ecrã + gap entre secções
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da secção
          Text(
            'Last Memory',
            style: AppText.titleMediumEmph.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: Gaps.titleField), // 8

          // Card
          InkWell(
            borderRadius: BorderRadius.circular(Radii.md),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 94),
              padding: const EdgeInsets.symmetric(
                horizontal: Pads.ctlH, // 16
                vertical: Pads.ctlV,   // 12
              ),
              decoration: BoxDecoration(
                color: BrandColors.bg2,
                borderRadius: BorderRadius.circular(Radii.md), // 16
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Coluna de textos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji + título
                        Row(
                          children: [
                            Text(emoji,
                                style:
                                    const TextStyle(fontSize: 28, height: 1)),
                            const SizedBox(width: Gaps.inCardText), // 4
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.titleMediumEmph
                                    .copyWith(color: scheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Gaps.sameType), // 8
                        // Mensagem
                        Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyMedium
                              .copyWith(color: BrandColors.text2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gaps.sameType), // 8
                  Icon(Icons.chevron_right_rounded, color: BrandColors.text2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
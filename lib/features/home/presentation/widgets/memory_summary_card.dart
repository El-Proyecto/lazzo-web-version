import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class MemorySummaryCard extends StatelessWidget {
  final String emoji; // ex.: '🐟'
  final String title; // ex.: 'Pescaria com o Zé'
  final String message; // default abaixo
  final VoidCallback? onTap;

  const MemorySummaryCard({
    super.key,
    required this.emoji,
    required this.title,
    this.message = 'Your Event Memory is Ready!',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final radius = BorderRadius.circular(Radii.md);

    return Material(
      color: BrandColors.bg2,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.ctlH,
            vertical: Pads.ctlV,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 28, height: 1),
                        ),
                        const SizedBox(width: Gaps.xs),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.titleMediumEmph.copyWith(
                              color: t.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gaps.xs),
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gaps.xs),
              const Icon(Icons.chevron_right_rounded, color: BrandColors.text2),
            ],
          ),
        ),
      ),
    );
  }
}

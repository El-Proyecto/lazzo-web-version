import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Feature-specific widget for sharing options
class ShareOptionsSection extends StatelessWidget {
  final VoidCallback? onInstagramPressed;
  final VoidCallback? onWhatsAppPressed;
  final VoidCallback? onSavePressed;
  final VoidCallback? onMorePressed;

  const ShareOptionsSection({
    super.key,
    this.onInstagramPressed,
    this.onWhatsAppPressed,
    this.onSavePressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Share to',
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
          const SizedBox(height: Gaps.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShareOption(
                icon: Icons.camera_alt,
                label: 'Instagram Story',
                onPressed: onInstagramPressed,
              ),
              _ShareOption(
                icon: Icons.chat,
                label: 'WhatsApp',
                onPressed: onWhatsAppPressed,
              ),
              _ShareOption(
                icon: Icons.download,
                label: 'Save',
                onPressed: onSavePressed,
              ),
              _ShareOption(
                icon: Icons.ios_share,
                label: 'More',
                onPressed: onMorePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ShareOption({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: Gaps.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.smAlt),
              ),
              child: Icon(
                icon,
                color: BrandColors.text1,
                size: IconSizes.md,
              ),
            ),
            const SizedBox(height: Gaps.xxs),
            Text(
              label,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

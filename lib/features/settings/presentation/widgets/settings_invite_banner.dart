import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class SettingsInviteBanner extends StatelessWidget {
  final int invitesCount;
  final VoidCallback onShare;

  const SettingsInviteBanner({
    super.key,
    required this.invitesCount,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Pads.ctlV),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: BrandColors.planning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite your friend group',
                  style: AppText.bodyLarge.copyWith(
                    color: BrandColors.text1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have $invitesCount early access invites',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: Gaps.md),

          // Share Button
          GestureDetector(
            onTap: onShare,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Pads.ctlH,
                vertical: Pads.ctlV / 2,
              ),
              decoration: BoxDecoration(
                color: BrandColors.planning,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Text(
                'Share',
                style: AppText.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

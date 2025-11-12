import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/buttons/green_button.dart';

/// Empty state card shown when user has no groups yet
/// Feature-specific widget for Home page
class NoGroupsYetCard extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const NoGroupsYetCard({
    super.key,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Start your first group',
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
          const SizedBox(height: Gaps.xs),

          // Subtitle
          Text(
            'Events live inside groups. Create one to plan together.',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
          const SizedBox(height: Gaps.md),

          // CTA Button
          GreenButton(
            text: 'Create group',
            onPressed: onCreateGroup,
          ),
          const SizedBox(height: Gaps.xs),

          // Helper text
          Text(
            'You can add members later.',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontSize:
                  12,
            ),
          ),
        ],
      ),
    );
  }
}

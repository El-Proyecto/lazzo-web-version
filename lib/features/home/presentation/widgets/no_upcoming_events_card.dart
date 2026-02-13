import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/buttons/green_button.dart';

/// Empty state card shown when user has no upcoming events
/// Feature-specific widget for Home page
/// LAZZO 2.0: Simplified — no group chip selection, direct event creation
class NoUpcomingEventsCard extends StatelessWidget {
  final VoidCallback onCreateEvent;
  final VoidCallback? onDismiss;

  const NoUpcomingEventsCard({
    super.key,
    required this.onCreateEvent,
    this.onDismiss,
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
          // Title row with close button
          Row(
            children: [
              Expanded(
                child: Text(
                  'No plans coming up',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    padding: const EdgeInsets.all(Gaps.xxs),
                    child: const Icon(
                      Icons.close,
                      size: IconSizes.smAlt,
                      color: BrandColors.text2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gaps.xs),

          // Subtitle
          Text(
            'Create an event and invite your friends.',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
          const SizedBox(height: Gaps.md),

          // CTA Button
          GreenButton(
            text: 'Create event',
            onPressed: onCreateEvent,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

class PendingEventCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String dateTime;
  final String location;
  final Widget? voteButton; // Custom vote button for different states

  const PendingEventCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.dateTime,
    required this.location,
    this.voteButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH,
        vertical: Pads.ctlV,
      ),
      decoration: ShapeDecoration(
        color: BrandColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      child: Row(
        children: [
          // Event info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with emoji
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: Gaps.xs),
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.titleMediumEmph.copyWith(
                          color: BrandColors.text1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gaps.xxs),
                // Date and location
                Text(
                  '$dateTime • $location',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Gaps.xs),
          // Vote button section
          if (voteButton != null) voteButton!,
        ],
      ),
    );
  }
}

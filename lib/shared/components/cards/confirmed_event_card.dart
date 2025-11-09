import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Simple confirmed event card without voting functionality
/// Shows event info with a confirmed status badge
class ConfirmedEventCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String dateTime;
  final String location;
  final VoidCallback? onTap;

  const ConfirmedEventCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.dateTime,
    required this.location,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with emoji and confirmed badge
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
                const SizedBox(width: Gaps.xs),
                // Confirmed badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.sectionV,
                    vertical: Pads.ctlVXss,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColors.planning,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(
                    'Confirmed',
                    style: AppText.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
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
    );
  }
}

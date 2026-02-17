import 'package:flutter/material.dart';
import '../../domain/entities/action.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Legacy activity card — now delegates to the same ActionEntity as InboxActionCard.
/// Kept for backward compatibility; prefer InboxActionCard for new code.
class InboxActivityCard extends StatelessWidget {
  final ActionEntity activity;
  final VoidCallback? onTap;

  const InboxActivityCard({super.key, required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Gaps.md),
        decoration: ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Row(
          children: [
            // Event emoji
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  activity.eventEmoji ?? activity.typeEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                  const SizedBox(height: Gaps.xs / 4),
                  Text(
                    activity.eventName ?? '',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gaps.sm),
            _buildTimeLeftIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLeftIndicator() {
    final text = activity.deadlineText;
    if (text == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, color: _getTimeLeftColor(), size: IconSizes.sm),
        const SizedBox(width: Gaps.xs / 2),
        Text(
          text,
          style: AppText.labelLarge.copyWith(color: _getTimeLeftColor()),
        ),
      ],
    );
  }

  Color _getTimeLeftColor() {
    if (activity.isOverdue) {
      return BrandColors.cantVote;
    }

    final timeLeft = activity.timeLeft;
    if (timeLeft == null) return BrandColors.text2;

    if (timeLeft.inHours <= 2) {
      return BrandColors.cantVote;
    } else if (timeLeft.inHours <= 24) {
      return BrandColors.recap;
    } else {
      return BrandColors.planning;
    }
  }
}

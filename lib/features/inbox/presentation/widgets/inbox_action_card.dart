import 'package:flutter/material.dart';
import '../../domain/entities/action.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class InboxActionCard extends StatelessWidget {
  final ActionEntity action;
  final VoidCallback? onTap;

  const InboxActionCard({super.key, required this.action, this.onTap});

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
                  action.eventEmoji ?? action.typeEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Gaps.xs / 4),
                  Text(
                    action.eventName ?? '',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gaps.sm),
            // Time left
            _buildTimeLeftBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLeftBadge() {
    final text = action.deadlineText;
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
    if (action.isOverdue) {
      return BrandColors.cantVote;
    }

    final timeLeft = action.timeLeft;
    if (timeLeft == null) return BrandColors.text2;

    if (timeLeft.inHours <= 2) {
      return BrandColors.cantVote; // Red
    } else if (timeLeft.inHours <= 24) {
      return BrandColors.recap; // Orange
    } else {
      return BrandColors.planning; // Green
    }
  }
}

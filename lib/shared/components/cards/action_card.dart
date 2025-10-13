import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

enum ActionCardPriority { low, medium, high, urgent }

enum ActionCardStatus { pending, completed, overdue, cancelled }

class ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final ActionCardPriority priority;
  final ActionCardStatus status;
  final Duration? timeLeft;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final String? actionText;
  final IconData? actionIcon;

  const ActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.timeLeft,
    this.onTap,
    this.onActionTap,
    this.actionText,
    this.actionIcon,
  });

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
            side: BorderSide(color: _getBorderColor(), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppText.titleMediumEmph.copyWith(
                                color: _getTitleColor(),
                              ),
                            ),
                          ),
                          _buildPriorityIndicator(),
                        ],
                      ),
                      const SizedBox(height: Gaps.xs),
                      Text(
                        description,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onActionTap != null) ...[
                  const SizedBox(width: Gaps.md),
                  _buildActionButton(),
                ],
              ],
            ),
            if (timeLeft != null) ...[
              const SizedBox(height: Gaps.md),
              _buildTimeLeft(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: ShapeDecoration(
        color: _getPriorityColor(),
        shape: const CircleBorder(),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: onActionTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: ShapeDecoration(
          color: _getActionButtonColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actionIcon != null) ...[
              Icon(actionIcon, size: IconSizes.sm, color: Colors.white),
              if (actionText != null) const SizedBox(width: Gaps.xs),
            ],
            if (actionText != null)
              Text(
                actionText!,
                style: AppText.labelLarge.copyWith(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLeft() {
    final isOverdue = status == ActionCardStatus.overdue;
    final timeText = _formatTimeLeft();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.sm,
        vertical: Gaps.xs,
      ),
      decoration: ShapeDecoration(
        color: isOverdue
            ? BrandColors.cantVote.withValues(alpha: 0.1)
            : BrandColors.bg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_outlined : Icons.schedule_outlined,
            size: IconSizes.sm,
            color: isOverdue ? BrandColors.cantVote : BrandColors.text2,
          ),
          const SizedBox(width: Gaps.xs),
          Text(
            timeText,
            style: AppText.labelLarge.copyWith(
              color: isOverdue ? BrandColors.cantVote : BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    switch (status) {
      case ActionCardStatus.overdue:
        return BrandColors.cantVote;
      case ActionCardStatus.completed:
        return BrandColors.planning;
      default:
        return BrandColors.bg3;
    }
  }

  Color _getTitleColor() {
    switch (status) {
      case ActionCardStatus.completed:
        return BrandColors.text2;
      default:
        return BrandColors.text1;
    }
  }

  Color _getPriorityColor() {
    switch (priority) {
      case ActionCardPriority.urgent:
        return BrandColors.cantVote;
      case ActionCardPriority.high:
        return BrandColors.recap;
      case ActionCardPriority.medium:
        return BrandColors.planning;
      case ActionCardPriority.low:
        return BrandColors.text2;
    }
  }

  Color _getActionButtonColor() {
    switch (status) {
      case ActionCardStatus.overdue:
        return BrandColors.cantVote;
      default:
        return BrandColors.planning;
    }
  }

  String _formatTimeLeft() {
    if (timeLeft == null) return '';

    if (status == ActionCardStatus.overdue) {
      return 'Overdue';
    }

    final hours = timeLeft!.inHours;
    final days = timeLeft!.inDays;

    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'} left';
    } else if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} left';
    } else {
      final minutes = timeLeft!.inMinutes;
      return '$minutes min${minutes == 1 ? '' : 's'} left';
    }
  }
}

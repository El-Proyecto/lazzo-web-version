import 'package:flutter/material.dart';
import '../../domain/entities/activity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class InboxActivityCard extends StatelessWidget {
  final ActivityEntity activity;
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
        child: Column(
          children: [
            _buildTopSection(),
            const SizedBox(height: Gaps.md),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Row(
      children: [
        _buildEventIcon(),
        const SizedBox(width: Gaps.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getActionTitle(),
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
              const SizedBox(height: Gaps.xs / 2),
              Text(
                _getEventName(),
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
            ],
          ),
        ),
        const SizedBox(width: Gaps.md),
        const Icon(
          Icons.chevron_right,
          color: BrandColors.text2,
          size: IconSizes.md,
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Row(
      children: [
        _buildGroupIcon(),
        const SizedBox(width: Gaps.sm),
        Text(
          _getGroupName(),
          style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
        ),
        const Spacer(),
        _buildTimeLeftIndicator(),
      ],
    );
  }

  Widget _buildEventIcon() {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Text(_getEventEmoji(), style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildGroupIcon() {
    return const Icon(
      Icons.group,
      color: BrandColors.text2,
      size: IconSizes.sm,
    );
  }

  Widget _buildTimeLeftIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, color: _getTimeLeftColor(), size: IconSizes.sm),
        const SizedBox(width: Gaps.xs),
        Text(
          _formatTimeLeft(),
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
      ],
    );
  }

  String _getActionTitle() {
    switch (activity.type) {
      case ActivityType.vote:
        return 'Vote on a local';
      case ActivityType.rsvp:
        return 'Confirm attendance';
      case ActivityType.payment:
        return 'Pay for tickets';
      case ActivityType.taskAssignment:
        return 'Bring decorations';
      case ActivityType.eventPreparation:
        return 'Import photos';
    }
  }

  String _getEventName() {
    // In a real app, this would come from the activity entity
    // For now, we'll extract from the description or use a placeholder
    return activity.description.split(' ').take(3).join(' ');
  }

  String _getGroupName() {
    // In a real app, this would come from the activity entity
    // For now, we'll use a placeholder
    return 'Summer Trip';
  }

  String _getEventEmoji() {
    switch (activity.type) {
      case ActivityType.vote:
        return '🗳️';
      case ActivityType.rsvp:
        return '📅';
      case ActivityType.payment:
        return '💳';
      case ActivityType.taskAssignment:
        return '📋';
      case ActivityType.eventPreparation:
        return '📸';
    }
  }

  Color _getTimeLeftColor() {
    if (activity.isOverdue) {
      return BrandColors.cantVote; // Red
    }

    final timeLeft = activity.timeLeft;
    if (timeLeft == null) return BrandColors.text2;

    if (timeLeft.inHours <= 2) {
      return BrandColors.cantVote; // Red - urgent
    } else if (timeLeft.inHours <= 24) {
      return BrandColors.recap; // Orange - warning
    } else {
      return BrandColors.planning; // Green - good
    }
  }

  String _formatTimeLeft() {
    if (activity.isOverdue) {
      return 'Overdue';
    }

    final timeLeft = activity.timeLeft;
    if (timeLeft == null) return 'No deadline';

    final hours = timeLeft.inHours;
    final days = timeLeft.inDays;

    if (days > 0) {
      return '${days}d left';
    } else if (hours > 0) {
      return '${hours}h left';
    } else {
      final minutes = timeLeft.inMinutes;
      return '${minutes}m left';
    }
  }
}

import 'package:flutter/material.dart';
import '../../../features/group_hub/domain/entities/group_event_entity.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Reusable event card for group hub Events section
/// Shows event details with date, status, attendees, and going count
class GroupEventCard extends StatelessWidget {
  final GroupEventEntity event;
  final VoidCallback? onTap;

  const GroupEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.sectionH),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Status row
            _buildDateAndStatus(),
            const SizedBox(height: Gaps.sm),

            // Event title and location
            _buildEventInfo(),
            const SizedBox(height: Gaps.sm),

            // Attendees and going count
            _buildAttendeeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date
        Text(
          event.date != null ? _formatEventDate(event.date!) : 'To be decided',
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text2,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Status chip (non-interactive for display only)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.ctlH,
            vertical: 6.0,
          ),
          decoration: BoxDecoration(
            color: event.status == GroupEventStatus.confirmed
                ? BrandColors.planning
                : BrandColors.bg2,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: event.status == GroupEventStatus.confirmed
                  ? BrandColors.planning
                  : BrandColors.bg3,
              width: 1,
            ),
          ),
          child: Text(
            event.status == GroupEventStatus.confirmed
                ? 'Confirmed'
                : 'Pending',
            style: AppText.labelLarge.copyWith(
              color: event.status == GroupEventStatus.confirmed
                  ? Colors.white
                  : BrandColors.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Row(
      children: [
        // Event emoji
        Text(
          event.emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: Gaps.sm),

        // Event name and location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name,
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.location != null) ...[
                const SizedBox(height: 2),
                Text(
                  event.location!,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeInfo() {
    return Row(
      children: [
        // Profile pictures
        _buildAttendeeAvatars(),
        const SizedBox(width: Gaps.sm),

        // Going count text
        Text(
          '${event.goingCount} going',
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeAvatars() {
    const avatarSize = 24.0;
    const overlap = 8.0;

    if (event.attendeeAvatars.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleAvatars = event.attendeeAvatars.take(3).toList();
    final totalWidth =
        avatarSize + (visibleAvatars.length - 1) * (avatarSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: visibleAvatars.asMap().entries.map((entry) {
          final index = entry.key;
          final avatarUrl = entry.value;

          return Positioned(
            left: index * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: BrandColors.bg1,
                  width: 2,
                ),
                image: DecorationImage(
                  image: NetworkImage(avatarUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image loading error
                  },
                ),
              ),
              child: avatarUrl.isEmpty
                  ? Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: BrandColors.bg3,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 12,
                        color: BrandColors.text2,
                      ),
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    final difference = eventDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return _getWeekdayName(date.weekday);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }
}

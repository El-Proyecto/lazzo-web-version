import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/cards/confirmed_event_card.dart';
import '../../../group_hub/domain/entities/group_event_entity.dart';

/// Section displaying upcoming events that both users are attending
/// Shows vertical list of confirmed events
class UpcomingTogetherSection extends StatelessWidget {
  final List<GroupEventEntity> events;
  final Function(GroupEventEntity)? onEventTap;

  const UpcomingTogetherSection({
    super.key,
    required this.events,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show section if no events
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Upcoming Together',
            style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
          ),

          const SizedBox(height: Gaps.sm),

          // Vertical list of events
          ...events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < events.length - 1 ? Gaps.md : 0,
              ),
              child: ConfirmedEventCard(
                emoji: event.emoji,
                title: event.name,
                dateTime: _formatEventDate(event.date),
                location: event.location ?? 'Location TBD',
                onTap: () => onEventTap?.call(event),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'To be decided';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];

    return '$weekday, $day $month';
  }
}

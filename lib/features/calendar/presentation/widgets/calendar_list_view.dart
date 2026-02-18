import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/calendar_event_entity.dart';

/// List view showing all events organized by day
/// Each day section has a header and event cards
class CalendarListView extends StatelessWidget {
  final List<CalendarEventEntity> events;

  const CalendarListView({
    super.key,
    required this.events,
  });

  /// Group events by date
  Map<DateTime, List<CalendarEventEntity>> _groupByDate() {
    final Map<DateTime, List<CalendarEventEntity>> grouped = {};
    for (final event in events) {
      if (event.date == null) continue;
      final dateKey = DateTime(
        event.date!.year,
        event.date!.month,
        event.date!.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(event);
    }
    return grouped;
  }

  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    if (dateOnly == today) {
      return 'Today — $weekday, $month ${date.day}';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow — $weekday, $month ${date.day}';
    }
    return '$weekday, $month ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyState(context);
    }

    final grouped = _groupByDate();
    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.sectionH,
        vertical: Gaps.md,
      ),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayEvents = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: Gaps.lg),
            // Day header
            Text(
              _formatDayHeader(date),
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
            ),
            const SizedBox(height: Gaps.xs),
            // Event cards for this day
            ...dayEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.xs),
                child: _ListEventCard(event: event),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: Gaps.sm),
          Text(
            'No upcoming events',
            style: AppText.bodyLarge.copyWith(color: BrandColors.text2),
          ),
          const SizedBox(height: Gaps.md),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRouter.createEvent);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Pads.ctlH,
                vertical: Pads.ctlVXs,
              ),
              decoration: BoxDecoration(
                color: BrandColors.planning,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                'Create Event',
                style: AppText.labelLargeEmph.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact event card for list view
class _ListEventCard extends StatelessWidget {
  final CalendarEventEntity event;

  const _ListEventCard({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = event.status == CalendarEventStatus.confirmed;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.event,
          arguments: {'eventId': event.id},
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
          border: isConfirmed
              ? Border.all(color: BrandColors.planning, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Emoji
            Text(event.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: Gaps.xs),
            // Event info
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
            const SizedBox(width: Gaps.xs),
            // Status chip
            _ListStatusChip(status: event.status),
          ],
        ),
      ),
    );
  }
}

/// Status chip for list view cards
class _ListStatusChip extends StatelessWidget {
  final CalendarEventStatus status;

  const _ListStatusChip({required this.status});

  Color get _backgroundColor {
    switch (status) {
      case CalendarEventStatus.pending:
        return BrandColors.bg3;
      case CalendarEventStatus.confirmed:
        return BrandColors.planning;
      case CalendarEventStatus.living:
        return BrandColors.living;
      case CalendarEventStatus.recap:
        return BrandColors.recap;
    }
  }

  Color get _borderColor {
    if (status == CalendarEventStatus.pending) return BrandColors.border;
    return Colors.transparent;
  }

  Color get _textColor {
    if (status == CalendarEventStatus.pending) return BrandColors.text1;
    return Colors.white;
  }

  String get _label {
    switch (status) {
      case CalendarEventStatus.pending:
        return 'Pending';
      case CalendarEventStatus.confirmed:
        return 'Confirmed';
      case CalendarEventStatus.living:
        return 'Live';
      case CalendarEventStatus.recap:
        return 'Recap';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.sectionV,
        vertical: Pads.ctlVXss,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Text(
        _label,
        style: AppText.labelLarge.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

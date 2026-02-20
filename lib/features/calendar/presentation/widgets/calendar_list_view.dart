import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../shared/components/cards/memory_small_card.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/calendar_event_entity.dart';

/// List view showing events for the current month, grouped by day
/// Supports horizontal swipe for month navigation
class CalendarListView extends StatelessWidget {
  final List<CalendarEventEntity> events;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const CalendarListView({
    super.key,
    required this.events,
    required this.onSwipeLeft,
    required this.onSwipeRight,
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

  EventSmallCardState _mapStatus(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.pending:
        return EventSmallCardState.pending;
      case CalendarEventStatus.confirmed:
        return EventSmallCardState.confirmed;
      case CalendarEventStatus.living:
        return EventSmallCardState.living;
      case CalendarEventStatus.recap:
        return EventSmallCardState.recap;
    }
  }

  /// Format: "14:30-18h30" (same day) or "14:30 - 28 Nov 18h30" (multi-day)
  String _formatEventDateTime(CalendarEventEntity event) {
    if (event.date == null) return 'Date TBD';
    final start = event.date!;
    final end = event.endDate;

    String fmtTime(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    String fmtTimeH(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';

    final startTime = fmtTime(start);
    if (end == null) return startTime;

    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final endTime = fmtTimeH(end);

    if (sameDay) {
      return '$startTime-$endTime';
    } else {
      const monthsShort = [
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
        'Dec',
      ];
      final endMonth = monthsShort[end.month - 1];
      return '$startTime - ${end.day} $endMonth $endTime';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            onSwipeLeft(); // Next month
          } else if (details.primaryVelocity! > 100) {
            onSwipeRight(); // Previous month
          }
        }
      },
      child: events.isEmpty ? _buildEmptyState(context) : _buildEventList(),
    );
  }

  Widget _buildEventList() {
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
                child: _buildEventCard(context, event),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Returns true if this event should be rendered as a memory card
  bool _isMemoryEvent(CalendarEventEntity event) {
    return event.hasMemory && event.isPast;
  }

  /// Format memory date: "12 Jul"
  String _formatMemoryDate(CalendarEventEntity event) {
    if (event.date == null) return '';
    const monthsShort = [
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
      'Dec',
    ];
    return '${event.date!.day} ${monthsShort[event.date!.month - 1]}';
  }

  /// Build the appropriate card widget for an event
  Widget _buildEventCard(BuildContext context, CalendarEventEntity event) {
    if (_isMemoryEvent(event)) {
      return MemorySmallCard(
        title: event.name,
        dateTime: _formatMemoryDate(event),
        location: event.location,
        coverPhotoUrl: event.coverPhotoUrl,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.memory,
            arguments: {'memoryId': event.id},
          );
        },
      );
    }

    return EventSmallCard(
      emoji: event.emoji,
      title: event.name,
      dateTime: _formatEventDateTime(event),
      location: event.location,
      state: _mapStatus(event.status),
      isExpired: event.isPast && event.status == CalendarEventStatus.pending,
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.event,
          arguments: {'eventId': event.id},
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_note_outlined,
            size: 48,
            color: BrandColors.text2,
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            'No events this month',
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

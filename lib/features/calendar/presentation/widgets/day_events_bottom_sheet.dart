import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../shared/components/cards/memory_small_card.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/calendar_event_entity.dart';

/// Bottom sheet that shows events for the selected day
/// Can be dragged from collapsed to almost full screen
/// Background uses bg2 color
class DayEventsBottomSheet extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarEventEntity> events;
  final ScrollController scrollController;

  const DayEventsBottomSheet({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.scrollController,
  });

  String _formatDate(DateTime date) {
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
    return '$weekday, ${date.day} $month';
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
      case CalendarEventStatus.ended:
        return EventSmallCardState.pending;
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
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.bg1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.md),
        ),
        border: Border(
          top: BorderSide(
              color: BrandColors.border.withValues(alpha: 0.6), width: 1),
        ),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: Gaps.sm, bottom: Gaps.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.text2.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Day header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Pads.sectionH,
            ),
            child: Text(
              _formatDate(selectedDate),
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: Gaps.md),
          // Events list or empty state
          if (events.isEmpty)
            _buildEmptyState(context)
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.sectionH,
                  vertical: Gaps.xxs,
                ),
                child: _buildEventCard(context, event),
              ),
            ),
          const SizedBox(height: Gaps.xl),
        ],
      ),
    );
  }

  /// Returns true if this event should be rendered as a memory card
  /// Only ended events with photos are memories
  bool _isMemoryEvent(CalendarEventEntity event) {
    return event.status == CalendarEventStatus.ended && event.hasMemory;
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

    final isLivingOrRecap = event.status == CalendarEventStatus.living ||
        event.status == CalendarEventStatus.recap;

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
          isLivingOrRecap ? AppRouter.eventLiving : AppRouter.event,
          arguments: {'eventId': event.id},
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.sectionH,
        vertical: Gaps.xl,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 48,
            color: BrandColors.text2,
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            'No events on this day',
            style: AppText.bodyLarge.copyWith(
              color: BrandColors.text2,
            ),
          ),
          const SizedBox(height: Gaps.md),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.createEvent,
                arguments: {'preSelectedDate': selectedDate},
              );
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

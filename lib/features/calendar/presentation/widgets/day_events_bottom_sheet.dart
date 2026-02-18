import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/calendar_event_entity.dart';

/// Bottom sheet that shows events for the selected day
/// Can be dragged from collapsed to almost full screen
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

  String _formatEventDate(CalendarEventEntity event) {
    if (event.date == null) return 'Date TBD';
    final d = event.date!;
    const weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    final wd = weekdaysShort[d.weekday - 1];
    final mo = monthsShort[d.month - 1];
    return '$wd, ${d.day} $mo';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.bg1,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Radii.md),
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
              style: AppText.titleLargeEmph.copyWith(
                color: BrandColors.text1,
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
                child: _CalendarEventCard(
                  event: event,
                  formattedDate: _formatEventDate(event),
                  cardState: _mapStatus(event.status),
                ),
              ),
            ),
          const SizedBox(height: Gaps.xl),
        ],
      ),
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
          const Text(
            '📭',
            style: TextStyle(fontSize: 48),
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

/// Calendar-specific event card with green border for confirmed events
/// Matches the design from the screenshot
class _CalendarEventCard extends StatelessWidget {
  final CalendarEventEntity event;
  final String formattedDate;
  final EventSmallCardState cardState;

  const _CalendarEventCard({
    required this.event,
    required this.formattedDate,
    required this.cardState,
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
            Text(event.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: Gaps.sm),
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
                  const SizedBox(height: 2),
                  if (event.location != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: BrandColors.text2,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (event.groupName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.groups,
                          size: 14,
                          color: BrandColors.text2,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.groupName!,
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Gaps.xs),
            // Status chip
            _StatusChip(status: event.status),
          ],
        ),
      ),
    );
  }
}

/// Status chip for calendar event cards
class _StatusChip extends StatelessWidget {
  final CalendarEventStatus status;

  const _StatusChip({required this.status});

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

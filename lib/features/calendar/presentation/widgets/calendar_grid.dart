import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/calendar_event_entity.dart';

/// Calendar grid widget showing a month view with event indicators
/// Days with events show ONLY emojis or cover photos (no day number)
/// Days without events show the day number
/// Past dates use text2 color for the number
class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime selectedDate;
  final Map<int, List<CalendarEventEntity>> eventsByDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.eventsByDay,
    required this.onDaySelected,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

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
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          const SizedBox(height: Gaps.xs),
          _buildDayGrid(context),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays
            .map(
              (day) => SizedBox(
                width: 44,
                child: Center(
                  child: Text(
                    day,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDayGrid(BuildContext context) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0=Sun

    final today = DateTime.now();
    bool isToday(DateTime day) =>
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    bool isSelected(DateTime day) =>
        day.year == selectedDate.year &&
        day.month == selectedDate.month &&
        day.day == selectedDate.day;
    bool isPast(DateTime day) => DateTime(day.year, day.month, day.day)
        .isBefore(DateTime(today.year, today.month, today.day));

    final List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Add empty cells for days before the 1st
    for (int i = 0; i < startingWeekday; i++) {
      currentRow.add(const SizedBox(width: 44, height: 56));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dayEvents = eventsByDay[day] ?? [];

      currentRow.add(
        _DayCell(
          day: day,
          events: dayEvents,
          isToday: isToday(date),
          isSelected: isSelected(date),
          isPast: isPast(date),
          onTap: () => onDaySelected(date),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: currentRow,
            ),
          ),
        );
        currentRow = [];
      }
    }

    // Fill remaining cells in the last row
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const SizedBox(width: 44, height: 56));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: currentRow,
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

/// Individual day cell in the calendar grid
/// If event exists: show ONLY emoji or cover photo (no number)
/// If no event: show day number
/// Past dates numbers use text2 color
class _DayCell extends StatelessWidget {
  final int day;
  final List<CalendarEventEntity> events;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.onTap,
  });

  /// Returns the selection colour based on the highest-priority non-memory event.
  /// Priority: living > recap > confirmed > expired > pending.
  /// Memory events (past + has cover photo) are excluded from colour calculation.
  Color get _selectionColor {
    if (events.isEmpty) return BrandColors.bg3;

    // Collect effective statuses, excluding memory events
    final statuses = <String>{};
    for (final e in events) {
      // Skip memory events — they don't contribute to selection color
      if (e.hasMemory && e.isPast) continue;
      final key = (isPast && e.status == CalendarEventStatus.pending)
          ? 'expired'
          : e.status.name;
      statuses.add(key);
    }

    // If only memories (no non-memory events), use default bg
    if (statuses.isEmpty) return BrandColors.bg3;

    // Pure priority — first match wins
    if (statuses.contains('living')) {
      return BrandColors.living.withValues(alpha: 0.25);
    }
    if (statuses.contains('recap')) {
      return BrandColors.recap.withValues(alpha: 0.25);
    }
    if (statuses.contains('confirmed')) {
      return BrandColors.planning.withValues(alpha: 0.25);
    }
    if (statuses.contains('expired')) {
      return Colors.amber.withValues(alpha: 0.25);
    }
    // pending
    return BrandColors.bg3;
  }

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    // Check if any past event has a memory cover photo
    final memoryEvent = events.where((e) => e.hasMemory && e.isPast).toList();
    final showCoverPhoto = memoryEvent.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 56,
        decoration: isSelected
            ? BoxDecoration(
                color: _selectionColor,
                borderRadius: BorderRadius.circular(Radii.sm),
              )
            : null,
        child: Center(
          child: hasEvents && showCoverPhoto
              ? _buildCoverPhoto(memoryEvent.first.coverPhotoUrl!)
              : hasEvents
                  ? _buildEmojiOnly()
                  : _buildDayNumber(),
        ),
      ),
    );
  }

  /// Show only the day number (no events)
  Widget _buildDayNumber() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isToday
            ? BrandColors.planning.withValues(alpha: 0.3)
            : Colors.transparent,
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppText.bodyLarge.copyWith(
            color: isToday
                ? BrandColors.planning
                : isPast
                    ? BrandColors.text2
                    : BrandColors.text1,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// Show ONLY emojis — no day number at all
  Widget _buildEmojiOnly() {
    final emojis = events.map((e) => e.emoji).toSet().toList();
    final displayEmojis = emojis.take(2).toList();

    if (displayEmojis.length == 1) {
      return Text(
        displayEmojis.first,
        style: const TextStyle(fontSize: 24),
      );
    }

    // Multiple emojis: overlapping stack
    return SizedBox(
      width: 40,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 2,
            child: Text(
              displayEmojis[0],
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Positioned(
            left: 16,
            child: Text(
              displayEmojis[1],
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Show cover photo thumbnail (for past events with memories)
  Widget _buildCoverPhoto(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Image.network(
        url,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildEmojiOnly(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/calendar_event_entity.dart';

/// Calendar grid widget showing a month view with event indicators
/// Days with events show emojis (overlapping if multiple)
/// Past events with memory cover photos show a thumbnail
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
class _DayCell extends StatelessWidget {
  final int day;
  final List<CalendarEventEntity> events;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    // Check if any past event has a memory cover photo
    final memoryEvent = events.where((e) => e.hasMemory && e.isPast).toList();
    final showCoverPhoto = memoryEvent.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasEvents && !showCoverPhoto)
              // Show emojis for events
              _buildEmojiIndicator()
            else if (showCoverPhoto)
              // Show cover photo for past events with memories
              _buildCoverPhoto(memoryEvent.first.coverPhotoUrl!)
            else
              // Just show the day number
              _buildDayNumber(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayNumber() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? BrandColors.bg3
            : isToday
                ? BrandColors.planning.withValues(alpha: 0.3)
                : Colors.transparent,
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppText.bodyLarge.copyWith(
            color: isToday ? BrandColors.planning : BrandColors.text1,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiIndicator() {
    // Show emojis with overlapping effect (max 2 visible)
    final emojis = events.map((e) => e.emoji).toSet().toList();
    final displayEmojis = emojis.take(2).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day number (smaller when has events)
        Container(
          width: 36,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.sm),
            color: isSelected
                ? BrandColors.bg3
                : isToday
                    ? BrandColors.planning.withValues(alpha: 0.3)
                    : Colors.transparent,
          ),
          child: Center(
            child: Text(
              '$day',
              style: AppText.bodyMedium.copyWith(
                color: isToday ? BrandColors.planning : BrandColors.text1,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Overlapping emojis row
        SizedBox(
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < displayEmojis.length; i++)
                Positioned(
                  left: i == 0 ? (displayEmojis.length > 1 ? 0 : 8) : 14,
                  child: Text(
                    displayEmojis[i],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPhoto(String url) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day number
        Container(
          width: 36,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.sm),
            color: isSelected
                ? BrandColors.bg3
                : isToday
                    ? BrandColors.planning.withValues(alpha: 0.3)
                    : Colors.transparent,
          ),
          child: Center(
            child: Text(
              '$day',
              style: AppText.bodyMedium.copyWith(
                color: isToday ? BrandColors.planning : BrandColors.text1,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 1),
        // Cover photo thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            url,
            width: 30,
            height: 30,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 30,
              height: 30,
              child: Icon(Icons.image, size: 16, color: BrandColors.text2),
            ),
          ),
        ),
      ],
    );
  }
}

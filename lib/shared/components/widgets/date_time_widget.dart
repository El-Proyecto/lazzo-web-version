import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Date and time widget for displaying event schedule
/// Shows calendar preview and button to add to calendar
class DateTimeWidget extends StatelessWidget {
  final String eventName;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String? location;

  const DateTimeWidget({
    super.key,
    required this.eventName,
    required this.startDateTime,
    this.endDateTime,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Date & Time', style: AppText.labelLarge),
          const SizedBox(height: Gaps.md),

          // Date and time display
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar icon - show multi-day if applicable
              _buildCalendarIcon(),
              const SizedBox(width: Gaps.sm),

              // Date and time text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDateRange(startDateTime, endDateTime),
                      style: AppText.bodyMediumEmph,
                    ),
                    const SizedBox(height: Gaps.xxs),
                    Text(
                      _getTimeRange(startDateTime, endDateTime),
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.md),

          // Add to calendar button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addToCalendar(),
              icon: const Icon(Icons.calendar_today, size: IconSizes.sm),
              label: Text('Add to calendar', style: AppText.bodyMediumEmph),
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColors.text1,
                side: const BorderSide(color: BrandColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.ctlH,
                  vertical: Pads.ctlV,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarIcon() {
    // Check if it's a multi-day event
    if (endDateTime != null && !_isSameDay(startDateTime, endDateTime!)) {
      // Multi-day event - show range indicator
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${startDateTime.day}-${endDateTime!.day}',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _getMonthAbbreviation(startDateTime.month),
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else {
      // Single day event
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getMonthAbbreviation(startDateTime.month),
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontSize: 10,
              ),
            ),
            Text(
              startDateTime.day.toString(),
              style: AppText.titleMediumEmph.copyWith(fontSize: 20),
            ),
          ],
        ),
      );
    }
  }

  String _getDateRange(DateTime start, DateTime? end) {
    if (end == null || _isSameDay(start, end)) {
      return _getFullDate(start);
    }

    // Multi-day event
    if (start.month == end.month && start.year == end.year) {
      // Same month - show: "Monday, 12 - Friday, 15 October"
      return '${_getWeekday(start)}, ${start.day} - ${_getWeekday(end)}, ${end.day} ${_getMonthName(start.month)}';
    } else {
      // Different months - show full dates
      return '${_getFullDate(start)} - ${_getFullDate(end)}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getWeekday(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];
    return months[month - 1];
  }

  String _getFullDate(DateTime date) {
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
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _getTimeRange(DateTime start, DateTime? end) {
    final startTime =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end != null) {
      final endTime =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      return '$startTime - $endTime';
    }
    return startTime;
  }

  void _addToCalendar() {
    // TODO: Implement calendar integration with add_2_calendar package
    // For now, this is a placeholder
  }
}

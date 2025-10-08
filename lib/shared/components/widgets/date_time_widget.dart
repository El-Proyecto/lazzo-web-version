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
              // Calendar icon
              Container(
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
              ),
              const SizedBox(width: Gaps.sm),

              // Date and time text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFullDate(startDateTime),
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

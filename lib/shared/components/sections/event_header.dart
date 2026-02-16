import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Event header widget with emoji, title, and quick info
/// Displays essential event information at the top of event page
class EventHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String? location;
  final DateTime? dateTime;
  final DateTime? endDateTime;
  final bool isExpired;

  const EventHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.location,
    this.dateTime,
    this.endDateTime,
    this.isExpired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji
        Text(
          emoji,
          style: const TextStyle(fontSize: 80, height: 1.0),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Gaps.xs),

        // Event title
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.titleMediumEmph,
        ),
        const SizedBox(height: Gaps.xs),

        // Location info (if available)
        if (location != null) ...[
          _InfoRow(icon: Icons.location_on, text: location!),
        ],

        // Date info (if available)
        if (dateTime != null) ...[
          const SizedBox(height: Gaps.xxs),
          _InfoRow(
            icon: Icons.calendar_today,
            text: _formatDateTime(dateTime!, endDateTime),
            isExpired: isExpired,
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime startDt, DateTime? endDt) {
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
      'Dec',
    ];

    final startDay = startDt.day;
    final startMonth = months[startDt.month - 1];
    final startTime =
        '${startDt.hour.toString().padLeft(2, '0')}:${startDt.minute.toString().padLeft(2, '0')}';

    if (endDt == null) {
      // Only start date and time
      return '$startDay $startMonth · $startTime';
    }

    final endDay = endDt.day;
    final endMonth = months[endDt.month - 1];
    final endTime =
        '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}';

    // Check if same day
    if (startDt.year == endDt.year &&
        startDt.month == endDt.month &&
        startDt.day == endDt.day) {
      // Same day: "15 Oct · 10:00 - 18:00"
      return '$startDay $startMonth · $startTime - $endTime';
    } else {
      // Different days: "15 Oct 10:00 - 16 Oct 18:00"
      return '$startDay $startMonth $startTime - $endDay $endMonth $endTime';
    }
  }
}

/// Internal widget for displaying icon + text rows
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isExpired;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.isExpired = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpired
        ? BrandColors.text2.withValues(alpha: 0.5)
        : BrandColors.text2;

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.sm, color: color),
          const SizedBox(width: Gaps.xs),
          Flexible(
            child: Text(
              text,
              style: AppText.bodyMedium.copyWith(
                color: color,
                decoration: isExpired ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

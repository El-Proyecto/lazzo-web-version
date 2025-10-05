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

  const EventHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.location,
    this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji
        Text(
          emoji,
          style: const TextStyle(fontSize: 64, height: 1.0),
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
            text: _formatDateTime(dateTime!),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${dt.day} ${months[dt.month - 1]} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Internal widget for displaying icon + text rows
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.sm, color: BrandColors.text2),
          const SizedBox(width: Gaps.xs),
          Flexible(
            child: Text(
              text,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

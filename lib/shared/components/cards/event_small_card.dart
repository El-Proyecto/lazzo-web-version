import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Small event card state
/// Pending: chip with bg3 and border
/// Confirmed: chip with green background
enum EventSmallCardState { pending, confirmed }

/// Small event card without voting functionality
/// Shows event info with a status chip (pending or confirmed)
/// Used in other profiles and smaller event lists
class EventSmallCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String dateTime;
  final String location;
  final EventSmallCardState state;
  final VoidCallback? onTap;

  const EventSmallCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.state,
    this.onTap,
  });

  Color _getChipBackgroundColor() {
    switch (state) {
      case EventSmallCardState.pending:
        return BrandColors.bg3;
      case EventSmallCardState.confirmed:
        return BrandColors.planning;
    }
  }

  Color _getChipBorderColor() {
    if (state == EventSmallCardState.pending) {
      return BrandColors.border;
    }
    return Colors.transparent;
  }

  Color _getChipTextColor() {
    if (state == EventSmallCardState.pending) {
      return BrandColors.text1;
    }
    return Colors.white;
  }

  String _getStatusLabel() {
    switch (state) {
      case EventSmallCardState.pending:
        return 'Pending';
      case EventSmallCardState.confirmed:
        return 'Confirmed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with emoji and status chip
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: Gaps.xs),
                Expanded(
                  child: Text(
                    title,
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Gaps.xs),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.sectionV,
                    vertical: Pads.ctlVXss,
                  ),
                  decoration: BoxDecoration(
                    color: _getChipBackgroundColor(),
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(
                      color: _getChipBorderColor(),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: AppText.labelLarge.copyWith(
                      color: _getChipTextColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gaps.xxs),
            // Date and location
            Text(
              '$dateTime • $location',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

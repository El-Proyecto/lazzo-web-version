import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Details widget for displaying event description/details
/// Follows the same visual pattern as LocationWidget and DateTimeWidget
class EventDetailsWidget extends StatelessWidget {
  final String details;

  const EventDetailsWidget({
    super.key,
    required this.details,
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
          Text('Details', style: AppText.labelLarge),
          const SizedBox(height: Gaps.sm),

          // Details text
          Text(
            details,
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }
}

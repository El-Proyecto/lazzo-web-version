import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// A card showing the count of votes for a specific RSVP status.
/// Used in the ManageGuests page filter row.
/// Tapping selects/deselects the filter.
class GuestVoteSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color countColor;
  final bool isSelected;
  final VoidCallback onTap;

  const GuestVoteSummaryCard({
    super.key,
    required this.label,
    required this.count,
    required this.countColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: Pads.ctlV,
          ),
          decoration: BoxDecoration(
            color: BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.smAlt),
            border: isSelected
                ? Border.all(
                    color: countColor.withValues(alpha: 0.6), width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                ),
              ),
              const SizedBox(height: Gaps.xxs),
              Text(
                '$count',
                style: AppText.headlineMedium.copyWith(
                  color: countColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

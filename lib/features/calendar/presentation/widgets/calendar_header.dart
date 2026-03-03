import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Calendar view mode toggle
enum CalendarViewMode { calendar, list }

/// Private header widget for the calendar page
/// Shows month/year title on the left and calendar/list toggle on the right
/// This is NOT an AppBar — it lives inside the page body
class CalendarHeader extends StatelessWidget {
  final String title;
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode> onViewModeChanged;
  final Color activeColor;

  const CalendarHeader({
    super.key,
    required this.title,
    required this.viewMode,
    required this.onViewModeChanged,
    this.activeColor = BrandColors.planning,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.sectionH,
        vertical: Gaps.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
              fontSize: 18,
            ),
          ),
          _ViewToggle(
            viewMode: viewMode,
            onChanged: onViewModeChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}

/// Toggle widget that switches between calendar and list view
class _ViewToggle extends StatelessWidget {
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode> onChanged;
  final Color activeColor;

  const _ViewToggle({
    required this.viewMode,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            icon: Icons.calendar_today,
            isSelected: viewMode == CalendarViewMode.calendar,
            onTap: () => onChanged(CalendarViewMode.calendar),
          ),
          _buildOption(
            icon: Icons.format_list_bulleted,
            isSelected: viewMode == CalendarViewMode.list,
            onTap: () => onChanged(CalendarViewMode.list),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Icon(
          icon,
          size: IconSizes.smAlt,
          color: isSelected ? Colors.white : BrandColors.text2,
        ),
      ),
    );
  }
}

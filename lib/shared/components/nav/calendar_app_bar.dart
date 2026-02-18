import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Calendar view mode toggle
enum CalendarViewMode { calendar, list }

/// Shared app bar for the Calendar page
/// Month/year title on the left, view toggle on the right
class CalendarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode> onViewModeChanged;

  const CalendarAppBar({
    super.key,
    required this.title,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month/Year title on the left
                  Text(
                    title,
                    style: AppText.headlineMedium.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // View toggle on the right
                  _ViewToggle(
                    viewMode: viewMode,
                    onChanged: onViewModeChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Toggle widget that switches between calendar and list view
class _ViewToggle extends StatelessWidget {
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode> onChanged;

  const _ViewToggle({
    required this.viewMode,
    required this.onChanged,
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
          color: isSelected ? BrandColors.planning : Colors.transparent,
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

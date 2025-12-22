import 'package:flutter/material.dart';
import '../../constants/text_styles.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

/// Configurable AppBar that replaces ProfileAppBar, CreateEventAppBar, and GroupsAppBar
/// Provides flexible layout with optional leading/trailing actions and centered title
/// Supports 0, 1, or 2 trailing icons with consistent spacing
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final Widget? trailing2;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final bool automaticallyImplyLeading;

  const CommonAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.trailing2,
    this.centerTitle = true,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0,
    this.automaticallyImplyLeading = false,
  });

  /// Factory constructor for profile-style AppBar
  factory CommonAppBar.profile({
    String title = 'Profile',
    VoidCallback? onEditPressed,
  }) {
    return CommonAppBar(
      title: title,
      trailing: onEditPressed != null
          ? GestureDetector(
              onTap: onEditPressed,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit_outlined,
                  color: BrandColors.text1,
                  size: 20,
                ),
              ),
            )
          : null,
    );
  }

  /// Factory constructor for create event-style AppBar
  factory CommonAppBar.createEvent({
    String title = 'Create Event',
    VoidCallback? onBackPressed,
    VoidCallback? onHistoryPressed,
  }) {
    return CommonAppBar(
      title: title,
      leading: GestureDetector(
        onTap: onBackPressed,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_ios,
            color: BrandColors.text1,
            size: 20,
          ),
        ),
      ),
      trailing: onHistoryPressed != null
          ? GestureDetector(
              onTap: onHistoryPressed,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.history,
                  color: BrandColors.text1,
                  size: 20,
                ),
              ),
            )
          : null,
    );
  }

  /// Factory constructor for groups-style AppBar
  factory CommonAppBar.groups({
    String title = 'Groups',
    VoidCallback? onCreateGroupPressed,
  }) {
    return CommonAppBar(
      title: title,
      trailing: onCreateGroupPressed != null
          ? GestureDetector(
              onTap: onCreateGroupPressed,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.group_add,
                  color: BrandColors.text1,
                  size: 20,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Leading widget (left-aligned)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: leading ?? const SizedBox(width: 36, height: 36),
                    ),
                  ),

                  // Title (absolutely centered both horizontally and vertically)
                  Align(
                    alignment:
                        centerTitle ? Alignment.center : Alignment.centerLeft,
                    child: Text(
                      title,
                      style: AppText.dropdownTitle.copyWith(
                        color: BrandColors.text1,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign:
                          centerTitle ? TextAlign.center : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Trailing widget(s) (right-aligned)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildTrailingIcons(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build trailing icons with proper spacing
  /// Supports 0, 1, or 2 icons on the right side
  Widget _buildTrailingIcons() {
    // No icons
    if (trailing == null && trailing2 == null) {
      return const SizedBox(width: 36, height: 36);
    }

    // Only trailing2
    if (trailing == null && trailing2 != null) {
      return SizedBox(
        width: 36,
        height: 36,
        child: trailing2,
      );
    }

    // Only trailing
    if (trailing != null && trailing2 == null) {
      return SizedBox(
        width: 36,
        height: 36,
        child: trailing,
      );
    }

    // Both trailing and trailing2 (with 4px spacing)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: trailing!,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 36,
          height: 36,
          child: trailing2!,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

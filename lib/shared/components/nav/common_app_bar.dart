import 'package:flutter/material.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Configurable AppBar that replaces ProfileAppBar, CreateEventAppBar, and GroupsAppBar
/// Provides flexible layout with optional leading/trailing actions and centered title
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final bool automaticallyImplyLeading;

  const CommonAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
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
                width: 25,
                height: 25,
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
          width: 32,
          height: 32,
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
                width: 32,
                height: 32,
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
                width: 28,
                height: 28,
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
      title: Stack(
        alignment: Alignment.center,
        children: [
          // Leading widget (left-aligned)
          Align(
            alignment: Alignment.centerLeft,
            child: leading ?? const SizedBox(width: 28, height: 28),
          ),

          // Title (absolutely centered both horizontally and vertically)
          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              style: AppText.dropdownTitle.copyWith(
                color: BrandColors.text1,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Trailing widget (right-aligned)
          Align(
            alignment: Alignment.centerRight,
            child: trailing ?? const SizedBox(width: 28, height: 28),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

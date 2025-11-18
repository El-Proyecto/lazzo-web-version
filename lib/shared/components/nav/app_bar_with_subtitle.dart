import 'package:flutter/material.dart';
import '../../../shared/constants/text_styles.dart';
import '../../../shared/themes/colors.dart';
import '../../../shared/constants/spacing.dart';

/// AppBar with subtitle support
/// Used for pages that need additional context below the title (e.g., countdown timers)
class AppBarWithSubtitle extends StatelessWidget
    implements PreferredSizeWidget {
  const AppBarWithSubtitle({
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.leading,
    this.trailing,
    this.centerTitle = true,
    this.backgroundColor,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? BrandColors.bg1,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // First row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.ctlVXs),
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  leading ?? const SizedBox(width: 36, height: 36),
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: AppText.dropdownTitle.copyWith(
                          color: BrandColors.text1,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  trailing ?? const SizedBox(width: 36, height: 36),
                ],
              ),
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -8),
            child: Text(
              subtitle,
              style: AppText.bodyMedium.copyWith(
                color: subtitleColor ?? BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(76);
}

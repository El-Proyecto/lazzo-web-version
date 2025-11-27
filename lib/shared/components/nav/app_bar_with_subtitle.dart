import 'package:flutter/material.dart';
import '../../../shared/constants/text_styles.dart';
import '../../../shared/themes/colors.dart';
import '../../../shared/constants/spacing.dart';

/// AppBar with subtitle support
/// Used for pages that need additional context below the title (e.g., countdown timers)
class AppBarWithSubtitle extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWithSubtitle({
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.leading,
    this.trailing,
    this.trailing2,
    this.centerTitle = true,
    this.backgroundColor,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget? leading;
  final Widget? trailing;
  final Widget? trailing2;
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
            child: SizedBox(
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: leading ?? const SizedBox(width: 36, height: 36),
                    ),
                  ),

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
                    ),
                  ),

                  // Trailing(s) alinhados à direita
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildTrailingIcons(),
                  ),
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

  /// Build trailing icons with proper spacing
  /// Supports 1 or 2 icons on the right side
  Widget _buildTrailingIcons() {
    // Nenhum ícone
    if (trailing == null && trailing2 == null) {
      return const SizedBox(width: 36, height: 36);
    }

    if (trailing == null && trailing2 != null) {
      return SizedBox(
        width: 36,
        height: 36,
        child: trailing2,
      );
    }

    if (trailing != null && trailing2 == null) {
      return SizedBox(
        width: 36,
        height: 36,
        child: trailing,
      );
    }

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
  Size get preferredSize => const Size.fromHeight(76);
}

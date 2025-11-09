import 'package:flutter/material.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Tokenized app bar for other user profile pages
/// Shows title with back button and invite to group icon
class OtherProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onInvitePressed;
  final VoidCallback? onBackPressed;

  const OtherProfileAppBar({
    super.key,
    this.title = 'Profile',
    this.onInvitePressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: AppText.dropdownTitle.copyWith(
          color: BrandColors.text1,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: onInvitePressed,
          icon: const Icon(
            Icons.person_add_outlined,
            color: BrandColors.text1,
            size: 24,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

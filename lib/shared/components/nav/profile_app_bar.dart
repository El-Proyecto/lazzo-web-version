import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Tokenized app bar for profile pages
/// Shows title and edit profile icon button
class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onEditPressed;

  const ProfileAppBar({super.key, this.title = 'Profile', this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: Insets.screenH),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Invisible placeholder for centering
            SizedBox(width: 28, height: 28),

            // Title
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

            // Edit Profile Button
            GestureDetector(
              onTap: onEditPressed,
              child: Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                child: Icon(
                  Icons.edit_outlined,
                  color: BrandColors.text1,
                  size: 20,
                ),
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

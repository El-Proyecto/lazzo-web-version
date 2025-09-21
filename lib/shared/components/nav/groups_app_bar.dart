import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// AppBar tokenizada para a página de grupos
class GroupsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onCreateGroupPressed;

  const GroupsAppBar({
    super.key,
    this.title = 'Groups',
    this.onCreateGroupPressed,
  });

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
            // Espaço vazio para centralizar o título
            SizedBox(width: 28, height: 28),

            // Título
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

            // Ícone de criar grupo
            GestureDetector(
              onTap: onCreateGroupPressed,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: Icon(
                  Icons.group_add,
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
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// AppBar tokenizada para criação/edição de eventos
/// Inclui botão back, título editável e botão de histórico
class CreateEventAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onHistoryPressed;
  final bool isEditable;
  final ValueChanged<String>? onTitleChanged;

  const CreateEventAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onHistoryPressed,
    this.isEditable = false,
    this.onTitleChanged,
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
            // Botão Back
            GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.arrow_back_ios,
                  color: BrandColors.text1,
                  size: 24,
                ),
              ),
            ),

            // Título fixo
            Expanded(
              child: Center(
                child: Text(
                  'Create Event',
                  style: AppText.dropdownTitle.copyWith(
                    color: BrandColors.text1,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ), // Botão Histórico
            GestureDetector(
              onTap: onHistoryPressed,
              child: SizedBox(
                width: 24,
                height: 24,
                child: Icon(Icons.history, color: BrandColors.text1, size: 24),
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

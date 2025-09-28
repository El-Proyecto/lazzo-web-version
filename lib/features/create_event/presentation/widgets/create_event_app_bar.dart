import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botão Back
            GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
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
            ),

            // Botão Histórico
            GestureDetector(
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

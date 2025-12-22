import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Dialog de confirmação comum e reutilizável
/// Padrão usado em toda a aplicação para ações destrutivas e confirmações
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BrandColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      contentPadding: const EdgeInsets.all(Gaps.lg),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Text(
            title,
            style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Gaps.md),

          // Mensagem
          Text(
            message,
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Gaps.lg),

          // Botões lado a lado
          Row(
            children: [
              // Cancel button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel?.call();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: BrandColors.bg3,
                    padding: const EdgeInsets.symmetric(vertical: Pads.ctlVSm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.smAlt),
                    ),
                  ),
                  child: Text(
                    cancelText ?? 'Cancel',
                    style: AppText.labelLarge.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ),
              ),

              // Only show confirm button if confirmText is provided
              if (confirmText != null) ...[
                const SizedBox(width: Gaps.sm),

                // Confirm button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isDestructive
                          ? BrandColors.cantVote
                          : BrandColors.planning,
                      padding:
                          const EdgeInsets.symmetric(vertical: Pads.ctlVSm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.smAlt),
                      ),
                    ),
                    child: Text(
                      confirmText!,
                      style: AppText.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

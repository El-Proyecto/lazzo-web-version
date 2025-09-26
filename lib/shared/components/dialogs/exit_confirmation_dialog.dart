import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Dialog de confirmação para sair da criação de evento
/// Oferece opções para salvar rascunho ou descartar alterações
class ExitConfirmationDialog extends StatelessWidget {
  final VoidCallback? onSaveDraft;
  final VoidCallback? onDiscard;

  const ExitConfirmationDialog({super.key, this.onSaveDraft, this.onDiscard});

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
            'Save your progress?',
            style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
          ),

          const SizedBox(height: Gaps.md),

          // Descrição
          Text(
            'You have unsaved changes. Would you like to save a draft before leaving?',
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Gaps.lg),

          // Botões lado a lado
          Row(
            children: [
              // Discard button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDiscard?.call();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: BrandColors.bg3,
                    padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                  child: Text(
                    'Discard',
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: Gaps.sm),

              // Save Draft button (highlighted)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSaveDraft?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.planning,
                    padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

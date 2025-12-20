import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../dialogs/confirmation_dialog.dart';

/// Card for hosts to close recap/living phase early
/// Only shown in recap or living state for event hosts
/// Allows immediate access to memory by ending recap/living timer
class CloseRecapCard extends StatelessWidget {
  final String timeRemaining;
  final VoidCallback onCloseConfirmed;
  final bool isLiving; // true for living mode, false for recap mode

  const CloseRecapCard({
    super.key,
    required this.timeRemaining,
    required this.onCloseConfirmed,
    this.isLiving = false, // defaults to recap mode
  });

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Close Recap Early?',
        message: 'This will end the recap phase. This action cannot be undone.',
        confirmText: 'Close Now',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: onCloseConfirmed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajusta o breakpoint depois de testares em SE / 16 Max
        final bool isCompact = constraints.maxWidth < 360;

        return Container(
          padding: const EdgeInsets.all(Gaps.md),
          decoration: BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: isCompact
              ? _buildVerticalLayout(context)
              : _buildHorizontalLayout(context),
        );
      },
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Row(
      children: [
        // Texto à esquerda
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Closes in $timeRemaining',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
              const SizedBox(height: Gaps.xxs),
              Text(
                'Memory can be shared after!',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Gaps.md),

        // Botão à direita
        _CloseNowButton(
          onTap: () => _showConfirmationDialog(context),
          isLiving: isLiving,
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Closes automatically in $timeRemaining',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.titleMediumEmph.copyWith(
            color: BrandColors.text1,
          ),
        ),
        const SizedBox(height: Gaps.xxs),
        Text(
          'Memory can be shared after!',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text2,
          ),
        ),
        const SizedBox(height: Gaps.sm),

        // Botão em baixo, alinhado à direita
        Align(
          alignment: Alignment.centerRight,
          child: _CloseNowButton(
            onTap: () => _showConfirmationDialog(context),
            isLiving: isLiving,
          ),
        ),
      ],
    );
  }
}

class _CloseNowButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLiving;

  const _CloseNowButton({required this.onTap, this.isLiving = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Gaps.md,
          vertical: Gaps.sm,
        ),
        decoration: BoxDecoration(
          color: BrandColors.cantVote, // Always red for destructive action
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
        child: Text(
          'Close Now',
          style: AppText.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

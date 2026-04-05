import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';

/// Widget for host-only time controls in recap mode (orange accent)
/// Shows time left pill that opens bottom sheet with "End Now" only (no add time)
class RecapHostTimeControls extends StatelessWidget {
  final DateTime recapEndTime;
  final VoidCallback onEndNow;

  const RecapHostTimeControls({
    super.key,
    required this.recapEndTime,
    required this.onEndNow,
  });

  String _formatTimeLeft(Duration duration) {
    if (duration.isNegative) return 'Ending soon';
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Ending soon';
    }
  }

  void _showRecapManagementSheet(BuildContext context) {
    final now = DateTime.now();
    final timeLeft = recapEndTime.difference(now);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RecapManagementBottomSheet(
        currentTimeLeft: timeLeft,
        onEndNow: () {
          Navigator.pop(context);
          _showEndConfirmation(context);
        },
      ),
    );
  }

  void _showEndConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'End Recap Now',
        message:
            'Are you sure you want to end the recap phase now? If no photos were uploaded, no memory will be created.',
        confirmText: 'End Recap',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: onEndNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLeft = recapEndTime.difference(now);

    return GestureDetector(
      onTap: () => _showRecapManagementSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: BrandColors.recap,
          borderRadius: BorderRadius.circular(Radii.pill),
          boxShadow: [
            BoxShadow(
              color: BrandColors.recap.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              _formatTimeLeft(timeLeft),
              style: AppText.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for recap management — End Now only (no add time)
class _RecapManagementBottomSheet extends StatelessWidget {
  final Duration currentTimeLeft;
  final VoidCallback onEndNow;

  const _RecapManagementBottomSheet({
    required this.currentTimeLeft,
    required this.onEndNow,
  });

  String _formatTimeLeft(Duration duration) {
    if (duration.isNegative) return 'Ending soon';
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Ending soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        Insets.screenH,
        Insets.screenH,
        Insets.screenH,
        Insets.screenBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and time left
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recap phase',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_formatTimeLeft(currentTimeLeft)} left',
                style: AppText.bodyMediumEmph.copyWith(
                  color: BrandColors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.md),

          // Info text
          Text(
            'Participants can still upload photos until the recap period ends.',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
          const SizedBox(height: Gaps.lg),

          // End Now button (destructive)
          GestureDetector(
            onTap: onEndNow,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Pads.ctlH,
                vertical: Pads.ctlV,
              ),
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Center(
                child: Text(
                  'End Now',
                  style: AppText.bodyMediumEmph.copyWith(
                    color: BrandColors.cantVote,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/common_bottom_sheet.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';

/// Widget for host-only time controls in living mode
/// Shows time left pill that opens bottom sheet with extend/end options
class HostTimeControls extends StatelessWidget {
  final DateTime eventEndTime;
  final VoidCallback onExtend30Minutes;
  final VoidCallback onCustomExtend;
  final VoidCallback onEndNow;

  const HostTimeControls({
    super.key,
    required this.eventEndTime,
    required this.onExtend30Minutes,
    required this.onCustomExtend,
    required this.onEndNow,
  });

  String _formatTimeLeft(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h ${minutes}m left';
      }
      return '${hours}h left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m left';
    } else {
      return 'Ending soon';
    }
  }

  void _showControlsSheet(BuildContext context) {
    CommonBottomSheet.show(
      context: context,
      title: 'Event Controls',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // +30m button
          _ControlButton(
            label: '+30 minutes',
            icon: Icons.add_circle_outline,
            onPressed: () {
              Navigator.pop(context);
              onExtend30Minutes();
            },
          ),
          const SizedBox(height: Gaps.md),

          // Custom extend button
          _ControlButton(
            label: 'Custom time',
            icon: Icons.schedule,
            onPressed: () {
              Navigator.pop(context);
              onCustomExtend();
            },
          ),
          const SizedBox(height: Gaps.md),

          // End now button (destructive)
          _ControlButton(
            label: 'End now',
            icon: Icons.stop_circle_outlined,
            isDestructive: true,
            onPressed: () {
              Navigator.pop(context);
              _showEndConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEndConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'End Event Now',
        message:
            'Are you sure you want to end this event? Participants will have 24h to upload photos.',
        confirmText: 'End Event',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: onEndNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLeft = eventEndTime.difference(now);

    return InkWell(
      onTap: () => _showControlsSheet(context),
      borderRadius: BorderRadius.circular(Radii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: BrandColors.living,
          borderRadius: BorderRadius.circular(Radii.pill),
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
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Button for control options in bottom sheet
class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: BoxDecoration(
          color: isDestructive ? BrandColors.cantVote : BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.white : BrandColors.text1,
              size: 24,
            ),
            const SizedBox(width: Gaps.md),
            Text(
              label,
              style: AppText.labelLarge.copyWith(
                color: isDestructive ? Colors.white : BrandColors.text1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

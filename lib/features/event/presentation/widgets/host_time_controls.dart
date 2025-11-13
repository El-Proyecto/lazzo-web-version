import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';

/// Widget for host-only time controls in living mode
/// Shows time left pill that opens bottom sheet with time picker
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
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Ending soon';
    }
  }

  void _showTimeManagementSheet(BuildContext context) {
    final now = DateTime.now();
    final timeLeft = eventEndTime.difference(now);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TimeManagementBottomSheet(
        currentTimeLeft: timeLeft,
        onAddTime: (minutes) {
          // TODO: Implement add time
          Navigator.pop(context);
        },
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

    return GestureDetector(
      onTap: () => _showTimeManagementSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: BrandColors.living,
          borderRadius: BorderRadius.circular(Radii.pill),
          boxShadow: [
            BoxShadow(
              color: BrandColors.living.withValues(alpha: 0.4),
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

/// Bottom sheet for managing event time
class _TimeManagementBottomSheet extends StatefulWidget {
  final Duration currentTimeLeft;
  final Function(int minutes) onAddTime;
  final VoidCallback onEndNow;

  const _TimeManagementBottomSheet({
    required this.currentTimeLeft,
    required this.onAddTime,
    required this.onEndNow,
  });

  @override
  State<_TimeManagementBottomSheet> createState() =>
      _TimeManagementBottomSheetState();
}

class _TimeManagementBottomSheetState
    extends State<_TimeManagementBottomSheet> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  int _selectedHours = 0;
  int _selectedMinutes = 30; // Default 30 minutes

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: _selectedHours);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinutes ~/ 5);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  String _formatTimeLeft(Duration duration) {
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
                'Manage event time',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_formatTimeLeft(widget.currentTimeLeft)} left',
                style: AppText.bodyMediumEmph.copyWith(
                  color: BrandColors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.lg),

          // Time picker
          Container(
            height: 140,
            padding: const EdgeInsets.symmetric(
              horizontal: Pads.ctlH,
              vertical: Pads.ctlV,
            ),
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Row(
              children: [
                // Hours picker
                Expanded(
                  child: _buildWheelPicker(
                    controller: _hourController,
                    itemCount: 24,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedHours = index;
                      });
                    },
                    formatter: (value) =>
                        '${value.toString().padLeft(2, '0')}h',
                  ),
                ),

                const SizedBox(width: Gaps.md),

                // Minutes picker (5 min increments)
                Expanded(
                  child: _buildWheelPicker(
                    controller: _minuteController,
                    itemCount: 12, // 0 to 55 in steps of 5
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedMinutes = index * 5;
                      });
                    },
                    formatter: (value) =>
                        '${(value * 5).toString().padLeft(2, '0')}m',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gaps.lg),

          // Add Time button
          GestureDetector(
            onTap: () {
              final totalMinutes = (_selectedHours * 60) + _selectedMinutes;
              if (totalMinutes > 0) {
                widget.onAddTime(totalMinutes);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Pads.ctlH,
                vertical: Pads.ctlV,
              ),
              decoration: BoxDecoration(
                color: BrandColors.living,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Center(
                child: Text(
                  'Add Time',
                  style: AppText.bodyMediumEmph.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Gaps.md),

          // End Now button (destructive)
          GestureDetector(
            onTap: widget.onEndNow,
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

  Widget _buildWheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onSelectedItemChanged,
    required String Function(int) formatter,
  }) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 32,
      onSelectedItemChanged: onSelectedItemChanged,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          color: BrandColors.living.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      children: List.generate(itemCount, (index) {
        return Center(
          child: Text(
            formatter(index),
            style: AppText.bodyLarge.copyWith(
              color: BrandColors.text1,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        );
      }),
    );
  }
}

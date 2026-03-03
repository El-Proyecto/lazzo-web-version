import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Picker inline de tempo estilo iOS com rodas para hora e minuto
/// Permite seleção de hora e minuto em formato 24h
class InlineTimePicker extends StatefulWidget {
  final TimeOfDay? selectedTime;
  final Function(TimeOfDay)? onTimeChanged;

  const InlineTimePicker({super.key, this.selectedTime, this.onTimeChanged});

  @override
  State<InlineTimePicker> createState() => _InlineTimePickerState();
}

class _InlineTimePickerState extends State<InlineTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  /// Minute values: 0, 5, 10, ..., 55
  static const _minuteSteps = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  int _selectedHour = 0;
  int _selectedMinuteIndex = 0; // index into _minuteSteps
  int _tempHour = 0;
  int _tempMinuteIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize with selected time or current time
    final now = widget.selectedTime ?? TimeOfDay.now();
    _selectedHour = now.hour;
    // Snap minute to nearest 5-min slot
    _selectedMinuteIndex = _snapToNearest5(now.minute);
    _tempHour = _selectedHour;
    _tempMinuteIndex = _selectedMinuteIndex;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinuteIndex,
    );
  }

  /// Returns the index in _minuteSteps closest to the given minute
  int _snapToNearest5(int minute) {
    int bestIndex = 0;
    int bestDiff = 60;
    for (int i = 0; i < _minuteSteps.length; i++) {
      final diff = (minute - _minuteSteps[i]).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH, vertical: Pads.ctlV),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.smAlt),
      ),
      child: Row(
        children: [
          // Hour picker
          Expanded(
            child: _buildWheelPicker(
              controller: _hourController,
              itemCount: 24,
              selectedValue: _selectedHour,
              onSelectedItemChanged: (index) {
                setState(() {
                  _tempHour = index;
                });
              },
              onScrollEnd: () {
                if (_tempHour != _selectedHour) {
                  setState(() {
                    _selectedHour = _tempHour;
                  });
                  _notifyTimeChanged();
                }
              },
              formatter: (value) => value.toString().padLeft(2, '0'),
            ),
          ),

          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.xs),
            child: Text(
              ':',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
                fontSize: 20,
              ),
            ),
          ),

          // Minute picker (5-min steps: 00, 05, 10, ..., 55)
          Expanded(
            child: _buildWheelPicker(
              controller: _minuteController,
              itemCount: _minuteSteps.length,
              selectedValue: _selectedMinuteIndex,
              onSelectedItemChanged: (index) {
                setState(() {
                  _tempMinuteIndex = index;
                });
              },
              onScrollEnd: () {
                if (_tempMinuteIndex != _selectedMinuteIndex) {
                  setState(() {
                    _selectedMinuteIndex = _tempMinuteIndex;
                  });
                  _notifyTimeChanged();
                }
              },
              formatter: (value) =>
                  _minuteSteps[value].toString().padLeft(2, '0'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedValue,
    required Function(int) onSelectedItemChanged,
    required VoidCallback onScrollEnd,
    required String Function(int) formatter,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification) {
          // Call onScrollEnd when scrolling ends
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onScrollEnd();
          });
        }
        return false;
      },
      child: Stack(
        children: [
          // Selection overlay (behind the wheel)
          Positioned.fill(
            child: Center(
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: BrandColors.planning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          // Wheel picker without haptic feedback (no CupertinoPicker sound)
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 28,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.5,
            perspective: 0.003,
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) {
                return Center(
                  child: Text(
                    formatter(index),
                    style: AppText.bodyLarge.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _notifyTimeChanged() {
    final minute = _minuteSteps[_selectedMinuteIndex];
    final timeOfDay = TimeOfDay(hour: _selectedHour, minute: minute);
    widget.onTimeChanged?.call(timeOfDay);
  }
}

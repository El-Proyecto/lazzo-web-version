import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

  int _selectedHour = 0;
  int _selectedMinute = 0;
  int _tempHour = 0;
  int _tempMinute = 0;

  @override
  void initState() {
    super.initState();

    // Initialize with selected time or current time
    final now = widget.selectedTime ?? TimeOfDay.now();
    _selectedHour = now.hour;
    _selectedMinute = now.minute;
    _tempHour = _selectedHour;
    _tempMinute = _selectedMinute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
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

          // Minute picker
          Expanded(
            child: _buildWheelPicker(
              controller: _minuteController,
              itemCount: 60,
              selectedValue: _selectedMinute,
              onSelectedItemChanged: (index) {
                setState(() {
                  _tempMinute = index;
                });
              },
              onScrollEnd: () {
                if (_tempMinute != _selectedMinute) {
                  setState(() {
                    _selectedMinute = _tempMinute;
                  });
                  _notifyTimeChanged();
                }
              },
              formatter: (value) => value.toString().padLeft(2, '0'),
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
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 28,
        onSelectedItemChanged: onSelectedItemChanged,
        selectionOverlay: Container(
          decoration: BoxDecoration(
            color: BrandColors.planning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        children: List.generate(itemCount, (index) {
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
        }),
      ),
    );
  }

  void _notifyTimeChanged() {
    final timeOfDay = TimeOfDay(hour: _selectedHour, minute: _selectedMinute);
    widget.onTimeChanged?.call(timeOfDay);
  }
}

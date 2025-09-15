import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

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

  @override
  void initState() {
    super.initState();
    final time = widget.selectedTime ?? TimeOfDay.now();
    _selectedHour = time.hour;
    _selectedMinute = time.minute;

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
      padding: EdgeInsets.symmetric(horizontal: Pads.ctlH, vertical: Pads.ctlV),
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
                  _selectedHour = index;
                });
                _notifyTimeChanged();
              },
              formatter: (value) => value.toString().padLeft(2, '0'),
            ),
          ),

          // Separator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Gaps.xs),
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
                  _selectedMinute = index;
                });
                _notifyTimeChanged();
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
    required String Function(int) formatter,
  }) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 28,
      onSelectedItemChanged: onSelectedItemChanged,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          color: BrandColors.planning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      children: List.generate(itemCount, (index) {
        final isSelected = index == selectedValue;
        return Center(
          child: Text(
            formatter(index),
            style: AppText.bodyLarge.copyWith(
              color: isSelected ? BrandColors.planning : BrandColors.text1,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 16,
            ),
          ),
        );
      }),
    );
  }

  void _notifyTimeChanged() {
    final timeOfDay = TimeOfDay(hour: _selectedHour, minute: _selectedMinute);
    widget.onTimeChanged?.call(timeOfDay);
  }
}

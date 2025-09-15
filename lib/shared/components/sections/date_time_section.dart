import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../forms/inline_date_picker.dart';
import '../forms/inline_time_picker.dart';

enum DateTimeState { decideLater, setNow }

/// Seção expansível para seleção de data e hora
/// Suporta estados: Decide later, Set Now com Start e End
class DateTimeSection extends StatefulWidget {
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final Function(DateTime?)? onStartDateChanged;
  final Function(TimeOfDay?)? onStartTimeChanged;
  final Function(DateTime?)? onEndDateChanged;
  final Function(TimeOfDay?)? onEndTimeChanged;
  final DateTimeState initialState;

  const DateTimeSection({
    super.key,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.onStartDateChanged,
    this.onStartTimeChanged,
    this.onEndDateChanged,
    this.onEndTimeChanged,
    this.initialState = DateTimeState.decideLater,
  });

  @override
  State<DateTimeSection> createState() => _DateTimeSectionState();
}

class _DateTimeSectionState extends State<DateTimeSection> {
  DateTimeState _currentState = DateTimeState.decideLater;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: Pads.sectionV,
        left: Pads.sectionH,
        right: Pads.sectionH,
        bottom: Pads.sectionV,
      ),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        children: [
          // Header com toggle
          _buildHeader(),

          // Conteúdo expansível
          if (_currentState == DateTimeState.setNow) ...[
            SizedBox(height: Gaps.md),
            _buildExpandedContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Date & Time',
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),

        // Toggle buttons
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.smAlt),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleButton(
                text: 'Decide later',
                isSelected: _currentState == DateTimeState.decideLater,
                onTap: () => _changeState(DateTimeState.decideLater),
              ),
              _ToggleButton(
                text: 'Set Now',
                isSelected: _currentState == DateTimeState.setNow,
                onTap: () => _changeState(DateTimeState.setNow),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        // Start Date & Time
        _DateTimeRow(
          label: 'Start',
          date: widget.startDate,
          time: widget.startTime,
          onDateChanged: widget.onStartDateChanged,
          onTimeChanged: widget.onStartTimeChanged,
        ),

        SizedBox(height: Gaps.sm),

        // End Date & Time
        _DateTimeRow(
          label: 'End',
          date: widget.endDate,
          time: widget.endTime,
          onDateChanged: widget.onEndDateChanged,
          onTimeChanged: widget.onEndTimeChanged,
        ),
      ],
    );
  }

  void _changeState(DateTimeState newState) {
    setState(() {
      _currentState = newState;
    });
  }
}

class _ToggleButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ToggleButton({
    required this.text,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Pads.ctlH - 2, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? BrandColors.planning : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
        child: Text(
          text,
          style: AppText.labelLarge.copyWith(
            color: BrandColors.text1,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DateTimeRow extends StatefulWidget {
  final String label;
  final DateTime? date;
  final TimeOfDay? time;
  final Function(DateTime?)? onDateChanged;
  final Function(TimeOfDay?)? onTimeChanged;

  const _DateTimeRow({
    required this.label,
    this.date,
    this.time,
    this.onDateChanged,
    this.onTimeChanged,
  });

  @override
  State<_DateTimeRow> createState() => _DateTimeRowState();
}

class _DateTimeRowState extends State<_DateTimeRow> {
  bool _isDatePickerExpanded = false;
  bool _isTimePickerExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Label
            SizedBox(
              width: 40,
              child: Text(
                widget.label,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),

            const Spacer(),

            // Date Button
            _DateTimeButton(
              label: widget.date != null
                  ? '${widget.date!.day}/${widget.date!.month}/${widget.date!.year}'
                  : 'Date',
              icon: Icons.calendar_today,
              onTap: () => _toggleDatePicker(),
            ),

            SizedBox(width: Gaps.xs),

            // Time Button
            _DateTimeButton(
              label: widget.time != null
                  ? '${widget.time!.hour.toString().padLeft(2, '0')}:${widget.time!.minute.toString().padLeft(2, '0')}'
                  : 'Time',
              icon: Icons.access_time,
              onTap: () => _toggleTimePicker(),
            ),
          ],
        ),

        // Inline Date Picker
        if (_isDatePickerExpanded) ...[
          SizedBox(height: Gaps.sm),
          InlineDatePicker(
            selectedDate: widget.date,
            onDateChanged: (date) {
              widget.onDateChanged?.call(date);
              setState(() {
                _isDatePickerExpanded = false;
              });
            },
          ),
        ],

        // Inline Time Picker
        if (_isTimePickerExpanded) ...[
          SizedBox(height: Gaps.sm),
          InlineTimePicker(
            selectedTime: widget.time,
            onTimeChanged: (time) {
              widget.onTimeChanged?.call(time);
              setState(() {
                _isTimePickerExpanded = false;
              });
            },
          ),
        ],
      ],
    );
  }

  void _toggleDatePicker() {
    setState(() {
      _isDatePickerExpanded = !_isDatePickerExpanded;
      if (_isDatePickerExpanded) {
        _isTimePickerExpanded = false; // Close time picker if open
      }
    });
  }

  void _toggleTimePicker() {
    setState(() {
      _isTimePickerExpanded = !_isTimePickerExpanded;
      if (_isTimePickerExpanded) {
        _isDatePickerExpanded = false; // Close date picker if open
      }
    });
  }
}

class _DateTimeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _DateTimeButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Pads.ctlH - 2,
          vertical: Pads.ctlV - 1,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: BrandColors.text2, size: 14),
            SizedBox(width: Gaps.xs),
            Flexible(
              child: Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

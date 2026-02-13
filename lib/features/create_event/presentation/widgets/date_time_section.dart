import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'inline_date_picker.dart';
import 'inline_time_picker.dart';

/// Seção para seleção de data e hora
/// Mostra sempre os campos de Start e End (sem toggle Decide later / Set Now)
class DateTimeSection extends StatelessWidget {
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final Function(DateTime?)? onStartDateChanged;
  final Function(TimeOfDay?)? onStartTimeChanged;
  final Function(DateTime?)? onEndDateChanged;
  final Function(TimeOfDay?)? onEndTimeChanged;
  final String? validationError;

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
    this.validationError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
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
          // Header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Date & Time',
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),
          ),

          const SizedBox(height: Gaps.md),

          // Start Date & Time
          _DateTimeRow(
            label: 'Start',
            date: startDate,
            time: startTime,
            onDateChanged: onStartDateChanged,
            onTimeChanged: onStartTimeChanged,
          ),

          const SizedBox(height: Gaps.sm),

          // End Date & Time
          _DateTimeRow(
            label: 'End',
            date: endDate,
            time: endTime,
            onDateChanged: onEndDateChanged,
            onTimeChanged: onEndTimeChanged,
          ),

          // Error message
          if (validationError != null) ...[
            const SizedBox(height: Gaps.sm),
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: Text(
                validationError!,
                style: AppText.bodyMedium.copyWith(color: BrandColors.cantVote),
              ),
            ),
          ],
        ],
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
              isExpanded: _isDatePickerExpanded,
              onTap: () => _toggleDatePicker(),
            ),

            const SizedBox(width: Gaps.xs),

            // Time Button
            _DateTimeButton(
              label: widget.time != null
                  ? '${widget.time!.hour.toString().padLeft(2, '0')}:${widget.time!.minute.toString().padLeft(2, '0')}'
                  : 'Time',
              icon: Icons.access_time,
              isExpanded: _isTimePickerExpanded,
              onTap: () => _toggleTimePicker(),
            ),
          ],
        ),

        // Inline Date Picker
        if (_isDatePickerExpanded) ...[
          const SizedBox(height: Gaps.sm),
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
          const SizedBox(height: Gaps.sm),
          InlineTimePicker(
            selectedTime: widget.time,
            onTimeChanged: (time) {
              widget.onTimeChanged?.call(time);
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
        _isTimePickerExpanded = false;
      }
    });
  }

  void _toggleTimePicker() {
    setState(() {
      _isTimePickerExpanded = !_isTimePickerExpanded;
      if (_isTimePickerExpanded) {
        _isDatePickerExpanded = false;
      }
    });
  }
}

class _DateTimeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback? onTap;

  const _DateTimeButton({
    required this.label,
    required this.icon,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH - 2,
          vertical: Pads.ctlV - 1,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
          border: isExpanded
              ? Border.all(color: BrandColors.planning, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: BrandColors.text2, size: 14),
            const SizedBox(width: Gaps.xs),
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

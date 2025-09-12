import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

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

class _DateTimeRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Label
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),

        SizedBox(width: Gaps.xs),

        // Date Button
        Flexible(
          flex: 3,
          child: _DateTimeButton(
            label: date != null
                ? '${date!.day}/${date!.month}/${date!.year}'
                : 'Date',
            icon: Icons.calendar_today,
            onTap: () => _showDatePicker(context),
          ),
        ),

        SizedBox(width: Gaps.xs),

        // Time Button
        Flexible(
          flex: 2,
          child: _DateTimeButton(
            label: time != null
                ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
                : 'Time',
            icon: Icons.access_time,
            onTap: () => _showTimePicker(context),
          ),
        ),
      ],
    );
  }

  void _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: BrandColors.planning,
              onPrimary: BrandColors.text1,
              surface: BrandColors.bg2,
              onSurface: BrandColors.text1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      onDateChanged?.call(pickedDate);
    }
  }

  void _showTimePicker(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: BrandColors.planning,
              onPrimary: BrandColors.text1,
              surface: BrandColors.bg2,
              onSurface: BrandColors.text1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      onTimeChanged?.call(pickedTime);
    }
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
          mainAxisAlignment: MainAxisAlignment.center,
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

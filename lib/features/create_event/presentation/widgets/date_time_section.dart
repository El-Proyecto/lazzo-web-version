import 'package:flutter/material.dart';
import '../../../../shared/components/common/create_event_segmented_control.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'inline_date_picker.dart';
import 'inline_time_picker.dart';

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
  final Function(DateTimeState)? onStateChanged;
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
    this.initialState = DateTimeState.decideLater,
    this.onStateChanged,
    this.validationError,
  });

  @override
  State<DateTimeSection> createState() => _DateTimeSectionState();
}

class _DateTimeSectionState extends State<DateTimeSection>
    with SingleTickerProviderStateMixin {
  DateTimeState _currentState = DateTimeState.decideLater;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _currentState == DateTimeState.decideLater ? 0 : 1,
    );
  }

  @override
  void didUpdateWidget(DateTimeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to external state changes (e.g., from event history)
    if (oldWidget.initialState != widget.initialState) {
      _changeState(widget.initialState);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          // Header com toggle
          _buildHeader(),

          // Conteúdo expansível
          if (_currentState == DateTimeState.setNow) ...[
            const SizedBox(height: Gaps.md),
            _buildExpandedContent(),
          ],

          // Error message
          if (widget.validationError != null) ...[
            const SizedBox(height: Gaps.sm),
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.validationError!,
                style: AppText.bodyMedium.copyWith(color: BrandColors.cantVote),
              ),
            ),
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

        // Segmented Control
        SizedBox(
          width: 200, // Fixed width to prevent overflow
          child: CreateEventSegmentedControl(
            controller: _tabController,
            labels: const ['Decide later', 'Set Now'],
            onTap: (index) {
              final newState =
                  index == 0 ? DateTimeState.decideLater : DateTimeState.setNow;
              _changeState(newState);
            },
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

        const SizedBox(height: Gaps.sm),

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

    // Update tab controller to match new state
    final newIndex = newState == DateTimeState.decideLater ? 0 : 1;
    if (_tabController.index != newIndex) {
      _tabController.animateTo(newIndex);
    }

    // Notify parent of state change for validation
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged?.call(newState);
    });
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
              // Time picker stays open until user clicks outside or taps time button again
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

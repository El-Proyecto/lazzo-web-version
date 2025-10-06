import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../create_event/presentation/widgets/inline_date_picker.dart';
import '../../../create_event/presentation/widgets/inline_time_picker.dart';

/// Show add suggestion bottom sheet
void showAddSuggestionBottomSheet(
  BuildContext context, {
  required DateTime eventStartDate,
  required TimeOfDay eventStartTime,
  required DateTime eventEndDate,
  required TimeOfDay eventEndTime,
  required VoidCallback onSuggestionAdded,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddSuggestionBottomSheet(
      eventStartDate: eventStartDate,
      eventStartTime: eventStartTime,
      eventEndDate: eventEndDate,
      eventEndTime: eventEndTime,
      onSuggestionAdded: onSuggestionAdded,
    ),
  );
}

/// Bottom sheet for adding date/time suggestions
class _AddSuggestionBottomSheet extends StatefulWidget {
  final DateTime eventStartDate;
  final TimeOfDay eventStartTime;
  final DateTime eventEndDate;
  final TimeOfDay eventEndTime;
  final VoidCallback onSuggestionAdded;

  const _AddSuggestionBottomSheet({
    required this.eventStartDate,
    required this.eventStartTime,
    required this.eventEndDate,
    required this.eventEndTime,
    required this.onSuggestionAdded,
  });

  @override
  State<_AddSuggestionBottomSheet> createState() =>
      _AddSuggestionBottomSheetState();
}

class _AddSuggestionBottomSheetState extends State<_AddSuggestionBottomSheet> {
  late DateTime startDate;
  late TimeOfDay startTime;
  late DateTime endDate;
  late TimeOfDay endTime;

  bool isStartDatePickerExpanded = false;
  bool isStartTimePickerExpanded = false;
  bool isEndDatePickerExpanded = false;
  bool isEndTimePickerExpanded = false;

  @override
  void initState() {
    super.initState();
    // Pre-select with event's current date/time
    startDate = widget.eventStartDate;
    startTime = widget.eventStartTime;
    endDate = widget.eventEndDate;
    endTime = widget.eventEndTime;
  }

  bool get _hasChanges {
    return startDate != widget.eventStartDate ||
        startTime != widget.eventStartTime ||
        endDate != widget.eventEndDate ||
        endTime != widget.eventEndTime;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.85; // Almost full length

    return Container(
      height: bottomSheetHeight,
      decoration: const BoxDecoration(
        color: BrandColors.bg1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        children: [
          // Header with grabber
          const SizedBox(height: Gaps.sm),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: BrandColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: Gaps.md),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
            child: Row(
              children: [
                Text(
                  'Add Suggestion',
                  style: AppText.labelLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: const Padding(
                    padding: EdgeInsets.all(Gaps.xs),
                    child: Icon(
                      Icons.close,
                      size: IconSizes.md,
                      color: BrandColors.text2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Gaps.lg),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Start Date & Time Row
                  _buildDateTimeRow(
                    label: 'Start',
                    date: startDate,
                    time: startTime,
                    isDatePickerExpanded: isStartDatePickerExpanded,
                    isTimePickerExpanded: isStartTimePickerExpanded,
                    onDateTap: () {
                      setState(() {
                        isStartDatePickerExpanded = !isStartDatePickerExpanded;
                        isStartTimePickerExpanded = false;
                        isEndDatePickerExpanded = false;
                        isEndTimePickerExpanded = false;
                      });
                    },
                    onTimeTap: () {
                      setState(() {
                        isStartTimePickerExpanded = !isStartTimePickerExpanded;
                        isStartDatePickerExpanded = false;
                        isEndDatePickerExpanded = false;
                        isEndTimePickerExpanded = false;
                      });
                    },
                  ),

                  if (isStartDatePickerExpanded) ...[
                    const SizedBox(height: Gaps.sm),
                    InlineDatePicker(
                      selectedDate: startDate,
                      onDateChanged: (date) {
                        setState(() {
                          startDate = date;
                          isStartDatePickerExpanded = false;
                        });
                      },
                    ),
                  ],

                  if (isStartTimePickerExpanded) ...[
                    const SizedBox(height: Gaps.sm),
                    InlineTimePicker(
                      selectedTime: startTime,
                      onTimeChanged: (time) {
                        setState(() {
                          startTime = time;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: Gaps.sm),

                  // End Date & Time Row
                  _buildDateTimeRow(
                    label: 'End',
                    date: endDate,
                    time: endTime,
                    isDatePickerExpanded: isEndDatePickerExpanded,
                    isTimePickerExpanded: isEndTimePickerExpanded,
                    onDateTap: () {
                      setState(() {
                        isEndDatePickerExpanded = !isEndDatePickerExpanded;
                        isEndTimePickerExpanded = false;
                        isStartDatePickerExpanded = false;
                        isStartTimePickerExpanded = false;
                      });
                    },
                    onTimeTap: () {
                      setState(() {
                        isEndTimePickerExpanded = !isEndTimePickerExpanded;
                        isEndDatePickerExpanded = false;
                        isStartDatePickerExpanded = false;
                        isStartTimePickerExpanded = false;
                      });
                    },
                  ),

                  if (isEndDatePickerExpanded) ...[
                    const SizedBox(height: Gaps.sm),
                    InlineDatePicker(
                      selectedDate: endDate,
                      onDateChanged: (date) {
                        setState(() {
                          endDate = date;
                          isEndDatePickerExpanded = false;
                        });
                      },
                    ),
                  ],

                  if (isEndTimePickerExpanded) ...[
                    const SizedBox(height: Gaps.sm),
                    InlineTimePicker(
                      selectedTime: endTime,
                      onTimeChanged: (time) {
                        setState(() {
                          endTime = time;
                        });
                      },
                    ),
                  ],

                  const Spacer(),

                  // Submit button - Green when changes are made
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _hasChanges
                          ? () {
                              Navigator.of(context).pop();
                              widget.onSuggestionAdded();
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _hasChanges
                            ? BrandColors
                                  .planning // Green when valid
                            : BrandColors.text1.withOpacity(0.3),
                        foregroundColor: BrandColors.bg1,
                        padding: const EdgeInsets.symmetric(
                          vertical: Pads.ctlV,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                      ),
                      child: Text(
                        'Add Suggestion',
                        style: AppText.bodyMediumEmph,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + Gaps.md,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required bool isDatePickerExpanded,
    required bool isTimePickerExpanded,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
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

        const Spacer(),

        // Date Button
        _DateTimeButton(
          label: '${date.day}/${date.month}/${date.year}',
          icon: Icons.calendar_today,
          isExpanded: isDatePickerExpanded,
          onTap: onDateTap,
        ),

        const SizedBox(width: Gaps.xs),

        // Time Button
        _DateTimeButton(
          label:
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          icon: Icons.access_time,
          isExpanded: isTimePickerExpanded,
          onTap: onTimeTap,
        ),
      ],
    );
  }
}

/// Date/Time button matching create_event design
class _DateTimeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.label,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: isExpanded
              ? Border.all(color: BrandColors.planning, width: 1)
              : Border.all(color: BrandColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: BrandColors.text2),
            const SizedBox(width: Gaps.xs),
            Text(
              label,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

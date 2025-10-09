import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/inputs/segmented_control.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../create_event/presentation/widgets/inline_date_picker.dart';
import '../../../create_event/presentation/widgets/inline_time_picker.dart';
import '../../../create_event/presentation/widgets/location_section.dart';
import '../providers/event_providers.dart';

/// Enum for suggestion types
enum SuggestionType { dateTime, location }

/// Show add suggestion bottom sheet
void showAddSuggestionBottomSheet(
  BuildContext context, {
  required String eventId,
  required DateTime eventStartDate,
  required TimeOfDay eventStartTime,
  required DateTime eventEndDate,
  required TimeOfDay eventEndTime,
  SuggestionType type = SuggestionType.dateTime,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddSuggestionBottomSheet(
      eventId: eventId,
      eventStartDate: eventStartDate,
      eventStartTime: eventStartTime,
      eventEndDate: eventEndDate,
      eventEndTime: eventEndTime,
      suggestionType: type,
    ),
  );
}

/// Bottom sheet for adding date/time suggestions
class _AddSuggestionBottomSheet extends ConsumerStatefulWidget {
  final String eventId;
  final DateTime eventStartDate;
  final TimeOfDay eventStartTime;
  final DateTime eventEndDate;
  final TimeOfDay eventEndTime;
  final SuggestionType suggestionType;

  const _AddSuggestionBottomSheet({
    required this.eventId,
    required this.eventStartDate,
    required this.eventStartTime,
    required this.eventEndDate,
    required this.eventEndTime,
    required this.suggestionType,
  });

  @override
  ConsumerState<_AddSuggestionBottomSheet> createState() =>
      _AddSuggestionBottomSheetState();
}

class _AddSuggestionBottomSheetState
    extends ConsumerState<_AddSuggestionBottomSheet>
    with SingleTickerProviderStateMixin {
  late DateTime startDate;
  late TimeOfDay startTime;
  late DateTime endDate;
  late TimeOfDay endTime;

  bool isStartDatePickerExpanded = false;
  bool isStartTimePickerExpanded = false;
  bool isEndDatePickerExpanded = false;
  bool isEndTimePickerExpanded = false;

  // Suggestion type state
  late SuggestionType _selectedType;
  late TabController _tabController;

  // Location fields
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _addressSearchController =
      TextEditingController();
  LocationInfo? _selectedLocation;
  List<LocationInfo> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initialize suggestion type
    _selectedType = widget.suggestionType;
    // Initialize tab controller
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedType == SuggestionType.dateTime ? 0 : 1,
    );
    // Pre-select with event's current date/time
    startDate = widget.eventStartDate;
    startTime = widget.eventStartTime;
    endDate = widget.eventEndDate;
    endTime = widget.eventEndTime;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationNameController.dispose();
    _addressSearchController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return startDate != widget.eventStartDate ||
        startTime != widget.eventStartTime ||
        endDate != widget.eventEndDate ||
        endTime != widget.eventEndTime;
  }

  bool get _isTimeValid {
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    return endDateTime.isAfter(startDateTime);
  }

  String? get _timeValidationError {
    if (!_isTimeValid) {
      return 'End time must be after start time';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.90; // Almost full length
    final createSuggestionState = ref.watch(createSuggestionNotifierProvider);

    return Container(
      height: bottomSheetHeight,
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
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

          const SizedBox(height: Gaps.md),

          // Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
            child: _buildSegmentedControl(),
          ),

          const SizedBox(height: Gaps.lg),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: _selectedType == SuggestionType.dateTime
                ? _buildDateTimeContent()
                : _buildLocationContent(),
          ),
        ),

        // Fixed bottom section
        _buildBottomSection(),
      ],
    );
  }

  Widget _buildDateTimeContent() {
    return Column(
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

        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  Widget _buildLocationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO: Add location fields here
        const Center(child: Text('Location content coming soon...')),
        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  Widget _buildBottomSection() {
    final createSuggestionState = ref.watch(createSuggestionNotifierProvider);

    return Column(
      children: [
        // Error message
        if (_timeValidationError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Pads.ctlH),
            margin: const EdgeInsets.only(bottom: Gaps.sm),
            decoration: BoxDecoration(
              color: BrandColors.cantVote.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(
                color: BrandColors.cantVote.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _timeValidationError!,
              style: AppText.bodyMedium.copyWith(color: BrandColors.cantVote),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        // Submit button - Green when changes are made and valid
        createSuggestionState.when(
          data: (_) => SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _hasChanges && _isTimeValid ? _submitSuggestion : null,
              style: FilledButton.styleFrom(
                backgroundColor: _hasChanges && _isTimeValid
                    ? BrandColors
                          .planning // Green when valid
                    : BrandColors.text1.withValues(alpha: 0.3),
                foregroundColor: _hasChanges && _isTimeValid
                    ? BrandColors
                          .text1 // Green text when enabled
                    : BrandColors.bg1,
                padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
              child: Text('Add Suggestion', style: AppText.bodyMediumEmph),
            ),
          ),
          loading: () => SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.text2,
                foregroundColor: BrandColors.bg1,
                padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
              child: Text('Adding...', style: AppText.bodyMediumEmph),
            ),
          ),
          error: (error, _) => Column(
            children: [
              Text(
                'Error: $error',
                style: AppText.bodyMedium.copyWith(color: Colors.red),
              ),
              const SizedBox(height: Gaps.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _hasChanges && _isTimeValid
                      ? _submitSuggestion
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.planning,
                    foregroundColor: BrandColors.bg1,
                    padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                  child: Text('Try Again', style: AppText.bodyMediumEmph),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: MediaQuery.of(context).padding.bottom + Gaps.md),
      ],
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

  Future<void> _submitSuggestion() async {
    if (!_hasChanges || !_isTimeValid) return;

    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    await ref
        .read(createSuggestionNotifierProvider.notifier)
        .createSuggestion_(
          eventId: widget.eventId,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
        );

    if (mounted) {
      // Show success and close
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suggestion added!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildSegmentedControl() {
    return BottomSheetSegmentedControl(
      controller: _tabController,
      labels: const ['Date & Time', 'Location'],
      margin: EdgeInsets.zero,
      onTap: (index) {
        setState(() {
          _selectedType = index == 0
              ? SuggestionType.dateTime
              : SuggestionType.location;
        });
      },
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

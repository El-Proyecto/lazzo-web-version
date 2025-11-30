import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../shared/components/inputs/segmented_control.dart';
import '../../../../shared/components/common/top_banner.dart';
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
  String? currentEventLocationName,
  String? currentEventAddress,
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
      currentEventLocationName: currentEventLocationName,
      currentEventAddress: currentEventAddress,
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
  final String? currentEventLocationName;
  final String? currentEventAddress;

  const _AddSuggestionBottomSheet({
    required this.eventId,
    required this.eventStartDate,
    required this.eventStartTime,
    required this.eventEndDate,
    required this.eventEndTime,
    required this.suggestionType,
    this.currentEventLocationName,
    this.currentEventAddress,
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
  List<LocationSuggestion> _searchResults = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _searchTimer;
  bool _showValidationError = false;

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
    _searchTimer?.cancel();
    super.dispose();
  }

  bool get _hasChanges {
    if (_selectedType == SuggestionType.dateTime) {
      return startDate != widget.eventStartDate ||
          startTime != widget.eventStartTime ||
          endDate != widget.eventEndDate ||
          endTime != widget.eventEndTime;
    } else {
      // Location type
      return _selectedLocation != null ||
          _locationNameController.text.trim().isNotEmpty ||
          _addressSearchController.text.trim().isNotEmpty;
    }
  }

  bool get _isTimeValid {
    if (_selectedType == SuggestionType.dateTime) {
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
    } else {
      // For location type, we need at least one field filled
      return _selectedLocation != null ||
          _locationNameController.text.trim().isNotEmpty ||
          _addressSearchController.text.trim().isNotEmpty;
    }
  }

  String? get _validationError {
    if (!_showValidationError) return null;

    if (_selectedType == SuggestionType.dateTime) {
      if (!_hasChanges) {
        return 'Please select different dates/times from the original event';
      }
      if (!_isTimeValid) {
        return 'End time must be after start time';
      }
    } else {
      // Location type
      if (!_hasChanges) {
        return 'Please fill at least one location field';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.90; // Almost full length

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
                // Calculate the difference in days between old and new start date
                final daysDifference = date.difference(startDate).inDays;

                // Update start date
                startDate = date;

                // Adjust end date to maintain the same duration
                if (daysDifference != 0) {
                  endDate = endDate.add(Duration(days: daysDifference));
                }

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
    return _buildLocationInput();
  }

  Widget _buildLocationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location name field
        _buildTextField(
          hintText: 'Location name (optional)',
          icon: Icons.edit_location_alt,
          controller: _locationNameController,
          onChanged: (value) {
            if (_showValidationError) {
              setState(() {
                _showValidationError = false;
              });
            }
          },
        ),

        const SizedBox(height: Gaps.sm),

        // Address search field
        _buildTextField(
          hintText: 'Search address or place',
          icon: Icons.search,
          controller: _addressSearchController,
          onChanged: (value) {
            if (_showValidationError) {
              setState(() {
                _showValidationError = false;
              });
            }
            _handleAddressSearch(value);
          },
          onSubmitted: (value) => _handleEnterKeyPressed(),
        ),

        // Suggestions list
        if (_showSuggestions) ...[
          const SizedBox(height: Gaps.sm),
          _buildSuggestionsList(),
        ],

        const SizedBox(height: Gaps.md),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.my_location,
                text: 'Current location',
                onTap: () => _useCurrentLocation(),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: _buildActionButton(
                icon: Icons.map_outlined,
                text: 'Pick on map',
                onTap: () => _pickOnMap(),
              ),
            ),
          ],
        ),

        // Map preview (always visible)
        if (_selectedLocation != null) ...[
          const SizedBox(height: Gaps.md),
          _buildMapPreview(),
        ],

        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  Widget _buildMapPreview() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: BrandColors.border, width: 1),
        color: BrandColors.bg3,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 48, color: BrandColors.text2),
          const SizedBox(height: Gaps.xs),
          Text(
            'Map Preview',
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
          // TODO: P2 - Integrate with Google Maps to show actual location preview
          // TODO: P2 - Add tap functionality to open in external Maps app
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    // Watch the appropriate provider based on suggestion type
    final createSuggestionState = _selectedType == SuggestionType.dateTime
        ? ref.watch(createSuggestionNotifierProvider)
        : ref.watch(createLocationSuggestionNotifierProvider);

    return Column(
      children: [
        // Error message
        if (_validationError != null) ...[
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
              _validationError!,
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
              onPressed: _handleAddSuggestionPressed,
              style: FilledButton.styleFrom(
                backgroundColor: _hasChanges && _isTimeValid
                    ? BrandColors.planning // Green when valid
                    : BrandColors.border,
                foregroundColor: _hasChanges && _isTimeValid
                    ? BrandColors.text1 // Green text when enabled
                    : BrandColors.text2,
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
                  onPressed: _handleAddSuggestionPressed,
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

  void _handleAddSuggestionPressed() {
    // Always show validation errors when button is pressed
    if (!_hasChanges || !_isTimeValid) {
      setState(() {
        _showValidationError = true;
      });
      return;
    }

    // If validation passes, proceed with submission
    _submitSuggestion();
  }

  Future<void> _submitSuggestion() async {
    // This method is called only when validation has already passed
    if (_selectedType == SuggestionType.dateTime) {
      // Handle datetime suggestion
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
    } else {
      // Handle location suggestion
      if (_selectedLocation != null) {
        // Use selected location from search
        await ref
            .read(createLocationSuggestionNotifierProvider.notifier)
            .createLocationSuggestion(
              eventId: widget.eventId,
              locationName:
                  _selectedLocation!.displayName ?? 'Selected Location',
              address: _selectedLocation!.formattedAddress,
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
              currentEventLocationName: widget.currentEventLocationName,
              currentEventAddress: widget.currentEventAddress,
            );
      } else if (_locationNameController.text.trim().isNotEmpty ||
          _addressSearchController.text.trim().isNotEmpty) {
        // Use manually entered location data
        await ref
            .read(createLocationSuggestionNotifierProvider.notifier)
            .createLocationSuggestion(
              eventId: widget.eventId,
              locationName: _locationNameController.text.trim().isNotEmpty
                  ? _locationNameController.text.trim()
                  : 'Custom Location',
              address: _addressSearchController.text.trim().isNotEmpty
                  ? _addressSearchController.text.trim()
                  : null,
              currentEventLocationName: widget.currentEventLocationName,
              currentEventAddress: widget.currentEventAddress,
            );
      }
    }

    if (mounted) {
      // Show success and close
      final suggestionType =
          _selectedType == SuggestionType.dateTime ? 'Date/Time' : 'Location';
      Navigator.of(context).pop();
      TopBanner.showSuccess(
        context,
        message: '$suggestionType suggestion added!',
      );
    }
  }

  // Location helper methods
  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    VoidCallback? onTap,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: Pads.ctlH, right: Gaps.xs),
          child: Icon(icon, color: BrandColors.text2, size: 18),
        ),
        filled: true,
        fillColor: BrandColors.bg3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(
            color: BrandColors.text2.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(
            color: BrandColors.text2.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: BrandColors.planning, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH - 2,
          vertical: Pads.ctlV,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: isSecondary
                ? BrandColors.text2.withValues(alpha: 0.3)
                : BrandColors.planning,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSecondary ? BrandColors.text2 : BrandColors.planning,
              size: 16,
            ),
            const SizedBox(width: Gaps.xs),
            Flexible(
              child: Text(
                text,
                style: AppText.bodyMedium.copyWith(
                  color: isSecondary ? BrandColors.text1 : BrandColors.planning,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: BrandColors.text2.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(BrandColors.text2),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Text(
              'Searching...',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: BrandColors.text2.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No results found',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
            const SizedBox(height: Gaps.xs),
            Text(
              'Try using current location or pick on map',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(
          color: BrandColors.text2.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: _searchResults.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;
          return _buildSuggestionTile(suggestion, index == 0);
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionTile(LocationSuggestion suggestion, bool isTopMatch) {
    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlV),
        child: Row(
          children: [
            Icon(
              isTopMatch ? Icons.star : Icons.location_on,
              color: BrandColors.text2,
              size: 18,
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                      fontWeight:
                          isTopMatch ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (suggestion.address != suggestion.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.address,
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddressSearch(String query) {
    // Cancel previous timer
    _searchTimer?.cancel();

    if (query.length < 3) {
      setState(() {
        _searchResults.clear();
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    // Start new debounce timer
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        await _performGeocodingSearch(query);
      }
    });
  }

  Future<void> _performGeocodingSearch(String query) async {
    try {
      // Use geocoding to search for locations
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      // Reverse geocode each location to get full details
      final results = <LocationSuggestion>[];
      for (var i = 0; i < locations.length && i < 3; i++) {
        final location = locations[i];
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            results.add(LocationSuggestion(
              id: 'geocoded-$i-${DateTime.now().millisecondsSinceEpoch}',
              name: placemark.name ?? query,
              address: _formatAddress(placemark),
              latitude: location.latitude,
              longitude: location.longitude,
            ));
          }
        } catch (e) {
          // Skip this result if reverse geocoding fails
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      // Fallback to mock results if geocoding fails
      if (mounted) {
        setState(() {
          _searchResults = _generateFallbackResults(query);
          _isSearching = false;
        });
      }
    }
  }

  List<LocationSuggestion> _generateFallbackResults(String query) {
    // Fallback results if geocoding fails
    final fallbackLocations = [
      const LocationSuggestion(
        id: 'fallback-1',
        name: 'Café Central',
        address: 'Rua da Betesga, 1200-109 Lisboa',
        latitude: 38.7071,
        longitude: -9.1363,
      ),
      const LocationSuggestion(
        id: 'fallback-2',
        name: 'Restaurante Ramiro',
        address: 'Av. Almirante Reis, 1A, 1150-007 Lisboa',
        latitude: 38.7242,
        longitude: -9.1342,
      ),
      const LocationSuggestion(
        id: 'fallback-3',
        name: 'Miradouro da Senhora do Monte',
        address: 'Largo Monte, 1170-253 Lisboa',
        latitude: 38.7185,
        longitude: -9.1333,
      ),
    ];

    // Filter results based on query
    return fallbackLocations
        .where(
          (location) =>
              location.name.toLowerCase().contains(query.toLowerCase()) ||
              location.address.toLowerCase().contains(query.toLowerCase()),
        )
        .take(3)
        .toList();
  }

  void _handleEnterKeyPressed() {
    final addressText = _addressSearchController.text.trim();

    if (addressText.isEmpty) {
      // Clear location when address field is empty and enter is pressed
      setState(() {
        _selectedLocation = null;
        _showSuggestions = false;
        _searchResults.clear();
        _showValidationError = false;
      });
      return;
    }

    if (_searchResults.isNotEmpty) {
      _selectSuggestion(_searchResults.first);
    } else {
      if (addressText.isNotEmpty) {
        final addressOnlyLocation = LocationInfo(
          id: 'typed-address-${DateTime.now().millisecondsSinceEpoch}',
          displayName: _locationNameController.text.isNotEmpty
              ? _locationNameController.text
              : null,
          formattedAddress: addressText,
          latitude: 38.7223, // Default Lisbon coordinates
          longitude: -9.1393,
        );

        setState(() {
          _selectedLocation = addressOnlyLocation;
          _showSuggestions = false;
          _searchResults.clear();
          _showValidationError = false; // Reset validation error
        });
      }
    }
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    final location = LocationInfo(
      id: suggestion.id,
      displayName: _locationNameController.text.isNotEmpty
          ? _locationNameController.text
          : null,
      formattedAddress: suggestion.address,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
    );

    setState(() {
      _selectedLocation = location;
      _showSuggestions = false;
      _searchResults.clear();
      _showValidationError = false; // Reset validation error
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);

        final currentLocation = LocationInfo(
          id: 'current-location-${DateTime.now().millisecondsSinceEpoch}',
          displayName: _locationNameController.text.isNotEmpty
              ? _locationNameController.text
              : placemark.name ?? 'Current Location',
          formattedAddress: address,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        setState(() {
          _selectedLocation = currentLocation;
          _showSuggestions = false;
          _searchResults.clear();
          _showValidationError = false;
        });
      }
    } catch (e) {
      _showLocationError('Failed to get current location: ${e.toString()}');
    }
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    return parts.join(', ');
  }

  void _showLocationError(String message) {
    if (mounted) {
      TopBanner.showError(
        context,
        message: message,
      );
    }
  }

  void _pickOnMap() {
    // For P1, show dialog about P2 implementation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.bg2,
        title: Text(
          'Pick on Map',
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),
        content: Text(
          'Map picking functionality will be implemented in P2 phase. For now, using default location.',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppText.labelLarge.copyWith(color: BrandColors.text2),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _useCurrentLocation(); // Use default location
            },
            child: Text(
              'Use Default',
              style: AppText.labelLarge.copyWith(color: BrandColors.planning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return BottomSheetSegmentedControl(
      controller: _tabController,
      labels: const ['Date & Time', 'Location'],
      margin: EdgeInsets.zero,
      onTap: (index) {
        setState(() {
          _selectedType =
              index == 0 ? SuggestionType.dateTime : SuggestionType.location;
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

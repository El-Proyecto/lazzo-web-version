import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// iOS-style birthday picker card with wheel interface for day, month, year
/// Includes optional birthday notification checkbox
class IosBirthdayPickerCard extends StatefulWidget {
  final DateTime? birthday;
  final bool isEditing;
  final bool allowNotifications;
  final String? errorMessage;
  final VoidCallback? onEdit;
  final Function(DateTime?)? onSave;
  final VoidCallback? onCancel;
  final Function(bool)? onNotificationChanged;
  final VoidCallback? onRemove;

  const IosBirthdayPickerCard({
    super.key,
    this.birthday,
    this.isEditing = false,
    this.allowNotifications = false,
    this.errorMessage,
    this.onEdit,
    this.onSave,
    this.onCancel,
    this.onNotificationChanged,
    this.onRemove,
  });

  @override
  State<IosBirthdayPickerCard> createState() => _IosBirthdayPickerCardState();
}

class _IosBirthdayPickerCardState extends State<IosBirthdayPickerCard> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  int _selectedDay = 1;
  int _selectedMonth = 1;
  int _selectedYear = 2000;
  bool _allowNotifications = false;

  // Track original values for cancel functionality
  DateTime? _originalBirthday;
  bool _originalAllowNotifications = false;

  // Generate years from 1900 to current year
  late List<int> _years;

  @override
  void initState() {
    super.initState();

    // Only include years up to current year (no future dates)
    final currentYear = DateTime.now().year;
    _years = List.generate(
      currentYear - 1900 + 1,
      (index) => 1900 + index,
    ).reversed.toList();

    // Store original values
    _originalBirthday = widget.birthday;
    _originalAllowNotifications = widget.allowNotifications;

    // Initialize with selected birthday or default values
    if (widget.birthday != null) {
      _selectedDay = widget.birthday!.day;
      _selectedMonth = widget.birthday!.month;
      _selectedYear = widget.birthday!.year;
    } else {
      // Default to current day
      final now = DateTime.now();
      _selectedDay = now.day;
      _selectedMonth = now.month;
      _selectedYear = now.year;
    }

    _allowNotifications = widget.allowNotifications;

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear),
    );
  }

  @override
  void didUpdateWidget(IosBirthdayPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When entering edit mode, capture the original values
    if (widget.isEditing && !oldWidget.isEditing) {
      _originalBirthday = widget.birthday;
      _originalAllowNotifications = widget.allowNotifications;

      // Reset picker to current values
      if (widget.birthday != null) {
        _selectedDay = widget.birthday!.day;
        _selectedMonth = widget.birthday!.month;
        _selectedYear = widget.birthday!.year;
      }
      _allowNotifications = widget.allowNotifications;

      // Update controllers
      _dayController.animateToItem(
        _selectedDay - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
      _monthController.animateToItem(
        _selectedMonth - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
      _yearController.animateToItem(
        _years.indexOf(_selectedYear),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBirthday = widget.birthday != null;
    final showEmptyState = !hasBirthday && !widget.isEditing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.ctlH,
            vertical: Pads.ctlV,
          ),
          decoration: ShapeDecoration(
            color: showEmptyState ? BrandColors.bg3 : BrandColors.bg2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              side: widget.errorMessage != null
                  ? const BorderSide(color: BrandColors.cantVote, width: 1)
                  : BorderSide.none,
            ),
          ),
          child: widget.isEditing ? _buildEditMode() : _buildViewMode(),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: Gaps.xxs),
          Padding(
            padding: const EdgeInsets.only(left: Pads.ctlH),
            child: Text(
              widget.errorMessage!,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.cantVote,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildViewMode() {
    final hasBirthday = widget.birthday != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Label
        Text(
          'Birthday',
          style: AppText.bodyMediumEmph.copyWith(
            color: BrandColors.text1,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Right side: Value and actions
        Row(
          children: [
            GestureDetector(
              onTap: widget.onEdit,
              child: Row(
                children: [
                  Text(
                    hasBirthday ? _formatDate(widget.birthday!) : 'Tap to add',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: Gaps.xs),
                  Icon(
                    hasBirthday ? Icons.edit_outlined : Icons.add,
                    size: 16,
                    color: BrandColors.text2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with label and action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Birthday',
              style: AppText.bodyMediumEmph.copyWith(
                color: BrandColors.text1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildEditingActions(),
          ],
        ),

        const SizedBox(height: Gaps.md),
        _buildDatePicker(),
        const SizedBox(height: Gaps.md),
        _buildNotificationCheckbox(),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: Pads.ctlH, vertical: Pads.ctlV),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.smAlt),
      ),
      child: Row(
        children: [
          // Day picker
          Expanded(
            child: _buildWheelPicker(
              controller: _dayController,
              itemCount: _getMaxDaysForCurrentSelection(),
              selectedValue: _selectedDay,
              onSelectedItemChanged: (index) {
                final newDay = index + 1;
                final newDate = DateTime(_selectedYear, _selectedMonth, newDay);
                final now = DateTime.now();

                // Prevent selecting future dates
                if (newDate.isAfter(now)) {
                  return;
                }

                setState(() {
                  _selectedDay = newDay;
                });
              },
              formatter: (value) => (value + 1).toString().padLeft(2, '0'),
            ),
          ),

          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.xs),
            child: Text(
              '/',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text2,
                fontSize: 20,
              ),
            ),
          ),

          // Month picker
          Expanded(
            child: _buildWheelPicker(
              controller: _monthController,
              itemCount: _getMaxMonthsForCurrentSelection(),
              selectedValue: _selectedMonth,
              onSelectedItemChanged: (index) {
                final newMonth = index + 1;
                final now = DateTime.now();

                // Prevent selecting future months
                if (_selectedYear == now.year && newMonth > now.month) {
                  return;
                }

                setState(() {
                  _selectedMonth = newMonth;
                  // Adjust day if it's invalid for the new month or would be in future
                  final maxDays = _getMaxDaysForMonth(newMonth, _selectedYear);
                  if (_selectedDay > maxDays) {
                    _selectedDay = maxDays;
                    _dayController.animateToItem(
                      _selectedDay - 1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
              formatter: (value) => _getMonthName(value + 1),
            ),
          ),

          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.xs),
            child: Text(
              '/',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text2,
                fontSize: 20,
              ),
            ),
          ),

          // Year picker
          Expanded(
            child: _buildWheelPicker(
              controller: _yearController,
              itemCount: _years.length,
              selectedValue: _selectedYear,
              onSelectedItemChanged: (index) {
                final newYear = _years[index];
                final now = DateTime.now();

                // Prevent selecting future years
                if (newYear > now.year) {
                  return;
                }

                setState(() {
                  _selectedYear = newYear;

                  // If current year, adjust month if needed
                  if (_selectedYear == now.year && _selectedMonth > now.month) {
                    _selectedMonth = now.month;
                    _monthController.animateToItem(
                      _selectedMonth - 1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }

                  // Adjust day if it's invalid for the new year or would be in future
                  final maxDays = _getMaxDaysForMonth(
                    _selectedMonth,
                    _selectedYear,
                  );
                  if (_selectedDay > maxDays) {
                    _selectedDay = maxDays;
                    _dayController.animateToItem(
                      _selectedDay - 1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
              formatter: (value) => _years[value].toString(),
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
    );
  }

  Widget _buildNotificationCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _allowNotifications = !_allowNotifications;
            });
            widget.onNotificationChanged?.call(_allowNotifications);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _allowNotifications
                        ? BrandColors.planning
                        : BrandColors.text2,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: _allowNotifications
                      ? BrandColors.planning
                      : Colors.transparent,
                ),
                child: _allowNotifications
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: Gaps.xs),
              Text(
                'Let friends get notified on my birthday',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditingActions() {
    return Row(
      children: [
        // Remove button (only show if there's a birthday to remove)
        if (widget.onRemove != null && widget.birthday != null) ...[
          GestureDetector(
            onTap: () {
              // Auto-save the removal
              widget.onRemove?.call();
            },
            child: Container(
              width: 28, // Square shape, same height as Cancel/Save
              height: 28,
              decoration: ShapeDecoration(
                color: BrandColors.bg3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 16,
                color: BrandColors.cantVote,
              ),
            ),
          ),
          const SizedBox(width: Gaps.xs),
        ],

        // Cancel button
        GestureDetector(
          onTap: () {
            // Restore original values
            if (_originalBirthday != null) {
              setState(() {
                _selectedDay = _originalBirthday!.day;
                _selectedMonth = _originalBirthday!.month;
                _selectedYear = _originalBirthday!.year;
                _allowNotifications = _originalAllowNotifications;
              });

              // Update controllers
              _dayController.animateToItem(
                _selectedDay - 1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
              _monthController.animateToItem(
                _selectedMonth - 1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
              _yearController.animateToItem(
                _years.indexOf(_selectedYear),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
            }
            widget.onCancel?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gaps.xs + 1,
              vertical: Gaps.xxs - 1,
            ),
            decoration: ShapeDecoration(
              color: BrandColors.bg3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppText.bodyMediumEmph.copyWith(
                color: BrandColors.text2,
                fontSize: 14,
              ),
            ),
          ),
        ),

        const SizedBox(width: Gaps.xs),

        // Save button
        GestureDetector(
          onTap: () {
            final selectedDate = DateTime(
              _selectedYear,
              _selectedMonth,
              _selectedDay,
            );
            widget.onSave?.call(selectedDate);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gaps.sm - 1,
              vertical: Gaps.xxs - 1,
            ),
            decoration: ShapeDecoration(
              color: BrandColors.planning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
            child: Text(
              'Save',
              style: AppText.bodyMediumEmph.copyWith(
                color: BrandColors.text1,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${_getMonthName(date.month)}/${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  int _getDaysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  int _getMaxDaysForCurrentSelection() {
    final now = DateTime.now();

    // If current year and month, limit to current day
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return now.day;
    }

    // Otherwise return max days in the month
    return _getDaysInMonth(_selectedMonth, _selectedYear);
  }

  int _getMaxMonthsForCurrentSelection() {
    final now = DateTime.now();

    // If current year, limit to current month
    if (_selectedYear == now.year) {
      return now.month;
    }

    // Otherwise return all 12 months
    return 12;
  }

  int _getMaxDaysForMonth(int month, int year) {
    final now = DateTime.now();

    // If current year and month, limit to current day
    if (year == now.year && month == now.month) {
      return now.day;
    }

    // Otherwise return max days in the month
    return DateTime(year, month + 1, 0).day;
  }
}

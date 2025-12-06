import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Birthday picker bottom sheet with iOS-style wheel interface
/// Includes optional notification checkbox for letting friends know about birthday
class BirthdayPickerBottomSheet extends StatefulWidget {
  final DateTime? initialDate;
  final bool allowNotifications;
  final Function(DateTime, bool) onSave;

  const BirthdayPickerBottomSheet({
    super.key,
    this.initialDate,
    this.allowNotifications = false,
    required this.onSave,
  });

  /// Show the bottom sheet and return selected date and notification preference
  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    DateTime? initialDate,
    bool allowNotifications = false,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BirthdayPickerBottomSheet(
        initialDate: initialDate,
        allowNotifications: allowNotifications,
        onSave: (date, notify) {
          Navigator.of(context).pop({
            'date': date,
            'allowNotifications': notify,
          });
        },
      ),
    );
  }

  @override
  State<BirthdayPickerBottomSheet> createState() =>
      _BirthdayPickerBottomSheetState();
}

class _BirthdayPickerBottomSheetState extends State<BirthdayPickerBottomSheet> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;
  late bool _allowNotifications;
  late List<int> _years;

  // Track original values to detect changes
  late DateTime? _originalDate;
  late bool _originalAllowNotifications;

  @override
  void initState() {
    super.initState();

    // Generate years from 1900 to current year
    final currentYear = DateTime.now().year;
    _years = List.generate(
      currentYear - 1900 + 1,
      (index) => 1900 + index,
    ).reversed.toList();

    // Initialize with selected birthday or default values
    if (widget.initialDate != null) {
      _selectedDay = widget.initialDate!.day;
      _selectedMonth = widget.initialDate!.month;
      _selectedYear = widget.initialDate!.year;
    } else {
      // Default to 18 years ago
      final defaultDate =
          DateTime.now().subtract(const Duration(days: 365 * 18));
      _selectedDay = defaultDate.day;
      _selectedMonth = defaultDate.month;
      _selectedYear = defaultDate.year;
    }

    _allowNotifications = widget.allowNotifications;

    // Store original values
    _originalDate = widget.initialDate;
    _originalAllowNotifications = widget.allowNotifications;

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController =
        FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController =
        FixedExtentScrollController(initialItem: _years.indexOf(_selectedYear));
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
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: Gaps.lg,
          right: Gaps.lg,
          top: Gaps.lg,
          bottom: Gaps.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Birthday',
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.md),

            // Date picker
            _buildDatePicker(),
            const SizedBox(height: Gaps.md),

            // Notification checkbox
            _buildNotificationCheckbox(),
            const SizedBox(height: Gaps.lg),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: BrandColors.bg3,
                      padding: const EdgeInsets.symmetric(
                        vertical: Pads.ctlVSm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppText.labelLarge.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Gaps.sm),

                // Remove button (only show if there's an existing birthday)
                if (widget.initialDate != null) ...[
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop({'remove': true}),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: BrandColors.bg3,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: BrandColors.cantVote,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gaps.sm),
                ],

                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasChanges()
                          ? BrandColors.planning
                          : BrandColors.bg3,
                      padding: const EdgeInsets.symmetric(
                        vertical: Pads.ctlVSm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: AppText.labelLarge.copyWith(
                        color: _hasChanges()
                            ? BrandColors.text1
                            : BrandColors.text2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH,
        vertical: Pads.ctlV,
      ),
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
              onSelectedItemChanged: (index) {
                final newDay = index + 1;
                final newDate = DateTime(_selectedYear, _selectedMonth, newDay);
                final now = DateTime.now();

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
              onSelectedItemChanged: (index) {
                final newMonth = index + 1;
                final now = DateTime.now();

                if (_selectedYear == now.year && newMonth > now.month) {
                  return;
                }

                setState(() {
                  _selectedMonth = newMonth;
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
              onSelectedItemChanged: (index) {
                final newYear = _years[index];
                final now = DateTime.now();

                if (newYear > now.year) {
                  return;
                }

                setState(() {
                  _selectedYear = newYear;

                  if (_selectedYear == now.year && _selectedMonth > now.month) {
                    _selectedMonth = now.month;
                    _monthController.animateToItem(
                      _selectedMonth - 1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }

                  final maxDays =
                      _getMaxDaysForMonth(_selectedMonth, _selectedYear);
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _allowNotifications = !_allowNotifications;
        });
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
    );
  }

  bool _hasChanges() {
    final currentDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);

    // Check if date changed
    if (_originalDate == null) {
      return true; // Adding a new date is always a change
    }

    if (currentDate.year != _originalDate!.year ||
        currentDate.month != _originalDate!.month ||
        currentDate.day != _originalDate!.day) {
      return true;
    }

    // Check if notification preference changed
    if (_allowNotifications != _originalAllowNotifications) {
      return true;
    }

    return false;
  }

  void _handleSave() {
    // Only proceed if there are changes
    if (!_hasChanges()) {
      return; // Stay on bottom sheet, don't close
    }

    // Has changes - save and close
    final selectedDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    widget.onSave(selectedDate, _allowNotifications);
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
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return now.day;
    }
    return _getDaysInMonth(_selectedMonth, _selectedYear);
  }

  int _getMaxMonthsForCurrentSelection() {
    final now = DateTime.now();
    if (_selectedYear == now.year) {
      return now.month;
    }
    return 12;
  }

  int _getMaxDaysForMonth(int month, int year) {
    final now = DateTime.now();
    if (year == now.year && month == now.month) {
      return now.day;
    }
    return DateTime(year, month + 1, 0).day;
  }
}

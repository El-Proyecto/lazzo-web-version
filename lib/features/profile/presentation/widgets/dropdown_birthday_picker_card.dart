import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Dropdown birthday picker card with day/month/year selection
/// Shows view/edit states with dropdown selectors
class DropdownBirthdayPickerCard extends StatefulWidget {
  final DateTime? birthday;
  final bool isEditing;
  final bool showNotificationCheckbox;
  final bool allowNotifications;
  final Function(DateTime?)? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final Function(bool)? onNotificationToggle;

  const DropdownBirthdayPickerCard({
    super.key,
    this.birthday,
    this.isEditing = false,
    this.showNotificationCheckbox = false,
    this.allowNotifications = false,
    this.onSave,
    this.onCancel,
    this.onEdit,
    this.onNotificationToggle,
  });

  @override
  State<DropdownBirthdayPickerCard> createState() =>
      _DropdownBirthdayPickerCardState();
}

class _DropdownBirthdayPickerCardState
    extends State<DropdownBirthdayPickerCard> {
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;
  bool _allowNotifications = false;

  @override
  void initState() {
    super.initState();
    if (widget.birthday != null) {
      _selectedDay = widget.birthday!.day;
      _selectedMonth = widget.birthday!.month;
      _selectedYear = widget.birthday!.year;
    }
    _allowNotifications = widget.allowNotifications;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.birthday != null;
    final showEmptyState = !hasValue && !widget.isEditing;

    return Column(
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
            ),
          ),
          child: widget.isEditing ? _buildEditMode() : _buildViewMode(),
        ),

        // Show notification checkbox when birthday is set
        if (widget.showNotificationCheckbox && hasValue) ...[
          const SizedBox(height: Gaps.sm),
          _buildNotificationCheckbox(),
        ],
      ],
    );
  }

  Widget _buildViewMode() {
    final hasValue = widget.birthday != null;

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

        // Right side: Value and edit action
        GestureDetector(
          onTap: widget.onEdit,
          child: Row(
            children: [
              Text(
                hasValue ? _formatBirthday(widget.birthday!) : 'Tap to add',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: Gaps.xs),
              Icon(
                hasValue ? Icons.edit_outlined : Icons.add,
                size: 16,
                color: BrandColors.text2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with label and action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Birthday',
              style: AppText.bodyMediumEmph.copyWith(color: BrandColors.text1),
            ),
            _buildEditingActions(),
          ],
        ),

        const SizedBox(height: Gaps.md),

        // Dropdown selectors
        _buildDropdownSelectors(),
      ],
    );
  }

  Widget _buildDropdownSelectors() {
    return Row(
      children: [
        // Day dropdown
        Expanded(
          child: _buildDropdown(
            value: _selectedDay,
            hint: 'Day',
            items: List.generate(31, (index) => index + 1),
            onChanged: (value) => setState(() => _selectedDay = value),
          ),
        ),

        const SizedBox(width: Gaps.sm),

        // Month dropdown
        Expanded(
          child: _buildDropdown(
            value: _selectedMonth,
            hint: 'Month',
            items: List.generate(12, (index) => index + 1),
            onChanged: (value) => setState(() => _selectedMonth = value),
            itemBuilder: (value) => _getMonthName(value),
          ),
        ),

        const SizedBox(width: Gaps.sm),

        // Year dropdown
        Expanded(
          child: _buildDropdown(
            value: _selectedYear,
            hint: 'Year',
            items: List.generate(100, (index) => DateTime.now().year - index),
            onChanged: (value) => setState(() => _selectedYear = value),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required int? value,
    required String hint,
    required List<int> items,
    required Function(int?) onChanged,
    String Function(int)? itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH - 2,
        vertical: Pads.ctlV - 2,
      ),
      decoration: ShapeDecoration(
        color: BrandColors.bg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          hint: Text(
            hint,
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
          dropdownColor: BrandColors.bg3,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: BrandColors.text2,
            size: 20,
          ),
          isExpanded: true,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item,
              child: Text(
                itemBuilder != null ? itemBuilder(item) : item.toString(),
                style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEditingActions() {
    return Row(
      children: [
        // Cancel button
        GestureDetector(
          onTap: widget.onCancel,
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
          onTap: _handleSave,
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

  Widget _buildNotificationCheckbox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH,
        vertical: Pads.ctlV,
      ),
      decoration: ShapeDecoration(
        color: BrandColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _allowNotifications,
            onChanged: (value) {
              setState(() => _allowNotifications = value ?? false);
              widget.onNotificationToggle?.call(_allowNotifications);
            },
            activeColor: BrandColors.planning,
            checkColor: BrandColors.text1,
            side: const BorderSide(color: BrandColors.border, width: 1),
          ),
          const SizedBox(width: Gaps.sm),
          Expanded(
            child: Text(
              'Let friends get notified on my birthday',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    if (_selectedDay != null &&
        _selectedMonth != null &&
        _selectedYear != null) {
      try {
        final birthday = DateTime(
          _selectedYear!,
          _selectedMonth!,
          _selectedDay!,
        );
        widget.onSave?.call(birthday);
      } catch (e) {
        // Invalid date combination, don't save
      }
    } else {
      // Clear birthday if incomplete selection
      widget.onSave?.call(null);
    }
  }

  String _formatBirthday(DateTime birthday) {
    return '${_getMonthName(birthday.month)} ${birthday.day}, ${birthday.year}';
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}

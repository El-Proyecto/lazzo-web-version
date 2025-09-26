import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../forms/inline_date_picker.dart';

/// Tokenized birthday picker card
/// Shows view/edit states with integrated date picker
class BirthdayPickerCard extends StatefulWidget {
  final DateTime? birthday;
  final bool isEditing;
  final Function(DateTime?)? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;

  const BirthdayPickerCard({
    super.key,
    this.birthday,
    this.isEditing = false,
    this.onSave,
    this.onCancel,
    this.onEdit,
  });

  @override
  State<BirthdayPickerCard> createState() => _BirthdayPickerCardState();
}

class _BirthdayPickerCardState extends State<BirthdayPickerCard> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.birthday;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.birthday != null;
    final showEmptyState = !hasValue && !widget.isEditing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.ctlH),
      decoration: ShapeDecoration(
        color: showEmptyState ? BrandColors.bg3 : BrandColors.bg2,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: BrandColors.border),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Birthday',
                style: AppText.bodyMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),

              // Action buttons
              if (widget.isEditing)
                _buildEditingActions()
              else if (hasValue)
                _buildViewActions(),
            ],
          ),

          const SizedBox(height: Gaps.md),

          // Content
          if (widget.isEditing)
            _buildDatePicker()
          else if (showEmptyState)
            _buildEmptyState()
          else
            _buildViewContent(),
        ],
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
          onTap: () => widget.onSave?.call(_selectedDate),
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

  Widget _buildViewActions() {
    return GestureDetector(
      onTap: widget.onEdit,
      child: const Icon(Icons.edit_outlined, size: 20, color: BrandColors.text2),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.ctlH),
      decoration: ShapeDecoration(
        color: BrandColors.bg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
      ),
      child: InlineDatePicker(
        selectedDate:
            _selectedDate ??
            DateTime.now().subtract(
              const Duration(days: 365 * 25),
            ), // Default to 25 years ago
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: widget.onEdit,
      child: Text(
        'Tap to add',
        style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
      ),
    );
  }

  Widget _buildViewContent() {
    if (widget.birthday == null) return const SizedBox.shrink();

    final birthday = widget.birthday!;
    final formatted =
        '${_getMonthName(birthday.month)} ${birthday.day}, ${birthday.year}';

    return Text(
      formatted,
      style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
    );
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

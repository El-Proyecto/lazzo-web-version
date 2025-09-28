import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Tokenized editable info card for profile information
/// Shows view/edit states with save/cancel actions
class EditableInfoCard extends StatefulWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool isRequired;
  final bool isEditing;
  final String? errorMessage;
  final Function(String)? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final TextInputType? keyboardType;
  final int? maxLines;

  const EditableInfoCard({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    this.isRequired = false,
    this.isEditing = false,
    this.errorMessage,
    this.onSave,
    this.onCancel,
    this.onEdit,
    this.onRemove,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  State<EditableInfoCard> createState() => _EditableInfoCardState();
}

class _EditableInfoCardState extends State<EditableInfoCard> {
  late TextEditingController _controller;
  String? _originalValue; // Track original value to restore on cancel

  @override
  void initState() {
    super.initState();
    _originalValue = widget.value;
    _controller = TextEditingController(text: widget.value ?? '');
    _controller.addListener(() {
      setState(() {}); // Rebuild to show/hide clear button
    });
  }

  @override
  void didUpdateWidget(EditableInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When entering edit mode, capture the original value
    if (widget.isEditing && !oldWidget.isEditing) {
      _originalValue = widget.value;
      _controller.text = widget.value ?? '';
    }
    // Reset text field to actual saved value when value changes
    else if (widget.value != oldWidget.value) {
      _originalValue = widget.value;
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.value!.isNotEmpty;
    final showEmptyState = !hasValue && !widget.isEditing;

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
    final hasValue = widget.value != null && widget.value!.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Label with required indicator
        Row(
          children: [
            Text(
              widget.label,
              style: AppText.bodyMediumEmph.copyWith(
                color: BrandColors.text1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: Gaps.xs),
              Text(
                '*',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.cantVote,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),

        // Right side: Value and actions
        Row(
          children: [
            GestureDetector(
              onTap: widget.onEdit,
              child: Row(
                children: [
                  Text(
                    hasValue ? widget.value! : 'Tap to add',
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
            // Label with required indicator
            Row(
              children: [
                Text(
                  widget.label,
                  style: AppText.bodyMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
                if (widget.isRequired) ...[
                  const SizedBox(width: Gaps.xs),
                  Text(
                    '*',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.cantVote,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),

            // Action buttons
            _buildEditingActions(),
          ],
        ),

        const SizedBox(height: Gaps.md),

        // Edit field
        _buildEditField(),
      ],
    );
  }

  Widget _buildEditingActions() {
    return Row(
      children: [
        // Remove button (only show if there's a value to remove)
        if (widget.onRemove != null &&
            widget.value != null &&
            widget.value!.isNotEmpty) ...[
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
            // Restore original value on cancel
            _controller.text = _originalValue ?? '';
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
            widget.onSave?.call(_controller.text);
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

  Widget _buildEditField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH - 2,
        vertical: Pads.ctlV,
      ),
      decoration: ShapeDecoration(
        color: BrandColors.bg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

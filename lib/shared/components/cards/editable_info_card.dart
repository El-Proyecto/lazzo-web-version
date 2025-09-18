import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Tokenized editable info card for profile information
/// Shows view/edit states with save/cancel actions
class EditableInfoCard extends StatefulWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool isRequired;
  final bool isEditing;
  final Function(String)? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final TextInputType? keyboardType;
  final int? maxLines;

  const EditableInfoCard({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    this.isRequired = false,
    this.isEditing = false,
    this.onSave,
    this.onCancel,
    this.onEdit,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  State<EditableInfoCard> createState() => _EditableInfoCardState();
}

class _EditableInfoCardState extends State<EditableInfoCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Pads.ctlH),
      decoration: ShapeDecoration(
        color: showEmptyState ? BrandColors.bg3 : BrandColors.bg2,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: BrandColors.border),
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
                    SizedBox(width: 4),
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
              if (widget.isEditing)
                _buildEditingActions()
              else if (hasValue)
                _buildViewActions(),
            ],
          ),

          SizedBox(height: Gaps.md),

          // Content
          if (widget.isEditing)
            _buildEditField()
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
            padding: EdgeInsets.symmetric(
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

        SizedBox(width: Gaps.xs),

        // Save button
        GestureDetector(
          onTap: () => widget.onSave?.call(_controller.text),
          child: Container(
            padding: EdgeInsets.symmetric(
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
      child: Icon(Icons.edit_outlined, size: 20, color: BrandColors.text2),
    );
  }

  Widget _buildEditField() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
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
    return Text(
      widget.value ?? '',
      style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
    );
  }
}

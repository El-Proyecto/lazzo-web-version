import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Generic bottom sheet for editing text fields
/// Reusable component following shared components guidelines
class EditFieldBottomSheet extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String placeholder;
  final bool isRequired;
  final ValueChanged<String> onSave;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String)? validator;

  const EditFieldBottomSheet({
    super.key,
    required this.title,
    this.initialValue,
    required this.placeholder,
    this.isRequired = false,
    required this.onSave,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  /// Show the bottom sheet and return the edited value
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? initialValue,
    required String placeholder,
    bool isRequired = false,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? maxLength,
    String? Function(String)? validator,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditFieldBottomSheet(
        title: title,
        initialValue: initialValue,
        placeholder: placeholder,
        isRequired: isRequired,
        onSave: (value) {
          Navigator.of(context).pop(value);
        },
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
      ),
    );
  }

  @override
  State<EditFieldBottomSheet> createState() => _EditFieldBottomSheetState();
}

class _EditFieldBottomSheetState extends State<EditFieldBottomSheet> {
  late TextEditingController _controller;
  String? _errorMessage;
  bool _saveAttempted = false;
  late String _initialValue;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.initialValue ?? '';
    _controller = TextEditingController(text: _initialValue);

    // Listen for changes to update button state and clear errors
    _controller.addListener(() {
      setState(() {
        if (_saveAttempted && _controller.text.trim().isNotEmpty) {
          _errorMessage = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateInput(String value) {
    if (widget.isRequired && value.trim().isEmpty) {
      return '${widget.title} is required';
    }
    if (widget.validator != null) {
      return widget.validator!(value);
    }
    return null;
  }

  bool _hasChanges() {
    final currentValue = _controller.text.trim();
    final originalValue = _initialValue.trim();
    return currentValue != originalValue;
  }

  bool _isFormValid() {
    // Valid if: has changes AND (not required OR not empty)
    if (!_hasChanges()) return false;
    if (widget.isRequired && _controller.text.trim().isEmpty) return false;
    if (widget.validator != null) {
      return widget.validator!(_controller.text) == null;
    }
    return true;
  }

  void _handleSave() {
    // Don't proceed if form is invalid (no changes or validation failed)
    if (!_isFormValid()) {
      setState(() {
        _saveAttempted = true;
        _errorMessage = _validateInput(_controller.text);
        // If no validation error but no changes, show specific message
        if (_errorMessage == null && !_hasChanges()) {
          _errorMessage = 'No changes made';
        }
      });
      return; // Stay on bottom sheet, don't close
    }

    // Form is valid - save and close
    widget.onSave(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: keyboardHeight > 0 ? maxHeight : screenHeight * 0.4,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: Gaps.lg,
          right: Gaps.lg,
          top: Gaps.lg,
          bottom: Gaps.lg + keyboardHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              widget.title,
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.md),

            // Text field
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              style: AppText.bodyLarge.copyWith(color: BrandColors.text1),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: AppText.bodyLarge.copyWith(color: BrandColors.text2),
                filled: true,
                fillColor: BrandColors.bg3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.smAlt),
                  borderSide: BorderSide.none,
                ),
                errorText: _errorMessage,
                errorStyle: AppText.bodyMedium.copyWith(color: Colors.red),
                counterStyle:
                    AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
            ),
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
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid()
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
                        color: _isFormValid()
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
}

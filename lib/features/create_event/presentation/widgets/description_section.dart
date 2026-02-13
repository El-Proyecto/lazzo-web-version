import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Section for event details input
/// Multi-line text area with character counter
class DescriptionSection extends StatefulWidget {
  final String? description;
  final ValueChanged<String?>? onDescriptionChanged;
  final int maxLength;

  const DescriptionSection({
    super.key,
    this.description,
    this.onDescriptionChanged,
    this.maxLength = 500,
  });

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.description ?? '');
  }

  @override
  void didUpdateWidget(DescriptionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the description changed externally
    if (widget.description != oldWidget.description &&
        widget.description != _controller.text) {
      _controller.text = widget.description ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.screenH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Details',
            style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
          ),
          const SizedBox(height: Gaps.md),

          // Text area
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 2,
            maxLength: widget.maxLength,
            onChanged: (value) {
              final trimmed = value.trim();
              widget.onDescriptionChanged
                  ?.call(trimmed.isEmpty ? null : trimmed);
            },
            style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
            decoration: InputDecoration(
              hintText: 'Add details for your event...',
              hintStyle: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              filled: true,
              fillColor: BrandColors.bg3,
              counterStyle:
                  AppText.labelLarge.copyWith(color: BrandColors.text2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.sm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(Gaps.md),
            ),
          ),
        ],
      ),
    );
  }
}

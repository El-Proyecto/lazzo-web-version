import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Simple bottom sheet for selecting from a list of options
/// Used for single-choice selections like categories, languages, etc.
class SimpleSelectionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onSelected;

  const SimpleSelectionSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onSelected,
  });

  /// Show a simple selection sheet
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    String? selectedOption,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SimpleSelectionSheet(
        title: title,
        options: options,
        selectedOption: selectedOption,
        onSelected: (value) {
          Navigator.of(context).pop(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(Pads.sectionH),
            child: Text(
              title,
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
            ),
          ),

          const SizedBox(height: Gaps.xs),

          // Options list (no scroll, shows all options)
          Padding(
            padding: const EdgeInsets.only(
              left: Pads.sectionH,
              right: Pads.sectionH,
              bottom: Pads.sectionH,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = option == selectedOption;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < options.length - 1 ? Gaps.xs : 0,
                  ),
                  child: InkWell(
                    onTap: () => onSelected(option),
                    borderRadius: BorderRadius.circular(Radii.smAlt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Pads.ctlH,
                        vertical: Pads.ctlV,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.bg3,
                        borderRadius: BorderRadius.circular(Radii.smAlt),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: AppText.bodyLarge.copyWith(
                                color: BrandColors.text1,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + Gaps.md),
        ],
      ),
    );
  }
}

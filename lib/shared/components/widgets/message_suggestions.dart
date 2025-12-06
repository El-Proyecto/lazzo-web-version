import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Suggested message bubble for empty chat state
/// Shows suggestions like "Where should we meet?" to kickstart conversations
class MessageSuggestionBubble extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const MessageSuggestionBubble({
    super.key,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Gaps.sm,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: BrandColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: Gaps.xs),
            const Icon(
              Icons.arrow_forward,
              size: IconSizes.sm,
              color: BrandColors.text2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Container for message suggestions shown in empty chat state
class MessageSuggestionsList extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const MessageSuggestionsList({
    super.key,
    required this.onSuggestionTap,
  });

  static const List<String> suggestions = [
    'Where should we meet?',
    'Who needs a ride?',
    'Anyone knows the dress code?',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Gaps.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start the conversation',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: Gaps.sm),
          Wrap(
            spacing: Gaps.sm,
            runSpacing: Gaps.sm,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: suggestions
                .map(
                  (suggestion) => MessageSuggestionBubble(
                    message: suggestion,
                    onTap: () => onSuggestionTap(suggestion),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

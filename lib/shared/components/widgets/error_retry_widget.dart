import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';
import '../../constants/text_styles.dart';

/// A compact error widget with an optional retry button.
///
/// Use this instead of `SizedBox.shrink()` in `.when(error:)` blocks
/// so users see feedback and can retry.
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorRetryWidget({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.screenH,
        vertical: Gaps.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: BrandColors.text2.withValues(alpha: 0.6),
            size: 32,
          ),
          const SizedBox(height: Gaps.xs),
          Text(
            message,
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: Gaps.sm),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: BrandColors.planning,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

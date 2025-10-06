import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../widgets/grabber_bar.dart';

/// Generic bottom sheet dialog component for consistent dialog UI across the app
/// Use this for standard dialogs that need confirmation, selection, or input
class CommonBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final bool showGrabber;
  final EdgeInsetsGeometry? contentPadding;
  final double? maxHeight;

  const CommonBottomSheet({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.onClose,
    this.showGrabber = true,
    this.contentPadding,
    this.maxHeight,
  });

  /// Show a common bottom sheet with consistent styling
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    VoidCallback? onClose,
    bool showGrabber = true,
    EdgeInsetsGeometry? contentPadding,
    double? maxHeight,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommonBottomSheet(
        title: title,
        content: content,
        actions: actions,
        onClose: onClose,
        showGrabber: showGrabber,
        contentPadding: contentPadding,
        maxHeight: maxHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.bg1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showGrabber) ...[
            const Padding(
              padding: EdgeInsets.only(top: Gaps.sm),
              child: Center(child: GrabberBar()),
            ),
          ],

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    color: BrandColors.text2,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding:
                  contentPadding ??
                  const EdgeInsets.only(
                    left: Gaps.lg,
                    right: Gaps.lg,
                    bottom: Gaps.lg,
                  ),
              child: content,
            ),
          ),

          // Actions
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: Gaps.md),
            Padding(
              padding: contentPadding ?? const EdgeInsets.all(Pads.sectionH),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions!
                    .map(
                      (action) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Gaps.xs,
                          ),
                          child: action,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Simple confirmation dialog with title, message and two actions
class CommonConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;

  const CommonConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText = 'Cancelar',
    this.onCancel,
    this.confirmColor,
  });

  /// Show a confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
    String cancelText = 'Cancelar',
    VoidCallback? onCancel,
    Color? confirmColor,
  }) {
    return CommonBottomSheet.show<bool>(
      context: context,
      title: title,
      content: CommonConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        onConfirm: onConfirm,
        cancelText: cancelText,
        onCancel: onCancel,
        confirmColor: confirmColor,
      ),
      showGrabber: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: Gaps.lg),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  onCancel?.call();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: BrandColors.border),
                ),
                child: Text(
                  cancelText,
                  style: AppText.labelLarge.copyWith(color: BrandColors.text2),
                ),
              ),
            ),

            const SizedBox(width: Gaps.md),

            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      confirmColor ?? Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  confirmText,
                  style: AppText.labelLarge.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

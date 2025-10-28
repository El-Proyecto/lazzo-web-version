import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Memory Viewer AppBar with title/subtitle and play preview icon
/// Similar to event_chat AppBar but with different actions
class MemoryViewerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBackPressed;

  const MemoryViewerAppBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: BrandColors.bg1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main AppBar row (back + title + play preview)
            Padding(
              padding: const EdgeInsets.only(
                left: Insets.screenH,
                right: Insets.screenH,
                top: 12,
              ),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: onBackPressed,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: BrandColors.text1,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: Gaps.sm),

                    // Title (centered)
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.titleMediumEmph.copyWith(
                          color: BrandColors.text1,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(width: Gaps.sm),

                  ],
                ),
              ),
            ),

            // Subtitle (optional)
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: Insets.screenH,
                  right: Insets.screenH,
                  bottom: Gaps.xs,
                ),
                child: Text(
                  subtitle!,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    // Calculate dynamic height based on content
    double height = 44; // Base: 12 top padding + 32 row height

    if (subtitle != null) {
      height += 8 + 20; // 8px gap (Gaps.xs) + text height
    }

    return Size.fromHeight(height);
  }
}

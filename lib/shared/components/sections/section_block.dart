import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import 'section_header.dart';

class SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;

  /// Optional trailing widget (e.g., "See All" button)
  final Widget? trailing;

  const SectionBlock({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.screenH,
        ).copyWith(top: Gaps.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionHeader(title),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: Gaps.xs), // 8
            child,
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import 'section_header.dart';

class SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionBlock({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: Insets.screenH,
    ).copyWith(top: Gaps.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        const SizedBox(height: Gaps.xs), // 8
        child,
      ],
    ),
  );
}

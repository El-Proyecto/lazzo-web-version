import 'package:flutter/material.dart';

import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Segmented control for pages like inbox
/// Background bg2, indicator bg3, with horizontal margin
class PageSegmentedControl extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final Function(int)? onTap;

  const PageSegmentedControl({
    super.key,
    required this.controller,
    required this.labels,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        color: BrandColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xs),
        ),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        indicator: ShapeDecoration(
          color: BrandColors.bg3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xs),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: BrandColors.text1,
        unselectedLabelColor: BrandColors.text2,
        labelStyle: AppText.labelLarge,
        unselectedLabelStyle: AppText.labelLarge,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        tabs: labels.map((label) => Tab(text: label, height: 40)).toList(),
      ),
    );
  }
}

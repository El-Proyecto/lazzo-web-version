import 'package:flutter/material.dart';

import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Segmented control for create event page
/// Background bg2, green indicator for planning context
class CreateEventSegmentedControl extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final Function(int)? onTap;
  final EdgeInsets? margin;

  const CreateEventSegmentedControl({
    super.key,
    required this.controller,
    required this.labels,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        color: BrandColors.bg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        indicator: ShapeDecoration(
          color: BrandColors.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.smAlt),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: BrandColors.text2,
        labelStyle: AppText.labelLarge,
        unselectedLabelStyle: AppText.labelLarge,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        tabs: labels.map((label) => Tab(text: label, height: 36)).toList(),      ),
    );
  }
}

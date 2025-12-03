import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(left: Gaps.xs, bottom: Gaps.sm),
          child: Text(
            title,
            style: AppText.bodyLarge.copyWith(
              color: BrandColors.text2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Section Content
        Container(
          decoration: BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            children: _buildChildrenWithDividers(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildrenWithDividers() {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Pads.ctlH),
            child: Divider(
              color: BrandColors.border,
              height: 1,
              thickness: 1,
            ),
          ),
        );
      }
    }
    return result;
  }
}

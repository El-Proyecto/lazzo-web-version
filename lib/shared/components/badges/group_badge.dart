import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../../models/group_enums.dart';

/// Badge contextual para grupos com mudança de cor baseada na urgência
class GroupBadge extends StatelessWidget {
  final IconData icon;
  final String? text;
  final int? count;
  final BadgeUrgency urgency;

  const GroupBadge({
    super.key,
    required this.icon,
    this.text,
    this.count,
    required this.urgency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Gaps.sm, vertical: Gaps.xxs),
      decoration: ShapeDecoration(
        color: _getBadgeColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: BrandColors.text1, size: 14),
          if (text != null || (count != null && count! > 0)) ...[
            SizedBox(width: Gaps.xxs),
            Text(
              text ?? count.toString(),
              style: AppText.bodyMediumEmph.copyWith(
                color: BrandColors.text1,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBadgeColor() {
    switch (urgency) {
      case BadgeUrgency.high:
        return BrandColors.cantVote;
      case BadgeUrgency.medium:
        return BrandColors.recap;
      case BadgeUrgency.low:
        return BrandColors.planning;
      case BadgeUrgency.none:
        return BrandColors.bg3;
    }
  }
}

import 'package:flutter/material.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Vote button in the "Voted" state - showing voter avatars in stack
class VotedButton extends StatelessWidget {
  final int voterCount;
  final List<String> voterAvatars;
  final VoidCallback? onTap;

  const VotedButton({
    super.key,
    required this.voterCount,
    required this.voterAvatars,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatars stack
          _buildAvatarStack(),
          if (voterCount > voterAvatars.length) ...[
            const SizedBox(width: 4),
            // +X indicator for remaining voters
            Text(
              '+${voterCount - voterAvatars.length}',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    const double avatarSize = 30;
    final visibleAvatars = voterAvatars.take(3).toList();

    return SizedBox(
      height: avatarSize,
      width: visibleAvatars.length * avatarSize.toDouble(),
      child: Stack(
        children: visibleAvatars.asMap().entries.map((entry) {
          final index = entry.key;
          final avatarUrl = entry.value;

          return Positioned(
            left: index * avatarSize,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: ShapeDecoration(
                image: DecorationImage(
                  image: NetworkImage(avatarUrl),
                  fit: BoxFit.fill,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

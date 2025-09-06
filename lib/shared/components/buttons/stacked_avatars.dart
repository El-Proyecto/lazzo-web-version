import 'package:flutter/material.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../../../features/home/domain/entities/pending_event.dart'
    show VoterInfo;

class StackedAvatars extends StatelessWidget {
  final List<VoterInfo> voters;
  final VoidCallback? onTap;

  const StackedAvatars({super.key, required this.voters, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (voters.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 32,
        width: _calculateWidth(),
        child: Stack(children: _buildAvatarStack()),
      ),
    );
  }

  double _calculateWidth() {
    const avatarSize = 32.0;
    const overlap = 8.0;

    if (voters.length <= 3) {
      return avatarSize + (voters.length - 1) * (avatarSize - overlap);
    } else {
      // 3 avatars + counter
      return avatarSize + 2 * (avatarSize - overlap);
    }
  }

  List<Widget> _buildAvatarStack() {
    const avatarSize = 32.0;
    const overlap = 8.0;
    final widgets = <Widget>[];

    // Show maximum 3 avatars
    final visibleCount = voters.length > 3 ? 2 : voters.length;

    for (int i = 0; i < visibleCount; i++) {
      widgets.add(
        Positioned(
          left: i * (avatarSize - overlap),
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: NetworkImage(voters[i].avatarUrl),
                fit: BoxFit.cover,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60),
                side: const BorderSide(color: BrandColors.bg2, width: 2),
              ),
            ),
          ),
        ),
      );
    }

    // Add counter if more than 3 voters
    if (voters.length > 3) {
      final remainingCount = voters.length - 2;
      widgets.add(
        Positioned(
          left: 2 * (avatarSize - overlap),
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: ShapeDecoration(
              color: BrandColors.bg3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60),
                side: const BorderSide(color: BrandColors.bg2, width: 2),
              ),
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

// TODO P2: Remove this file - replaced by new home structure
import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/constants/vote_status.dart';
import '../../../../shared/themes/colors.dart';

class CompactVoteWidget extends StatelessWidget {
  final int totalVotes;
  final UserVoteStatus userVote;
  final VoidCallback? onVoteAgain;

  const CompactVoteWidget({
    super.key,
    required this.totalVotes,
    required this.userVote,
    this.onVoteAgain,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData iconData;
    String voteText;

    switch (userVote) {
      case UserVoteStatus.yes:
        borderColor = BrandColors.planning;
        iconColor = BrandColors.planning;
        textColor = BrandColors.planning;
        iconData = Icons.check_circle;
        voteText = 'Can';
        break;
      case UserVoteStatus.no:
        borderColor = BrandColors.cantVote;
        iconColor = BrandColors.cantVote;
        textColor = BrandColors.cantVote;
        iconData = Icons.cancel;
        voteText = "Can't";
        break;
      case UserVoteStatus.notVoted:
        borderColor = BrandColors.text2;
        iconColor = BrandColors.text2;
        textColor = BrandColors.text2;
        iconData = Icons.how_to_vote_outlined;
        voteText = 'Vote';
        break;
    }

    return GestureDetector(
      onTap: onVoteAgain,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show icon only for voted states, not for notVoted
            if (userVote != UserVoteStatus.notVoted) ...[
              Icon(iconData, size: 18, color: iconColor),
              const SizedBox(width: Gaps.xs),
            ],
            Text(
              voteText,
              style: AppText.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: Gaps.xxs),
            Text(
              '($totalVotes)',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

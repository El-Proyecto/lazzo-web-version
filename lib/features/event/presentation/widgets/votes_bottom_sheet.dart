import 'package:flutter/material.dart';
import '../../../../shared/components/dialogs/common_bottom_sheet.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';

/// Show votes bottom sheet
void showVotesBottomSheet(BuildContext context, List<RsvpVote> allVotes) {
  final going = allVotes
      .where((v) => v.status == RsvpVoteStatus.going)
      .toList();
  final notGoing = allVotes
      .where((v) => v.status == RsvpVoteStatus.notGoing)
      .toList();
  final pending = allVotes
      .where((v) => v.status == RsvpVoteStatus.pending)
      .toList();

  CommonBottomSheet.show(
    context: context,
    title: 'Votes',
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Can section
        if (going.isNotEmpty) ...[
          _VoteSection(title: 'Can', count: going.length, votes: going),
          const SizedBox(height: Gaps.lg),
        ],

        // Can't section
        if (notGoing.isNotEmpty) ...[
          _VoteSection(
            title: 'Can\'t',
            count: notGoing.length,
            votes: notGoing,
          ),
          const SizedBox(height: Gaps.lg),
        ],

        // Haven't Voted section
        if (pending.isNotEmpty) ...[
          _VoteSection(
            title: 'Haven\'t Voted',
            count: pending.length,
            votes: pending,
          ),
        ],
      ],
    ),
  );
}

/// Vote section in bottom sheet
class _VoteSection extends StatelessWidget {
  final String title;
  final int count;
  final List<RsvpVote> votes;

  const _VoteSection({
    required this.title,
    required this.count,
    required this.votes,
  });

  Color _getTitleColor() {
    switch (title) {
      case 'Can':
        return BrandColors.planning;
      case 'Can\'t':
        return BrandColors.cantVote;
      default:
        return BrandColors.text1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and count on same line, aligned left
        Row(
          children: [
            Text(
              title,
              style: AppText.labelLarge.copyWith(
                color: _getTitleColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: Gaps.xs),
            Text(
              '$count Vote${count != 1 ? 's' : ''}',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: Gaps.sm),

        // Users list
        ...votes.map(
          (vote) => Padding(
            padding: const EdgeInsets.only(bottom: Gaps.sm),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: BrandColors.bg3,
                  backgroundImage: vote.userAvatar != null
                      ? NetworkImage(vote.userAvatar!)
                      : null,
                  child: vote.userAvatar == null
                      ? Text(
                          vote.userName[0].toUpperCase(),
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: Gaps.sm),

                // Name
                Expanded(
                  child: Text(
                    vote.userName,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ),

                // Voted time (if available)
                if (vote.votedAt != null)
                  Text(
                    _formatVoteTime(vote.votedAt!),
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatVoteTime(DateTime votedAt) {
    final now = DateTime.now();
    final difference = now.difference(votedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

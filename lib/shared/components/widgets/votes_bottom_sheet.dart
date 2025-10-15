import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../dialogs/common_bottom_sheet.dart';
import 'rsvp_widget.dart';

/// Bottom sheet to display votes for an event
class VotesBottomSheet {
  static void show({
    required BuildContext context,
    required List<RsvpVote> allVotes,
  }) {
    final going =
        allVotes.where((v) => v.status == RsvpVoteStatus.going).toList();
    final notGoing =
        allVotes.where((v) => v.status == RsvpVoteStatus.notGoing).toList();
    final pending =
        allVotes.where((v) => v.status == RsvpVoteStatus.pending).toList();

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

          // Haven't Responded section
          if (pending.isNotEmpty) ...[
            _VoteSection(
              title: 'No response',
              count: pending.length,
              votes: pending,
            ),
          ],
        ],
      ),
    );
  }
}

/// Vote section widget for displaying a group of votes
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

  String _getCountText() {
    if (title == 'No response') {
      return '$count ${count == 1 ? "left" : "left"}';
    }
    return '$count ${count == 1 ? "Vote" : "Votes"}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppText.labelLarge.copyWith(color: _getTitleColor()),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _getCountText(),
              style: AppText.bodyMediumEmph.copyWith(color: BrandColors.text1),
            ),
          ],
        ),
        const SizedBox(height: Gaps.md),
        ...votes.map(
          (vote) => _VoteItem(vote: vote, showDate: title != 'No response'),
        ),
      ],
    );
  }
}

/// Individual vote item
class _VoteItem extends StatelessWidget {
  final RsvpVote vote;
  final bool showDate;

  const _VoteItem({required this.vote, this.showDate = true});

  String get _displayName {
    // Show "You" for current user, otherwise show the user name
    return vote.userId == 'current_user' ? 'You' : vote.userName;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.sm),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: BrandColors.bg3,
            child: vote.userAvatar != null
                ? ClipOval(
                    child: Image.network(
                      vote.userAvatar!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: Gaps.sm),

          // Name
          Expanded(child: Text(_displayName, style: AppText.bodyMedium)),

          // Date (if voted and should show date)
          if (showDate && vote.votedAt != null)
            Text(
              _formatVoteTime(vote.votedAt!),
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      vote.userName.isNotEmpty ? vote.userName[0].toUpperCase() : '?',
      style: AppText.bodyMediumEmph.copyWith(
        color: BrandColors.text2,
        fontSize: 14,
      ),
    );
  }

  String _formatVoteTime(DateTime votedAt) {
    final now = DateTime.now();
    final diff = now.difference(votedAt);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${votedAt.day}/${votedAt.month}';
    }
  }
}

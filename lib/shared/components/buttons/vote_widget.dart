import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../constants/vote_status.dart';
import '../../themes/colors.dart';

/// Style variants for the vote widget
enum VoteStyle {
  simple, // Simple "Vote" button
  compact, // Compact vote result display
  expanded, // Full yes/no voting interface
  voters, // Show voters with avatars
}

/// Unified vote widget that replaces all 14 voting button variants
/// Configurable to handle different voting states and styles
class VoteWidget extends StatelessWidget {
  final VoteStyle style;
  final UserVoteStatus userVoteStatus;
  final int? totalVotes;
  final int? yesVotes;
  final int? noVotes;
  final List<String>? avatarUrls;
  final VoidCallback? onVote;
  final VoidCallback? onYes;
  final VoidCallback? onNo;
  final VoidCallback? onVoteAgain;
  final VoidCallback? onExpandVoters;

  const VoteWidget({
    super.key,
    required this.style,
    this.userVoteStatus = UserVoteStatus.notVoted,
    this.totalVotes,
    this.yesVotes,
    this.noVotes,
    this.avatarUrls,
    this.onVote,
    this.onYes,
    this.onNo,
    this.onVoteAgain,
    this.onExpandVoters,
  });

  /// Factory for simple vote button (replacement for SimpleVoteButton)
  factory VoteWidget.simple({VoidCallback? onVote}) {
    return VoteWidget(style: VoteStyle.simple, onVote: onVote);
  }

  /// Factory for compact vote display (replacement for CompactVoteWidget)
  factory VoteWidget.compact({
    required UserVoteStatus userVoteStatus,
    required int totalVotes,
    VoidCallback? onVoteAgain,
  }) {
    return VoteWidget(
      style: VoteStyle.compact,
      userVoteStatus: userVoteStatus,
      totalVotes: totalVotes,
      onVoteAgain: onVoteAgain,
    );
  }

  /// Factory for voting interface (replacement for VotingButton)
  factory VoteWidget.voting({VoidCallback? onYes, VoidCallback? onNo}) {
    return VoteWidget(style: VoteStyle.expanded, onYes: onYes, onNo: onNo);
  }

  /// Factory for voters display (replacement for VotersExpandedButton)
  factory VoteWidget.voters({
    required int totalVotes,
    List<String>? avatarUrls,
    VoidCallback? onExpandVoters,
  }) {
    return VoteWidget(
      style: VoteStyle.voters,
      totalVotes: totalVotes,
      avatarUrls: avatarUrls,
      onExpandVoters: onExpandVoters,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case VoteStyle.simple:
        return _buildSimpleVote();
      case VoteStyle.compact:
        return _buildCompactVote();
      case VoteStyle.expanded:
        return _buildExpandedVoting();
      case VoteStyle.voters:
        return _buildVotersDisplay();
    }
  }

  Widget _buildSimpleVote() {
    return GestureDetector(
      onTap: onVote,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(
          color: BrandColors.planning,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: Center(
          child: Text(
            'Vote',
            style: AppText.bodyMediumEmph.copyWith(color: BrandColors.text1),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactVote() {
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData iconData;
    String voteText;

    switch (userVoteStatus) {
      case UserVoteStatus.yes:
        borderColor = BrandColors.planning;
        iconColor = BrandColors.planning;
        textColor = BrandColors.text1;
        iconData = Icons.check;
        voteText = totalVotes == 1 ? '1 vote' : '$totalVotes votes';
        break;
      case UserVoteStatus.no:
        borderColor = BrandColors.cantVote;
        iconColor = BrandColors.cantVote;
        textColor = BrandColors.text1;
        iconData = Icons.close;
        voteText = totalVotes == 1 ? '1 vote' : '$totalVotes votes';
        break;
      case UserVoteStatus.notVoted:
        borderColor = BrandColors.text2;
        iconColor = BrandColors.text2;
        textColor = BrandColors.text2;
        iconData = Icons.circle_outlined;
        voteText = totalVotes == 1 ? '1 vote' : '$totalVotes votes';
        break;
    }

    return GestureDetector(
      onTap: onVoteAgain,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: Gaps.sm),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: borderColor),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: iconColor, size: 16),
            const SizedBox(width: Gaps.xs),
            Text(
              voteText,
              style: AppText.bodyMedium.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedVoting() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // No button (Red)
        GestureDetector(
          onTap: onNo,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: ShapeDecoration(
              color: BrandColors.cantVote.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: BrandColors.cantVote),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
            child: const Icon(
              Icons.close,
              color: BrandColors.cantVote,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: Gaps.xs),
        // Yes button (Green)
        GestureDetector(
          onTap: onYes,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: ShapeDecoration(
              color: BrandColors.planning.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: BrandColors.planning),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
            child: const Icon(
              Icons.check,
              color: BrandColors.planning,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVotersDisplay() {
    return GestureDetector(
      onTap: onExpandVoters,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: Gaps.sm),
        decoration: ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar stack (if provided)
            if (avatarUrls != null && avatarUrls!.isNotEmpty) ...[
              _buildAvatarStack(),
              const SizedBox(width: Gaps.xs),
            ],
            // Vote count text
            Text(
              totalVotes == 1 ? '1 vote' : '$totalVotes votes',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(width: Gaps.xs),
            const Icon(
              Icons.keyboard_arrow_down,
              color: BrandColors.text2,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    if (avatarUrls == null || avatarUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayAvatars = avatarUrls!.take(3).toList();

    return SizedBox(
      width: 24 + (displayAvatars.length - 1) * 12,
      height: 24,
      child: Stack(
        children: [
          for (int i = 0; i < displayAvatars.length; i++)
            Positioned(
              left: i * 12.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: BrandColors.bg3,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: BrandColors.bg1),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: displayAvatars[i].isNotEmpty
                      ? Image.network(
                          displayAvatars[i],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 16),
                        )
                      : const Icon(Icons.person, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

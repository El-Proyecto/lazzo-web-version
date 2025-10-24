import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../constants/vote_status.dart';
import '../../themes/colors.dart';
import '../../../features/home/domain/entities/pending_event.dart'
    show VoterInfo;
import '../buttons/expanded_card_button.dart';

class PendingEventExpandedCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String dateTime;
  final String location;
  final List<VoterInfo> yesVoters;
  final List<VoterInfo> noVoters;
  final List<VoterInfo> noResponseVoters;
  final int noResponseCount;
  final UserVoteStatus userVote; // User's current vote status
  final VoidCallback? onCollapse;
  final VoidCallback? onVoteAgain;
  final VoidCallback? onTap;

  const PendingEventExpandedCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.yesVoters,
    required this.noVoters,
    required this.noResponseVoters,
    required this.noResponseCount,
    required this.userVote,
    this.onCollapse,
    this.onVoteAgain,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and collapse button
            Row(
              children: [
                // Event info section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with emoji
                      Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: Gaps.xs),
                          Expanded(
                            child: Text(
                              title,
                              style: AppText.titleMediumEmph.copyWith(
                                color: BrandColors.text1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gaps.xxs),
                      // Date and location
                      Text(
                        '$dateTime • $location',
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Gaps.md),

                // Vote Again Button
                ExpandedCardButton(onTap: onVoteAgain),

                const SizedBox(width: Gaps.xs),

                // Collapse Button
                GestureDetector(
                  onTap: onCollapse,
                  child: Container(
                    width: IconSizes.lg,
                    height: IconSizes.lg,
                    decoration: ShapeDecoration(
                      color: BrandColors.bg3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                    ),
                    child: const Icon(
                      Icons.expand_less,
                      size: 18,
                      color: BrandColors.text1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Gaps.md),

            // Voting sections
            Column(
              children: [
                // "Can" section (Yes votes)
                if (yesVoters.isNotEmpty)
                  _buildVoteSection(
                    'Can',
                    BrandColors.planning, // Green
                    yesVoters.length,
                    yesVoters,
                  ),

                if (yesVoters.isNotEmpty &&
                    (noVoters.isNotEmpty || noResponseCount > 0))
                  const SizedBox(height: Gaps.xs),

                // "Can't" section (No votes)
                if (noVoters.isNotEmpty)
                  _buildVoteSection(
                    "Can't",
                    BrandColors.cantVote, // Red
                    noVoters.length,
                    noVoters,
                  ),

                if (noVoters.isNotEmpty && noResponseCount > 0)
                  const SizedBox(height: Gaps.xs),

                // "No response" section
                if (noResponseCount > 0) _buildNoResponseSection(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteSection(
    String title,
    Color color,
    int count,
    List<VoterInfo> voters,
  ) {
    return Column(
      children: [
        // Section header
        Row(
          children: [
            // Icon at the left
            Container(
              width: 16,
              height: 16,
              decoration: ShapeDecoration(
                color: color,
                shape: const OvalBorder(),
              ),
              child: Icon(
                title == 'Can' ? Icons.check : Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: Gaps.xs),
            Text(
              title,
              style: AppText.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$count Vote${count != 1 ? 's' : ''}',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: Gaps.xs),

        // Voters list
        Column(children: voters.map((voter) => _buildVoterRow(voter)).toList()),
      ],
    );
  }

  Widget _buildNoResponseSection() {
    return Column(
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: ShapeDecoration(
                color: BrandColors.text2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(
                Icons.help_outline,
                size: 12,
                color: BrandColors.text1,
              ),
            ),
            const SizedBox(width: Gaps.xs),
            Text(
              'No response',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$noResponseCount Vote${noResponseCount != 1 ? 's' : ''}',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: Gaps.xs),

        // No response voters list
        Column(
          children: noResponseVoters
              .map((voter) => _buildNoResponseVoterRow(voter))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildVoterRow(VoterInfo voter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.sm),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: NetworkImage(voter.avatarUrl),
                fit: BoxFit.fill,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
          const SizedBox(width: Gaps.xs),

          // Name
          Expanded(
            child: Text(
              voter.name,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Time ago
          Text(
            _formatTimeAgo(voter.votedAt),
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResponseVoterRow(VoterInfo voter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.sm),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: NetworkImage(voter.avatarUrl),
                fit: BoxFit.fill,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
          const SizedBox(width: Gaps.xs),

          // Name
          Expanded(
            child: Text(
              voter.name,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Notify button for non-responders
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: ShapeDecoration(
              color: BrandColors.bg3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 16,
                  color: BrandColors.text1,
                ),
                const SizedBox(width: Gaps.xxs),
                Text(
                  'Notify',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

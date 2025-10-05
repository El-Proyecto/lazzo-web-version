import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Poll widget for date/location suggestions
/// Shows poll options with votes and allows voting
class PollWidget extends StatelessWidget {
  final String question;
  final List<PollOptionData> options;
  final String? userVotedOptionId;
  final bool isHost;
  final Function(String optionId) onVote;
  final Function(String optionId)? onPickFinal;

  const PollWidget({
    super.key,
    required this.question,
    required this.options,
    this.userVotedOptionId,
    required this.isHost,
    required this.onVote,
    this.onPickFinal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(question, style: AppText.labelLarge),
          const SizedBox(height: Gaps.md),

          // Options
          ...options.map((option) {
            final isVoted = userVotedOptionId == option.id;
            final maxVotes = options.fold<int>(
              0,
              (max, opt) => opt.voteCount > max ? opt.voteCount : max,
            );
            final isWinning = option.voteCount == maxVotes && maxVotes > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: Gaps.sm),
              child: _PollOption(
                label: option.label,
                voteCount: option.voteCount,
                isVoted: isVoted,
                isWinning: isWinning,
                onTap: () => onVote(option.id),
              ),
            );
          }),

          // Pick final button (host only)
          if (isHost && onPickFinal != null) ...[
            const SizedBox(height: Gaps.xs),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final winningOption = options.firstWhere(
                    (opt) =>
                        opt.voteCount ==
                        options.fold<int>(
                          0,
                          (max, o) => o.voteCount > max ? o.voteCount : max,
                        ),
                  );
                  onPickFinal!(winningOption.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.planning,
                  foregroundColor: BrandColors.text1,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.ctlH,
                    vertical: Pads.ctlV,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
                child: Text(
                  'Escolher data final',
                  style: AppText.bodyMediumEmph,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Poll option data model
class PollOptionData {
  final String id;
  final String label;
  final int voteCount;

  const PollOptionData({
    required this.id,
    required this.label,
    required this.voteCount,
  });
}

/// Internal poll option widget
class _PollOption extends StatelessWidget {
  final String label;
  final int voteCount;
  final bool isVoted;
  final bool isWinning;
  final VoidCallback onTap;

  const _PollOption({
    required this.label,
    required this.voteCount,
    required this.isVoted,
    required this.isWinning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          border: Border.all(
            color: isVoted ? BrandColors.planning : BrandColors.border,
            width: isVoted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  color: isVoted ? BrandColors.planning : BrandColors.text1,
                  fontWeight: isVoted ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (voteCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isWinning ? BrandColors.planning : BrandColors.border,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  voteCount.toString(),
                  style: AppText.bodyMedium.copyWith(
                    color: isWinning ? BrandColors.bg1 : BrandColors.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

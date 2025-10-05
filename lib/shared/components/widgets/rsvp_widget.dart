import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// RSVP widget for event confirmation
/// Allows users to vote going/not going and view current votes
class RsvpWidget extends StatelessWidget {
  final int goingCount;
  final int notGoingCount;
  final bool? userVote; // true = going, false = not going, null = pending
  final VoidCallback onGoingPressed;
  final VoidCallback onNotGoingPressed;
  final VoidCallback onViewVotesPressed;
  final VoidCallback? onAddSuggestionPressed;

  const RsvpWidget({
    super.key,
    required this.goingCount,
    required this.notGoingCount,
    this.userVote,
    required this.onGoingPressed,
    required this.onNotGoingPressed,
    required this.onViewVotesPressed,
    this.onAddSuggestionPressed,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RSVP', style: AppText.labelLarge),
              InkWell(
                onTap: onViewVotesPressed,
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gaps.xs,
                    vertical: Gaps.xxs,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Ver votos',
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                      ),
                      const SizedBox(width: Gaps.xxs),
                      const Icon(
                        Icons.chevron_right,
                        size: IconSizes.sm,
                        color: BrandColors.text2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.md),

          // Vote buttons
          Row(
            children: [
              Expanded(
                child: _VoteButton(
                  label: 'Vou',
                  count: goingCount,
                  isSelected: userVote == true,
                  color: BrandColors.planning,
                  onPressed: onGoingPressed,
                ),
              ),
              const SizedBox(width: Gaps.sm),
              Expanded(
                child: _VoteButton(
                  label: 'Não vou',
                  count: notGoingCount,
                  isSelected: userVote == false,
                  color: BrandColors.cantVote,
                  onPressed: onNotGoingPressed,
                ),
              ),
            ],
          ),

          // Add suggestion button (shown when user votes "not going")
          if (userVote == false && onAddSuggestionPressed != null) ...[
            const SizedBox(height: Gaps.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddSuggestionPressed,
                icon: const Icon(Icons.add, size: IconSizes.sm),
                label: Text(
                  'Adicionar sugestão',
                  style: AppText.bodyMediumEmph,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.text1,
                  side: const BorderSide(color: BrandColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.ctlH,
                    vertical: Pads.ctlV,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Internal vote button widget
class _VoteButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onPressed;

  const _VoteButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TouchTargets.min,
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : BrandColors.bg3,
        border: Border.all(
          color: isSelected ? color : BrandColors.border,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppText.bodyMediumEmph.copyWith(
                  color: isSelected ? color : BrandColors.text1,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: Gaps.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : BrandColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppText.bodyMedium.copyWith(
                      color: isSelected ? BrandColors.bg1 : BrandColors.text2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

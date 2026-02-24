import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Data model for RSVP vote info displayed in the summary
class RsvpVoterInfo {
  final String userId;
  final String userName;
  final String? userAvatar;
  final RsvpVoteType voteType;

  const RsvpVoterInfo({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.voteType,
  });
}

/// The selected vote type
enum RsvpVoteType { going, maybe, notGoing }

/// Index of each vote type in the row (used for slide animation direction).
int _voteIndex(RsvpVoteType type) {
  switch (type) {
    case RsvpVoteType.going:
      return 0;
    case RsvpVoteType.maybe:
      return 1;
    case RsvpVoteType.notGoing:
      return 2;
  }
}

/// RSVP vote buttons widget for pending/confirmed events.
///
/// **Stage 1 (not voted):** 3 large side-by-side buttons (icon + label), bg2.
/// **Stage 2 (voted):** Selected button (same format, colored) sits above a
/// vote-summary row sharing a single border — looks like one integrated card.
/// Includes a slide-right animation when switching from a left-positioned vote.
class RsvpVoteButtons extends StatefulWidget {
  final RsvpVoteType? selectedVote;
  final int goingCount;
  final int maybeCount;
  final int notGoingCount;
  final VoidCallback onGoingPressed;
  final VoidCallback onMaybePressed;
  final VoidCallback onNotGoingPressed;
  final VoidCallback? onVoteSummaryTap;
  final List<RsvpVoterInfo> voters;
  final String? currentUserId;

  const RsvpVoteButtons({
    super.key,
    this.selectedVote,
    required this.goingCount,
    required this.maybeCount,
    required this.notGoingCount,
    required this.onGoingPressed,
    required this.onMaybePressed,
    required this.onNotGoingPressed,
    this.onVoteSummaryTap,
    this.voters = const [],
    this.currentUserId,
  });

  @override
  State<RsvpVoteButtons> createState() => _RsvpVoteButtonsState();
}

class _RsvpVoteButtonsState extends State<RsvpVoteButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    // If already voted on first build, skip animation.
    if (widget.selectedVote != null) {
      _slideController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant RsvpVoteButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldVote = oldWidget.selectedVote;
    final newVote = widget.selectedVote;

    if (oldVote != newVote && newVote != null) {
      // Determine slide direction: comes from the left when previous position
      // was to the left of current (or when going from null → voted).
      final oldIdx = oldVote != null ? _voteIndex(oldVote) : -1;
      final newIdx = _voteIndex(newVote);
      final fromLeft = oldIdx < newIdx;

      _slideAnimation = Tween<Offset>(
        begin: Offset(fromLeft ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ));

      _slideController.forward(from: 0);
    } else if (newVote == null && oldVote != null) {
      // Went back to unvoted — reset.
      _slideController.value = 0;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedVote == null) {
      return _buildUnvotedState();
    }
    return _buildVotedState();
  }

  // ─── Stage 1: 3 large buttons ────────────────────────────────

  Widget _buildUnvotedState() {
    return Row(
      children: [
        Expanded(
          child: _VoteButton(
            icon: Icons.check,
            label: 'Can',
            onPressed: widget.onGoingPressed,
          ),
        ),
        const SizedBox(width: Gaps.sm),
        Expanded(
          child: _VoteButton(
            icon: Icons.question_mark,
            label: 'Maybe',
            onPressed: widget.onMaybePressed,
          ),
        ),
        const SizedBox(width: Gaps.sm),
        Expanded(
          child: _VoteButton(
            icon: Icons.close,
            label: "Can't",
            onPressed: widget.onNotGoingPressed,
          ),
        ),
      ],
    );
  }

  // ─── Stage 2: voter info left + selected button right ─────────

  Widget _buildVotedState() {
    final type = widget.selectedVote!;
    final color = _voteColor(type);
    final icon = _voteIcon(type);
    final label = _voteLabel(type);
    final onTap = _voteCallback(type);

    return Container(
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left: voter info + summary counts ──
            Expanded(
              flex: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onVoteSummaryTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.sectionH,
                    vertical: Pads.sectionV,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Voter avatars + "Name is going/maybe/can't"
                      _buildVoterRow(),
                      const SizedBox(height: Gaps.xs),
                      // Summary counts
                      Text(
                        '${widget.goingCount} can · ${widget.maybeCount} maybe · ${widget.notGoingCount} can\'t',
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Right: selected vote card (same height as stage-1 button) ──
            SlideTransition(
              position: _slideAnimation,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(Radii.md),
                  bottomRight: Radius.circular(Radii.md),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.ctlH + 8,
                    vertical: Pads.sectionH,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(Radii.md),
                      bottomRight: Radius.circular(Radii.md),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 32, color: color),
                      const SizedBox(height: Gaps.xxs),
                      Text(
                        label,
                        style: AppText.labelLarge.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Row with stacked avatars + "You and X others are going/maybe/can't"
  Widget _buildVoterRow() {
    // Show only voters of the same type as current vote (stage 2).
    final selectedType = widget.selectedVote;
    final sameTypeVoters = selectedType != null
        ? widget.voters.where((v) => v.voteType == selectedType).toList()
        : widget.voters;

    if (sameTypeVoters.isEmpty) {
      return Text(
        'No votes yet',
        style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
      );
    }

    // Build summary text with "You" for current user.
    String summaryText;
    if (widget.currentUserId != null && selectedType != null) {
      final others = sameTypeVoters
          .where((v) => v.userId != widget.currentUserId)
          .toList();
      final vphrase = _verbPhrase(selectedType);
      if (others.isEmpty) {
        summaryText = 'You $vphrase';
      } else if (others.length == 1) {
        summaryText = 'You and ${others.first.userName} $vphrase';
      } else {
        summaryText = 'You and ${others.length} others $vphrase';
      }
    } else {
      final lastVoter = sameTypeVoters.last;
      summaryText =
          '${lastVoter.userName} voted ${_voteStatusText(sameTypeVoters.last)}';
    }

    return Row(
      children: [
        // Stacked avatars (same vote type only)
        SizedBox(
          width: _stackedAvatarsWidth(sameTypeVoters.take(5).length),
          height: 24,
          child: _buildStackedAvatars(sameTypeVoters.take(5).toList()),
        ),
        const SizedBox(width: Gaps.xs),
        // Summary text
        Expanded(
          child: Text(
            summaryText,
            style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Verb phrase for each vote type.
  String _verbPhrase(RsvpVoteType type) {
    switch (type) {
      case RsvpVoteType.going:
        return 'are going';
      case RsvpVoteType.maybe:
        return 'maybe can go';
      case RsvpVoteType.notGoing:
        return "can't go";
    }
  }

  /// Returns the vote status text for a specific voter.
  String _voteStatusText(RsvpVoterInfo voter) {
    return _voteLabel(voter.voteType).toLowerCase();
  }

  double _stackedAvatarsWidth(int count) {
    const avatarSize = 24.0;
    const overlap = 6.0;
    if (count <= 0) return 0;
    return avatarSize + (count - 1) * (avatarSize - overlap);
  }

  Widget _buildStackedAvatars(List<RsvpVoterInfo> displayVoters) {
    const avatarSize = 24.0;
    const overlap = 6.0;

    return Stack(
      children: List.generate(displayVoters.length, (index) {
        final voter = displayVoters[index];
        return Positioned(
          left: index * (avatarSize - overlap),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.bg2, width: 1.5),
            ),
            child: CircleAvatar(
              radius: (avatarSize - 3) / 2,
              backgroundColor: BrandColors.bg3,
              backgroundImage: voter.userAvatar != null
                  ? NetworkImage(voter.userAvatar!)
                  : null,
              child: voter.userAvatar == null
                  ? Text(
                      voter.userName.isNotEmpty
                          ? voter.userName[0].toUpperCase()
                          : '?',
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                        fontSize: 10,
                      ),
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _voteLabel(RsvpVoteType type) {
    switch (type) {
      case RsvpVoteType.going:
        return 'Can';
      case RsvpVoteType.maybe:
        return 'Maybe';
      case RsvpVoteType.notGoing:
        return "Can't";
    }
  }

  Color _voteColor(RsvpVoteType type) {
    switch (type) {
      case RsvpVoteType.going:
        return BrandColors.planning;
      case RsvpVoteType.maybe:
        return BrandColors.warning;
      case RsvpVoteType.notGoing:
        return BrandColors.cantVote;
    }
  }

  IconData _voteIcon(RsvpVoteType type) {
    switch (type) {
      case RsvpVoteType.going:
        return Icons.check;
      case RsvpVoteType.maybe:
        return Icons.question_mark;
      case RsvpVoteType.notGoing:
        return Icons.close;
    }
  }

  VoidCallback _voteCallback(RsvpVoteType type) {
    switch (type) {
      case RsvpVoteType.going:
        return widget.onGoingPressed;
      case RsvpVoteType.maybe:
        return widget.onMaybePressed;
      case RsvpVoteType.notGoing:
        return widget.onNotGoingPressed;
    }
  }
}

// ─── Vote button (used in both stages) ────────────────────────────

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _VoteButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Pads.sectionH),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: BrandColors.text1),
            const SizedBox(height: Gaps.xxs),
            Text(
              label,
              style: AppText.labelLarge.copyWith(color: BrandColors.text1),
            ),
          ],
        ),
      ),
    );
  }
}

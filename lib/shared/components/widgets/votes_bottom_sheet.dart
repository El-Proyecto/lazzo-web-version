import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import 'rsvp_widget.dart';

/// Bottom sheet to display votes for an event with voting functionality
class VotesBottomSheet {
  static void show({
    required BuildContext context,
    required List<RsvpVote> allVotes,
    required String eventName,
    required String eventEmoji,
    String? eventDate,
    String? eventLocation,
    bool? userVote, // true = going, false = not going, null = not voted
    Function(bool)? onVoteChanged, // Updated callback
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VotesBottomSheetContent(
        allVotes: allVotes,
        eventName: eventName,
        eventEmoji: eventEmoji,
        eventDate: eventDate,
        eventLocation: eventLocation,
        initialUserVote: userVote,
        onVoteChanged: onVoteChanged,
      ),
    );
  }
}

/// Internal widget to manage the two states
class _VotesBottomSheetContent extends StatefulWidget {
  final List<RsvpVote> allVotes;
  final String eventName;
  final String eventEmoji;
  final String? eventDate;
  final String? eventLocation;
  final bool? initialUserVote;
  final Function(bool)? onVoteChanged;

  const _VotesBottomSheetContent({
    required this.allVotes,
    required this.eventName,
    required this.eventEmoji,
    required this.eventDate,
    required this.eventLocation,
    required this.initialUserVote,
    required this.onVoteChanged,
  });

  @override
  State<_VotesBottomSheetContent> createState() =>
      _VotesBottomSheetContentState();
}

class _VotesBottomSheetContentState extends State<_VotesBottomSheetContent> {
  late bool _isVotingState;
  late bool? _currentUserVote;

  @override
  void initState() {
    super.initState();
    _currentUserVote = widget.initialUserVote;
    // Start in voting state if user hasn't voted yet
    _isVotingState = _currentUserVote == null;
  }

  void _toggleState() {
    setState(() {
      _isVotingState = !_isVotingState;
    });
  }

  String _getVoteLabel() {
    if (_currentUserVote == true) return 'You voted: Can';
    if (_currentUserVote == false) return 'You voted: Can\'t';
    return '';
  }

  void _handleVote(bool vote) {
    setState(() {
      _currentUserVote = vote;
      _isVotingState = false; // Switch to voted state after voting
    });
    widget.onVoteChanged?.call(vote);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: Gaps.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(Pads.sectionH),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isVotingState
                          ? (_currentUserVote == null
                              ? 'Cast your vote'
                              : 'Vote')
                          : 'Votes',
                      style: AppText.titleMediumEmph.copyWith(
                        color: BrandColors.text1,
                      ),
                    ),
                  ),
                  if (_isVotingState && _currentUserVote != null) ...[
                    GestureDetector(
                      onTap: _toggleState,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See votes',
                            style: AppText.bodyMediumEmph.copyWith(
                              color: BrandColors.text2,
                            ),
                          ),
                          const SizedBox(width: Gaps.xs),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: BrandColors.text2,
                          ),
                        ],
                      ),
                    ),
                  ] else if (!_isVotingState && _currentUserVote != null) ...[
                    GestureDetector(
                      onTap: _toggleState,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getVoteLabel(),
                            style: AppText.bodyMediumEmph.copyWith(
                              color: BrandColors.text2,
                            ),
                          ),
                          const SizedBox(width: Gaps.xs),
                          const Icon(
                            Icons.edit,
                            size: 16,
                            color: BrandColors.text2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
                child: _isVotingState
                    ? _buildVotingContent()
                    : _buildVotedContent(),
              ),
            ),

            // Bottom padding
            SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom + Gaps.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingContent() {
    final going =
        widget.allVotes.where((v) => v.status == RsvpVoteStatus.going).length;
    final notGoing = widget.allVotes
        .where((v) => v.status == RsvpVoteStatus.notGoing)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vote buttons
        Row(
          children: [
            Expanded(
              child: _VoteButton(
                label: 'Can',
                count: going,
                isSelected: _currentUserVote == true,
                color: BrandColors.planning,
                onPressed: () => _handleVote(true),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: _VoteButton(
                label: 'Can\'t',
                count: notGoing,
                isSelected: _currentUserVote == false,
                color: BrandColors.cantVote,
                onPressed: () => _handleVote(false),
              ),
            ),
          ],
        ),

        const SizedBox(height: Gaps.lg),

        // Event info
        _buildEventInfo(),
      ],
    );
  }

  Widget _buildVotedContent() {
    final going =
        widget.allVotes.where((v) => v.status == RsvpVoteStatus.going).toList();
    final notGoing = widget.allVotes
        .where((v) => v.status == RsvpVoteStatus.notGoing)
        .toList();
    final pending = widget.allVotes
        .where((v) => v.status == RsvpVoteStatus.pending)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Can section
        if (going.isNotEmpty) ...[
          _VoteSection(title: 'Can', count: going.length, votes: going),
          const SizedBox(height: Gaps.md),
        ],

        // Can't section
        if (notGoing.isNotEmpty) ...[
          _VoteSection(
            title: 'Can\'t',
            count: notGoing.length,
            votes: notGoing,
          ),
          const SizedBox(height: Gaps.md),
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
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(Pads.sectionV),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event name with emoji
          Row(
            children: [
              Text(
                widget.eventEmoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: Gaps.sm),
              Expanded(
                child: Text(
                  widget.eventName,
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Event details
          if (widget.eventDate != null || widget.eventLocation != null) ...[
            const SizedBox(height: Gaps.xs),
            if (widget.eventDate != null)
              Text(
                widget.eventDate!,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
              ),
            if (widget.eventLocation != null) ...[
              if (widget.eventDate != null) const SizedBox(height: Gaps.xs),
              Text(
                widget.eventLocation!,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Vote button widget (copied from rsvp_widget.dart)
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
        color: isSelected ? color.withValues(alpha: 0.15) : BrandColors.bg3,
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
                const SizedBox(width: Gaps.xs),
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
                      color: isSelected ? BrandColors.text1 : BrandColors.text2,
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

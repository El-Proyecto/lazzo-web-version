import 'package:flutter/material.dart';
import '../../../routes/app_router.dart';
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
    Function(bool?)? onVoteChanged, // Updated callback to handle null (unvote)
    String? currentUserId,
    String? currentUserAvatar,
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
        currentUserId: currentUserId,
        currentUserAvatar: currentUserAvatar,
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
  final Function(bool?)? onVoteChanged;
  final String? currentUserId;
  final String? currentUserAvatar;

  const _VotesBottomSheetContent({
    required this.allVotes,
    required this.eventName,
    required this.eventEmoji,
    required this.eventDate,
    required this.eventLocation,
    required this.initialUserVote,
    required this.onVoteChanged,
    this.currentUserId,
    this.currentUserAvatar,
  });

  @override
  State<_VotesBottomSheetContent> createState() =>
      _VotesBottomSheetContentState();
}

class _VotesBottomSheetContentState extends State<_VotesBottomSheetContent> {
  late bool _isVotingState;
  late bool? _currentUserVote;
  late List<RsvpVote> _currentVotes;

  @override
  void initState() {
    super.initState();
    _currentUserVote = widget.initialUserVote;
    _currentVotes = List.from(widget.allVotes); // Create mutable copy
    // Start in voting state if user hasn't voted yet
    _isVotingState = _currentUserVote == null;
  }

  void _toggleState() {
    setState(() {
      _isVotingState = !_isVotingState;
    });
  }

  String _getVoteLabel() {
    if (_currentUserVote == true) return 'Can';
    if (_currentUserVote == false) return 'Can\'t';
    return 'Vote';
  }

  void _handleVote(bool vote) {
    setState(() {
      final bool isSameVote = _currentUserVote == vote;

      if (isSameVote) {
        // Same vote clicked - unvote (remove vote)
        _currentUserVote = null;
        _removeUserVote();
        // Stay in voting state when unvoting
        _isVotingState = true;
      } else {
        // Different vote or first vote - always switch to voted state after voting
        _currentUserVote = vote;
        _updateUserVote(vote);
        _isVotingState = false;
      }
    });
    widget.onVoteChanged?.call(_currentUserVote);
  }

  void _updateUserVote(bool vote) {
    final userId = widget.currentUserId ?? 'current_user';

    // Remove existing user vote if any
    _currentVotes.removeWhere((v) => v.userId == userId);

    // Add new user vote with real avatar
    final newVote = RsvpVote(
      id: 'vote_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: 'You',
      userAvatar: widget.currentUserAvatar,
      status: vote ? RsvpVoteStatus.going : RsvpVoteStatus.notGoing,
      votedAt: DateTime.now(),
    );
    _currentVotes.add(newVote);
  }

  void _removeUserVote() {
    final userId = widget.currentUserId ?? 'current_user';

    // Remove existing user vote if any
    _currentVotes.removeWhere((v) => v.userId == userId);

    // Add user as pending (no response) to show in "No response" section
    final pendingVote = RsvpVote(
      id: 'vote_${userId}_pending_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: 'You',
      userAvatar: widget.currentUserAvatar,
      status: RsvpVoteStatus.pending,
      votedAt: null, // No vote time for pending votes
    );
    _currentVotes.add(pendingVote);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.52; // 52% for medium size

    return Container(
      height: bottomSheetHeight,
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
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
                            ? 'Can you make it?'
                            : 'Vote')
                        : 'Votes',
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ),
                if (_isVotingState && _currentVotes.isNotEmpty) ...[
                  GestureDetector(
                    onTap: _toggleState,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View votes',
                          style: AppText.bodyMediumEmph.copyWith(
                            color: BrandColors.text2,
                          ),
                        ),
                        const SizedBox(width: Gaps.xxs),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: BrandColors.text2,
                        ),
                      ],
                    ),
                  ),
                ] else if (!_isVotingState) ...[
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
              child:
                  _isVotingState ? _buildVotingContent() : _buildVotedContent(),
            ),
          ),

          // Bottom padding
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + Gaps.lg),
        ],
      ),
    );
  }

  Widget _buildVotingContent() {
    final going =
        _currentVotes.where((v) => v.status == RsvpVoteStatus.going).length;
    final notGoing =
        _currentVotes.where((v) => v.status == RsvpVoteStatus.notGoing).length;

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
        _currentVotes.where((v) => v.status == RsvpVoteStatus.going).toList()
          ..sort((a, b) {
            if (a.votedAt == null && b.votedAt == null) return 0;
            if (a.votedAt == null) return 1;
            if (b.votedAt == null) return -1;
            return b.votedAt!.compareTo(a.votedAt!);
          });
    final notGoing =
        _currentVotes.where((v) => v.status == RsvpVoteStatus.notGoing).toList()
          ..sort((a, b) {
            if (a.votedAt == null && b.votedAt == null) return 0;
            if (a.votedAt == null) return 1;
            if (b.votedAt == null) return -1;
            return b.votedAt!.compareTo(a.votedAt!);
          });
    final pending =
        _currentVotes.where((v) => v.status == RsvpVoteStatus.pending).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Can section
          if (going.isNotEmpty) ...[
            _VoteSection(
              title: 'Can',
              count: going.length,
              votes: going,
              currentUserId: widget.currentUserId,
            ),
            const SizedBox(height: Gaps.md),
          ],

          // Can't section
          if (notGoing.isNotEmpty) ...[
            _VoteSection(
              title: 'Can\'t',
              count: notGoing.length,
              votes: notGoing,
              currentUserId: widget.currentUserId,
            ),
            const SizedBox(height: Gaps.md),
          ],

          // Haven't Responded section
          if (pending.isNotEmpty) ...[
            _VoteSection(
              title: 'No response',
              count: pending.length,
              votes: pending,
              currentUserId: widget.currentUserId,
            ),
          ],
        ],
      ),
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
  final String? currentUserId;

  const _VoteSection({
    required this.title,
    required this.count,
    required this.votes,
    this.currentUserId,
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
          (vote) => _VoteItem(
            vote: vote,
            showDate: title != 'No response',
            currentUserId: currentUserId,
          ),
        ),
      ],
    );
  }
}

/// Individual vote item
class _VoteItem extends StatelessWidget {
  final RsvpVote vote;
  final bool showDate;
  final String? currentUserId;

  const _VoteItem({
    required this.vote,
    this.showDate = true,
    this.currentUserId,
  });

  String get _displayName {
    // Show "You" for current user, otherwise show the user name
    return vote.userId == currentUserId ? 'You' : vote.userName;
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = vote.userId == currentUserId;
            
    return InkWell(
      onTap: isCurrentUser ? null : () {
        // Close bottom sheet
        Navigator.pop(context);
        // Navigate to other user profile
        Navigator.pushNamed(
          context,
          AppRouter.otherProfile,
          arguments: {'userId': vote.userId},
        );
      },
      child: Padding(
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
                        errorBuilder: (context, error, stackTrace) {
                                                  return _buildDefaultAvatar();
                        },
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
                ),
              ),
            
            // Chevron indicator (only if not current user)
            if (!isCurrentUser) ...[              const SizedBox(width: Gaps.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandColors.text2,
                size: 16,
              ),
            ],
          ],
        ),
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
      // Show time if voted today (e.g., "10:23")
      final hour = votedAt.hour.toString().padLeft(2, '0');
      final minute = votedAt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${votedAt.day}/${votedAt.month}';
    }
  }
}

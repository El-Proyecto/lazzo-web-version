import 'package:flutter/material.dart';
import '../../../features/home/domain/entities/home_event.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../widgets/votes_bottom_sheet.dart';
import '../widgets/rsvp_widget.dart';
import '../dialogs/add_expense_bottom_sheet.dart';

/// Home event card state
/// Planning phase: pending (border color) or confirmed (green)
/// Living phase: living (purple)
/// Recap phase: recap (purple)
enum HomeEventCardState { pending, confirmed, living, recap }

/// Large event card for Home page "Next Event" section
/// Shows event details with state-specific border/chip colors
/// Includes Chat and Expense action buttons at bottom
class HomeEventCard extends StatefulWidget {
  final HomeEventEntity event;
  final HomeEventCardState state;
  final VoidCallback? onTap;
  final VoidCallback? onChatPressed;
  final VoidCallback? onExpensePressed;
  final Function(String eventId, bool? vote)? onVoteChanged;

  const HomeEventCard({
    super.key,
    required this.event,
    required this.state,
    this.onTap,
    this.onChatPressed,
    this.onExpensePressed,
    this.onVoteChanged,
  });

  @override
  State<HomeEventCard> createState() => _HomeEventCardState();
}

class _HomeEventCardState extends State<HomeEventCard> {
  late HomeEventEntity _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  void _updateVote(bool? vote) {
    setState(() {
      // Update the vote and recalculate going count and attendee data
      final updatedVotes = List<RsvpVote>.from(_currentEvent.allVotes);

      // Remove existing user vote if any
      updatedVotes.removeWhere((v) => v.userId == 'current_user');

      // Add new vote if not null
      if (vote != null) {
        final newVote = RsvpVote(
          id: 'vote_current_user_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'current_user',
          userName: 'You',
          userAvatar: null,
          status: vote ? RsvpVoteStatus.going : RsvpVoteStatus.notGoing,
          votedAt: DateTime.now(),
        );
        updatedVotes.add(newVote);
      }

      // Recalculate going count and attendee lists
      final goingVotes =
          updatedVotes.where((v) => v.status == RsvpVoteStatus.going).toList();
      final newGoingCount = goingVotes.length;

      // Sort votes to prioritize user first if they voted "Can"
      goingVotes.sort((a, b) {
        if (a.userId == 'current_user') return -1;
        if (b.userId == 'current_user') return 1;
        return 0;
      });

      final newAttendeeNames = goingVotes.map((v) => v.userName).toList();
      final newAttendeeAvatars =
          goingVotes.map((v) => v.userAvatar ?? '').toList();

      _currentEvent = _currentEvent.copyWith(
        userVote: vote,
        allVotes: updatedVotes,
        goingCount: newGoingCount,
        attendeeNames: newAttendeeNames,
        attendeeAvatars: newAttendeeAvatars,
        updateUserVote: true, // Allow explicit null setting
      );
    });
    widget.onVoteChanged?.call(_currentEvent.id, vote);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.sectionH),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: _getBorderColor(),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Status chip row
            _buildDateAndStatus(),
            const SizedBox(height: Gaps.sm),

            // Event emoji, title, and location
            _buildEventInfo(),
            const SizedBox(height: Gaps.sm),

            // Attendees info
            _buildAttendeeInfo(context),
            const SizedBox(height: Gaps.md),

            // Action buttons: Chat and Expense
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (widget.state) {
      case HomeEventCardState.pending:
        return BrandColors.border;
      case HomeEventCardState.confirmed:
        return BrandColors.planning;
      case HomeEventCardState.living:
        return BrandColors.living;
      case HomeEventCardState.recap:
        return BrandColors.recap;
    }
  }

  Color _getChipBackgroundColor() {
    switch (widget.state) {
      case HomeEventCardState.pending:
        return BrandColors.bg3;
      case HomeEventCardState.confirmed:
        return BrandColors.planning;
      case HomeEventCardState.living:
        return BrandColors.living;
      case HomeEventCardState.recap:
        return BrandColors.recap;
    }
  }

  Color _getChipBorderColor() {
    if (widget.state == HomeEventCardState.pending) {
      return BrandColors.border;
    }
    return Colors.transparent;
  }

  Color _getChipTextColor() {
    if (widget.state == HomeEventCardState.pending) {
      return BrandColors.text1;
    }
    return Colors.white;
  }

  String _getStatusLabel() {
    switch (widget.state) {
      case HomeEventCardState.pending:
        return 'Pending';
      case HomeEventCardState.confirmed:
        return 'Confirmed';
      case HomeEventCardState.living:
        return 'Living';
      case HomeEventCardState.recap:
        return 'Recap';
    }
  }

  Widget _buildDateAndStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date
        Text(
          _currentEvent.date != null
              ? _formatEventDate(_currentEvent.date!)
              : 'To be decided',
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text2,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.sectionV,
            vertical: Pads.ctlVXss,
          ),
          decoration: BoxDecoration(
            color: _getChipBackgroundColor(),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: _getChipBorderColor(),
              width: 1,
            ),
          ),
          child: Text(
            _getStatusLabel(),
            style: AppText.labelLarge.copyWith(
              color: _getChipTextColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Row(
      children: [
        // Event emoji
        Text(
          _currentEvent.emoji,
          style: const TextStyle(fontSize: 42),
        ),
        const SizedBox(width: Gaps.md),

        // Event name and location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentEvent.name,
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _currentEvent.location ?? 'To be decided',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeInfo(BuildContext context) {
    return InkWell(
      onTap: () => _showVotesBottomSheet(context),
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gaps.xxs),
        child: Row(
          children: [
            // Profile pictures
            _buildAttendeeAvatars(),
            const SizedBox(width: Gaps.xs),

            // Going count text with names
            Expanded(
              child: Text(
                _buildAttendeeText(),
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVotesBottomSheet(BuildContext context) {
    VotesBottomSheet.show(
      context: context,
      allVotes: _currentEvent.allVotes,
      eventName: _currentEvent.name,
      eventEmoji: _currentEvent.emoji,
      eventDate: _currentEvent.date != null
          ? _formatEventDate(_currentEvent.date!)
          : null,
      eventLocation: _currentEvent.location,
      userVote: _currentEvent.userVote,
      onVoteChanged: (vote) => _updateVote(vote),
    );
  }

  String _buildAttendeeText() {
    // If user hasn't voted yet, show "Tap to vote!" message
    if (_currentEvent.userVote == null) {
      return '${_currentEvent.goingCount} going • Tap to vote!';
    }

    // If user has voted, show "Tap to view votes" message
    return '${_currentEvent.goingCount} going • Tap to view votes';
  }

  Widget _buildAttendeeAvatars() {
    const avatarSize = 24.0;
    const overlap = 8.0;

    if (_currentEvent.attendeeAvatars.isEmpty) {
      return const SizedBox.shrink();
    }

    // Always show max 2 avatars + overflow indicator if there are more than 2
    final hasOverflow = _currentEvent.attendeeAvatars.length > 2;
    final visibleAvatars = hasOverflow
        ? _currentEvent.attendeeAvatars.take(2).toList()
        : _currentEvent.attendeeAvatars.take(3).toList();
    final remainingCount =
        hasOverflow ? _currentEvent.attendeeAvatars.length - 2 : 0;

    final totalWidth = hasOverflow
        ? avatarSize +
            2 * (avatarSize - overlap) // 2 avatars + overflow indicator
        : avatarSize + (visibleAvatars.length - 1) * (avatarSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: [
          // Regular avatars
          ...visibleAvatars.asMap().entries.map((entry) {
            final index = entry.key;
            final avatarUrl = entry.value;

            return Positioned(
              left: index * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BrandColors.bg2,
                    width: 2,
                  ),
                  image: avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Handle image loading error
                          },
                        )
                      : null,
                ),
                child: avatarUrl.isEmpty
                    ? Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: BrandColors.bg3,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 12,
                          color: BrandColors.text2,
                        ),
                      )
                    : null,
              ),
            );
          }),

          // Overflow indicator
          if (hasOverflow)
            Positioned(
              left: 2 * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.bg3,
                  border: Border.all(
                    color: BrandColors.bg2,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Chat button
        Expanded(
          child: GestureDetector(
            onTap: widget.onChatPressed,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: BrandColors.text1,
                      size: 18,
                    ),
                    const SizedBox(width: Gaps.xs),
                    Text(
                      'Chat',
                      style: AppText.bodyMediumEmph.copyWith(
                        color: BrandColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Gaps.sm),

        // Expense button
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Open add expense bottom sheet
              AddExpenseBottomSheet.show(
                context: context,
                participants: const [], // TODO P2: Load real participants
                onAddExpense: (title, paidByIds, payerIds, totalAmount) {
                  // TODO P2: Save expense to backend
                  debugPrint(
                    'Expense added: $title, \$${totalAmount.toStringAsFixed(2)}',
                  );
                  Navigator.of(context).pop();
                },
              );
              // Also call the callback if provided
              widget.onExpensePressed?.call();
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add,
                      color: BrandColors.text1,
                      size: 18,
                    ),
                    const SizedBox(width: Gaps.xs),
                    Text(
                      'Expense',
                      style: AppText.bodyMediumEmph.copyWith(
                        color: BrandColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatEventDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // For demo purposes, create a range with start and end times
    const startTime = '15:00';
    const endTime = '18:00';

    // Format: "Mon, 26 Feb • 15:00–18:00" for same day
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];

    return '$weekday, $day $month • $startTime–$endTime';
  }
}

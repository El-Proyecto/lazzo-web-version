import 'package:flutter/material.dart';
import '../../../features/group_hub/domain/entities/group_event_entity.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../widgets/votes_bottom_sheet.dart';
import '../widgets/rsvp_widget.dart';

/// Reusable event card for group hub Events section
/// Shows event details with date, status, attendees, and going count
class GroupEventCard extends StatefulWidget {
  final GroupEventEntity event;
  final VoidCallback? onTap;
  final Function(String eventId, bool? vote)? onVoteChanged;

  const GroupEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onVoteChanged,
  });

  @override
  State<GroupEventCard> createState() => _GroupEventCardState();
}

class _GroupEventCardState extends State<GroupEventCard> {
  late GroupEventEntity _currentEvent;

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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Status row
            _buildDateAndStatus(),
            const SizedBox(height: Gaps.sm),

            // Event title and location
            _buildEventInfo(),
            const SizedBox(height: Gaps.sm),

            // Attendees and going count
            _buildAttendeeInfo(context),
          ],
        ),
      ),
    );
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
            color: BrandColors.text1,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Status chip (non-interactive for display only)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.sectionV,
            vertical: Pads.ctlVXss,
          ),
          decoration: BoxDecoration(
            color: _currentEvent.status == GroupEventStatus.confirmed
                ? BrandColors.planning
                : BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: _currentEvent.status == GroupEventStatus.confirmed
                  ? BrandColors.planning
                  : BrandColors.border,
              width: 1,
            ),
          ),
          child: Text(
            _currentEvent.status == GroupEventStatus.confirmed
                ? 'Confirmed'
                : 'Pending',
            style: AppText.labelLarge.copyWith(
              color: _currentEvent.status == GroupEventStatus.confirmed
                  ? Colors.white
                  : BrandColors.text1,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_currentEvent.location != null) ...[
                const SizedBox(height: 2),
                Text(
                  _currentEvent.location!,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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

    if (_currentEvent.attendeeNames.isEmpty) {
      return '${_currentEvent.goingCount} going';
    }

    if (_currentEvent.attendeeNames.length == 1) {
      return '${_currentEvent.goingCount} going • ${_currentEvent.attendeeNames.first}';
    }

    if (_currentEvent.attendeeNames.length == 2) {
      return '${_currentEvent.goingCount} going • ${_currentEvent.attendeeNames[0]} and ${_currentEvent.attendeeNames[1]}';
    }

    if (_currentEvent.attendeeNames.length >= 3) {
      final othersCount = _currentEvent.attendeeNames.length - 2;
      return '${_currentEvent.goingCount} going • ${_currentEvent.attendeeNames[0]}, ${_currentEvent.attendeeNames[1]} and $othersCount other${othersCount > 1 ? 's' : ''}';
    }

    return '${_currentEvent.goingCount} going';
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
                  image: DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Handle image loading error
                    },
                  ),
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

          // Overflow indicator - replaces the third avatar position
          if (hasOverflow)
            Positioned(
              left: 2 *
                  (avatarSize -
                      overlap), // Position where third avatar would be
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
    final startTime = '15:00';
    final endTime = '18:00';

    // Format: "Mon, 26 Feb • 15:00–18:00" for same day
    // Format: "22–23 Oct • 15:00–23:00" for different days

    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];

    // For demo, we'll show same day format
    return '$weekday, $day $month • $startTime–$endTime';
  }
}

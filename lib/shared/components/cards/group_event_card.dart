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
        participantCount: _currentEvent.participantCount,
        photoCount: _currentEvent.photoCount,
        maxPhotos: _currentEvent.maxPhotos,
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
            // Time remaining (for Live/Recap) or Date (for Confirmed) with Status badge
            _buildTopRow(),
            const SizedBox(height: Gaps.sm),

            // Event emoji, title and location
            _buildEventInfo(),
            const SizedBox(height: Gaps.sm),

            // Participants/photos count OR RSVP info (depending on status)
            _buildBottomInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time remaining (Live/Recap) or Date (Confirmed)
        Expanded(
          child: Text(
            _getTopRowText(),
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: Gaps.sm),

        // Status badge
        _buildStatusBadge(),
      ],
    );
  }

  String _getTopRowText() {
    switch (_currentEvent.status) {
      case GroupEventStatus.live:
      case GroupEventStatus.recap:
        if (_currentEvent.endsAt != null) {
          return _formatTimeRemaining(_currentEvent.endsAt!);
        }
        return 'In progress';
      case GroupEventStatus.confirmed:
        if (_currentEvent.date != null) {
          return _formatEventDate(_currentEvent.date!);
        }
        return 'Date to be confirmed';
      case GroupEventStatus.pending:
        return 'To be decided';
    }
  }

  String _formatTimeRemaining(DateTime endsAt) {
    final now = DateTime.now();
    final difference = endsAt.difference(now);

    if (difference.isNegative) {
      return 'Ended';
    }

    // Se mais de 24 horas, mostrar data e hora específica
    if (difference.inHours >= 24) {
      return _formatEventDateTime(endsAt);
    }

    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
    }

    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} left';
    }

    return 'Less than a minute left';
  }

  String _formatEventDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    // Formatar hora
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    // Se é amanhã
    if (dateOnly.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow • $timeStr';
    }

    // Formato: "Day, DD Mon • HH:MM"
    final weekday = _getWeekdayShort(dateTime.weekday);
    final day = dateTime.day;
    final month = _getMonthShort(dateTime.month);

    return '$weekday, $day $month • $timeStr';
  }

  String _getWeekdayShort(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (_currentEvent.status) {
      case GroupEventStatus.live:
        backgroundColor = const Color(0xFF7C3AED); // Purple for Live
        textColor = Colors.white;
        label = 'Live';
        break;
      case GroupEventStatus.recap:
        backgroundColor = const Color(0xFFEA580C); // Orange for Recap
        textColor = Colors.white;
        label = 'Recap';
        break;
      case GroupEventStatus.confirmed:
        backgroundColor = const Color(0xFF16A34A); // Green for Confirmed
        textColor = Colors.white;
        label = 'Confirmed';
        break;
      case GroupEventStatus.pending:
        backgroundColor = BrandColors.bg3;
        textColor = BrandColors.text2;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.sectionV,
        vertical: Pads.ctlVXss,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        style: AppText.labelLarge.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
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

  Widget _buildBottomInfo(BuildContext context) {
    // For Live/Recap events, show participants and photos count
    if (_currentEvent.status == GroupEventStatus.live ||
        _currentEvent.status == GroupEventStatus.recap) {
      return _buildParticipantInfo(context);
    }

    // For Confirmed events, show RSVP info
    if (_currentEvent.status == GroupEventStatus.confirmed) {
      return _buildRsvpInfo(context);
    }

    // For Pending events, show participants count if any
    if (_currentEvent.participantCount > 0) {
      return _buildParticipantInfo(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildParticipantInfo(BuildContext context) {
    return InkWell(
      onTap: () => _showVotesBottomSheet(context),
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gaps.xxs),
        child: Row(
          children: [
            // Profile pictures (apenas avatares, sem texto)
            _buildAttendeeAvatars(),
            const SizedBox(width: Gaps.xs),

            // Photos count (se houver)
            if (_currentEvent.photoCount > 0 || _currentEvent.maxPhotos != null)
              Expanded(
                child: Text(
                  _buildPhotosOnlyText(),
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

  Widget _buildRsvpInfo(BuildContext context) {
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

            // RSVP text ("5 going • You, Sarah and 3 others")
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

  String _buildPhotosOnlyText() {
    if (_currentEvent.maxPhotos != null) {
      return '${_currentEvent.photoCount}/${_currentEvent.maxPhotos} photos';
    } else if (_currentEvent.photoCount > 0) {
      return '${_currentEvent.photoCount} photo${_currentEvent.photoCount != 1 ? 's' : ''}';
    }
    return '';
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

    // Show max 3 avatars + overflow indicator if there are more than 3
    final hasOverflow = _currentEvent.attendeeAvatars.length > 3;
    final visibleAvatars = hasOverflow
        ? _currentEvent.attendeeAvatars.take(3).toList()
        : _currentEvent.attendeeAvatars;
    final remainingCount =
        hasOverflow ? _currentEvent.attendeeAvatars.length - 3 : 0;

    final totalWidth = hasOverflow
        ? avatarSize +
            3 * (avatarSize - overlap) // 3 avatars + overflow indicator
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

          // Overflow indicator - appears after the third avatar
          if (hasOverflow)
            Positioned(
              left: 3 *
                  (avatarSize -
                      overlap), // Position where fourth avatar would be
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

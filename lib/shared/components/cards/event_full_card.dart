import 'package:flutter/material.dart';
import '../../../features/group_hub/domain/entities/group_event_entity.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../widgets/votes_bottom_sheet.dart';
import '../widgets/photos_bottom_sheet.dart';

/// Event full card state for group hub
/// Planning phase: pending (chip bg3) or confirmed (green chip)
/// Living phase: living (purple chip)
/// Recap phase: recap (purple chip)
enum EventFullCardState { pending, confirmed, living, recap }

/// Full event card for group hub Events section
/// Shows event details with date, status chip, attendees, and going count
/// Supports voting for planning phase events
class EventFullCard extends StatefulWidget {
  final GroupEventEntity event;
  final EventFullCardState state;
  final VoidCallback? onTap;
  final Function(String eventId, bool? vote)? onVoteChanged;

  const EventFullCard({
    super.key,
    required this.event,
    required this.state,
    this.onTap,
    this.onVoteChanged,
  });

  @override
  State<EventFullCard> createState() => _EventFullCardState();
}

class _EventFullCardState extends State<EventFullCard> {
  late GroupEventEntity _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  @override
  void didUpdateWidget(covariant EventFullCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when parent passes new event data (e.g., after voting)
    if (widget.event != oldWidget.event) {
      setState(() {
        _currentEvent = widget.event;
      });
    }
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

  Color _getChipBackgroundColor() {
    switch (widget.state) {
      case EventFullCardState.pending:
        return BrandColors.bg3;
      case EventFullCardState.confirmed:
        return BrandColors.planning;
      case EventFullCardState.living:
        return BrandColors.living;
      case EventFullCardState.recap:
        return BrandColors.recap;
    }
  }

  Color _getChipBorderColor() {
    if (widget.state == EventFullCardState.pending) {
      return BrandColors.border;
    }
    return Colors.transparent;
  }

  Color _getChipTextColor() {
    if (widget.state == EventFullCardState.pending) {
      return BrandColors.text1;
    }
    return Colors.white;
  }

  String _getStatusLabel() {
    switch (widget.state) {
      case EventFullCardState.pending:
        return 'Pending';
      case EventFullCardState.confirmed:
        return 'Confirmed';
      case EventFullCardState.living:
        return 'Live';
      case EventFullCardState.recap:
        return 'Recap';
    }
  }

  Widget _buildDateAndStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date or Time left
        Text(
          _getDateOrTimeLeftText(),
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

  String _getDateOrTimeLeftText() {
    // For Living state: show time left until end
    if (widget.state == EventFullCardState.living &&
        _currentEvent.endDate != null) {
      return _formatTimeLeft(_currentEvent.endDate!);
    }

    // For Recap state: show time left in 24h upload window
    if (widget.state == EventFullCardState.recap &&
        _currentEvent.endDate != null) {
      final uploadDeadline =
          _currentEvent.endDate!.add(const Duration(hours: 24));
      return _formatTimeLeft(uploadDeadline);
    }

    // For Pending/Confirmed: show formatted date
    if (_currentEvent.date != null) {
      return _formatEventDate(_currentEvent.date!);
    }

    return 'To be decided';
  }

  String _formatTimeLeft(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative) {
      return 'Ended';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} left';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} left';
    } else if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''} left';
    } else {
      return 'Less than a minute left';
    }
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
    // Show photos bottom sheet for Living/Recap, votes for Pending/Confirmed
    return InkWell(
      onTap: () {
        if (widget.state == EventFullCardState.living ||
            widget.state == EventFullCardState.recap) {
          _showPhotosBottomSheet(context);
        } else {
          _showVotesBottomSheet(context);
        }
      },
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gaps.xxs),
        child: Row(
          children: [
            // Profile pictures (or expired message)
            _buildAttendeeAvatars(),
            
            // Only show vote count if not expired
            if (_buildAttendeeText().isNotEmpty) ...[
              const SizedBox(width: Gaps.xs),
              // Going count text with names or photo count
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
          ],
        ),
      ),
    );
  }

  void _showPhotosBottomSheet(BuildContext context) {
    PhotosBottomSheet.show(
      context: context,
      participants: _currentEvent.participantPhotos,
      totalPhotos: _currentEvent.photoCount,
      maxPhotos: _currentEvent.maxPhotos,
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
      onVoteChanged: widget.onVoteChanged != null
          ? (vote) => widget.onVoteChanged!(_currentEvent.id, vote)
          : null,
    );
  }

  String _buildAttendeeText() {
    // Check if event is expired (pending status + date passed)
    final isExpired = widget.state == EventFullCardState.pending &&
        _currentEvent.date != null &&
        DateTime.now().isAfter(_currentEvent.date!);

    // If expired, don't show any vote counts (avatars section shows expired message)
    if (isExpired) {
      return '';
    }

    // For Living/Recap states: show photo count
    if (widget.state == EventFullCardState.living ||
        widget.state == EventFullCardState.recap) {
      if (_currentEvent.photoCount == 0) {
        return '${_currentEvent.goingCount} participants • No photos yet';
      }
      return '${_currentEvent.goingCount} participants • ${_currentEvent.photoCount}/${_currentEvent.maxPhotos} photos';
    }

    // For Pending/Confirmed states: show names
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

    // Check if event is expired (pending status + date passed)
    final isExpired = widget.state == EventFullCardState.pending &&
        _currentEvent.date != null &&
        DateTime.now().isAfter(_currentEvent.date!);

    // If expired, show expired state text instead of avatars
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.all(Gaps.xs),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Text(
          'Event date expired',
          style: AppText.labelLarge.copyWith(
            color: BrandColors.text2,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

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

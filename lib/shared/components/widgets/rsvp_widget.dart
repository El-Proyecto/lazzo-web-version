import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../common/common_bottom_sheet.dart';
import '../common/top_banner.dart';
import '../../../features/create_event/presentation/widgets/inline_date_picker.dart';
import '../../../features/create_event/presentation/widgets/inline_time_picker.dart';

/// RSVP data model for view votes bottom sheet
class RsvpVote {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final RsvpVoteStatus status;
  final DateTime? votedAt;

  const RsvpVote({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.status,
    this.votedAt,
  });
}

enum RsvpVoteStatus { going, notGoing, pending }

/// RSVP widget for event confirmation
/// Allows users to vote and view all votes
class RsvpWidget extends StatelessWidget {
  final int goingCount;
  final int notGoingCount;
  final int pendingCount;
  final bool? userVote; // true = going, false = not going, null = pending
  final VoidCallback onGoingPressed;
  final VoidCallback onNotGoingPressed;
  final List<RsvpVote> allVotes;
  final VoidCallback? onAddSuggestion;
  final DateTime? eventStartDateTime;
  final DateTime? eventEndDateTime;
  final bool isHost; // Whether current user is host/admin
  final bool hasSuggestions; // Whether suggestions already exist
  final String? currentUserId; // Current user ID for profile navigation

  const RsvpWidget({
    super.key,
    required this.goingCount,
    required this.notGoingCount,
    required this.pendingCount,
    this.userVote,
    required this.onGoingPressed,
    required this.onNotGoingPressed,
    required this.allVotes,
    this.onAddSuggestion,
    this.eventStartDateTime,
    this.eventEndDateTime,
    this.isHost = false,
    this.hasSuggestions = false,
    this.currentUserId,
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
            children: [
              Expanded(
                child: Text('Can you make it?', style: AppText.labelLarge),
              ),
              // Only show view votes if there are any votes
              if (goingCount + notGoingCount + pendingCount > 0) ...[
                InkWell(
                  onTap: () => _showViewVotesBottomSheet(context),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Gaps.xxs),
                    child: Row(
                      children: [
                        Text(
                          'View votes',
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                          ),
                        ),
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
            ],
          ),
          const SizedBox(height: Gaps.md),

          // Vote buttons
          Row(
            children: [
              Expanded(
                child: _VoteButton(
                  label: 'Can',
                  count: goingCount,
                  isSelected: userVote == true,
                  color: BrandColors.planning,
                  onPressed: onGoingPressed,
                ),
              ),
              const SizedBox(width: Gaps.sm),
              Expanded(
                child: _VoteButton(
                  label: 'Can\'t',
                  count: notGoingCount,
                  isSelected: userVote == false,
                  color: BrandColors.cantVote,
                  onPressed: onNotGoingPressed,
                ),
              ),
            ],
          ),

          // Add suggestion button (shown when user votes "not going" AND no suggestions exist)
          if (userVote == false &&
              onAddSuggestion != null &&
              !hasSuggestions) ...[
            const SizedBox(height: Gaps.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (onAddSuggestion != null) {
                    onAddSuggestion!();
                  } else {
                    _showAddSuggestionBottomSheet(context);
                  }
                },
                icon: const Icon(Icons.add, size: IconSizes.sm),
                label: Text('Add suggestion', style: AppText.bodyMediumEmph),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.text1,
                  side: const BorderSide(color: BrandColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.ctlH,
                    vertical: Pads.ctlV,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showViewVotesBottomSheet(BuildContext context) {
    final going =
        allVotes.where((v) => v.status == RsvpVoteStatus.going).toList()
          ..sort((a, b) {
            if (a.votedAt == null && b.votedAt == null) return 0;
            if (a.votedAt == null) return 1;
            if (b.votedAt == null) return -1;
            return b.votedAt!.compareTo(a.votedAt!);
          });
    final notGoing =
        allVotes.where((v) => v.status == RsvpVoteStatus.notGoing).toList()
          ..sort((a, b) {
            if (a.votedAt == null && b.votedAt == null) return 0;
            if (a.votedAt == null) return 1;
            if (b.votedAt == null) return -1;
            return b.votedAt!.compareTo(a.votedAt!);
          });
    final pending =
        allVotes.where((v) => v.status == RsvpVoteStatus.pending).toList();

    CommonBottomSheet.show(
      context: context,
      title: 'Votes',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Can section
          if (going.isNotEmpty) ...[
            _VoteSection(
              title: 'Can',
              count: going.length,
              votes: going,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: Gaps.lg),
          ],

          // Can't section
          if (notGoing.isNotEmpty) ...[
            _VoteSection(
              title: 'Can\'t',
              count: notGoing.length,
              votes: notGoing,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: Gaps.lg),
          ],

          // Haven't Responded section
          if (pending.isNotEmpty) ...[
            _VoteSection(
              title: 'No response',
              count: pending.length,
              votes: pending,
              currentUserId: currentUserId,
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSuggestionBottomSheet(BuildContext context) {
    // Initialize with event dates or today as fallback
    final now = DateTime.now();
    final fallbackStart = DateTime(
      now.year,
      now.month,
      now.day,
      18,
      0,
    ); // 6 PM today
    final fallbackEnd = DateTime(
      now.year,
      now.month,
      now.day,
      22,
      0,
    ); // 10 PM today

    DateTime? startDate = eventStartDateTime ?? fallbackStart;
    TimeOfDay? startTime = eventStartDateTime != null
        ? TimeOfDay.fromDateTime(eventStartDateTime!)
        : TimeOfDay.fromDateTime(fallbackStart);
    DateTime? endDate = eventEndDateTime ?? fallbackEnd;
    TimeOfDay? endTime = eventEndDateTime != null
        ? TimeOfDay.fromDateTime(eventEndDateTime!)
        : TimeOfDay.fromDateTime(fallbackEnd);

    // Track original values to check if changed
    final originalStartDate = startDate;
    final originalStartTime = startTime;
    final originalEndDate = endDate;
    final originalEndTime = endTime;

    bool isStartDatePickerExpanded = false;
    bool isStartTimePickerExpanded = false;
    bool isEndDatePickerExpanded = false;
    bool isEndTimePickerExpanded = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.85, // 85% of screen height
          decoration: const BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Radii.md),
              topRight: Radius.circular(Radii.md),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: Gaps.sm),
                decoration: BoxDecoration(
                  color: BrandColors.text2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(Pads.sectionH),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Suggestion', style: AppText.titleMediumEmph),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: BrandColors.text2),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    // Check if any value has changed from original
                    final bool hasChanges = startDate != originalStartDate ||
                        startTime != originalStartTime ||
                        endDate != originalEndDate ||
                        endTime != originalEndTime;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Pads.sectionH,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Start Date & Time Row
                          _buildDateTimeRow(
                            label: 'Start',
                            date: startDate,
                            time: startTime,
                            isDatePickerExpanded: isStartDatePickerExpanded,
                            isTimePickerExpanded: isStartTimePickerExpanded,
                            onDateTap: () {
                              setState(() {
                                isStartDatePickerExpanded =
                                    !isStartDatePickerExpanded;
                                isStartTimePickerExpanded = false;
                                isEndDatePickerExpanded = false;
                                isEndTimePickerExpanded = false;
                              });
                            },
                            onTimeTap: () {
                              setState(() {
                                isStartTimePickerExpanded =
                                    !isStartTimePickerExpanded;
                                isStartDatePickerExpanded = false;
                                isEndDatePickerExpanded = false;
                                isEndTimePickerExpanded = false;
                              });
                            },
                            onDateChanged: (date) {
                              setState(() {
                                startDate = date;
                                isStartDatePickerExpanded = false;
                              });
                            },
                            onTimeChanged: (time) {
                              setState(() {
                                startTime = time;
                              });
                            },
                          ),

                          if (isStartDatePickerExpanded) ...[
                            const SizedBox(height: Gaps.sm),
                            InlineDatePicker(
                              selectedDate: startDate,
                              onDateChanged: (date) {
                                setState(() {
                                  startDate = date;
                                  isStartDatePickerExpanded = false;
                                });
                              },
                            ),
                          ],

                          if (isStartTimePickerExpanded) ...[
                            const SizedBox(height: Gaps.sm),
                            InlineTimePicker(
                              selectedTime: startTime,
                              onTimeChanged: (time) {
                                setState(() {
                                  startTime = time;
                                });
                              },
                            ),
                          ],

                          const SizedBox(height: Gaps.sm),

                          // End Date & Time Row
                          _buildDateTimeRow(
                            label: 'End',
                            date: endDate,
                            time: endTime,
                            isDatePickerExpanded: isEndDatePickerExpanded,
                            isTimePickerExpanded: isEndTimePickerExpanded,
                            onDateTap: () {
                              setState(() {
                                isEndDatePickerExpanded =
                                    !isEndDatePickerExpanded;
                                isEndTimePickerExpanded = false;
                                isStartDatePickerExpanded = false;
                                isStartTimePickerExpanded = false;
                              });
                            },
                            onTimeTap: () {
                              setState(() {
                                isEndTimePickerExpanded =
                                    !isEndTimePickerExpanded;
                                isEndDatePickerExpanded = false;
                                isStartDatePickerExpanded = false;
                                isStartTimePickerExpanded = false;
                              });
                            },
                            onDateChanged: (date) {
                              setState(() {
                                endDate = date;
                                isEndDatePickerExpanded = false;
                              });
                            },
                            onTimeChanged: (time) {
                              setState(() {
                                endTime = time;
                              });
                            },
                          ),

                          if (isEndDatePickerExpanded) ...[
                            const SizedBox(height: Gaps.sm),
                            InlineDatePicker(
                              selectedDate: endDate,
                              onDateChanged: (date) {
                                setState(() {
                                  endDate = date;
                                  isEndDatePickerExpanded = false;
                                });
                              },
                            ),
                          ],

                          if (isEndTimePickerExpanded) ...[
                            const SizedBox(height: Gaps.sm),
                            InlineTimePicker(
                              selectedTime: endTime,
                              onTimeChanged: (time) {
                                setState(() {
                                  endTime = time;
                                });
                              },
                            ),
                          ],

                          const Spacer(),

                          // Submit button - only enabled when changes are made
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(
                              bottom: Pads.sectionV,
                            ),
                            child: FilledButton(
                              onPressed: hasChanges &&
                                      startDate != null &&
                                      startTime != null &&
                                      endDate != null &&
                                      endTime != null
                                  ? () {
                                      Navigator.of(context).pop();
                                      // TODO: Create poll with the selected dates/times
                                      TopBanner.showSuccess(
                                        context,
                                        message: 'Suggestion added!',
                                      );
                                    }
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: hasChanges
                                    ? Colors.green
                                    : BrandColors.text2,
                                foregroundColor: hasChanges
                                    ? Colors.white
                                    : BrandColors.text2,
                                padding: const EdgeInsets.symmetric(
                                  vertical: Pads.ctlV,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Add Suggestion',
                                style: AppText.bodyMediumEmph,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateTimeRow({
    required String label,
    required DateTime? date,
    required TimeOfDay? time,
    required bool isDatePickerExpanded,
    required bool isTimePickerExpanded,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
    required Function(DateTime) onDateChanged,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Label
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const Spacer(),

        // Date Button
        _CreateEventDateTimeButton(
          label:
              date != null ? '${date.day}/${date.month}/${date.year}' : 'Date',
          icon: Icons.calendar_today,
          isExpanded: isDatePickerExpanded,
          onTap: onDateTap,
        ),

        const SizedBox(width: Gaps.xs),

        // Time Button
        _CreateEventDateTimeButton(
          label: time != null
              ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
              : 'Time',
          icon: Icons.access_time,
          isExpanded: isTimePickerExpanded,
          onTap: onTimeTap,
        ),
      ],
    );
  }
}

/// Date/Time button matching create_event design
class _CreateEventDateTimeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;

  const _CreateEventDateTimeButton({
    required this.label,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
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
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: isExpanded
              ? Border.all(color: BrandColors.planning, width: 1)
              : Border.all(color: BrandColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: BrandColors.text2),
            const SizedBox(width: Gaps.xs),
            Text(
              label,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text1,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vote section in bottom sheet
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
      onTap: () {
        // Close bottom sheet
        Navigator.pop(context);
        
        if (isCurrentUser) {
          // Navigate to own profile with back button
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {'showBackButton': true},
          );
        } else {
          // Navigate to other user profile
          Navigator.pushNamed(
            context,
            '/other-profile',
            arguments: {'userId': vote.userId},
          );
        }
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
                _formatDate(vote.votedAt!),
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
              ),
            
            // Chevron indicator (always show for navigation)
            const SizedBox(width: Gaps.xs),
            const Icon(
              Icons.chevron_right_rounded,
              color: BrandColors.text2,
              size: 16,
            ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      // Show time if voted today (e.g., "10:23")
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
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
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : BrandColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: AppText.bodyMedium.copyWith(
                        color:
                            isSelected ? BrandColors.text1 : BrandColors.text2,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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

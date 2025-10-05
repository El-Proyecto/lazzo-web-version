import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../dialogs/common_bottom_sheet.dart';
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
              Text('Can you make it?', style: AppText.labelLarge),
              InkWell(
                onTap: () => _showViewVotesBottomSheet(context),
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gaps.xs,
                    vertical: Gaps.xxs,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View votes',
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

          // Add suggestion button (shown when user votes "not going")
          if (userVote == false && onAddSuggestion != null) ...[
            const SizedBox(height: Gaps.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddSuggestionBottomSheet(context),
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

  void _showViewVotesBottomSheet(BuildContext context) {
    final going = allVotes
        .where((v) => v.status == RsvpVoteStatus.going)
        .toList();
    final notGoing = allVotes
        .where((v) => v.status == RsvpVoteStatus.notGoing)
        .toList();
    final pending = allVotes
        .where((v) => v.status == RsvpVoteStatus.pending)
        .toList();

    CommonBottomSheet.show(
      context: context,
      title: 'Votes',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Can section
          if (going.isNotEmpty) ...[
            _VoteSection(title: 'Can', count: going.length, votes: going),
            const SizedBox(height: Gaps.lg),
          ],

          // Can't section
          if (notGoing.isNotEmpty) ...[
            _VoteSection(
              title: 'Can\'t',
              count: notGoing.length,
              votes: notGoing,
            ),
            const SizedBox(height: Gaps.lg),
          ],

          // Haven't Responded section
          if (pending.isNotEmpty) ...[
            _VoteSection(
              title: 'Haven\'t Responded',
              count: pending.length,
              votes: pending,
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSuggestionBottomSheet(BuildContext context) {
    DateTime? startDate;
    TimeOfDay? startTime;
    DateTime? endDate;
    TimeOfDay? endTime;

    CommonBottomSheet.show(
      context: context,
      title: 'Add Suggestion',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start Date & Time
            Text('Start', style: AppText.labelLarge),
            const SizedBox(height: Gaps.sm),

            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    label: startDate != null
                        ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                        : 'Date',
                    isSelected: startDate != null,
                    onPressed: () {
                      // Show date picker inline
                      setState(() {
                        startDate = DateTime.now().add(const Duration(days: 1));
                      });
                    },
                  ),
                ),
                const SizedBox(width: Gaps.sm),
                Expanded(
                  child: _DateTimeButton(
                    label: startTime != null
                        ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                        : 'Time',
                    isSelected: startTime != null,
                    onPressed: () {
                      // Show time picker inline
                      setState(() {
                        startTime = const TimeOfDay(hour: 19, minute: 0);
                      });
                    },
                  ),
                ),
              ],
            ),

            if (startDate != null) ...[
              const SizedBox(height: Gaps.sm),
              InlineDatePicker(
                selectedDate: startDate,
                onDateChanged: (date) {
                  setState(() {
                    startDate = date;
                  });
                },
              ),
            ],

            if (startTime != null) ...[
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

            const SizedBox(height: Gaps.lg),

            // End Date & Time
            Text('End', style: AppText.labelLarge),
            const SizedBox(height: Gaps.sm),

            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    label: endDate != null
                        ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                        : 'Date',
                    isSelected: endDate != null,
                    onPressed: () {
                      // Show date picker inline
                      setState(() {
                        endDate = DateTime.now().add(const Duration(days: 1));
                      });
                    },
                  ),
                ),
                const SizedBox(width: Gaps.sm),
                Expanded(
                  child: _DateTimeButton(
                    label: endTime != null
                        ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                        : 'Time',
                    isSelected: endTime != null,
                    onPressed: () {
                      // Show time picker inline
                      setState(() {
                        endTime = const TimeOfDay(hour: 22, minute: 0);
                      });
                    },
                  ),
                ),
              ],
            ),

            if (endDate != null) ...[
              const SizedBox(height: Gaps.sm),
              InlineDatePicker(
                selectedDate: endDate,
                onDateChanged: (date) {
                  setState(() {
                    endDate = date;
                  });
                },
              ),
            ],

            if (endTime != null) ...[
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

            const SizedBox(height: Gaps.xl),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    (startDate != null &&
                        startTime != null &&
                        endDate != null &&
                        endTime != null)
                    ? () {
                        Navigator.of(context).pop();
                        // TODO: Create poll with the selected dates/times
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Suggestion added!')),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: BrandColors.text1,
                  foregroundColor: BrandColors.bg1,
                  padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
                child: Text('Add Suggestion', style: AppText.bodyMediumEmph),
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

  const _VoteSection({
    required this.title,
    required this.count,
    required this.votes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with count
        Row(
          children: [
            Text(title, style: AppText.labelLarge),
            const SizedBox(width: Gaps.xs),
            Text(
              count.toString(),
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
        const SizedBox(height: Gaps.md),

        // Vote list
        ...votes.map((vote) => _VoteItem(vote: vote)),
      ],
    );
  }
}

/// Individual vote item
class _VoteItem extends StatelessWidget {
  final RsvpVote vote;

  const _VoteItem({required this.vote});

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
          Expanded(child: Text(vote.userName, style: AppText.bodyMedium)),

          // Date (if voted)
          if (vote.votedAt != null)
            Text(
              _formatDate(vote.votedAt!),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
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

/// Date/Time button for the add suggestion bottom sheet
class _DateTimeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _DateTimeButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TouchTargets.min,
      decoration: BoxDecoration(
        color: isSelected
            ? BrandColors.text1.withValues(alpha: 0.1)
            : BrandColors.bg3,
        border: Border.all(
          color: isSelected ? BrandColors.text1 : BrandColors.border,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Center(
          child: Text(
            label,
            style: AppText.bodyMedium.copyWith(
              color: isSelected ? BrandColors.text1 : BrandColors.text2,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

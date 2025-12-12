import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/home/domain/entities/home_event.dart';
import '../../../features/event/presentation/providers/event_participants_provider.dart';
import '../../../features/expense/presentation/providers/event_expense_providers.dart';
import '../../../features/inbox/presentation/providers/payments_provider.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../widgets/votes_bottom_sheet.dart';
import '../dialogs/add_expense_bottom_sheet.dart';

/// Home event card state
/// Planning phase: pending (border color) or confirmed (green)
/// Living phase: living (purple)
/// Recap phase: recap (purple)
enum HomeEventCardState { pending, confirmed, living, recap }

/// Large event card for Home page "Next Event" section
/// Shows event details with state-specific border/chip colors
/// Includes Chat and Expense action buttons at bottom
class HomeEventCard extends ConsumerStatefulWidget {
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
  ConsumerState<HomeEventCard> createState() => _HomeEventCardState();
}

class _HomeEventCardState extends ConsumerState<HomeEventCard> {
  late HomeEventEntity _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  @override
  void didUpdateWidget(HomeEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when event changes from parent
    if (oldWidget.event.id != widget.event.id ||
        oldWidget.event.name != widget.event.name ||
        oldWidget.event.date != widget.event.date) {
      _currentEvent = widget.event;
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
        // Date or Time Left
        Text(
          _getDateOrTimeLeftText(),
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text1,
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

        // Event name, group, and location
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
              const SizedBox(height: 4),
              // Location with icon
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: BrandColors.text2,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _currentEvent.location ?? 'To be decided',
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_currentEvent.groupName != null) const SizedBox(height: 2),
              // Group with icon
              if (_currentEvent.groupName != null)
                Row(
                  children: [
                    const Icon(
                      Icons.group,
                      size: 14,
                      color: BrandColors.text2,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _currentEvent.groupName!,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeInfo(BuildContext context) {
    // Show votes bottom sheet when tapping on attendee info
    // This displays all participants with their RSVPs
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

            // Going count text with names OR photo count
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
    // Get current user ID and avatar
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;
    final currentUserAvatar = currentUser?.userMetadata?['avatar_url'] as String?;
    
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
      currentUserId: currentUserId,
      currentUserAvatar: currentUserAvatar,
    );
  }

  String _buildAttendeeText() {
    final participantText =
        _currentEvent.goingCount == 1 ? 'participant' : 'participants';

    // For Living and Recap states, include photo count
    if (widget.state == HomeEventCardState.living ||
        widget.state == HomeEventCardState.recap) {
      final photoInfo = _currentEvent.photoCount == 0
          ? 'No photos yet'
          : '${_currentEvent.photoCount}/${_currentEvent.maxPhotos} ${_currentEvent.photoCount == 1 ? 'photo' : 'photos'}';

      return '${_currentEvent.goingCount} $participantText • $photoInfo';
    }

    // For other states (Pending/Confirmed), show simple participant count
    return '${_currentEvent.goingCount} $participantText';
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
            onTap: () {
              // Navigate to event chat page
              if (widget.state == HomeEventCardState.living) {
                Navigator.pushNamed(
                  context,
                  '/event-chat',
                  arguments: {'eventId': _currentEvent.id},
                );
              } else {
                // For non-living events, use the callback if provided
                widget.onChatPressed?.call();
              }
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
            onTap: () async {
              try {
                final currentState =
                    ref.read(eventParticipantsProvider(_currentEvent.id));

                // If loading, wait for it to complete
                if (currentState is AsyncLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loading participants...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Wait a bit and try again
                  await Future.delayed(const Duration(milliseconds: 1500));

                  final newState =
                      ref.read(eventParticipantsProvider(_currentEvent.id));

                  if (newState is AsyncData) {
                    final participants = newState.value ?? [];

                    if (participants.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('No participants found for this event')),
                        );
                      }
                      return;
                    }

                    // Get current user ID
                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;

                    // Convert participants - replace current user name with "You"
                    final participantOptions = participants
                        .map((p) => ExpenseParticipantOption(
                              id: p.userId,
                              name: p.userId == currentUserId
                                  ? 'You'
                                  : p.displayName,
                              avatarUrl: p.avatarUrl,
                            ))
                        .toList();

                    // Sort: "You" first, then alphabetically by name
                    participantOptions.sort((a, b) {
                      if (a.name == 'You') return -1;
                      if (b.name == 'You') return 1;
                      return a.name.compareTo(b.name);
                    });

                    // Capture eventId before async callback
                    final eventId = _currentEvent.id;

                    if (mounted) {
                      AddExpenseBottomSheet.show(
                        context: context,
                        participants: participantOptions,
                        onAddExpense: (title, paidById, participantsOwe,
                            totalAmount) async {
                          try {
                            // ✅ Create expense in Supabase
                            await ref
                                .read(eventExpensesProvider(eventId).notifier)
                                .addExpense(
                              description: title,
                              amount: totalAmount,
                              paidBy: paidById,
                              participantsOwe: participantsOwe,
                              participantsPaid: [],
                            );

                            // ✅ Invalidate payments to refresh home page
                            ref.invalidate(paymentsOwedToUserProvider);
                            ref.invalidate(paymentsUserOwesProvider);

                            // Show success message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Expense "$title" created!'),
                                  backgroundColor: BrandColors.planning,
                                ),
                              );
                            }

                            widget.onExpensePressed?.call();
                          } catch (e) {
                            // Show error message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error creating expense: $e'),
                                  backgroundColor: BrandColors.cantVote,
                                ),
                              );
                            }
                          }
                        },
                      );
                    }
                  } else if (newState is AsyncError) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Error loading participants: ${newState.error}')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Still loading, please try again')),
                      );
                    }
                  }
                  return;
                }

                // If already loaded, use data directly
                if (currentState is AsyncData) {
                  final participants = currentState.value ?? [];

                  if (participants.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('No participants found for this event')),
                    );
                    return;
                  }

                  // Get current user ID
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;

                  // Convert participants - replace current user name with "You"
                  final participantOptions = participants
                      .map((p) => ExpenseParticipantOption(
                            id: p.userId,
                            name: p.userId == currentUserId
                                ? 'You'
                                : p.displayName,
                            avatarUrl: p.avatarUrl,
                          ))
                      .toList();

                  // Sort: "You" first, then alphabetically by name
                  participantOptions.sort((a, b) {
                    if (a.name == 'You') return -1;
                    if (b.name == 'You') return 1;
                    return a.name.compareTo(b.name);
                  });

                  // Capture event ID before async callback
                  final eventId = _currentEvent.id;

                  // Show the bottom sheet
                  AddExpenseBottomSheet.show(
                    context: context,
                    participants: participantOptions,
                    onAddExpense:
                        (title, paidById, participantsOwe, totalAmount) async {
                      try {
                        // ✅ Create expense in Supabase
                        await ref
                            .read(eventExpensesProvider(eventId).notifier)
                            .addExpense(
                          description: title,
                          amount: totalAmount,
                          paidBy: paidById,
                          participantsOwe: participantsOwe,
                          participantsPaid: [],
                        );

                        // Show success message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Expense "$title" created!'),
                              backgroundColor: BrandColors.planning,
                            ),
                          );
                        }

                        widget.onExpensePressed?.call();
                      } catch (e) {
                        // Show error message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating expense: $e'),
                              backgroundColor: BrandColors.cantVote,
                            ),
                          );
                        }
                      }
                    },
                  );
                  return;
                }

                // If error state
                if (currentState is AsyncError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${currentState.error}')),
                  );
                  return;
                }
              } catch (e, stackTrace) {
                debugPrint(
                    '❌ [HomeEventCard] Error opening expense sheet: $e\n$stackTrace');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
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

  String _getDateOrTimeLeftText() {
    // Show time left for Living and Recap states
    if (widget.state == HomeEventCardState.living) {
      // Living: time until end date
      if (_currentEvent.endDate != null) {
        return _formatTimeLeft(_currentEvent.endDate!);
      }
      return 'Happening now';
    } else if (widget.state == HomeEventCardState.recap) {
      // Recap: 24h countdown from end date for photo uploads
      if (_currentEvent.endDate != null) {
        final recapDeadline =
            _currentEvent.endDate!.add(const Duration(hours: 24));
        return _formatTimeLeft(recapDeadline);
      }
      return 'Upload photos';
    }

    // For Pending and Confirmed, show normal date
    return _currentEvent.date != null
        ? _formatEventDate(_currentEvent.date!)
        : 'To be decided';
  }

  String _formatTimeLeft(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative) {
      return 'Ended';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    if (hours > 24) {
      final days = difference.inDays;
      return '$days day${days != 1 ? 's' : ''} left';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else if (minutes > 0) {
      return '${minutes}m left';
    } else {
      return 'Less than 1m left';
    }
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

    // ✅ Extract real start and end times from event dates
    final startTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final endTime = _currentEvent.endDate != null
        ? '${_currentEvent.endDate!.hour.toString().padLeft(2, '0')}:${_currentEvent.endDate!.minute.toString().padLeft(2, '0')}'
        : null;

    // Format: "Mon, 26 Feb • 15:00–18:00" for same day
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];

    // Show time range if endDate is available, otherwise just start time
    final timeRange = endTime != null ? '$startTime–$endTime' : startTime;
    return '$weekday, $day $month • $timeRange';
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../create_event/domain/entities/event.dart' as create_event;
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/chips/event_status_chip.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart' as rsvp_widget;
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/components/widgets/date_time_widget.dart';
import '../../../../shared/components/widgets/poll_widget.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../services/calendar_service.dart';
import '../../domain/entities/rsvp.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/event_providers.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_preview_widget.dart';
import '../widgets/event_expenses_widget.dart';
import '../widgets/date_time_suggestions_widget.dart'
    show DateTimeSuggestionsWidget, DateTimeSuggestion;
import '../widgets/date_time_suggestions_widget.dart' as datetime_widget;
import '../widgets/location_suggestions_widget.dart';
import '../widgets/add_suggestion_bottom_sheet.dart';
import '../providers/event_participants_provider.dart';

import '../../../../shared/components/dialogs/add_expense_bottom_sheet.dart';
import '../../../expense/presentation/providers/event_expense_providers.dart';

/// Event detail page
/// Displays all event information and interactions
class EventPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventPage({super.key, required this.eventId});

  @override
  ConsumerState<EventPage> createState() => _EventPageState();
}

class _EventPageState extends ConsumerState<EventPage> {
  // Track events that have been added to calendar
  final Set<String> _addedToCalendar = {};

  String get eventId => widget.eventId;

  /// Helper to replace current user's name with "You"
  String _getUserDisplayName(
      String userId, String userName, String? currentUserId) {
    return userId == currentUserId ? 'You' : userName;
  }

  /// Show dialog to change event status
  void _showStatusChangeDialog(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    EventStatus currentStatus,
  ) {
    final isConfirmed = currentStatus == EventStatus.confirmed;

    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: isConfirmed ? 'Unmark Event' : 'Confirm Event',
        message: isConfirmed
            ? 'Are you sure you want to unmark this event as confirmed?'
            : 'Are you sure you want to confirm this event?',
        confirmText: isConfirmed ? 'Unmark' : 'Confirm',
        cancelText: 'Cancel',
        isDestructive: isConfirmed,
        onConfirm: () async {
          final newStatus =
              isConfirmed ? EventStatus.pending : EventStatus.confirmed;

          print('📢 [DIALOG] User confirmed status change');
          print('   📄 Current status: $currentStatus');
          print('   ➡️ New status: $newStatus');
          print('   🎯 Is confirmed: $isConfirmed');

          await ref
              .read(eventStatusNotifierProvider(eventId).notifier)
              .updateStatus(eventId, newStatus);

          // Show success message
          if (context.mounted) {
            _showStatusMessage(context, newStatus);
          }
        },
      ),
    );
  }

  /// Show message banner when status changes
  void _showStatusMessage(BuildContext context, EventStatus newStatus) {
    final isConfirmed = newStatus == EventStatus.confirmed;
    final message = isConfirmed
        ? 'Event confirmed successfully!'
        : 'Event unmarked successfully!';

    if (isConfirmed) {
      TopBanner.showSuccess(context, message: message);
    } else {
      TopBanner.showInfo(context, message: message);
    }
  }

  /// Add event to device calendar
  Future<void> _addToCalendar(
    BuildContext context,
    EventDetail event,
  ) async {
    // Only add if event has start date
    if (event.startDateTime == null) {
      TopBanner.showError(
        context,
        message: 'Event date not set. Cannot add to calendar.',
      );
      return;
    }

    final success = await CalendarService.addEventToCalendar(
      title: '${event.emoji} ${event.name}',
      startDate: event.startDateTime!,
      endDate: event.endDateTime,
      description: 'Lazzo event',
      location: event.location?.displayName,
    );

    if (context.mounted) {
      if (success) {
        setState(() {
          _addedToCalendar.add(event.id);
        });
        TopBanner.showSuccess(
          context,
          message: 'Event added to calendar!',
        );
      } else {
        TopBanner.showError(
          context,
          message: 'Could not add event to calendar.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final rsvpsAsync = ref.watch(eventRsvpsProvider(eventId));
    final userRsvpAsync = ref.watch(userRsvpProvider(eventId));
    final pollsAsync = ref.watch(eventPollsProvider(eventId));
    final messagesAsync = ref.watch(chatMessagesProvider(eventId));
    final suggestionsAsync = ref.watch(eventSuggestionsProvider(eventId));
    final suggestionVotesAsync = ref.watch(suggestionVotesProvider(eventId));
    final userSuggestionVotesAsync = ref.watch(
      userSuggestionVotesProvider(eventId),
    );
    final participantsAsync = ref.watch(eventParticipantsProvider(eventId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: Consumer(
          builder: (context, consumerRef, _) {
            final canManageAsync = consumerRef.watch(
              canManageEventProvider(eventId),
            );

            return canManageAsync.when(
              data: (canManage) {
                // Only show settings icon for host or group admins
                if (!canManage) {
                  print(
                      '⚙️ [SETTINGS] User cannot manage event - settings hidden');
                  return const SizedBox.shrink();
                }

                print('⚙️ [SETTINGS] User can manage event - settings visible');
                return IconButton(
                  icon: const Icon(Icons.edit, color: BrandColors.text1),
                  onPressed: () {
                    // Only navigate if event data is available
                    final eventData = eventAsync.value;
                    if (eventData != null) {
                      // Convert EventDetail to Event for edit page
                      final editEvent = create_event.Event(
                        id: eventData.id,
                        name: eventData.name,
                        emoji: eventData.emoji,
                        groupId: eventData.groupId,
                        startDateTime: eventData.startDateTime,
                        endDateTime: eventData.endDateTime,
                        location: eventData.location != null
                            ? create_event.EventLocation(
                                id: eventData.location!.id,
                                displayName: eventData.location!.displayName,
                                formattedAddress:
                                    eventData.location!.formattedAddress,
                                latitude: eventData.location!.latitude,
                                longitude: eventData.location!.longitude,
                              )
                            : null,
                        status: create_event.EventStatus.confirmed,
                        createdAt: eventData.createdAt,
                      );

                      Navigator.pushNamed(
                        context,
                        AppRouter.editEvent,
                        arguments: {'event': editEvent},
                      );
                    }
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
      ),
      body: eventAsync.when(
        data: (event) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.screenH,
            vertical: Gaps.lg,
          ),
          child: Column(
            children: [
              // Event header
              EventHeader(
                emoji: event.emoji,
                title: event.name,
                location: event.location?.displayName,
                dateTime: event.startDateTime,
                endDateTime: event.endDateTime,
              ),
              const SizedBox(height: Gaps.md),

              // Event status chip - visible for event host OR group admins
              Consumer(
                builder: (context, consumerRef, _) {
                  final canManageAsync = consumerRef.watch(
                    canManageEventProvider(eventId),
                  );

                  return canManageAsync.when(
                    data: (canManage) {
                      if (!canManage) {
                        print(
                            '🎯 [STATUS CHIP] User cannot manage event - chip hidden');
                        return const SizedBox.shrink();
                      }

                      final isHost = event.hostId == currentUserId;
                      print('🎯 [STATUS CHIP] Permission check:');
                      print('   Event host ID: ${event.hostId}');
                      print('   Current user ID: $currentUserId');
                      print('   Is host: $isHost');
                      print('   Can manage: $canManage');
                      print('   Chip visible: true');

                      return Column(
                        children: [
                          EventStatusChip(
                            status: event.status,
                            isHost: true,
                            onTap: () => _showStatusChangeDialog(
                              context,
                              ref,
                              eventId,
                              event.status,
                            ),
                          ),
                          const SizedBox(height: Gaps.lg),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),

              // RSVP Widget
              rsvpsAsync.when(
                data: (rsvps) {
                  return userRsvpAsync.when(
                    data: (userRsvp) {
                      return suggestionsAsync.when(
                        data: (suggestions) {
                          // Filter suggestions that are DIFFERENT from current event date
                          // (for "Add Suggestion" button visibility)
                          final alternateDateSuggestions =
                              suggestions.where((s) {
                            if (event.startDateTime == null ||
                                event.endDateTime == null) {
                              return true;
                            }
                            final isDifferent = !s.startDateTime
                                    .isAtSameMomentAs(event.startDateTime!) ||
                                !(s.endDateTime?.isAtSameMomentAs(
                                        event.endDateTime!) ??
                                    false);
                            return isDifferent;
                          }).toList();

                          // Also check location suggestions for hasSuggestions flag
                          return Consumer(
                            builder: (context, consumerRef, child) {
                              final locationSuggestionsAsync =
                                  consumerRef.watch(
                                eventLocationSuggestionsProvider(eventId),
                              );

                              return locationSuggestionsAsync.when(
                                data: (locationSuggestions) {
                                  // Filter location suggestions DIFFERENT from current event location
                                  final alternateLocationSuggestions =
                                      locationSuggestions.where((s) {
                                    if (event.location == null) return true;
                                    final isDifferent = s.locationName !=
                                            event.location!.displayName ||
                                        (s.address ?? '') !=
                                            event.location!.formattedAddress;
                                    return isDifferent;
                                  }).toList();

                                  // Calculate dynamic counts from actual RSVP data
                                  final goingCount = rsvps
                                      .where(
                                        (r) => r.status == RsvpStatus.going,
                                      )
                                      .length;
                                  final notGoingCount = rsvps
                                      .where(
                                        (r) => r.status == RsvpStatus.notGoing,
                                      )
                                      .length;
                                  final pendingCount = rsvps
                                      .where(
                                        (r) => r.status == RsvpStatus.pending,
                                      )
                                      .length;

                                  return rsvp_widget.RsvpWidget(
                                    goingCount: goingCount,
                                    notGoingCount: notGoingCount,
                                    pendingCount: pendingCount,
                                    userVote: _getUserVoteStatus(userRsvp),
                                    onGoingPressed: () async {
                                      final currentStatus = userRsvp?.status ??
                                          RsvpStatus.pending;
                                      final newStatus =
                                          currentStatus == RsvpStatus.going
                                              ? RsvpStatus.pending
                                              : RsvpStatus.going;
                                      await ref
                                          .read(userRsvpProvider(eventId)
                                              .notifier)
                                          .submitVote(newStatus);
                                    },
                                    onNotGoingPressed: () async {
                                      final currentStatus = userRsvp?.status ??
                                          RsvpStatus.pending;
                                      final newStatus =
                                          currentStatus == RsvpStatus.notGoing
                                              ? RsvpStatus.pending
                                              : RsvpStatus.notGoing;
                                      await ref
                                          .read(userRsvpProvider(eventId)
                                              .notifier)
                                          .submitVote(newStatus);
                                    },
                                    allVotes: rsvps
                                        .map(
                                          (r) => rsvp_widget.RsvpVote(
                                            id: r.id,
                                            userId: r.userId,
                                            userName: _getUserDisplayName(
                                                r.userId,
                                                r.userName,
                                                currentUserId),
                                            userAvatar: r.userAvatar,
                                            status: r.status == RsvpStatus.going
                                                ? rsvp_widget
                                                    .RsvpVoteStatus.going
                                                : r.status ==
                                                        RsvpStatus.notGoing
                                                    ? rsvp_widget
                                                        .RsvpVoteStatus.notGoing
                                                    : rsvp_widget
                                                        .RsvpVoteStatus.pending,
                                            votedAt: r.createdAt,
                                          ),
                                        )
                                        .toList(),
                                    onAddSuggestion: _getUserVoteStatus(
                                                userRsvp) ==
                                            false
                                        ? () {
                                            if (event.startDateTime != null &&
                                                event.endDateTime != null) {
                                              showAddSuggestionBottomSheet(
                                                context,
                                                eventId: eventId,
                                                eventStartDate:
                                                    event.startDateTime!,
                                                eventStartTime:
                                                    TimeOfDay.fromDateTime(
                                                  event.startDateTime!,
                                                ),
                                                eventEndDate:
                                                    event.endDateTime!,
                                                eventEndTime:
                                                    TimeOfDay.fromDateTime(
                                                  event.endDateTime!,
                                                ),
                                                type: locationSuggestions
                                                        .isNotEmpty
                                                    ? SuggestionType.location
                                                    : SuggestionType
                                                        .dateTime, // Start with Location tab if location suggestions exist
                                                currentEventLocationName:
                                                    event.location?.displayName,
                                                currentEventAddress: event
                                                    .location?.formattedAddress,
                                              );
                                            }
                                          }
                                        : null,
                                    eventStartDateTime: event.startDateTime,
                                    eventEndDateTime: event.endDateTime,
                                    isHost: event.hostId == currentUserId,
                                    hasSuggestions: alternateDateSuggestions
                                            .isNotEmpty ||
                                        alternateLocationSuggestions.isNotEmpty,
                                  );
                                },
                                loading: () => rsvp_widget.RsvpWidget(
                                  goingCount: event.goingCount,
                                  notGoingCount: event.notGoingCount,
                                  pendingCount: rsvps
                                      .where(
                                        (r) => r.status == RsvpStatus.pending,
                                      )
                                      .length,
                                  userVote: _getUserVoteStatus(userRsvp),
                                  onGoingPressed: () {
                                    final currentStatus =
                                        userRsvp?.status ?? RsvpStatus.pending;
                                    final newStatus =
                                        currentStatus == RsvpStatus.going
                                            ? RsvpStatus.pending
                                            : RsvpStatus.going;
                                    ref
                                        .read(
                                          userRsvpProvider(eventId).notifier,
                                        )
                                        .submitVote(newStatus);
                                  },
                                  onNotGoingPressed: () {
                                    final currentStatus =
                                        userRsvp?.status ?? RsvpStatus.pending;
                                    final newStatus =
                                        currentStatus == RsvpStatus.notGoing
                                            ? RsvpStatus.pending
                                            : RsvpStatus.notGoing;
                                    ref
                                        .read(
                                          userRsvpProvider(eventId).notifier,
                                        )
                                        .submitVote(newStatus);
                                  },
                                  allVotes: rsvps
                                      .map(
                                        (r) => rsvp_widget.RsvpVote(
                                          id: r.id,
                                          userId: r.userId,
                                          userName: _getUserDisplayName(
                                              r.userId,
                                              r.userName,
                                              currentUserId),
                                          userAvatar: r.userAvatar,
                                          status: r.status == RsvpStatus.going
                                              ? rsvp_widget.RsvpVoteStatus.going
                                              : r.status == RsvpStatus.notGoing
                                                  ? rsvp_widget
                                                      .RsvpVoteStatus.notGoing
                                                  : rsvp_widget
                                                      .RsvpVoteStatus.pending,
                                          votedAt: r.createdAt,
                                        ),
                                      )
                                      .toList(),
                                  onAddSuggestion:
                                      _getUserVoteStatus(userRsvp) == false
                                          ? () {
                                              if (event.startDateTime != null &&
                                                  event.endDateTime != null) {
                                                showAddSuggestionBottomSheet(
                                                  context,
                                                  eventId: eventId,
                                                  eventStartDate:
                                                      event.startDateTime!,
                                                  eventStartTime:
                                                      TimeOfDay.fromDateTime(
                                                    event.startDateTime!,
                                                  ),
                                                  eventEndDate:
                                                      event.endDateTime!,
                                                  eventEndTime:
                                                      TimeOfDay.fromDateTime(
                                                    event.endDateTime!,
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                  eventStartDateTime: event.startDateTime,
                                  eventEndDateTime: event.endDateTime,
                                  isHost: event.hostId == currentUserId,
                                  hasSuggestions:
                                      false, // Default to false when loading
                                ),
                                error: (error, stack) => rsvp_widget.RsvpWidget(
                                  goingCount: event.goingCount,
                                  notGoingCount: event.notGoingCount,
                                  pendingCount: rsvps
                                      .where(
                                        (r) => r.status == RsvpStatus.pending,
                                      )
                                      .length,
                                  userVote: _getUserVoteStatus(userRsvp),
                                  onGoingPressed: () {
                                    final currentStatus =
                                        userRsvp?.status ?? RsvpStatus.pending;
                                    final newStatus =
                                        currentStatus == RsvpStatus.going
                                            ? RsvpStatus.pending
                                            : RsvpStatus.going;
                                    ref
                                        .read(
                                          userRsvpProvider(eventId).notifier,
                                        )
                                        .submitVote(newStatus);
                                  },
                                  onNotGoingPressed: () {
                                    final currentStatus =
                                        userRsvp?.status ?? RsvpStatus.pending;
                                    final newStatus =
                                        currentStatus == RsvpStatus.notGoing
                                            ? RsvpStatus.pending
                                            : RsvpStatus.notGoing;
                                    ref
                                        .read(
                                          userRsvpProvider(eventId).notifier,
                                        )
                                        .submitVote(newStatus);
                                  },
                                  allVotes: rsvps
                                      .map(
                                        (r) => rsvp_widget.RsvpVote(
                                          id: r.id,
                                          userId: r.userId,
                                          userName: _getUserDisplayName(
                                              r.userId,
                                              r.userName,
                                              currentUserId),
                                          userAvatar: r.userAvatar,
                                          status: r.status == RsvpStatus.going
                                              ? rsvp_widget.RsvpVoteStatus.going
                                              : r.status == RsvpStatus.notGoing
                                                  ? rsvp_widget
                                                      .RsvpVoteStatus.notGoing
                                                  : rsvp_widget
                                                      .RsvpVoteStatus.pending,
                                          votedAt: r.createdAt,
                                        ),
                                      )
                                      .toList(),
                                  onAddSuggestion:
                                      _getUserVoteStatus(userRsvp) == false
                                          ? () {
                                              if (event.startDateTime != null &&
                                                  event.endDateTime != null) {
                                                showAddSuggestionBottomSheet(
                                                  context,
                                                  eventId: eventId,
                                                  eventStartDate:
                                                      event.startDateTime!,
                                                  eventStartTime:
                                                      TimeOfDay.fromDateTime(
                                                    event.startDateTime!,
                                                  ),
                                                  eventEndDate:
                                                      event.endDateTime!,
                                                  eventEndTime:
                                                      TimeOfDay.fromDateTime(
                                                    event.endDateTime!,
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                  eventStartDateTime: event.startDateTime,
                                  eventEndDateTime: event.endDateTime,
                                  isHost: event.hostId == currentUserId,
                                  hasSuggestions:
                                      false, // Default to false on error
                                ),
                              );
                            },
                          );
                        },
                        loading: () => rsvp_widget.RsvpWidget(
                          goingCount: event.goingCount,
                          notGoingCount: event.notGoingCount,
                          pendingCount: rsvps
                              .where((r) => r.status == RsvpStatus.pending)
                              .length,
                          userVote: _getUserVoteStatus(userRsvp),
                          onGoingPressed: () {
                            final currentStatus =
                                userRsvp?.status ?? RsvpStatus.pending;
                            final newStatus = currentStatus == RsvpStatus.going
                                ? RsvpStatus.pending
                                : RsvpStatus.going;
                            ref
                                .read(userRsvpProvider(eventId).notifier)
                                .submitVote(newStatus);
                          },
                          onNotGoingPressed: () {
                            final currentStatus =
                                userRsvp?.status ?? RsvpStatus.pending;
                            final newStatus =
                                currentStatus == RsvpStatus.notGoing
                                    ? RsvpStatus.pending
                                    : RsvpStatus.notGoing;
                            ref
                                .read(userRsvpProvider(eventId).notifier)
                                .submitVote(newStatus);
                          },
                          allVotes: rsvps
                              .map(
                                (r) => rsvp_widget.RsvpVote(
                                  id: r.id,
                                  userId: r.userId,
                                  userName: _getUserDisplayName(
                                      r.userId, r.userName, currentUserId),
                                  userAvatar: r.userAvatar,
                                  status: r.status == RsvpStatus.going
                                      ? rsvp_widget.RsvpVoteStatus.going
                                      : r.status == RsvpStatus.notGoing
                                          ? rsvp_widget.RsvpVoteStatus.notGoing
                                          : rsvp_widget.RsvpVoteStatus.pending,
                                  votedAt: r.createdAt,
                                ),
                              )
                              .toList(),
                          onAddSuggestion: _getUserVoteStatus(userRsvp) == false
                              ? () {
                                  if (event.startDateTime != null &&
                                      event.endDateTime != null) {
                                    showAddSuggestionBottomSheet(
                                      context,
                                      eventId: eventId,
                                      eventStartDate: event.startDateTime!,
                                      eventStartTime: TimeOfDay.fromDateTime(
                                        event.startDateTime!,
                                      ),
                                      eventEndDate: event.endDateTime!,
                                      eventEndTime: TimeOfDay.fromDateTime(
                                        event.endDateTime!,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          eventStartDateTime: event.startDateTime,
                          eventEndDateTime: event.endDateTime,
                          isHost: event.hostId == currentUserId,
                          hasSuggestions:
                              false, // Default to false when loading
                        ),
                        error: (error, stack) => rsvp_widget.RsvpWidget(
                          goingCount: event.goingCount,
                          notGoingCount: event.notGoingCount,
                          pendingCount: rsvps
                              .where((r) => r.status == RsvpStatus.pending)
                              .length,
                          userVote: _getUserVoteStatus(userRsvp),
                          onGoingPressed: () {
                            final currentStatus =
                                userRsvp?.status ?? RsvpStatus.pending;
                            final newStatus = currentStatus == RsvpStatus.going
                                ? RsvpStatus.pending
                                : RsvpStatus.going;
                            ref
                                .read(userRsvpProvider(eventId).notifier)
                                .submitVote(newStatus);
                          },
                          onNotGoingPressed: () {
                            final currentStatus =
                                userRsvp?.status ?? RsvpStatus.pending;
                            final newStatus =
                                currentStatus == RsvpStatus.notGoing
                                    ? RsvpStatus.pending
                                    : RsvpStatus.notGoing;
                            ref
                                .read(userRsvpProvider(eventId).notifier)
                                .submitVote(newStatus);
                          },
                          allVotes: rsvps
                              .map(
                                (r) => rsvp_widget.RsvpVote(
                                  id: r.id,
                                  userId: r.userId,
                                  userName: _getUserDisplayName(
                                      r.userId, r.userName, currentUserId),
                                  userAvatar: r.userAvatar,
                                  status: r.status == RsvpStatus.going
                                      ? rsvp_widget.RsvpVoteStatus.going
                                      : r.status == RsvpStatus.notGoing
                                          ? rsvp_widget.RsvpVoteStatus.notGoing
                                          : rsvp_widget.RsvpVoteStatus.pending,
                                  votedAt: r.createdAt,
                                ),
                              )
                              .toList(),
                          onAddSuggestion: _getUserVoteStatus(userRsvp) == false
                              ? () {
                                  if (event.startDateTime != null &&
                                      event.endDateTime != null) {
                                    showAddSuggestionBottomSheet(
                                      context,
                                      eventId: eventId,
                                      eventStartDate: event.startDateTime!,
                                      eventStartTime: TimeOfDay.fromDateTime(
                                        event.startDateTime!,
                                      ),
                                      eventEndDate: event.endDateTime!,
                                      eventEndTime: TimeOfDay.fromDateTime(
                                        event.endDateTime!,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          eventStartDateTime: event.startDateTime,
                          eventEndDateTime: event.endDateTime,
                          isHost: event.hostId == currentUserId,
                          hasSuggestions: false, // Default to false on error
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) {
                      // Show RSVP widget with empty votes on error
                      return rsvp_widget.RsvpWidget(
                        goingCount: 0,
                        notGoingCount: 0,
                        pendingCount: 0,
                        userVote: null,
                        onGoingPressed: () {},
                        onNotGoingPressed: () {},
                        allVotes: const [],
                        onAddSuggestion: null,
                        eventStartDateTime: event.startDateTime,
                        eventEndDateTime: event.endDateTime,
                        isHost: event.hostId == currentUserId,
                        hasSuggestions: false,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) {
                  // Show RSVP widget with empty votes on error
                  return rsvp_widget.RsvpWidget(
                    goingCount: 0,
                    notGoingCount: 0,
                    pendingCount: 0,
                    userVote: null,
                    onGoingPressed: () {},
                    onNotGoingPressed: () {},
                    allVotes: const [],
                    onAddSuggestion: null,
                    eventStartDateTime: event.startDateTime,
                    eventEndDateTime: event.endDateTime,
                    isHost: event.hostId == currentUserId,
                    hasSuggestions: false,
                  );
                },
              ),
              const SizedBox(height: Gaps.lg),

              // Date & Time Suggestions Widget
              // ONLY SHOWS when there are alternative date suggestions (not just event's current date)
              suggestionsAsync.when(
                data: (suggestions) {
                  // Filter suggestions that are DIFFERENT from current event date
                  final alternateSuggestions = suggestions.where((s) {
                    if (event.startDateTime == null ||
                        event.endDateTime == null) {
                      return true;
                    }

                    // Keep only suggestions with DIFFERENT dates
                    final isDifferent = !s.startDateTime
                            .isAtSameMomentAs(event.startDateTime!) ||
                        !(s.endDateTime?.isAtSameMomentAs(event.endDateTime!) ??
                            false);
                    return isDifferent;
                  }).toList();

                  // ONLY show widget if there are ALTERNATIVE suggestions (different from current date)
                  if (alternateSuggestions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return suggestionVotesAsync.when(
                    data: (allVotes) {
                      return userSuggestionVotesAsync.when(
                        data: (userVotes) {
                          final List<DateTimeSuggestion> dateTimeSuggestions =
                              [];

                          // Always add current event date as FIRST option (for comparison)
                          if (event.startDateTime != null &&
                              event.endDateTime != null) {
                            dateTimeSuggestions.add(DateTimeSuggestion(
                              id: 'current_event_date',
                              startDateTime: event.startDateTime!,
                              endDateTime: event.endDateTime!,
                              voteCount:
                                  0, // Current date has no votes (it's the default)
                              hasUserVoted: false,
                              votes: [],
                            ));
                          }

                          // Add all ALTERNATIVE suggestions (different from current date)
                          dateTimeSuggestions.addAll(alternateSuggestions.map((
                            suggestion,
                          ) {
                            final suggestionVotes = allVotes
                                .where(
                                  (vote) => vote.suggestionId == suggestion.id,
                                )
                                .map(
                                  (vote) => datetime_widget.SuggestionVote(
                                    id: vote.id,
                                    userId: vote.userId,
                                    userName: _getUserDisplayName(vote.userId,
                                        vote.userName, currentUserId),
                                    userAvatar: vote.userAvatar,
                                    votedAt: vote.createdAt,
                                  ),
                                )
                                .toList();

                            return DateTimeSuggestion(
                              id: suggestion.id,
                              startDateTime: suggestion.startDateTime,
                              endDateTime: suggestion.endDateTime,
                              voteCount: suggestionVotes.length,
                              hasUserVoted: userVotes.any(
                                (vote) => vote.suggestionId == suggestion.id,
                              ),
                              votes: suggestionVotes,
                            );
                          }));

                          final userVoteIds = userVotes
                              .map((vote) => vote.suggestionId)
                              .toSet();

                          return Column(
                            children: [
                              DateTimeSuggestionsWidget(
                                suggestions: dateTimeSuggestions,
                                userVotes: userVoteIds,
                                currentEventStartDateTime: event.startDateTime,
                                currentEventEndDateTime: event.endDateTime,
                                onVote: (suggestionId) {
                                  ref
                                      .read(
                                        toggleSuggestionVoteNotifierProvider
                                            .notifier,
                                      )
                                      .toggleVote_(eventId, suggestionId);
                                },
                                isHost: event.hostId == currentUserId,
                                onAddSuggestion: () {
                                  if (event.startDateTime != null &&
                                      event.endDateTime != null) {
                                    showAddSuggestionBottomSheet(
                                      context,
                                      eventId: eventId,
                                      eventStartDate: event.startDateTime!,
                                      eventStartTime: TimeOfDay.fromDateTime(
                                        event.startDateTime!,
                                      ),
                                      eventEndDate: event.endDateTime!,
                                      eventEndTime: TimeOfDay.fromDateTime(
                                        event.endDateTime!,
                                      ),
                                    );
                                  }
                                },
                                onSetDate: (selectedSuggestion) async {
                                  await _setEventDate(
                                    context,
                                    ref,
                                    selectedSuggestion,
                                  );
                                },
                              ),
                              const SizedBox(height: Gaps.lg),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => const SizedBox.shrink(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),

              // Location suggestions widget (independent of datetime suggestions)
              Consumer(
                builder: (context, consumerRef, child) {
                  final locationSuggestionsAsync = consumerRef.watch(
                    eventLocationSuggestionsProvider(eventId),
                  );
                  final locationVotesAsync = consumerRef.watch(
                    locationSuggestionVotesProvider(eventId),
                  );
                  final userLocationVotesAsync = consumerRef.watch(
                    userLocationSuggestionVotesProvider(eventId),
                  );

                  return locationSuggestionsAsync.when(
                    data: (locationSuggestions) {
                      // Hide if no suggestions
                      if (locationSuggestions.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      // Filter suggestions DIFFERENT from current event location (if exists)
                      final alternateLocationSuggestions =
                          locationSuggestions.where((s) {
                        if (event.location == null) return true;

                        // Check if suggestion is different from current location
                        final isDifferent =
                            s.locationName != event.location!.displayName ||
                                (s.address ?? '') !=
                                    event.location!.formattedAddress;
                        return isDifferent;
                      }).toList();

                      // Hide if no suggestions at all (should never happen, but safety check)
                      if (locationSuggestions.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      // Hide if event has location but no alternative suggestions
                      if (event.location != null &&
                          alternateLocationSuggestions.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return locationVotesAsync.when(
                        data: (locationVotes) {
                          return userLocationVotesAsync.when(
                            data: (userLocationVotes) {
                              final userLocationVoteIds = userLocationVotes
                                  .map((vote) => vote.suggestionId)
                                  .toSet();

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Gaps.lg, //TODO: Fix spaces
                                ),
                                child: LocationSuggestionsWidget(
                                  suggestions: locationSuggestions,
                                  allVotes: locationVotes,
                                  userVotes: userLocationVoteIds,
                                  onVote: (suggestionId) {
                                    ref
                                        .read(
                                          toggleLocationSuggestionVoteNotifierProvider
                                              .notifier,
                                        )
                                        .toggleVote(eventId, suggestionId);
                                  },
                                  isHost: event.hostId == currentUserId,
                                  onAddSuggestion: () {
                                    showAddSuggestionBottomSheet(
                                      context,
                                      eventId: eventId,
                                      eventStartDate: event.startDateTime!,
                                      eventStartTime: TimeOfDay.fromDateTime(
                                        event.startDateTime!,
                                      ),
                                      eventEndDate: event.endDateTime!,
                                      eventEndTime: TimeOfDay.fromDateTime(
                                        event.endDateTime!,
                                      ),
                                      type: SuggestionType.location,
                                      currentEventLocationName:
                                          event.location?.displayName,
                                      currentEventAddress:
                                          event.location?.formattedAddress,
                                    );
                                  },
                                  onPickLocation: (selectedLocation) async {
                                    await _setEventLocation(
                                      context,
                                      ref,
                                      selectedLocation,
                                    );
                                  },
                                  currentEventLocationName:
                                      event.location?.displayName,
                                  currentEventAddress:
                                      event.location?.formattedAddress,
                                ),
                              );
                            },
                            loading: () {
                              if (kDebugMode) {
                                print(
                                    '⏳ [EventPage] Loading user location votes...');
                              }
                              return const SizedBox.shrink();
                            },
                            error: (error, stack) {
                              if (kDebugMode) {
                                print(
                                    '❌ [EventPage] Error loading user location votes: $error');
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        },
                        loading: () {
                          if (kDebugMode) {
                            print('⏳ [EventPage] Loading location votes...');
                          }
                          return const SizedBox.shrink();
                        },
                        error: (error, stack) {
                          if (kDebugMode) {
                            print(
                                '❌ [EventPage] Error loading location votes: $error');
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                  );
                },
              ),

              // Chat Preview
              messagesAsync.when(
                data: (messages) {
                  if (kDebugMode) {
                    print('\n═══════════════════════════════════════');
                    print('💬 [EventPage] PREVIEW - New data received!');
                    print('   - Event ID: $eventId');
                    print('   - Total messages: ${messages.length}');
                    if (messages.isNotEmpty) {
                      print(
                          '   - First: "${messages.first.content.substring(0, messages.first.content.length > 30 ? 30 : messages.first.content.length)}..." (read=${messages.first.read})');
                      print(
                          '   - Last: "${messages.last.content.substring(0, messages.last.content.length > 30 ? 30 : messages.last.content.length)}..."');
                    }
                    print('═══════════════════════════════════════\n');
                  }

                  final unreadCount = ref.watch(
                    unreadMessagesCountProvider(eventId),
                  );

                  final previewMessages = messages
                      .map(
                        (m) => ChatMessagePreview(
                          userId: m.userId,
                          userName: _getUserDisplayName(
                              m.userId, m.userName, currentUserId),
                          userAvatar: m.userAvatar,
                          content: m.content,
                          timestamp: m.createdAt,
                          read: m.read,
                          isPinned: m.isPinned,
                          replyTo: m.replyTo != null
                              ? ChatMessagePreview(
                                  userId: m.replyTo!.userId,
                                  userName: _getUserDisplayName(
                                      m.replyTo!.userId,
                                      m.replyTo!.userName,
                                      currentUserId),
                                  userAvatar: m.replyTo!.userAvatar,
                                  content: m.replyTo!.content,
                                  timestamp: m.replyTo!.createdAt,
                                  read: m.replyTo!.read,
                                  isPinned: m.replyTo!.isPinned,
                                )
                              : null,
                        ),
                      )
                      .toList();

                  if (kDebugMode) {
                    print(
                        '💬 [EventPage] Passing ${previewMessages.length} messages to ChatPreviewWidget');
                    print(
                        '💬 [EventPage] Unread count: $unreadCount, currentUserId: $currentUserId');

                    // Check for messages with replyTo
                    final messagesWithReply =
                        previewMessages.where((m) => m.replyTo != null).length;
                    print(
                        '📨 [EventPage] Messages with replyTo: $messagesWithReply/${previewMessages.length}');

                    if (previewMessages.isNotEmpty) {
                      print('💬 [EventPage] Preview messages details:');
                      for (var i = 0;
                          i < previewMessages.length && i < 3;
                          i++) {
                        final hasReply = previewMessages[i].replyTo != null
                            ? ' (replying to: "${previewMessages[i].replyTo!.content.substring(0, previewMessages[i].replyTo!.content.length > 15 ? 15 : previewMessages[i].replyTo!.content.length)}...")'
                            : '';
                        print(
                            '   $i: "${previewMessages[i].content}" (user: ${previewMessages[i].userName}, read: ${previewMessages[i].read})$hasReply');
                      }
                    }
                  }

                  return ChatPreviewWidget(
                    newMessagesCount: unreadCount,
                    currentUserId: currentUserId ?? '',
                    recentMessages: previewMessages,
                    onOpenChat: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.eventChat,
                        arguments: {'eventId': eventId},
                      );
                    },
                    onOpenChatWithMessage: (messageId) {
                      Navigator.pushNamed(
                        context,
                        AppRouter.eventChat,
                        arguments: {
                          'eventId': eventId,
                          'scrollToMessageId': messageId,
                        },
                      );
                    },
                    onSendMessage: (content,
                        {ChatMessagePreview? replyTo}) async {
                      if (kDebugMode) {
                        print(
                            '\n🚀 [EventPage] PREVIEW sending message (DATA state):');
                        print('   - Content: "$content"');
                        print('   - Event ID: $eventId');
                        print('   - ReplyTo: ${replyTo?.content}');
                      }

                      // Convert ChatMessagePreview to ChatMessage if replying
                      ChatMessage? replyToMessage;
                      if (replyTo != null) {
                        // Find the original ChatMessage from messages list
                        try {
                          replyToMessage = messages.firstWhere(
                            (m) =>
                                m.userId == replyTo.userId &&
                                m.content == replyTo.content &&
                                m.createdAt == replyTo.timestamp,
                          );
                          if (kDebugMode) {
                            print(
                                '   ✅ Found original message to reply to: ${replyToMessage.id}');
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print(
                                '   ⚠️ Could not find original message for reply');
                          }
                        }
                      }

                      await ref.read(chatActionsProvider(eventId)).sendMessage(
                            content,
                            replyTo: replyToMessage,
                          );
                      if (kDebugMode) {
                        print('✅ [EventPage] PREVIEW sendMessage completed');
                      }
                    },
                    onPinMessage: (message) async {
                      final originalMessage = messages.firstWhere(
                        (m) =>
                            m.content == message.content &&
                            m.userId == message.userId,
                      );
                      await ref.read(chatActionsProvider(eventId)).togglePin(
                            originalMessage.id,
                            !originalMessage.isPinned,
                          );
                      // Navigate to chat and scroll to pinned message
                      if (context.mounted) {
                        Navigator.pushNamed(
                          context,
                          AppRouter.eventChat,
                          arguments: {
                            'eventId': eventId,
                            'scrollToMessageId': originalMessage.id,
                          },
                        );
                      }
                    },
                    onDeleteMessage: (message) async {
                      final originalMessage = messages.firstWhere(
                        (m) =>
                            m.content == message.content &&
                            m.userId == message.userId,
                      );
                      await ref
                          .read(chatActionsProvider(eventId))
                          .deleteMessage(originalMessage.id);
                    },
                    onReplyMessage: (message) {
                      // Navigate to chat page with reply context (future enhancement)
                      Navigator.pushNamed(
                        context,
                        AppRouter.eventChat,
                        arguments: {'eventId': eventId},
                      );
                    },
                  );
                },
                loading: () => const ChatPreviewWidget(
                  newMessagesCount: 0,
                  currentUserId: '',
                  recentMessages: [],
                  onOpenChat: null,
                  onSendMessage: null,
                ),
                error: (error, stack) {
                  // Show empty chat widget on error so users can still try to send messages
                  return ChatPreviewWidget(
                    newMessagesCount: 0,
                    currentUserId: currentUserId ?? '',
                    recentMessages: const [],
                    onOpenChat: () {},
                    onSendMessage: (content,
                        {ChatMessagePreview? replyTo}) async {
                      if (kDebugMode) {
                        print(
                            '\n🚀 [EventPage] PREVIEW sending message (ERROR state):');
                        print('   - Content: "$content"');
                        print('   - ReplyTo: ${replyTo?.content}');
                      }
                      await ref
                          .read(chatActionsProvider(eventId))
                          .sendMessage(content);
                      if (kDebugMode) {
                        print('✅ [EventPage] PREVIEW sendMessage completed');
                      }
                    },
                    onPinMessage: (message) async {
                      // Try to send action even in error state
                      await ref
                          .read(chatActionsProvider(eventId))
                          .togglePin('', false);
                      // Navigate to chat
                      if (context.mounted) {
                        Navigator.pushNamed(
                          context,
                          AppRouter.eventChat,
                          arguments: {'eventId': eventId},
                        );
                      }
                    },
                    onDeleteMessage: (message) async {
                      await ref
                          .read(chatActionsProvider(eventId))
                          .deleteMessage('');
                    },
                  );
                },
              ),
              const SizedBox(height: Gaps.lg),

              // Expenses widget
              participantsAsync.when(
                data: (participants) {
                  print(
                      '💰 [EventPage] Rendering expenses widget with ${participants.length} participants');
                  final participantOptions = participants.map((p) {
                    print('   Converting: ${p.displayName} (${p.userId})');
                    return ExpenseParticipantOption(
                      id: p.userId,
                      name: p.displayName,
                      avatarUrl: p.avatarUrl,
                    );
                  }).toList();

                  return EventExpensesWidget(
                    eventId: eventId,
                    mode: ChatMode.planning,
                    participants: participantOptions, // ✅ Participantes reais
                    onAddExpense:
                        (title, paidById, participantsOwe, amount) async {
                      print('💸 [EventPage] Adding expense: $title, €$amount');
                      ref
                          .read(eventExpensesProvider(eventId).notifier)
                          .addExpense(
                        description: title,
                        amount: amount,
                        paidBy: paidById,
                        participantsOwe: participantsOwe,
                        participantsPaid: [],
                      );
                    },
                  );
                },
                loading: () {
                  print(
                      '⏳ [EventPage] Expenses widget loading participants...');
                  return const SizedBox.shrink();
                },
                error: (error, stack) {
                  print(
                      '❌ [EventPage] Error loading participants for expenses: $error');
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: Gaps.lg),

              // Location Widget (if location is set)
              if (event.location != null) ...[
                LocationWidget(
                  displayName: event.location!.displayName,
                  formattedAddress: event.location!.formattedAddress,
                  latitude: event.location!.latitude,
                  longitude: event.location!.longitude,
                ),
                const SizedBox(height: Gaps.lg),
              ],

              // Date & Time Widget (if date is set)
              if (event.startDateTime != null) ...[
                DateTimeWidget(
                  eventName: event.name,
                  startDateTime: event.startDateTime!,
                  endDateTime: event.endDateTime,
                  location: event.location?.formattedAddress,
                  onAddToCalendar: () => _addToCalendar(context, event),
                  isAddedToCalendar: _addedToCalendar.contains(event.id),
                ),
                const SizedBox(height: Gaps.lg),
              ],

              // Polls (if no date/location or if there are suggestions)
              pollsAsync.when(
                data: (polls) {
                  if (polls.isEmpty &&
                      (event.startDateTime == null || event.location == null)) {
                    // Show empty state for polls
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: polls.map((poll) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Gaps.lg),
                        child: PollWidget(
                          question: poll.question,
                          options: poll.options
                              .map(
                                (opt) => PollOptionData(
                                  id: opt.id,
                                  label: opt.value,
                                  voteCount: opt.voteCount,
                                ),
                              )
                              .toList(),
                          userVotedOptionId: _getUserVotedOption(poll),
                          isHost: event.hostId == currentUserId,
                          onVote: (optionId) {
                            // TODO: Implement vote on poll
                          },
                          onPickFinal: event.hostId == currentUserId
                              ? (optionId) {
                                  // TODO: Implement pick final option
                                }
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading event: $error')),
      ),
    );
  }

  bool? _getUserVoteStatus(Rsvp? rsvp) {
    if (rsvp == null || rsvp.status == RsvpStatus.pending) return null;
    return rsvp.status == RsvpStatus.going;
  }

  String? _getUserVotedOption(dynamic poll) {
    // TODO: Implement logic to check if current user voted
    return null;
  }

  /// Implements the complete Set Date business logic
  /// 1. Updates the event's date and time to match the selected suggestion
  /// 2. Resets RSVP votes from suggestion voters to match their "Can" votes
  /// 3. Clears all date/time suggestions for the event
  Future<void> _setEventDate(
    BuildContext context,
    WidgetRef ref,
    DateTimeSuggestion selectedSuggestion,
  ) async {
    try {
      // Step 1: Update the event's date and time
      final eventRepository = ref.read(eventRepositoryProvider);
      await eventRepository.updateEventDateTime(
        eventId,
        selectedSuggestion.startDateTime,
        selectedSuggestion.endDateTime,
      );

      // Step 2: Get all users who voted on the selected suggestion
      final suggestionVotesAsync = ref.read(suggestionVotesProvider(eventId));
      final suggestionVotes = suggestionVotesAsync.value ?? [];

      final suggestionVoters = suggestionVotes
          .where((vote) => vote.suggestionId == selectedSuggestion.id)
          .map((vote) => vote.userId)
          .toList();

      final rsvpRepository = ref.read(rsvpRepositoryProvider);
      await rsvpRepository.resetRsvpVotesFromSuggestion(
        eventId,
        suggestionVoters,
      );

      // Step 3: Clear all suggestions for this event
      final suggestionRepository = ref.read(suggestionRepositoryProvider);
      await suggestionRepository.clearEventSuggestions(eventId);

      // Step 4: Invalidate providers to refresh the UI
      ref.invalidate(eventDetailProvider(eventId));
      ref.invalidate(eventRsvpsProvider(eventId));
      ref.invalidate(userRsvpProvider(eventId));
      ref.invalidate(eventSuggestionsProvider(eventId));
      ref.invalidate(suggestionVotesProvider(eventId));
      ref.invalidate(userSuggestionVotesProvider(eventId));

      // Step 5: Show success feedback
      if (context.mounted) {
        TopBanner.showSuccess(
          context,
          message: 'Event date has been set successfully!',
        );
      }
    } catch (error) {
      // Show error feedback
      if (context.mounted) {
        TopBanner.showError(
          context,
          message: 'Failed to set event date: $error',
        );
      }
    }
  }

  /// Implements the complete Set Location business logic
  /// 1. Updates the event's location to match the selected suggestion
  /// 2. Resets RSVP votes from suggestion voters to match their "Can" votes
  /// 3. Clears all location suggestions for the event
  Future<void> _setEventLocation(
    BuildContext context,
    WidgetRef ref,
    LocationSuggestion selectedSuggestion,
  ) async {
    try {
      // Step 1: Update the event's location
      final eventRepository = ref.read(eventRepositoryProvider);
      await eventRepository.updateEventLocation(
        eventId,
        selectedSuggestion.locationName,
        selectedSuggestion.address ?? '',
        selectedSuggestion.latitude ?? 0.0,
        selectedSuggestion.longitude ?? 0.0,
      );

      // Step 2: Get all users who voted on the selected suggestion
      final locationVotesAsync = ref.read(
        locationSuggestionVotesProvider(eventId),
      );
      final locationVotes = locationVotesAsync.value ?? [];

      final suggestionVoters = locationVotes
          .where((vote) => vote.suggestionId == selectedSuggestion.id)
          .map((vote) => vote.userId)
          .toList();

      final rsvpRepository = ref.read(rsvpRepositoryProvider);
      await rsvpRepository.resetRsvpVotesFromSuggestion(
        eventId,
        suggestionVoters,
      );

      // Step 3: Clear all location suggestions for this event
      final suggestionRepository = ref.read(suggestionRepositoryProvider);
      await suggestionRepository.clearEventLocationSuggestions(eventId);

      // Step 4: Invalidate providers to refresh the UI
      ref.invalidate(eventDetailProvider(eventId));
      ref.invalidate(eventRsvpsProvider(eventId));
      ref.invalidate(userRsvpProvider(eventId));
      ref.invalidate(eventLocationSuggestionsProvider(eventId));
      ref.invalidate(locationSuggestionVotesProvider(eventId));
      ref.invalidate(userLocationSuggestionVotesProvider(eventId));

      // Step 5: Show success feedback
      if (context.mounted) {
        TopBanner.showSuccess(
          context,
          message: 'Event location has been set successfully!',
        );
      }
    } catch (error) {
      // Show error feedback
      if (context.mounted) {
        TopBanner.showError(
          context,
          message: 'Failed to set event location: $error',
        );
      }
    }
  }
}

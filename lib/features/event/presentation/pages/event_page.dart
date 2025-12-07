import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../../../inbox/presentation/providers/payments_provider.dart';

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

  // Scroll controller to detect when header is scrolled off screen
  final ScrollController _scrollController = ScrollController();

  // Track if title should be shown in app bar
  bool _showTitleInAppBar = false;

  // Cache isHost status to prevent flicker during operations
  bool? _cachedIsHost;

  String get eventId => widget.eventId;

  @override
  void initState() {
    super.initState();
    // Setup Realtime subscription for unread count badge updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unreadCountRealtimeProvider(eventId));
    });

    // Listen to scroll to show/hide title in app bar
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show title when scrolled past ~150px (approximate header height)
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 150;
    if (shouldShow != _showTitleInAppBar) {
      setState(() {
        _showTitleInAppBar = shouldShow;
      });
    }
  }

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
    // Note: userRsvpAsync is now watched inside _buildRsvpSection()
    final pollsAsync = ref.watch(eventPollsProvider(eventId));
    final messagesAsync = ref.watch(chatMessagesProvider(eventId));
    final suggestionsAsync = ref.watch(eventSuggestionsProvider(eventId));
    final suggestionVotesAsync = ref.watch(suggestionVotesProvider(eventId));
    final userSuggestionVotesAsync = ref.watch(
      userSuggestionVotesProvider(eventId),
    );
    final participantsAsync = ref.watch(eventParticipantsProvider(eventId));

    // Helper to refresh all event data
    Future<void> refreshEventData() async {
      ref.invalidate(eventDetailProvider(eventId));
      ref.invalidate(eventRsvpsProvider(eventId));
      ref.invalidate(userRsvpProvider(eventId));
      ref.invalidate(eventPollsProvider(eventId));
      ref.invalidate(chatMessagesProvider(eventId));
      ref.invalidate(eventSuggestionsProvider(eventId));
      ref.invalidate(suggestionVotesProvider(eventId));
      ref.invalidate(userSuggestionVotesProvider(eventId));
      ref.invalidate(eventLocationSuggestionsProvider(eventId));
      ref.invalidate(locationSuggestionVotesProvider(eventId));
      ref.invalidate(userLocationSuggestionVotesProvider(eventId));
      ref.invalidate(eventParticipantsProvider(eventId));

      // Invalidate expenses for this event
      ref.invalidate(eventExpensesProvider(eventId));

      // Invalidate base payment providers (affects all events)
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        ref.invalidate(paymentsOwedToUserProvider);
        ref.invalidate(paymentsUserOwesProvider);
      }
    }

    final eventName = eventAsync.value?.name ?? '';

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: _showTitleInAppBar ? eventName : '',
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
                // Cache the isHost status
                _cachedIsHost = canManage;

                // Only show settings icon for host or group admins
                if (!canManage) {
                  return const SizedBox.shrink();
                }

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
              loading: () {
                // Use cached state during loading to prevent flicker
                if (_cachedIsHost == true) {
                  final eventData = eventAsync.value;
                  if (eventData != null) {
                    return IconButton(
                      icon: const Icon(Icons.edit, color: BrandColors.text1),
                      onPressed: () {
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
                      },
                    );
                  }
                }
                return const SizedBox.shrink();
              },
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
      ),
      body: eventAsync.when(
        data: (event) => RefreshIndicator(
          onRefresh: refreshEventData,
          color: BrandColors.planning,
          backgroundColor: BrandColors.bg2,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(
              left: Insets.screenH,
              right: Insets.screenH,
              top: Gaps.sm,
              bottom: Gaps.lg,
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
                  groupName: event.groupName,
                ),
                const SizedBox(height: Gaps.md),

                // Event status chip - always visible
                _buildEventStatusSection(event),

                // RSVP Widget
                _buildRsvpSection(event, currentUserId),

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
                          !(s.endDateTime
                                  ?.isAtSameMomentAs(event.endDateTime!) ??
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

                            // Calculate going count from RSVP votes
                            final goingCount = rsvpsAsync.maybeWhen(
                              data: (rsvps) => rsvps
                                  .where((r) => r.status == RsvpStatus.going)
                                  .length,
                              orElse: () => 0,
                            );

                            // Always add current event date as FIRST option (for comparison)
                            if (event.startDateTime != null &&
                                event.endDateTime != null) {
                              dateTimeSuggestions.add(DateTimeSuggestion(
                                id: 'current_event_date',
                                startDateTime: event.startDateTime!,
                                endDateTime: event.endDateTime!,
                                voteCount:
                                    goingCount, // Show number of 'Can' votes from RSVP
                                hasUserVoted: false,
                                votes: [],
                              ));
                            }

                            // Add all ALTERNATIVE suggestions (different from current date)
                            dateTimeSuggestions
                                .addAll(alternateSuggestions.map((
                              suggestion,
                            ) {
                              final suggestionVotes = allVotes
                                  .where(
                                    (vote) =>
                                        vote.suggestionId == suggestion.id,
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
                                  currentEventStartDateTime:
                                      event.startDateTime,
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
                                    if (event.startDateTime == null ||
                                        event.endDateTime == null) {
                                      TopBanner.showError(
                                        context,
                                        message:
                                            'Event dates must be set before adding suggestions',
                                      );
                                      return;
                                    }
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

                                // Calculate going count from RSVP votes
                                final locationGoingCount = rsvpsAsync.maybeWhen(
                                  data: (rsvps) => rsvps
                                      .where(
                                          (r) => r.status == RsvpStatus.going)
                                      .length,
                                  orElse: () => 0,
                                );

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
                                    currentEventGoingCount: locationGoingCount,
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
                                if (kDebugMode) {}
                                return const SizedBox.shrink();
                              },
                              error: (error, stack) {
                                if (kDebugMode) {}
                                return const SizedBox.shrink();
                              },
                            );
                          },
                          loading: () {
                            if (kDebugMode) {}
                            return const SizedBox.shrink();
                          },
                          error: (error, stack) {
                            if (kDebugMode) {}
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
                      if (messages.isNotEmpty) {}
                    }

                    // Get unread count (now returns AsyncValue)
                    final unreadCountAsync = ref.watch(
                      unreadMessagesCountProvider(eventId),
                    );

                    final unreadCount = unreadCountAsync.maybeWhen(
                      data: (count) => count,
                      orElse: () => 0,
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
                            isReadBySomeone: m.isReadBySomeone,
                            isPinned: m.isPinned,
                            isDeleted: m.isDeleted,
                            isPending: m.isPending,
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
                                    isReadBySomeone: m.replyTo!.isReadBySomeone,
                                    isPinned: m.replyTo!.isPinned,
                                    isDeleted: m.replyTo!.isDeleted,
                                    isPending: m.replyTo!.isPending,
                                  )
                                : null,
                          ),
                        )
                        .toList();

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
                        if (kDebugMode) {}

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
                            if (kDebugMode) {}
                          } catch (e) {
                            if (kDebugMode) {}
                          }
                        }

                        await ref
                            .read(chatActionsProvider(eventId))
                            .sendMessage(
                              content,
                              replyTo: replyToMessage,
                            );
                        if (kDebugMode) {}
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
                        if (kDebugMode) {}
                        await ref
                            .read(chatActionsProvider(eventId))
                            .sendMessage(content);
                        if (kDebugMode) {}
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
                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;
                    final participantOptions = participants.map((p) {
                      return ExpenseParticipantOption(
                        id: p.userId,
                        name: _getUserDisplayName(
                            p.userId, p.displayName, currentUserId),
                        avatarUrl: p.avatarUrl,
                      );
                    }).toList();

                    // Sort: "You" first, then alphabetically by name
                    participantOptions.sort((a, b) {
                      if (a.name == 'You') return -1;
                      if (b.name == 'You') return 1;
                      return a.name.compareTo(b.name);
                    });

                    return EventExpensesWidget(
                      eventId: eventId,
                      mode: ChatMode.planning,
                      participants: participantOptions, // ✅ Participantes reais
                      onAddExpense:
                          (title, paidById, participantsOwe, amount) async {
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
                    return const SizedBox.shrink();
                  },
                  error: (error, stack) {
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
                        (event.startDateTime == null ||
                            event.location == null)) {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION BUILDER METHODS
  // These methods extract complex widget trees from build() for better organization
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds the event status chip section
  /// Shows status for all users, with management actions for hosts
  Widget _buildEventStatusSection(EventDetail event) {
    return Consumer(
      builder: (context, consumerRef, _) {
        final canManageAsync = consumerRef.watch(
          canManageEventProvider(eventId),
        );

        return canManageAsync.when(
          data: (canManage) {
            // Cache the isHost status
            _cachedIsHost = canManage;

            return Column(
              children: [
                EventStatusChip(
                  status: event.status,
                  isHost: canManage,
                  onTap: canManage
                      ? () => _showStatusChangeDialog(
                            context,
                            ref,
                            eventId,
                            event.status,
                          )
                      : () {},
                ),
                const SizedBox(height: Gaps.lg),
              ],
            );
          },
          loading: () => Column(
            children: [
              EventStatusChip(
                status: event.status,
                isHost: _cachedIsHost ?? false,
                onTap: (_cachedIsHost ?? false)
                    ? () => _showStatusChangeDialog(
                          context,
                          ref,
                          eventId,
                          event.status,
                        )
                    : () {},
              ),
              const SizedBox(height: Gaps.lg),
            ],
          ),
          error: (_, __) => Column(
            children: [
              EventStatusChip(
                status: event.status,
                isHost: _cachedIsHost ?? false,
                onTap: (_cachedIsHost ?? false)
                    ? () => _showStatusChangeDialog(
                          context,
                          ref,
                          eventId,
                          event.status,
                        )
                    : () {},
              ),
              const SizedBox(height: Gaps.lg),
            ],
          ),
        );
      },
    );
  }

  /// Builds the RSVP section with voting functionality
  /// This is one of the most complex sections with nested AsyncValues
  Widget _buildRsvpSection(EventDetail event, String? currentUserId) {
    final rsvpsAsync = ref.watch(eventRsvpsProvider(eventId));
    final userRsvpAsync = ref.watch(userRsvpProvider(eventId));
    final suggestionsAsync = ref.watch(eventSuggestionsProvider(eventId));

    return rsvpsAsync.when(
      data: (rsvps) {
        return userRsvpAsync.when(
          data: (userRsvp) {
            return suggestionsAsync.when(
              data: (suggestions) => _buildRsvpWidget(
                event,
                currentUserId,
                rsvps,
                userRsvp,
                suggestions,
              ),
              loading: () => _buildRsvpLoadingState(
                event,
                currentUserId,
                rsvps,
                userRsvp,
              ),
              error: (error, stack) => _buildRsvpLoadingState(
                event,
                currentUserId,
                rsvps,
                userRsvp,
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildRsvpErrorState(event, currentUserId),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildRsvpErrorState(event, currentUserId),
    );
  }

  /// Helper: Builds the actual RSVP widget with all data loaded
  Widget _buildRsvpWidget(
    EventDetail event,
    String? currentUserId,
    List<Rsvp> rsvps,
    Rsvp? userRsvp,
    List<Suggestion> suggestions,
  ) {
    // Filter suggestions DIFFERENT from current event date
    final alternateDateSuggestions = suggestions.where((s) {
      if (event.startDateTime == null || event.endDateTime == null) {
        return true;
      }
      final isDifferent =
          !s.startDateTime.isAtSameMomentAs(event.startDateTime!) ||
              !(s.endDateTime?.isAtSameMomentAs(event.endDateTime!) ?? false);
      return isDifferent;
    }).toList();

    return Consumer(
      builder: (context, consumerRef, child) {
        final locationSuggestionsAsync = consumerRef.watch(
          eventLocationSuggestionsProvider(eventId),
        );

        return locationSuggestionsAsync.when(
          data: (locationSuggestions) {
            // Filter location suggestions DIFFERENT from current event location
            final alternateLocationSuggestions = locationSuggestions.where((s) {
              if (event.location == null) return true;
              final isDifferent =
                  s.locationName != event.location!.displayName ||
                      (s.address ?? '') != event.location!.formattedAddress;
              return isDifferent;
            }).toList();

            // Calculate dynamic counts
            final goingCount =
                rsvps.where((r) => r.status == RsvpStatus.going).length;
            final notGoingCount =
                rsvps.where((r) => r.status == RsvpStatus.notGoing).length;
            final pendingCount =
                rsvps.where((r) => r.status == RsvpStatus.pending).length;

            return Column(
              children: [
                rsvp_widget.RsvpWidget(
                  goingCount: goingCount,
                  notGoingCount: notGoingCount,
                  pendingCount: pendingCount,
                  userVote: _getUserVoteStatus(userRsvp),
                  onGoingPressed: () async {
                    final currentStatus =
                        userRsvp?.status ?? RsvpStatus.pending;
                    final newStatus = currentStatus == RsvpStatus.going
                        ? RsvpStatus.pending
                        : RsvpStatus.going;
                    await ref
                        .read(userRsvpProvider(eventId).notifier)
                        .submitVote(newStatus);
                  },
                  onNotGoingPressed: () async {
                    final currentStatus =
                        userRsvp?.status ?? RsvpStatus.pending;
                    final newStatus = currentStatus == RsvpStatus.notGoing
                        ? RsvpStatus.pending
                        : RsvpStatus.notGoing;
                    await ref
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
                          if (event.startDateTime == null ||
                              event.endDateTime == null) {
                            TopBanner.showError(
                              context,
                              message:
                                  'Event dates must be set before adding suggestions',
                            );
                            return;
                          }
                          showAddSuggestionBottomSheet(
                            context,
                            eventId: eventId,
                            eventStartDate: event.startDateTime!,
                            eventStartTime:
                                TimeOfDay.fromDateTime(event.startDateTime!),
                            eventEndDate: event.endDateTime!,
                            eventEndTime:
                                TimeOfDay.fromDateTime(event.endDateTime!),
                            type: locationSuggestions.isNotEmpty
                                ? SuggestionType.location
                                : SuggestionType.dateTime,
                            currentEventLocationName:
                                event.location?.displayName,
                            currentEventAddress:
                                event.location?.formattedAddress,
                          );
                        }
                      : null,
                  eventStartDateTime: event.startDateTime,
                  eventEndDateTime: event.endDateTime,
                  isHost: event.hostId == currentUserId,
                  hasSuggestions: alternateDateSuggestions.isNotEmpty ||
                      alternateLocationSuggestions.isNotEmpty,
                ),
                const SizedBox(height: Gaps.lg),
              ],
            );
          },
          loading: () => _buildRsvpLoadingState(
            event,
            currentUserId,
            rsvps,
            userRsvp,
          ),
          error: (error, stack) => _buildRsvpLoadingState(
            event,
            currentUserId,
            rsvps,
            userRsvp,
          ),
        );
      },
    );
  }

  /// Helper: Builds RSVP widget in loading state
  Widget _buildRsvpLoadingState(
    EventDetail event,
    String? currentUserId,
    List<Rsvp> rsvps,
    Rsvp? userRsvp,
  ) {
    final goingCount = rsvps.where((r) => r.status == RsvpStatus.going).length;
    final notGoingCount =
        rsvps.where((r) => r.status == RsvpStatus.notGoing).length;
    final pendingCount =
        rsvps.where((r) => r.status == RsvpStatus.pending).length;

    return Column(
      children: [
        rsvp_widget.RsvpWidget(
          goingCount: goingCount,
          notGoingCount: notGoingCount,
          pendingCount: pendingCount,
          userVote: _getUserVoteStatus(userRsvp),
          onGoingPressed: () async {
            final currentStatus = userRsvp?.status ?? RsvpStatus.pending;
            final newStatus = currentStatus == RsvpStatus.going
                ? RsvpStatus.pending
                : RsvpStatus.going;
            await ref
                .read(userRsvpProvider(eventId).notifier)
                .submitVote(newStatus);
          },
          onNotGoingPressed: () async {
            final currentStatus = userRsvp?.status ?? RsvpStatus.pending;
            final newStatus = currentStatus == RsvpStatus.notGoing
                ? RsvpStatus.pending
                : RsvpStatus.notGoing;
            await ref
                .read(userRsvpProvider(eventId).notifier)
                .submitVote(newStatus);
          },
          allVotes: rsvps
              .map(
                (r) => rsvp_widget.RsvpVote(
                  id: r.id,
                  userId: r.userId,
                  userName:
                      _getUserDisplayName(r.userId, r.userName, currentUserId),
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
          onAddSuggestion: null,
          eventStartDateTime: event.startDateTime,
          eventEndDateTime: event.endDateTime,
          isHost: event.hostId == currentUserId,
          hasSuggestions: false,
        ),
        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  /// Helper: Builds RSVP widget in error state
  Widget _buildRsvpErrorState(EventDetail event, String? currentUserId) {
    return Column(
      children: [
        rsvp_widget.RsvpWidget(
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
        ),
        const SizedBox(height: Gaps.lg),
      ],
    );
  }
}

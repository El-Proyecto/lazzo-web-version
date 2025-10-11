import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart' as rsvp_widget;
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/components/widgets/date_time_widget.dart';
import '../../../../shared/components/widgets/poll_widget.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/rsvp.dart';
import '../../domain/entities/suggestion.dart';
import '../providers/event_providers.dart';
import '../widgets/chat_preview_widget.dart';
import '../widgets/date_time_suggestions_widget.dart'
    show DateTimeSuggestionsWidget, DateTimeSuggestion;
import '../widgets/date_time_suggestions_widget.dart' as datetime_widget;
import '../widgets/location_suggestions_widget.dart';
import '../widgets/add_suggestion_bottom_sheet.dart';

/// Event detail page
/// Displays all event information and interactions
class EventPage extends ConsumerWidget {
  final String eventId;

  const EventPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final rsvpsAsync = ref.watch(eventRsvpsProvider(eventId));
    final userRsvpAsync = ref.watch(userRsvpProvider(eventId));
    final pollsAsync = ref.watch(eventPollsProvider(eventId));
    final messagesAsync = ref.watch(recentMessagesProvider(eventId));
    final suggestionsAsync = ref.watch(eventSuggestionsProvider(eventId));
    final suggestionVotesAsync = ref.watch(suggestionVotesProvider(eventId));
    final userSuggestionVotesAsync = ref.watch(
      userSuggestionVotesProvider(eventId),
    );

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: BrandColors.text1),
          onPressed: () {
            // TODO: Navigate to edit event page
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
              const SizedBox(height: Gaps.lg),

              // RSVP Widget
              rsvpsAsync.when(
                data: (rsvps) {
                  return userRsvpAsync.when(
                    data: (userRsvp) {
                      return suggestionsAsync.when(
                        data: (suggestions) {
                          // Also check location suggestions for hasSuggestions flag
                          return Consumer(
                            builder: (context, ref, child) {
                              final locationSuggestionsAsync = ref.watch(
                                eventLocationSuggestionsProvider(eventId),
                              );

                              return locationSuggestionsAsync.when(
                                data: (locationSuggestions) {
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
                                      final currentStatus =
                                          userRsvp?.status ??
                                          RsvpStatus.pending;
                                      final newStatus =
                                          currentStatus == RsvpStatus.going
                                          ? RsvpStatus.pending
                                          : RsvpStatus.going;
                                      await ref
                                          .read(
                                            userRsvpProvider(eventId).notifier,
                                          )
                                          .submitVote(newStatus, ref: ref);
                                      // Invalidate RSVP data to refresh counts AFTER vote is submitted
                                      ref.invalidate(
                                        eventRsvpsProvider(eventId),
                                      );
                                    },
                                    onNotGoingPressed: () async {
                                      final currentStatus =
                                          userRsvp?.status ??
                                          RsvpStatus.pending;
                                      final newStatus =
                                          currentStatus == RsvpStatus.notGoing
                                          ? RsvpStatus.pending
                                          : RsvpStatus.notGoing;
                                      await ref
                                          .read(
                                            userRsvpProvider(eventId).notifier,
                                          )
                                          .submitVote(newStatus, ref: ref);
                                      // Invalidate RSVP data to refresh counts AFTER vote is submitted
                                      ref.invalidate(
                                        eventRsvpsProvider(eventId),
                                      );
                                    },
                                    allVotes: rsvps
                                        .map(
                                          (r) => rsvp_widget.RsvpVote(
                                            id: r.id,
                                            userId: r.userId,
                                            userName: r.userName,
                                            userAvatar: r.userAvatar,
                                            status: r.status == RsvpStatus.going
                                                ? rsvp_widget
                                                      .RsvpVoteStatus
                                                      .going
                                                : r.status ==
                                                      RsvpStatus.notGoing
                                                ? rsvp_widget
                                                      .RsvpVoteStatus
                                                      .notGoing
                                                : rsvp_widget
                                                      .RsvpVoteStatus
                                                      .pending,
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
                                                type:
                                                    locationSuggestions
                                                        .isNotEmpty
                                                    ? SuggestionType.location
                                                    : SuggestionType
                                                          .dateTime, // Start with Location tab if location suggestions exist
                                                currentEventLocationName:
                                                    event.location?.displayName,
                                                currentEventAddress: event
                                                    .location
                                                    ?.formattedAddress,
                                              );
                                            }
                                          }
                                        : null,
                                    eventStartDateTime: event.startDateTime,
                                    eventEndDateTime: event.endDateTime,
                                    isHost:
                                        event.hostId ==
                                        'current-user', // TODO: Get from auth service
                                    hasSuggestions:
                                        suggestions.isNotEmpty ||
                                        locationSuggestions.isNotEmpty,
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
                                          userName: r.userName,
                                          userAvatar: r.userAvatar,
                                          status: r.status == RsvpStatus.going
                                              ? rsvp_widget.RsvpVoteStatus.going
                                              : r.status == RsvpStatus.notGoing
                                              ? rsvp_widget
                                                    .RsvpVoteStatus
                                                    .notGoing
                                              : rsvp_widget
                                                    .RsvpVoteStatus
                                                    .pending,
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
                                              eventEndDate: event.endDateTime!,
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
                                  isHost:
                                      event.hostId ==
                                      'current-user', // TODO: Get from auth service
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
                                          userName: r.userName,
                                          userAvatar: r.userAvatar,
                                          status: r.status == RsvpStatus.going
                                              ? rsvp_widget.RsvpVoteStatus.going
                                              : r.status == RsvpStatus.notGoing
                                              ? rsvp_widget
                                                    .RsvpVoteStatus
                                                    .notGoing
                                              : rsvp_widget
                                                    .RsvpVoteStatus
                                                    .pending,
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
                                              eventEndDate: event.endDateTime!,
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
                                  isHost:
                                      event.hostId ==
                                      'current-user', // TODO: Get from auth service
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
                                  userName: r.userName,
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
                          isHost:
                              event.hostId ==
                              'current-user', // TODO: Get from auth service
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
                                  userName: r.userName,
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
                          isHost:
                              event.hostId ==
                              'current-user', // TODO: Get from auth service
                          hasSuggestions: false, // Default to false on error
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const SizedBox.shrink(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: Gaps.lg),

              // Date & Time Suggestions Widget (appears when suggestions exist)
              suggestionsAsync.when(
                data: (suggestions) {
                  if (suggestions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return suggestionVotesAsync.when(
                    data: (allVotes) {
                      return userSuggestionVotesAsync.when(
                        data: (userVotes) {
                          // Convert suggestions to DateTimeSuggestion format
                          final dateTimeSuggestions = suggestions.map((
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
                                    userName: vote.userName,
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
                          }).toList();

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
                                isHost:
                                    event.hostId ==
                                    'current-user', // TODO: Get from auth service
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
                builder: (context, ref, child) {
                  final locationSuggestionsAsync = ref.watch(
                    eventLocationSuggestionsProvider(eventId),
                  );
                  final locationVotesAsync = ref.watch(
                    locationSuggestionVotesProvider(eventId),
                  );
                  final userLocationVotesAsync = ref.watch(
                    userLocationSuggestionVotesProvider(eventId),
                  );

                  return locationSuggestionsAsync.when(
                    data: (locationSuggestions) {
                      // Only show widget when there are location suggestions
                      if (locationSuggestions.isEmpty) {
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
                                  isHost: event.hostId == 'current-user',
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
                            loading: () => const SizedBox.shrink(),
                            error: (error, stack) => const SizedBox.shrink(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
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
                  final unreadCount = ref.watch(
                    unreadMessagesCountProvider(eventId),
                  );
                  return ChatPreviewWidget(
                    newMessagesCount: unreadCount,
                    currentUserId:
                        'current-user', // TODO: Get from auth provider
                    recentMessages: messages
                        .map(
                          (m) => ChatMessagePreview(
                            userId: m.userId,
                            userName: m.userName,
                            userAvatar: m.userAvatar,
                            content: m.content,
                            timestamp: m.createdAt,
                            read: m.read,
                          ),
                        )
                        .toList(),
                    onOpenChat: () {
                      // TODO: Navigate to full chat page
                    },
                    onSendMessage: (content) async {
                      await ref
                          .read(sendMessageProvider.notifier)
                          .sendMessage(eventId, content);
                      // No need to invalidate - the provider handles state automatically
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
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
                          isHost: event.hostId == 'current-user',
                          onVote: (optionId) {
                            // TODO: Implement vote on poll
                          },
                          onPickFinal: event.hostId == 'current-user'
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event date has been set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      // Show error feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set event date: $error'),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event location has been set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      // Show error feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set event location: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

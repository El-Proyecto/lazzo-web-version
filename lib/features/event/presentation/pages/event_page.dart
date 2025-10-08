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
import '../providers/event_providers.dart';
import '../widgets/chat_preview_widget.dart';
import '../widgets/date_time_suggestions_widget.dart';
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
              const SizedBox(height: Gaps.xl),

              // RSVP Widget
              rsvpsAsync.when(
                data: (rsvps) {
                  return userRsvpAsync.when(
                    data: (userRsvp) {
                      return suggestionsAsync.when(
                        data: (suggestions) {
                          // Calculate dynamic counts from actual RSVP data
                          final goingCount = rsvps
                              .where((r) => r.status == RsvpStatus.going)
                              .length;
                          final notGoingCount = rsvps
                              .where((r) => r.status == RsvpStatus.notGoing)
                              .length;
                          final pendingCount = rsvps
                              .where((r) => r.status == RsvpStatus.pending)
                              .length;

                          return rsvp_widget.RsvpWidget(
                            goingCount: goingCount,
                            notGoingCount: notGoingCount,
                            pendingCount: pendingCount,
                            userVote: _getUserVoteStatus(userRsvp),
                            onGoingPressed: () async {
                              final currentStatus =
                                  userRsvp?.status ?? RsvpStatus.pending;
                              final newStatus =
                                  currentStatus == RsvpStatus.going
                                  ? RsvpStatus.pending
                                  : RsvpStatus.going;
                              await ref
                                  .read(userRsvpProvider(eventId).notifier)
                                  .submitVote(newStatus, ref: ref);
                              // Invalidate RSVP data to refresh counts AFTER vote is submitted
                              ref.invalidate(eventRsvpsProvider(eventId));
                            },
                            onNotGoingPressed: () async {
                              final currentStatus =
                                  userRsvp?.status ?? RsvpStatus.pending;
                              final newStatus =
                                  currentStatus == RsvpStatus.notGoing
                                  ? RsvpStatus.pending
                                  : RsvpStatus.notGoing;
                              await ref
                                  .read(userRsvpProvider(eventId).notifier)
                                  .submitVote(newStatus, ref: ref);
                              // Invalidate RSVP data to refresh counts AFTER vote is submitted
                              ref.invalidate(eventRsvpsProvider(eventId));
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
                            onAddSuggestion:
                                _getUserVoteStatus(userRsvp) == false
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
                            onPickAsFinal: () {
                              // TODO: Implement RSVP pick as final logic
                            },
                            hasSuggestions: suggestions.isNotEmpty,
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
                          onPickAsFinal: () {
                            // TODO: Implement RSVP pick as final logic
                          },
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
                          onPickAsFinal: () {
                            // TODO: Implement RSVP pick as final logic
                          },
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
              const SizedBox(height: Gaps.xl),

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
                                  (vote) => SuggestionVote(
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
                                onPickAsFinal: (suggestionId) {
                                  // TODO: Implement pick as final logic
                                },
                              ),
                              const SizedBox(height: Gaps.xl),
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
              const SizedBox(height: Gaps.xl),

              // Location Widget (if location is set)
              if (event.location != null) ...[
                LocationWidget(
                  displayName: event.location!.displayName,
                  formattedAddress: event.location!.formattedAddress,
                  latitude: event.location!.latitude,
                  longitude: event.location!.longitude,
                ),
                const SizedBox(height: Gaps.xl),
              ],

              // Date & Time Widget (if date is set)
              if (event.startDateTime != null) ...[
                DateTimeWidget(
                  eventName: event.name,
                  startDateTime: event.startDateTime!,
                  endDateTime: event.endDateTime,
                  location: event.location?.formattedAddress,
                ),
                const SizedBox(height: Gaps.xl),
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
                        padding: const EdgeInsets.only(bottom: Gaps.xl),
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
}

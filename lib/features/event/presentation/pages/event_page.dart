import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../create_event/domain/entities/event.dart' as create_event;
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/chips/event_status_chip.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../../../../shared/components/dialogs/missing_fields_confirmation_dialog.dart';
import '../../../../shared/components/widgets/help_plan_event_widget.dart';
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/components/widgets/event_details_widget.dart';
import '../../../../shared/components/widgets/date_time_widget.dart';
import '../../../../shared/components/widgets/poll_widget.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../services/calendar_service.dart';
import '../../domain/entities/rsvp.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/entities/event_detail.dart';
import '../providers/event_providers.dart';
import '../widgets/date_time_suggestions_widget.dart'
    show DateTimeSuggestionsWidget, DateTimeSuggestion;
import '../widgets/date_time_suggestions_widget.dart' as datetime_widget;
import '../widgets/location_suggestions_widget.dart';
import '../widgets/add_suggestion_bottom_sheet.dart';
import '../../../../config/app_config.dart';
import '../../../../shared/components/common/invite_bottom_sheet.dart';
import '../../../event_invites/presentation/providers/event_invite_providers.dart';
import '../../../../shared/components/widgets/rsvp_vote_buttons.dart';
import '../../../../shared/providers/realtime_refresh_provider.dart';
import 'event_page_models.dart';

// LAZZO 2.0: payments_provider import removed

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

  // Periodic timer to refresh guest RSVP counts (fallback for Realtime)
  Timer? _guestRsvpRefreshTimer;

  String get eventId => widget.eventId;

  @override
  void initState() {
    super.initState();
    // Setup Realtime subscription for unread count badge updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we need to show expiration warning
      _checkAndShowExpirationWarning();
    });

    // Listen to scroll to show/hide title in app bar
    _scrollController.addListener(_onScroll);

    // Periodically refresh guest RSVP list from web votes
    _guestRsvpRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          ref.invalidate(guestRsvpListProvider(eventId));
        }
      },
    );
  }

  @override
  void dispose() {
    _guestRsvpRefreshTimer?.cancel();
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

  /// Check if event is pending and about to expire, show warning to hosts
  Future<void> _checkAndShowExpirationWarning() async {
    try {
      final event = await ref.read(eventDetailProvider(eventId).future);
      final canManage = await ref.read(canManageEventProvider(eventId).future);

      // Only show for hosts
      if (!canManage) return;

      // Only show for pending events
      if (event.status != EventStatus.pending) return;

      // Only show if event has a start date
      if (event.startDateTime == null) return;

      // Check if less than 30 minutes until event starts
      final now = DateTime.now();
      final minutesUntilStart = event.startDateTime!.difference(now).inMinutes;

      // Show warning if less than 30 minutes and event hasn't started yet
      if (minutesUntilStart > 0 && minutesUntilStart <= 30 && mounted) {
        _showExpirationWarningDialog(event);
      }
    } catch (e) {
      // Silently fail - don't block page load
    }
  }

  /// Show warning dialog about event expiration
  void _showExpirationWarningDialog(EventDetail event) {
    // Check if location is defined
    final hasLocation = event.hasDefinedLocation;

    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => ConfirmationDialog(
        title: 'Event Will Expire Soon',
        message: hasLocation
            ? 'This event will be marked as expired if not confirmed before it starts. Confirm now to prevent expiration.'
            : 'This event will be marked as expired if not confirmed before it starts. Please set a location first, then confirm the event.',
        confirmText: hasLocation ? 'Confirm Event' : null,
        cancelText: 'Ok',
        isDestructive: false,
        onConfirm: hasLocation
            ? () async {
                // Check if event has date defined before confirming
                if (!event.hasDefinedDate) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => MissingFieldsConfirmationDialog(
                        hasLocation: event.hasDefinedLocation,
                        hasDate: event.hasDefinedDate,
                      ),
                    );
                  }
                  return;
                }

                // Confirm the event
                await ref
                    .read(eventStatusNotifierProvider(eventId).notifier)
                    .updateStatus(eventId, EventStatus.confirmed);

                if (context.mounted) {
                  TopBanner.showSuccess(
                    context,
                    message: 'Event confirmed successfully!',
                  );
                }
              }
            : null,
      ),
    );
  }

  /// Show dialog to change event status
  /// Now checks if event has required fields before allowing confirmation
  void _showStatusChangeDialog(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    EventDetail event,
    EventStatus currentStatus,
  ) {
    final isConfirmed = currentStatus == EventStatus.confirmed;

    // If trying to confirm expired event, show cannot confirm dialog
    if (!isConfirmed && event.isExpired) {
      showDialog(
        context: context,
        builder: (context) => ConfirmationDialog(
          title: 'Cannot Confirm Event',
          message:
              'Event date has expired. Please set a new date before confirming.',
          confirmText: 'OK',
          onConfirm: () {},
        ),
      );
      return;
    }

    // If trying to confirm but missing required fields, show warning dialog
    if (!isConfirmed && !event.isFullyDefined) {
      showDialog(
        context: context,
        builder: (context) => MissingFieldsConfirmationDialog(
          hasLocation: event.hasDefinedLocation,
          hasDate: event.hasDefinedDate,
        ),
      );
      return;
    }

    // If trying to confirm, check if there are participants who voted "Can"
    if (!isConfirmed) {
      final rsvpsAsync = ref.read(eventRsvpsProvider(eventId));
      final rsvps = rsvpsAsync.valueOrNull ?? [];
      final appGoingCount =
          rsvps.where((r) => r.status == RsvpStatus.going).length;
      final guestList = ref.read(guestRsvpListProvider(eventId)).valueOrNull ?? [];
      int webGoing = 0;
      for (final g in guestList) {
        if ((g['rsvp'] as String?) == 'going') webGoing++;
      }
      final goingCount = appGoingCount + webGoing;
      if (goingCount == 0) {
        showDialog(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: 'Cannot Confirm Event',
            message:
                'You need at least one participant who voted "Can" before confirming the event.',
            confirmText: 'Ok',
            onConfirm: () {},
          ),
        );
        return;
      }
    }

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
      description: event.description ?? 'Lazzo event',
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
    // Ensure Realtime refresh is active on this page (not just Home)
    ref.watch(realtimeRefreshProvider);

    final currentUserId = ref.watch(currentUserIdProvider);
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    // Note: rsvpsAsync, userRsvpAsync watched inside _buildRsvpSection()
    // Note: suggestionsAsync, suggestionVotesAsync, userSuggestionVotesAsync now in dateTimeSuggestionsDataProvider
    // Note: locationSuggestionsAsync, locationVotesAsync, userLocationVotesAsync now in locationSuggestionsDataProvider
    // Note: messagesAsync, unreadCountAsync now in chatPreviewDataProvider
    final pollsAsync = ref.watch(eventPollsProvider(eventId));
    // Participants watcher available via eventParticipantsProvider(eventId) when needed

    // Helper to refresh all event data
    Future<void> refreshEventData() async {
      ref.invalidate(eventDetailProvider(eventId));
      ref.invalidate(eventRsvpsProvider(eventId));
      ref.invalidate(userRsvpProvider(eventId));
      ref.invalidate(eventPollsProvider(eventId));
      ref.invalidate(eventSuggestionsProvider(eventId));
      ref.invalidate(suggestionVotesProvider(eventId));
      ref.invalidate(userSuggestionVotesProvider(eventId));
      ref.invalidate(eventLocationSuggestionsProvider(eventId));
      ref.invalidate(locationSuggestionVotesProvider(eventId));
      ref.invalidate(userLocationSuggestionVotesProvider(eventId));
      ref.invalidate(eventParticipantsProvider(eventId));
      ref.invalidate(guestRsvpListProvider(eventId));

      // LAZZO 2.0: payment provider invalidations removed
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
            final userRsvpAsync = consumerRef.watch(
              userRsvpProvider(eventId),
            );

            // Show ManageGuests icon only for hosts or users who have voted
            final isHost = canManageAsync.valueOrNull == true;
            final hasVoted = userRsvpAsync.valueOrNull != null &&
                userRsvpAsync.valueOrNull!.status != RsvpStatus.pending;

            if (!isHost && !hasVoted) return const SizedBox.shrink();

            return IconButton(
              icon: const Icon(Icons.people, color: BrandColors.text1),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.manageGuests,
                  arguments: {'eventId': eventId},
                );
              },
            );
          },
        ),
        trailing2: Consumer(
          builder: (context, consumerRef, _) {
            final canManageAsync = consumerRef.watch(
              canManageEventProvider(eventId),
            );

            return canManageAsync.when(
              data: (canManage) {
                // Cache the isHost status
                _cachedIsHost = canManage;

                // Show edit button for host/admin (except in living status)
                if (canManage) {
                  final eventData = eventAsync.value;
                  if (eventData != null &&
                      eventData.status != EventStatus.living) {
                    return IconButton(
                      icon: const Icon(Icons.edit, color: BrandColors.text1),
                      onPressed: () {
                        // Convert EventDetail to Event for edit page
                        final editEvent = create_event.Event(
                          id: eventData.id,
                          name: eventData.name,
                          emoji: eventData.emoji,
                          startDateTime: eventData.startDateTime,
                          endDateTime: eventData.endDateTime,
                          description: eventData.description,
                          location: eventData.location != null
                              ? create_event.EventLocation(
                                  id: 'temp-id',
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
              loading: () {
                // Use cached state during loading
                if (_cachedIsHost == true) {
                  final eventData = eventAsync.value;
                  if (eventData != null &&
                      eventData.status != EventStatus.living) {
                    return IconButton(
                      icon: const Icon(Icons.edit, color: BrandColors.text1),
                      onPressed: () {
                        final editEvent = create_event.Event(
                          id: eventData.id,
                          name: eventData.name,
                          emoji: eventData.emoji,
                          startDateTime: eventData.startDateTime,
                          endDateTime: eventData.endDateTime,
                          description: eventData.description,
                          location: eventData.location != null
                              ? create_event.EventLocation(
                                  id: 'temp-id',
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
      bottomNavigationBar: eventAsync.whenOrNull(
        data: (event) {
          // Show share button for pending, confirmed, living, and recap events
          if (event.status == EventStatus.pending ||
              event.status == EventStatus.confirmed ||
              event.status == EventStatus.living ||
              event.status == EventStatus.recap) {
            // Use accent color based on event status
            final buttonColor = event.status == EventStatus.living
                ? BrandColors.living
                : event.status == EventStatus.recap
                    ? BrandColors.recap
                    : BrandColors.planning;
            final buttonLabel = (event.status == EventStatus.living ||
                    event.status == EventStatus.recap)
                ? 'Share event with friends'
                : 'Share invite with friends';
            return Container(
              padding: const EdgeInsets.fromLTRB(
                Insets.screenH,
                Gaps.sm,
                Insets.screenH,
                Gaps.lg,
              ),
              decoration: const BoxDecoration(
                color: BrandColors.bg2,
                border: Border(
                  top: BorderSide(color: BrandColors.border, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: TouchTargets.input,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final useCase = ref.read(createEventInviteLinkProvider);
                        final entity = await useCase(
                          eventId: eventId,
                          shareChannel: 'share_button',
                        );
                        final inviteUrl =
                            '${AppConfig.invitesBaseUrl}/i/${entity.token}';
                        if (context.mounted) {
                          InviteBottomSheet.show(
                            context: context,
                            inviteUrl: inviteUrl,
                            entityName: event.name,
                            entityType: 'event',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to create invite link'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.ios_share, size: IconSizes.smAlt),
                    label: Text(
                      buttonLabel,
                      style: AppText.labelLarge.copyWith(
                        color: BrandColors.text1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: BrandColors.text1,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.smAlt),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return null;
        },
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
                  isExpired: event.isExpired,
                ),
                const SizedBox(height: Gaps.md),

                // Event status chip - always visible
                _buildEventStatusSection(event),

                // RSVP Widget
                _buildRsvpSection(event, currentUserId),

                // Date & Time Suggestions Widget (OPTIMIZED)
                // Skip entirely when event is expired (table may not exist)
                if (!event.isExpired)
                  Consumer(
                    builder: (context, ref, child) {
                      final dataAsync =
                          ref.watch(dateTimeSuggestionsDataProvider(eventId));

                      // If no data yet (initial load), show nothing
                      if (!dataAsync.hasValue) {
                        return const SizedBox.shrink();
                      }

                      // Use .value to access data even during refresh (when isLoading: true, hasValue: true)
                      final data = dataAsync.value!;

                      // Process raw data into UI models
                      final processedData = _processDateTimeSuggestions(
                        suggestions: data['suggestions'] as List<Suggestion>,
                        allVotes: data['allVotes'] as List<SuggestionVote>,
                        userVoteIds: data['userVoteIds'] as Set<String>,
                        event: event,
                        goingCount: data['goingCount'] as int,
                        currentUserId: currentUserId,
                      );

                      // Hide if no alternatives
                      if (!processedData.hasAlternatives) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          DateTimeSuggestionsWidget(
                            suggestions: processedData.suggestions,
                            userVotes: data['userVoteIds'] as Set<String>,
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
                            isHost: _cachedIsHost ?? false,
                            currentUserId: currentUserId,
                            onAddSuggestion: () {
                              showAddSuggestionBottomSheet(
                                context,
                                eventId: eventId,
                                eventStartDate:
                                    event.startDateTime ?? DateTime.now(),
                                eventStartTime: event.startDateTime != null
                                    ? TimeOfDay.fromDateTime(
                                        event.startDateTime!)
                                    : const TimeOfDay(hour: 0, minute: 0),
                                eventEndDate:
                                    event.endDateTime ?? DateTime.now(),
                                eventEndTime: event.endDateTime != null
                                    ? TimeOfDay.fromDateTime(event.endDateTime!)
                                    : const TimeOfDay(hour: 0, minute: 0),
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
                  ),

                // Location Suggestions Widget (OPTIMIZED)
                // Skip entirely when event is expired (table may not exist)
                if (!event.isExpired)
                  Consumer(
                    builder: (context, ref, child) {
                      final dataAsync =
                          ref.watch(locationSuggestionsDataProvider(eventId));

                      // If no data yet (initial load), show nothing
                      if (!dataAsync.hasValue) {
                        return const SizedBox.shrink();
                      }

                      // Use .value to access data even during refresh (when isLoading: true, hasValue: true)
                      final data = dataAsync.value!;
                      final locationSuggestions = data['locationSuggestions']
                          as List<LocationSuggestion>;

                      // Hide if no suggestions
                      if (locationSuggestions.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      // Process data to check for alternatives
                      final processedData = _processLocationSuggestions(
                        suggestions: locationSuggestions,
                        allVotes: data['locationVotes'] as List<SuggestionVote>,
                        event: event,
                        goingCount: data['goingCount'] as int,
                      );

                      // Hide if no alternatives
                      if (!processedData.hasAlternatives) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: Gaps.lg),
                        child: LocationSuggestionsWidget(
                          suggestions: processedData.suggestions,
                          allVotes:
                              data['locationVotes'] as List<SuggestionVote>,
                          userVotes: data['userVoteIds'] as Set<String>,
                          onVote: (suggestionId) {
                            ref
                                .read(
                                  toggleLocationSuggestionVoteNotifierProvider
                                      .notifier,
                                )
                                .toggleVote(eventId, suggestionId);
                          },
                          isHost: _cachedIsHost ?? false,
                          currentUserId: currentUserId,
                          currentEventGoingCount:
                              processedData.currentEventGoingCount,
                          onAddSuggestion: () {
                            showAddSuggestionBottomSheet(
                              context,
                              eventId: eventId,
                              eventStartDate:
                                  event.startDateTime ?? DateTime.now(),
                              eventStartTime: event.startDateTime != null
                                  ? TimeOfDay.fromDateTime(event.startDateTime!)
                                  : const TimeOfDay(hour: 0, minute: 0),
                              eventEndDate: event.endDateTime ?? DateTime.now(),
                              eventEndTime: event.endDateTime != null
                                  ? TimeOfDay.fromDateTime(event.endDateTime!)
                                  : const TimeOfDay(hour: 0, minute: 0),
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
                          currentEventLocationName: event.location?.displayName,
                          currentEventAddress: event.location?.formattedAddress,
                        ),
                      );
                    },
                  ),

                // LAZZO 2.0: Expenses widget removed

                // Event details/description (if present)
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  EventDetailsWidget(details: event.description!),
                  const SizedBox(height: Gaps.lg),
                ],

                // Location Widget (if location has valid coordinates)
                if (event.location != null &&
                    (event.location!.latitude != 0.0 ||
                        event.location!.longitude != 0.0)) ...[
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
                // Use whenOrNull to keep previous polls visible during refresh
                pollsAsync.whenOrNull(
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
                    ) ??
                    const SizedBox.shrink(), // Default when no data yet
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
      // Get suggestion votes BEFORE clearing (needed for Step 2)
      final suggestionVotesAsync = ref.read(suggestionVotesProvider(eventId));
      final suggestionVotes = suggestionVotesAsync.value ?? [];

      final suggestionVoters = suggestionVotes
          .where((vote) => vote.suggestionId == selectedSuggestion.id)
          .map((vote) => vote.userId)
          .toList();

      // Step 1: Update the event's date and time
      final eventRepository = ref.read(eventRepositoryProvider);
      await eventRepository.updateEventDateTime(
        eventId,
        selectedSuggestion.startDateTime,
        selectedSuggestion.endDateTime,
      );

      // Step 2: Reset RSVP votes for suggestion voters
      final rsvpRepository = ref.read(rsvpRepositoryProvider);
      await rsvpRepository.resetRsvpVotesFromSuggestion(
        eventId,
        suggestionVoters,
      );

      // Step 3: Clear all suggestions for this event
      final suggestionRepository = ref.read(suggestionRepositoryProvider);
      await suggestionRepository.clearEventSuggestions(eventId);

      // Step 3.5: Wait for DB to propagate changes
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Invalidate providers to refetch updated data
      // This triggers UI rebuild with new event state
      ref.invalidate(eventDetailProvider(eventId));
      ref.invalidate(eventSuggestionsProvider(eventId));
      ref.invalidate(suggestionVotesProvider(eventId));
      ref.invalidate(userSuggestionVotesProvider(eventId));
      ref.invalidate(dateTimeSuggestionsDataProvider(eventId));
      ref.invalidate(eventRsvpsProvider(eventId));
      ref.invalidate(userRsvpProvider(eventId));

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
      // Get location votes BEFORE clearing (needed for Step 2)
      final locationVotesAsync = ref.read(
        locationSuggestionVotesProvider(eventId),
      );
      final locationVotes = locationVotesAsync.value ?? [];

      final suggestionVoters = locationVotes
          .where((vote) => vote.suggestionId == selectedSuggestion.id)
          .map((vote) => vote.userId)
          .toList();

      // Step 1: Update the event's location
      final eventRepository = ref.read(eventRepositoryProvider);
      await eventRepository.updateEventLocation(
        eventId,
        selectedSuggestion.locationName,
        selectedSuggestion.address ?? '',
        selectedSuggestion.latitude ?? 0.0,
        selectedSuggestion.longitude ?? 0.0,
      );

      // Step 2: Reset RSVP votes for suggestion voters
      final rsvpRepository = ref.read(rsvpRepositoryProvider);
      await rsvpRepository.resetRsvpVotesFromSuggestion(
        eventId,
        suggestionVoters,
      );

      // Step 3: Clear all location suggestions for this event
      final suggestionRepository = ref.read(suggestionRepositoryProvider);
      await suggestionRepository.clearEventLocationSuggestions(eventId);

      // Step 3.5: Wait for DB to propagate changes
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3.6: Invalidate providers to refetch updated data
      // This triggers UI rebuild with new event state
      ref.invalidate(eventDetailProvider(eventId));
      ref.invalidate(eventLocationSuggestionsProvider(eventId));
      ref.invalidate(locationSuggestionVotesProvider(eventId));
      ref.invalidate(userLocationSuggestionVotesProvider(eventId));
      ref.invalidate(locationSuggestionsDataProvider(eventId));
      ref.invalidate(eventRsvpsProvider(eventId));
      ref.invalidate(userRsvpProvider(eventId));

      // Step 4: Show success feedback
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
                            event,
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
                          event,
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
                          event,
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

  /// Build help plan section when event has undefined/unsuggested fields
  /// Shows when location or date are not defined AND not suggested
  /// Shrinks when suggestions are added for the missing field
  Widget _buildHelpPlanSection(
    EventDetail event,
    List<dynamic> dateSuggestions,
    List<dynamic> locationSuggestions,
  ) {
    final hasSuggestedLocation = locationSuggestions.isNotEmpty;
    final hasSuggestedDate = dateSuggestions.isNotEmpty;

    // Check if widget should be visible
    final locationOk = event.hasDefinedLocation || hasSuggestedLocation;
    final dateOk = event.hasDefinedDate || hasSuggestedDate;

    // If both are ok (defined or suggested), shrink
    if (locationOk && dateOk) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        HelpPlanEventWidget(
          hasLocation: event.hasDefinedLocation,
          hasDate: event.hasDefinedDate,
          hasSuggestedLocation: hasSuggestedLocation,
          hasSuggestedDate: hasSuggestedDate,
          onAddSuggestion: () {
            // Determine initial tab:
            // - If both missing → start with dateTime tab
            // - If only location missing → location tab
            // - If only date missing → dateTime tab
            final SuggestionType initialType;
            if (!locationOk && !dateOk) {
              // Both missing: start with date/time
              initialType = SuggestionType.dateTime;
            } else if (!locationOk) {
              // Only location missing
              initialType = SuggestionType.location;
            } else {
              // Only date missing
              initialType = SuggestionType.dateTime;
            }

            // Use existing bottom sheet function
            showAddSuggestionBottomSheet(
              context,
              eventId: event.id,
              eventStartDate: event.startDateTime ?? DateTime.now(),
              eventStartTime: event.startDateTime != null
                  ? TimeOfDay.fromDateTime(event.startDateTime!)
                  : const TimeOfDay(hour: 12, minute: 0),
              eventEndDate: event.endDateTime ??
                  DateTime.now().add(const Duration(hours: 2)),
              eventEndTime: event.endDateTime != null
                  ? TimeOfDay.fromDateTime(event.endDateTime!)
                  : const TimeOfDay(hour: 14, minute: 0),
              type: initialType,
              currentEventLocationName: event.location?.displayName,
              currentEventAddress: event.location?.formattedAddress,
            );
          },
        ),
        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  /// Builds the expired event section
  /// Host: shows "Set new date" button that navigates to edit page
  /// Non-host: shows informational message that host needs to set a new date
  Widget _buildExpiredEventSection(EventDetail event, String? currentUserId) {
    final isHost = _cachedIsHost ?? (event.hostId == currentUserId);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Gaps.md),
          decoration: BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Event date has expired',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
              const SizedBox(height: Gaps.sm),

              if (isHost) ...[
                // Host: explain and provide action
                Text(
                  'The event date has passed without being confirmed. Set a new date to keep the event active.',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
                const SizedBox(height: Gaps.md),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to edit page
                    final editEvent = create_event.Event(
                      id: event.id,
                      name: event.name,
                      emoji: event.emoji,
                      startDateTime: event.startDateTime,
                      endDateTime: event.endDateTime,
                      description: event.description,
                      location: event.location != null
                          ? create_event.EventLocation(
                              id: 'temp-id',
                              displayName: event.location!.displayName,
                              formattedAddress:
                                  event.location!.formattedAddress,
                              latitude: event.location!.latitude,
                              longitude: event.location!.longitude,
                            )
                          : null,
                      status: create_event.EventStatus.pending,
                      createdAt: event.createdAt,
                    );

                    Navigator.pushNamed(
                      context,
                      AppRouter.editEvent,
                      arguments: {'event': editEvent},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.planning,
                    foregroundColor: BrandColors.bg1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gaps.md,
                      vertical: Pads.ctlVSm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.smAlt),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Set new date',
                    style: AppText.labelLarge.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ),
              ] else ...[
                // Non-host: informational message
                Text(
                  'The event date has passed. The host needs to set a new date for this event.',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  /// Builds the RSVP section with voting functionality
  /// This is one of the most complex sections with nested AsyncValues
  /// When event is not fully defined/suggested, shows HelpPlanSection instead
  Widget _buildRsvpSection(EventDetail event, String? currentUserId) {
    // If event is expired, show expired UI without loading suggestions
    // (suggestions table may not exist, so avoid the provider entirely)
    if (event.isExpired) {
      return _buildExpiredEventSection(event, currentUserId);
    }

    // Watch suggestions to determine visibility
    final suggestionsAsync = ref.watch(eventSuggestionsProvider(eventId));
    final locationSuggestionsAsync =
        ref.watch(eventLocationSuggestionsProvider(eventId));

    // If event is fully defined, show RSVP
    if (event.isFullyDefined) {
      // Original RSVP logic
      final rsvpsAsync = ref.watch(eventRsvpsProvider(eventId));
      final userRsvpAsync = ref.watch(userRsvpProvider(eventId));

      // Use whenOrNull to keep previous RSVP visible during refresh
      return rsvpsAsync.whenOrNull(
            data: (rsvps) {
              return userRsvpAsync.whenOrNull(
                    data: (userRsvp) {
                      return suggestionsAsync.whenOrNull(
                            data: (suggestions) => _buildRsvpWidget(
                              event,
                              currentUserId,
                              rsvps,
                              userRsvp,
                              suggestions,
                            ),
                          ) ??
                          _buildRsvpLoadingState(
                            event,
                            currentUserId,
                            rsvps,
                            userRsvp,
                          );
                    },
                  ) ??
                  _buildRsvpLoadingState(
                    event,
                    currentUserId,
                    rsvps,
                    null, // userRsvp not loaded yet
                  );
            },
          ) ??
          _buildRsvpErrorState(
              event, currentUserId); // Fallback for first load or error
    }

    // Event not fully defined - check suggestions and show HelpPlan if needed
    return suggestionsAsync.whenOrNull(
          data: (dateSuggestions) {
            return locationSuggestionsAsync.whenOrNull(
                  data: (locationSuggestions) => _buildHelpPlanSection(
                    event,
                    dateSuggestions,
                    locationSuggestions,
                  ),
                ) ??
                _buildHelpPlanSection(
                    event, dateSuggestions, const []); // location loading
          },
        ) ??
        _buildHelpPlanSection(
            event, const [], const []); // both loading or error
  }

  /// Helper: Builds the actual RSVP widget with all data loaded
  Widget _buildRsvpWidget(
    EventDetail event,
    String? currentUserId,
    List<Rsvp> rsvps,
    Rsvp? userRsvp,
    List<Suggestion> suggestions,
  ) {
    return Consumer(
      builder: (context, consumerRef, child) {
        final locationSuggestionsAsync = consumerRef.watch(
          eventLocationSuggestionsProvider(eventId),
        );

        // Watch guest RSVP list (single source of truth for web guests)
        final guestListAsync = consumerRef.watch(
          guestRsvpListProvider(eventId),
        );
        final guestList = guestListAsync.valueOrNull ?? [];

        return locationSuggestionsAsync.when(
          data: (locationSuggestions) {
            // Calculate dynamic counts from app participants
            final appGoingCount =
                rsvps.where((r) => r.status == RsvpStatus.going).length;
            final appNotGoingCount =
                rsvps.where((r) => r.status == RsvpStatus.notGoing).length;
            final appMaybeCount =
                rsvps.where((r) => r.status == RsvpStatus.maybe).length;

            // Derive web guest counts from the list (single source of truth)
            int webGoing = 0, webNotGoing = 0, webMaybe = 0;
            for (final g in guestList) {
              switch (g['rsvp'] as String?) {
                case 'going': webGoing++; break;
                case 'not_going': webNotGoing++; break;
                case 'maybe': webMaybe++; break;
              }
            }
            final goingCount = appGoingCount + webGoing;
            final notGoingCount = appNotGoingCount + webNotGoing;
            final maybeCount = appMaybeCount + webMaybe;

            return Column(
              children: [
                RsvpVoteButtons(
                  selectedVote: _mapToVoteType(userRsvp),
                  goingCount: goingCount,
                  maybeCount: maybeCount,
                  notGoingCount: notGoingCount,
                  onGoingPressed: () async {
                    final currentStatus =
                        userRsvp?.status ?? RsvpStatus.pending;
                    final newStatus = currentStatus == RsvpStatus.going
                        ? RsvpStatus.pending
                        : RsvpStatus.going;
                    // Host removing "Can" vote: show confirmation
                    if (newStatus == RsvpStatus.pending &&
                        event.hostId == currentUserId) {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (_) => ConfirmationDialog(
                          title: 'Remove Vote',
                          message:
                              'You are the host of this event. Are you sure you want to remove your "Can" vote?',
                          confirmText: 'Confirm',
                          cancelText: 'Cancel',
                          isDestructive: true,
                          onConfirm: () async {
                            await ref
                                .read(userRsvpProvider(eventId).notifier)
                                .submitVote(newStatus);
                          },
                        ),
                      );
                      return;
                    }
                    await ref
                        .read(userRsvpProvider(eventId).notifier)
                        .submitVote(newStatus);
                  },
                  onMaybePressed: () async {
                    final currentStatus =
                        userRsvp?.status ?? RsvpStatus.pending;
                    final newStatus = currentStatus == RsvpStatus.maybe
                        ? RsvpStatus.pending
                        : RsvpStatus.maybe;
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
                  onVoteSummaryTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.manageGuests,
                      arguments: {'eventId': eventId},
                    );
                  },
                  voters: [
                    // App participants
                    ...rsvps
                        .where((r) => r.status != RsvpStatus.pending)
                        .map((r) => RsvpVoterInfo(
                              userId: r.userId,
                              userName: r.userName,
                              userAvatar: r.userAvatar,
                              voteType: _mapStatusToVoteType(r.status),
                            )),
                    // Web guests
                    ...guestList.map((g) => RsvpVoterInfo(
                          userId: g['id'] as String? ?? '',
                          userName: g['guest_name'] as String? ?? 'Guest',
                          userAvatar: null,
                          voteType: _guestRsvpToVoteType(g['rsvp'] as String?),
                        )),
                  ],
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
    // Read cached guest data if available (single source of truth)
    final guestList =
        ref.read(guestRsvpListProvider(eventId)).valueOrNull ?? [];

    final appGoingCount =
        rsvps.where((r) => r.status == RsvpStatus.going).length;
    final appNotGoingCount =
        rsvps.where((r) => r.status == RsvpStatus.notGoing).length;
    final appMaybeCount =
        rsvps.where((r) => r.status == RsvpStatus.maybe).length;

    int webGoing = 0, webNotGoing = 0, webMaybe = 0;
    for (final g in guestList) {
      switch (g['rsvp'] as String?) {
        case 'going': webGoing++; break;
        case 'not_going': webNotGoing++; break;
        case 'maybe': webMaybe++; break;
      }
    }
    final goingCount = appGoingCount + webGoing;
    final notGoingCount = appNotGoingCount + webNotGoing;
    final maybeCount = appMaybeCount + webMaybe;

    return Column(
      children: [
        RsvpVoteButtons(
          selectedVote: _mapToVoteType(userRsvp),
          goingCount: goingCount,
          maybeCount: maybeCount,
          notGoingCount: notGoingCount,
          onGoingPressed: () async {
            final currentStatus = userRsvp?.status ?? RsvpStatus.pending;
            final newStatus = currentStatus == RsvpStatus.going
                ? RsvpStatus.pending
                : RsvpStatus.going;
            // Host removing "Can" vote: show confirmation
            if (newStatus == RsvpStatus.pending &&
                event.hostId == currentUserId) {
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (_) => ConfirmationDialog(
                  title: 'Remove Vote',
                  message:
                      'You are the host of this event. Are you sure you want to remove your "Can" vote?',
                  confirmText: 'Confirm',
                  cancelText: 'Cancel',
                  isDestructive: true,
                  onConfirm: () async {
                    await ref
                        .read(userRsvpProvider(eventId).notifier)
                        .submitVote(newStatus);
                  },
                ),
              );
              return;
            }
            await ref
                .read(userRsvpProvider(eventId).notifier)
                .submitVote(newStatus);
          },
          onMaybePressed: () async {
            final currentStatus = userRsvp?.status ?? RsvpStatus.pending;
            final newStatus = currentStatus == RsvpStatus.maybe
                ? RsvpStatus.pending
                : RsvpStatus.maybe;
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
          onVoteSummaryTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.manageGuests,
              arguments: {'eventId': eventId},
            );
          },
          voters: [
            // App participants
            ...rsvps
                .where((r) => r.status != RsvpStatus.pending)
                .map((r) => RsvpVoterInfo(
                      userId: r.userId,
                      userName: r.userName,
                      userAvatar: r.userAvatar,
                      voteType: _mapStatusToVoteType(r.status),
                    )),
            // Web guests
            ...guestList.map((g) => RsvpVoterInfo(
                  userId: g['id'] as String? ?? '',
                  userName: g['guest_name'] as String? ?? 'Guest',
                  userAvatar: null,
                  voteType: _guestRsvpToVoteType(g['rsvp'] as String?),
                )),
          ],
        ),
        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  /// Helper: Builds RSVP widget in error state
  Widget _buildRsvpErrorState(EventDetail event, String? currentUserId) {
    return Column(
      children: [
        RsvpVoteButtons(
          selectedVote: null,
          goingCount: 0,
          maybeCount: 0,
          notGoingCount: 0,
          onGoingPressed: () {},
          onMaybePressed: () {},
          onNotGoingPressed: () {},
          onVoteSummaryTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.manageGuests,
              arguments: {'eventId': eventId},
            );
          },
        ),
        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  /// Maps domain Rsvp to the new RsvpVoteType for RsvpVoteButtons
  RsvpVoteType? _mapToVoteType(Rsvp? rsvp) {
    if (rsvp == null) return null;
    switch (rsvp.status) {
      case RsvpStatus.going:
        return RsvpVoteType.going;
      case RsvpStatus.maybe:
        return RsvpVoteType.maybe;
      case RsvpStatus.notGoing:
        return RsvpVoteType.notGoing;
      case RsvpStatus.pending:
        return null;
    }
  }

  /// Maps a non-pending RsvpStatus to RsvpVoteType (for voter info).
  RsvpVoteType _mapStatusToVoteType(RsvpStatus status) {
    switch (status) {
      case RsvpStatus.going:
        return RsvpVoteType.going;
      case RsvpStatus.maybe:
        return RsvpVoteType.maybe;
      case RsvpStatus.notGoing:
        return RsvpVoteType.notGoing;
      case RsvpStatus.pending:
        return RsvpVoteType.going; // fallback, should not happen
    }
  }

  /// Maps web guest RSVP string ('going'/'not_going'/'maybe') to RsvpVoteType.
  RsvpVoteType _guestRsvpToVoteType(String? rsvp) {
    switch (rsvp) {
      case 'going':
        return RsvpVoteType.going;
      case 'not_going':
        return RsvpVoteType.notGoing;
      case 'maybe':
        return RsvpVoteType.maybe;
      default:
        return RsvpVoteType.going;
    }
  }

  // ===== DATA PROCESSING METHODS =====
  // Pure functions that transform raw data into UI-ready models
  // No refs, no side effects, easily testable

  /// Process date/time suggestions with votes and filters
  /// Returns data ready for UI consumption
  DateTimeSuggestionsData _processDateTimeSuggestions({
    required List<Suggestion> suggestions,
    required List<SuggestionVote> allVotes,
    required Set<String> userVoteIds,
    required EventDetail event,
    required int goingCount,
    required String? currentUserId,
  }) {
    // Filter suggestions that are DIFFERENT from current event date
    final alternateSuggestions = suggestions.where((s) {
      if (event.startDateTime == null || event.endDateTime == null) {
        return true;
      }
      final isDifferent =
          !s.startDateTime.isAtSameMomentAs(event.startDateTime!) ||
              !(s.endDateTime?.isAtSameMomentAs(event.endDateTime!) ?? false);
      return isDifferent;
    }).toList();

    final List<DateTimeSuggestion> dateTimeSuggestions = [];

    // Only add current event date if NOT expired
    // Expired dates should not be shown as a valid "current" option
    DateTimeSuggestion? currentEventOption;
    if (event.startDateTime != null &&
        event.endDateTime != null &&
        !event.isExpired) {
      currentEventOption = DateTimeSuggestion(
        id: 'current_event_date',
        startDateTime: event.startDateTime!,
        endDateTime: event.endDateTime!,
        voteCount: goingCount, // Show number of 'Can' votes from RSVP
        hasUserVoted: false,
        votes: [],
      );
      dateTimeSuggestions.add(currentEventOption);
    } else if (event.isExpired) {}

    // Add all ALTERNATIVE suggestions (different from current date)
    dateTimeSuggestions.addAll(alternateSuggestions.map((suggestion) {
      final suggestionVotes = allVotes
          .where((vote) => vote.suggestionId == suggestion.id)
          .map((vote) => datetime_widget.SuggestionVote(
                id: vote.id,
                userId: vote.userId,
                userName: _getUserDisplayName(
                    vote.userId, vote.userName, currentUserId),
                userAvatar: vote.userAvatar,
                votedAt: vote.createdAt,
              ))
          .toList();

      return DateTimeSuggestion(
        id: suggestion.id,
        startDateTime: suggestion.startDateTime,
        endDateTime: suggestion.endDateTime,
        voteCount: suggestionVotes.length,
        hasUserVoted: userVoteIds.contains(suggestion.id),
        votes: suggestionVotes,
      );
    }));

    return DateTimeSuggestionsData(
      suggestions: dateTimeSuggestions,
      hasAlternatives: alternateSuggestions.isNotEmpty,
      currentEventOption: currentEventOption,
    );
  }

  /// Process location suggestions with votes and filters
  /// Returns data ready for UI consumption
  /// Current location always appears first, followed by alternative suggestions
  LocationSuggestionsData _processLocationSuggestions({
    required List<LocationSuggestion> suggestions,
    required List<SuggestionVote> allVotes,
    required EventDetail event,
    required int goingCount,
  }) {
    // Separate current location from alternatives
    final currentLocationSuggestions = <LocationSuggestion>[];
    final alternateLocationSuggestions = <LocationSuggestion>[];

    // Track if we found the current location in the DB suggestions
    bool foundCurrentLocationInDB = false;

    for (final suggestion in suggestions) {
      if (event.location == null) {
        alternateLocationSuggestions.add(suggestion);
        continue;
      }

      // Detailed comparison
      final nameMatches =
          suggestion.locationName == event.location!.displayName;
      final suggestionAddr = suggestion.address ?? '';
      final eventAddr = event.location!.formattedAddress;
      final addressMatches = suggestionAddr == eventAddr;

      final isCurrentLocation = nameMatches && addressMatches;

      if (isCurrentLocation) {
        currentLocationSuggestions.add(suggestion);
        foundCurrentLocationInDB = true;
      } else {
        alternateLocationSuggestions.add(suggestion);
      }
    }

    // CRITICAL: If event has a location but we didn't find it in DB suggestions,
    // create a synthetic suggestion for it (happens after "Set Location" deletes all suggestions)
    if (event.location != null &&
        !foundCurrentLocationInDB &&
        alternateLocationSuggestions.isNotEmpty) {
      final syntheticCurrentLocation = LocationSuggestion(
        id: 'synthetic_current_location',
        eventId: event.id,
        userId: event.hostId,
        locationName: event.location!.displayName,
        address: event.location!.formattedAddress.isEmpty
            ? null
            : event.location!.formattedAddress,
        latitude: event.location!.latitude,
        longitude: event.location!.longitude,
        createdAt: event.createdAt,
        userName: '', // Not needed for display
        userAvatar: null, // Not needed for display
      );
      currentLocationSuggestions.add(syntheticCurrentLocation);
    }

    // Sort: current location first (with star at top), then alternatives
    // Note: Supabase returns suggestions in DESC order (newest first)
    // We want: current location at top, then alternatives with oldest at top (newest at bottom)
    // So we need to reverse the alternatives list from DB
    final sortedAlternatives = alternateLocationSuggestions.reversed.toList();

    final sortedSuggestions = [
      ...currentLocationSuggestions, // Current location with star at THE TOP
      ...sortedAlternatives // Alternative suggestions (oldest first, newest last)
    ];

    final hasAlternatives = event.location != null
        ? alternateLocationSuggestions.isNotEmpty
        : suggestions.isNotEmpty;

    return LocationSuggestionsData(
      suggestions: sortedSuggestions,
      allVotes: allVotes,
      hasAlternatives: hasAlternatives,
      currentEventGoingCount: goingCount,
    );
  }
}

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
import '../../../../shared/components/dialogs/missing_fields_confirmation_dialog.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart' as rsvp_widget;
import '../../../../shared/components/widgets/help_plan_event_widget.dart';
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/components/widgets/date_time_widget.dart';
import '../../../../shared/components/widgets/poll_widget.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../services/calendar_service.dart';
import '../../domain/entities/rsvp.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/entities/event_detail.dart';
import '../providers/event_providers.dart';
import '../widgets/event_expenses_widget.dart';
import '../widgets/date_time_suggestions_widget.dart'
    show DateTimeSuggestionsWidget, DateTimeSuggestion;
import '../widgets/date_time_suggestions_widget.dart' as datetime_widget;
import '../widgets/location_suggestions_widget.dart';
import '../widgets/add_suggestion_bottom_sheet.dart';
import 'event_page_models.dart';

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
      // Check if we need to show expiration warning
      _checkAndShowExpirationWarning();
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

  /// Show add expense bottom sheet
  Future<void> _showAddExpenseBottomSheet(BuildContext context) async {
    // Get event participants
    final participantsAsync =
        await ref.read(eventParticipantsProvider(eventId).future);

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Helper function to display "You" for current user
    String getUserDisplayName(String userId, String userName) {
      return userId == currentUserId ? 'You' : userName;
    }

    final participants = participantsAsync
        .map((p) => ExpenseParticipantOption(
              id: p.userId,
              name: getUserDisplayName(p.userId, p.displayName),
              avatarUrl: p.avatarUrl,
            ))
        .toList();

    if (!context.mounted) return;

    // ✅ Check if there are participants before opening bottom sheet
    if (participants.isEmpty) {
      TopBanner.showInfo(
        context,
        message: 'No participants to split expenses with yet',
      );
      return;
    }

    AddExpenseBottomSheet.show(
      context: context,
      participants: participants,
      onAddExpense: (title, paidBy, participantsOwe, amount) async {
        // Create expense using expense provider
        try {
          await ref.read(eventExpensesProvider(eventId).notifier).addExpense(
            description: title,
            amount: amount,
            paidBy: paidBy,
            participantsOwe: participantsOwe,
            participantsPaid: [paidBy],
          );

          if (context.mounted) {
            TopBanner.showSuccess(context,
                message: 'Expense added successfully');
          }
        } catch (e) {
          if (context.mounted) {
            TopBanner.showError(context, message: 'Failed to add expense: $e');
          }
        }
      },
    );
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
    // Note: rsvpsAsync, userRsvpAsync watched inside _buildRsvpSection()
    // Note: suggestionsAsync, suggestionVotesAsync, userSuggestionVotesAsync now in dateTimeSuggestionsDataProvider
    // Note: locationSuggestionsAsync, locationVotesAsync, userLocationVotesAsync now in locationSuggestionsDataProvider
    // Note: messagesAsync, unreadCountAsync now in chatPreviewDataProvider
    final pollsAsync = ref.watch(eventPollsProvider(eventId));
    final participantsAsync = ref.watch(eventParticipantsProvider(eventId));

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
    final eventStatus = eventAsync.value?.status;
    final showAddExpense = eventStatus == EventStatus.pending ||
        eventStatus == EventStatus.confirmed ||
        eventStatus == EventStatus.living;

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
                          groupId: eventData.groupId,
                          startDateTime: eventData.startDateTime,
                          endDateTime: eventData.endDateTime,
                          location: eventData.location != null
                              ? create_event.EventLocation(
                                  id: 'temp-id', // Will be created/updated in repository
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
                          groupId: eventData.groupId,
                          startDateTime: eventData.startDateTime,
                          endDateTime: eventData.endDateTime,
                          location: eventData.location != null
                              ? create_event.EventLocation(
                                  id: 'temp-id', // Will be created/updated in repository
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
        trailing2: showAddExpense
            ? IconButton(
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  color: BrandColors.text1,
                ),
                onPressed: () => _showAddExpenseBottomSheet(context),
              )
            : null,
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
                  groupId: event.groupId,
                  isExpired: event.isExpired,
                  onGroupTap: () {
                    // LAZZO 2.0: Group hub navigation removed — events are standalone
                  },
                ),
                const SizedBox(height: Gaps.md),

                // Event status chip - always visible
                _buildEventStatusSection(event),

                // RSVP Widget
                _buildRsvpSection(event, currentUserId),

                // Date & Time Suggestions Widget (OPTIMIZED)
                // Combined provider reduces nesting from 4 levels to 1
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
                                  toggleSuggestionVoteNotifierProvider.notifier,
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
                                  ? TimeOfDay.fromDateTime(event.startDateTime!)
                                  : const TimeOfDay(hour: 0, minute: 0),
                              eventEndDate: event.endDateTime ?? DateTime.now(),
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
                // Combined provider reduces nesting from 3 levels to 1
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
                    final locationSuggestions =
                        data['locationSuggestions'] as List<LocationSuggestion>;

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
                        allVotes: data['locationVotes'] as List<SuggestionVote>,
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

                // Expenses widget
                // Use whenOrNull to keep previous expenses visible during refresh
                participantsAsync.whenOrNull(
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

                        // Determine if expenses widget should be shrinked based on expenses count
                        final expensesAsync =
                            ref.watch(eventExpensesProvider(eventId));
                        final isExpensesShrinked = expensesAsync.maybeWhen(
                          data: (expenses) => expenses.isEmpty,
                          orElse: () => false,
                        );

                        return Padding(
                          padding: EdgeInsets.only(
                            top: isExpensesShrinked ? 0 : Gaps.lg,
                          ),
                          child: EventExpensesWidget(
                            eventId: eventId,
                            mode: EventMode.planning,
                            participants: participantOptions,
                            onAddExpense: (title, paidById, participantsOwe,
                                amount) async {
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
                          ),
                        );
                      },
                    ) ??
                    const SizedBox.shrink(),

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

  /// Builds the RSVP section with voting functionality
  /// This is one of the most complex sections with nested AsyncValues
  /// When event is not fully defined/suggested, shows HelpPlanSection instead
  Widget _buildRsvpSection(EventDetail event, String? currentUserId) {
    // Watch suggestions to determine visibility
    final suggestionsAsync = ref.watch(eventSuggestionsProvider(eventId));
    final locationSuggestionsAsync =
        ref.watch(eventLocationSuggestionsProvider(eventId));

    // If event is expired, never show RSVP
    if (event.isExpired) {
      final dateSuggestions = suggestionsAsync.value ?? [];

      // Filter out suggestions that are the SAME as the expired event date
      // Only consider suggestions that are DIFFERENT (alternatives)
      final alternateSuggestions = dateSuggestions.where((s) {
        if (event.startDateTime == null || event.endDateTime == null) {
          return true;
        }
        final isDifferent =
            !s.startDateTime.isAtSameMomentAs(event.startDateTime!) ||
                !(s.endDateTime?.isAtSameMomentAs(event.endDateTime!) ?? false);
        return isDifferent;
      }).toList();

      // If there are ALTERNATIVE date suggestions, hide this section (let suggestions widget show)
      if (alternateSuggestions.isNotEmpty) {
        return const SizedBox.shrink();
      }

      // No alternative suggestions - show expired widget
      return Column(
        children: [
          HelpPlanEventWidget(
            hasLocation: event.hasDefinedLocation,
            hasDate: false, // Force date as missing since it's expired
            hasSuggestedLocation: false,
            hasSuggestedDate: false,
            onAddSuggestion: () {
              showAddSuggestionBottomSheet(
                context,
                eventId: eventId,
                eventStartDate: event.startDateTime ?? DateTime.now(),
                eventStartTime: event.startDateTime != null
                    ? TimeOfDay.fromDateTime(event.startDateTime!)
                    : TimeOfDay.now(),
                eventEndDate: event.endDateTime ?? DateTime.now(),
                eventEndTime: event.endDateTime != null
                    ? TimeOfDay.fromDateTime(event.endDateTime!)
                    : TimeOfDay.now(),
              );
            },
            customTitle: 'Event date has expired',
          ),
          const SizedBox(height: Gaps.lg),
        ],
      );
    }

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
                  currentUserId: currentUserId,
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
          currentUserId: currentUserId,
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
          currentUserId: currentUserId,
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

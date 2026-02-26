import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/app_config.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/invite_bottom_sheet.dart';
import '../../../../shared/components/inputs/search_bar.dart' as custom;
import '../../../../shared/components/sections/section_block.dart';
import '../../../../shared/components/cards/home_event_card.dart';
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../shared/components/cards/event_full_card.dart';
// import '../../../../shared/components/cards/todo_card.dart'; // MVP: Actions removed, preserved for P2
// LAZZO 2.0: payment_summary_card import removed
import '../../../../shared/components/cards/recent_memory_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/layouts/main_layout_providers.dart';
// LAZZO 2.0: groups_provider import removed
// LAZZO 2.0: payments_provider import removed
import '../../../event/domain/entities/event_display_entity.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../../../event/domain/entities/rsvp.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';
// LAZZO 2.0: no_groups_yet_card import removed
import '../widgets/no_upcoming_events_card.dart';
import '../../../../shared/components/inputs/photo_selector.dart';
import '../providers/home_event_providers.dart';
import '../../../../routes/app_router.dart';
import '../../../event_invites/presentation/providers/event_invite_providers.dart';
import '../../../memory/data/fakes/fake_memory_repository.dart';
import '../../domain/entities/home_event.dart';
import '../../../../shared/providers/realtime_refresh_provider.dart';
import '../../../../shared/components/skeletons/home_event_card_skeleton.dart';
import '../../../../shared/components/skeletons/event_small_card_skeleton.dart';
import '../../../../shared/components/skeletons/memory_card_skeleton.dart';
import '../../../../shared/components/widgets/error_retry_widget.dart';

/// Home page - main screen showing next event, confirmed/pending events, and memories
///
/// LAZZO 2.0: Groups removed. Events are standalone.
/// This page purely consumes provider data - no mock logic here (Clean Architecture).

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isNoEventsCardDismissed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Removed blanket invalidation — was causing 6 parallel refetches on
    //    every navigation return, even when nothing changed.
    //    Now Supabase Realtime handles live updates automatically, and
    //    pull-to-refresh (RefreshIndicator) is available for manual refresh.
  }

  /// Refresh all home data providers (used by pull-to-refresh only)
  void _refreshData() {
    ref.invalidate(nextEventControllerProvider);
    ref.invalidate(confirmedEventsControllerProvider);
    ref.invalidate(homeEventsControllerProvider);
    ref.invalidate(livingAndRecapEventsControllerProvider);
    ref.invalidate(todosControllerProvider);
    ref.invalidate(recentMemoriesControllerProvider);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'Date and Location to be decided';

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

    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];

    return '$weekday, $day $month';
  }

  HomeEventCardState _mapStatusToHomeCardState(HomeEventStatus status) {
    switch (status) {
      case HomeEventStatus.pending:
        return HomeEventCardState.pending;
      case HomeEventStatus.confirmed:
        return HomeEventCardState.confirmed;
      case HomeEventStatus.living:
        return HomeEventCardState.living;
      case HomeEventStatus.recap:
        return HomeEventCardState.recap;
    }
  }

  EventSmallCardState _mapStatusToSmallCardState(HomeEventStatus status) {
    switch (status) {
      case HomeEventStatus.pending:
        return EventSmallCardState.pending;
      case HomeEventStatus.confirmed:
        return EventSmallCardState.confirmed;
      default:
        return EventSmallCardState.confirmed;
    }
  }

  EventDisplayEntity _convertHomeEventToDisplayEvent(HomeEventEntity event) {
    return EventDisplayEntity(
      id: event.id,
      name: event.name,
      emoji: event.emoji,
      date: event.date,
      endDate: event.endDate,
      location: event.location,
      status: _mapHomeStatusToDisplayStatus(event.status),
      goingCount: event.goingCount,
      participantCount: event.attendeeNames.length,
      attendeeAvatars: event.attendeeAvatars,
      attendeeNames: event.attendeeNames,
      userVote: event.userVote,
      allVotes: event.allVotes,
      photoCount: event.photoCount,
      maxPhotos: event.maxPhotos,
      participantPhotos: event.participantPhotos,
    );
  }

  EventDisplayStatus _mapHomeStatusToDisplayStatus(HomeEventStatus status) {
    switch (status) {
      case HomeEventStatus.pending:
        return EventDisplayStatus.pending;
      case HomeEventStatus.confirmed:
        return EventDisplayStatus.confirmed;
      case HomeEventStatus.living:
        return EventDisplayStatus.living;
      case HomeEventStatus.recap:
        return EventDisplayStatus.recap;
    }
  }

  /// Handle vote changes from bottom sheets - persists to Supabase and refreshes UI
  Future<void> _handleVoteChanged(String eventId, RsvpVoteStatus vote) async {
    try {
      final rsvpRepo = ref.read(rsvpRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) return;

      // Convert RsvpVoteStatus to RsvpStatus
      final RsvpStatus status;
      switch (vote) {
        case RsvpVoteStatus.going:
          status = RsvpStatus.going;
          break;
        case RsvpVoteStatus.maybe:
          status = RsvpStatus.maybe;
          break;
        case RsvpVoteStatus.notGoing:
          status = RsvpStatus.notGoing;
          break;
        case RsvpVoteStatus.pending:
          status = RsvpStatus.pending;
          break;
      }

      await rsvpRepo.submitRsvp(eventId, userId, status);

      // Refresh home providers to update UI
      ref.invalidate(nextEventControllerProvider);
      ref.invalidate(confirmedEventsControllerProvider);
      ref.invalidate(homeEventsControllerProvider);
      ref.invalidate(livingAndRecapEventsControllerProvider);

      // Also invalidate event-specific providers for consistency
      ref.invalidate(eventRsvpsProvider(eventId));
      ref.invalidate(userRsvpProvider(eventId));
    } catch (e) {
      // Failed to persist vote - UI will update on next load
    }
  }

  /// Navigate to manage guests page
  void _handleGuestsTap(String eventId) {
    Navigator.pushNamed(
      context,
      AppRouter.manageGuests,
      arguments: {'eventId': eventId},
    );
  }

  /// Share event invite
  Future<void> _handleInviteTap(String eventId, String eventName, String eventEmoji) async {
    try {
      final useCase = ref.read(createEventInviteLinkProvider);
      final entity = await useCase(
        eventId: eventId,
        shareChannel: 'home_card',
      );
      final inviteUrl = '${AppConfig.invitesBaseUrl}/i/${entity.token}';
      if (mounted) {
        InviteBottomSheet.show(
          context: context,
          inviteUrl: inviteUrl,
          entityName: eventName,
          entityType: 'event',
          eventEmoji: eventEmoji,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create invite link')),
        );
      }
    }
  }

  /// Navigate to photo picker/camera for adding photo
  void _handleAddPhotoTap(String eventId) {
    PhotoSelectionBottomSheet.show(
      context: context,
      title: 'Add Photo',
      showRemoveOption: false,
      onAction: (action) async {
        final picker = ImagePicker();
        if (action == PhotoSourceAction.camera) {
          final photo = await picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (photo != null && mounted) {
            // Navigate to event living page with photo for upload
            Navigator.pushNamed(
              context,
              AppRouter.eventLiving,
              arguments: {'eventId': eventId},
            );
          }
        } else if (action == PhotoSourceAction.gallery) {
          final photo = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (photo != null && mounted) {
            // Navigate to event living page with photo for upload
            Navigator.pushNamed(
              context,
              AppRouter.eventLiving,
              arguments: {'eventId': eventId},
            );
          }
        }
      },
    );
  }

  /// Navigate to manage memory page
  void _handleManagePhotosTap(String eventId) {
    Navigator.pushNamed(
      context,
      AppRouter.manageMemory,
      arguments: {'memoryId': eventId},
    );
  }

  /// Check if user can manage photos (has uploaded photos)
  /// Note: Host check requires hostId field in HomeEventEntity (not yet available)
  bool _canManagePhotos(HomeEventEntity event) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    // User has uploaded photos
    return event.participantPhotos.any(
      (p) => p.userId == userId && p.photoCount > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Activate Supabase Realtime watcher — auto-refreshes home when
    // web guests vote or events change (no manual polling needed).
    ref.watch(realtimeRefreshProvider);

    // Listen for scroll-to-top trigger (when tapping active NavBar tab)
    ref.listen<int>(scrollToTopProvider, (previous, next) {
      if (previous != next && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        // Also refresh data when scrolling to top
        _refreshData();
      }
    });

    final nextEventAsync = ref.watch(nextEventControllerProvider);
    final confirmedEventsAsync = ref.watch(confirmedEventsControllerProvider);
    final pendingEventsAsync = ref.watch(homeEventsControllerProvider);
    final livingAndRecapEventsAsync =
        ref.watch(livingAndRecapEventsControllerProvider);
    // final todosAsync = ref.watch(todosControllerProvider); // MVP: Actions removed, preserved for P2
    // LAZZO 2.0: paymentsAsync + totalBalanceAsync removed
    final recentMemoriesAsync = ref.watch(recentMemoriesControllerProvider);
    // LAZZO 2.0: groupsAsync removed â€” events are standalone
    final nextEventStatus = ref.watch(navBarStateProvider);

    // Debug prints to check data received
    nextEventAsync.whenData((event) {});
    confirmedEventsAsync.whenData((events) {});
    pendingEventsAsync.whenData((events) {});
    livingAndRecapEventsAsync.whenData((events) {});

    // Calculate empty states based on provider data
    // LAZZO 2.0: Groups empty state removed â€” only check events

    // Check if events data is loaded
    final eventsLoaded = nextEventAsync.hasValue &&
        confirmedEventsAsync.hasValue &&
        pendingEventsAsync.hasValue;
    final hasEvents = (nextEventAsync.asData?.value != null ||
        (confirmedEventsAsync.asData?.value.isNotEmpty ?? false) ||
        (pendingEventsAsync.asData?.value.isNotEmpty ?? false));

    // Show "No upcoming events" if no events and data is loaded
    final showNoEventsCard =
        eventsLoaded && !hasEvents && !_isNoEventsCardDismissed;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'LAZZO',
        centerTitle: true,
        trailing: (nextEventStatus == HomeEventStatus.living ||
                nextEventStatus == HomeEventStatus.recap)
            ? GestureDetector(
                onTap: () async {
                  await Navigator.pushNamed(context, AppRouter.createEvent);
                  // Refresh after creating an event
                  _refreshData();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: BrandColors.text1,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: BrandColors.text1,
                      size: 20,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Invalidate all providers to trigger refetch
            _refreshData();
            // Wait for providers to refetch
            await Future.wait([
              ref.read(nextEventControllerProvider.future),
              ref.read(confirmedEventsControllerProvider.future),
              ref.read(homeEventsControllerProvider.future),
              ref.read(livingAndRecapEventsControllerProvider.future),
              ref.read(todosControllerProvider.future),
              ref.read(recentMemoriesControllerProvider.future),
              // LAZZO 2.0: paymentSummariesControllerProvider removed
            ]);
          },
          color: BrandColors.planning,
          backgroundColor: BrandColors.bg2,
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: Gaps.xs),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
                child: custom.SearchBar(
                  placeholder: 'Search events, memories...',
                  enabled: false,
                  onTap: () {
                    Navigator.pushNamed(context, AppRouter.homeSearch);
                  },
                ),
              ),
              const SizedBox(height: Gaps.md),

              // Empty State - "No upcoming events" (LAZZO 2.0: NoGroupsYetCard removed)
              if (showNoEventsCard)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Insets.screenH),
                  child: Column(
                    children: [
                      NoUpcomingEventsCard(
                        onCreateEvent: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRouter.createEvent,
                          );
                          _refreshData();
                        },
                        onDismiss: () {
                          setState(() {
                            _isNoEventsCardDismissed = true;
                          });
                        },
                      ),
                      const SizedBox(height: Gaps.lg),
                    ],
                  ),
                ),

              // EVENT SECTIONS - Only show if NOT in empty state
              if (!showNoEventsCard) ...[
                // Living and Recap Events Sections
                livingAndRecapEventsAsync.when(
                  data: (allLivingAndRecapEvents) {
                    if (allLivingAndRecapEvents.isEmpty) {
                      // No living/recap events, show Next Event section
                      return nextEventAsync.when(
                        data: (event) {
                          if (event == null) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              SectionBlock(
                                title: 'Next Event',
                                child: HomeEventCard(
                                  event: event,
                                  state:
                                      _mapStatusToHomeCardState(event.status),
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRouter.event,
                                      arguments: {'eventId': event.id},
                                    );
                                  },
                                  onVoteChanged: _handleVoteChanged,
                                  onGuestsTap: () => _handleGuestsTap(event.id),
                                  onInviteTap: () => _handleInviteTap(event.id, event.name, event.emoji),
                                  onAddPhotoTap: () =>
                                      _handleAddPhotoTap(event.id),
                                  onManagePhotosTap: () =>
                                      _handleManagePhotosTap(event.id),
                                  canManagePhotos: _canManagePhotos(event),
                                ),
                              ),
                              const SizedBox(height: Gaps.lg),
                            ],
                          );
                        },
                        loading: () => const SectionBlock(
                          title: 'Next Event',
                          child: HomeEventCardSkeleton(),
                        ),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      );
                    }

                    // Separate living and recap events
                    final livingEvents = allLivingAndRecapEvents
                        .where((e) => e.status == HomeEventStatus.living)
                        .toList();
                    final recapEvents = allLivingAndRecapEvents
                        .where((e) => e.status == HomeEventStatus.recap)
                        .toList();

                    return Column(
                      children: [
                        // Live Events section
                        if (livingEvents.isNotEmpty) ...[
                          Column(
                            children: [
                              SectionBlock(
                                title: livingEvents.length == 1
                                    ? 'Live Event'
                                    : 'Live Events',
                                child: Column(
                                  children: [
                                    // Hero card for first living event
                                    HomeEventCard(
                                      event: livingEvents.first,
                                      state: HomeEventCardState.living,
                                      onTap: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          AppRouter.eventLiving,
                                          arguments: {
                                            'eventId': livingEvents.first.id
                                          },
                                        );
                                      },
                                      onVoteChanged: _handleVoteChanged,
                                      onGuestsTap: () => _handleGuestsTap(
                                          livingEvents.first.id),
                                      onInviteTap: () => _handleInviteTap(
                                          livingEvents.first.id,
                                          livingEvents.first.name,
                                          livingEvents.first.emoji),
                                      onAddPhotoTap: () => _handleAddPhotoTap(
                                          livingEvents.first.id),
                                      onManagePhotosTap: () =>
                                          _handleManagePhotosTap(
                                              livingEvents.first.id),
                                      canManagePhotos:
                                          _canManagePhotos(livingEvents.first),
                                    ),

                                    // Additional living events as EventFullCard
                                    if (livingEvents.length > 1) ...[
                                      const SizedBox(height: Gaps.sm),
                                      ...livingEvents
                                          .skip(1)
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final event = entry.value;
                                        return Column(
                                          children: [
                                            EventFullCard(
                                              event:
                                                  _convertHomeEventToDisplayEvent(
                                                      event),
                                              state: EventFullCardState.living,
                                              onTap: () async {
                                                await Navigator.pushNamed(
                                                  context,
                                                  AppRouter.eventLiving,
                                                  arguments: {
                                                    'eventId': event.id
                                                  },
                                                );
                                              },
                                              onVoteChanged: _handleVoteChanged,
                                            ),
                                            if (index < livingEvents.length - 2)
                                              const SizedBox(height: Gaps.sm),
                                          ],
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: Gaps.lg),
                            ],
                          ),
                        ],

                        // Recaps section
                        if (recapEvents.isNotEmpty) ...[
                          Column(
                            children: [
                              SectionBlock(
                                title: recapEvents.length == 1 &&
                                        livingEvents.isEmpty
                                    ? 'Recap'
                                    : 'Recaps',
                                child: Column(
                                  children: [
                                    // Hero card for first recap event (only if no living events)
                                    if (livingEvents.isEmpty)
                                      HomeEventCard(
                                        event: recapEvents.first,
                                        state: HomeEventCardState.recap,
                                        onTap: () async {
                                          await Navigator.pushNamed(
                                            context,
                                            AppRouter.eventRecap,
                                            arguments: {
                                              'eventId': recapEvents.first.id
                                            },
                                          );
                                        },
                                        onVoteChanged: _handleVoteChanged,
                                        onGuestsTap: () => _handleGuestsTap(
                                            recapEvents.first.id),
                                        onInviteTap: () => _handleInviteTap(
                                            recapEvents.first.id,
                                            recapEvents.first.name,
                                            recapEvents.first.emoji),
                                        onAddPhotoTap: () => _handleAddPhotoTap(
                                            recapEvents.first.id),
                                        onManagePhotosTap: () =>
                                            _handleManagePhotosTap(
                                                recapEvents.first.id),
                                        canManagePhotos:
                                            _canManagePhotos(recapEvents.first),
                                      ),

                                    // Additional recap events as EventFullCard
                                    // If living exists, all recap events use EventFullCard
                                    // If no living, skip first recap (already shown as hero)
                                    if (livingEvents.isNotEmpty) ...[
                                      ...recapEvents
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final event = entry.value;
                                        return Column(
                                          children: [
                                            EventFullCard(
                                              event:
                                                  _convertHomeEventToDisplayEvent(
                                                      event),
                                              state: EventFullCardState.recap,
                                              onTap: () async {
                                                await Navigator.pushNamed(
                                                  context,
                                                  AppRouter.eventRecap,
                                                  arguments: {
                                                    'eventId': event.id
                                                  },
                                                );
                                              },
                                              onVoteChanged: _handleVoteChanged,
                                            ),
                                            if (index < recapEvents.length - 1)
                                              const SizedBox(height: Gaps.sm),
                                          ],
                                        );
                                      }),
                                    ] else if (recapEvents.length > 1) ...[
                                      const SizedBox(height: Gaps.sm),
                                      ...recapEvents
                                          .skip(1)
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final event = entry.value;
                                        return Column(
                                          children: [
                                            EventFullCard(
                                              event:
                                                  _convertHomeEventToDisplayEvent(
                                                      event),
                                              state: EventFullCardState.recap,
                                              onTap: () async {
                                                await Navigator.pushNamed(
                                                  context,
                                                  AppRouter.eventRecap,
                                                  arguments: {
                                                    'eventId': event.id
                                                  },
                                                );
                                              },
                                              onVoteChanged: _handleVoteChanged,
                                            ),
                                            if (index < recapEvents.length - 2)
                                              const SizedBox(height: Gaps.sm),
                                          ],
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: Gaps.lg),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const SectionBlock(
                    title: 'Live Events',
                    child: HomeEventCardSkeleton(),
                  ),
                  error: (error, stackTrace) {
                    // If error, fall back to showing Next Event
                    return nextEventAsync.when(
                      data: (event) {
                        if (event == null) {
                          return const SizedBox.shrink();
                        }

                        String sectionTitle;
                        switch (event.status) {
                          case HomeEventStatus.living:
                            sectionTitle = 'Live Event';
                            break;
                          case HomeEventStatus.recap:
                            sectionTitle = 'Recap Event';
                            break;
                          case HomeEventStatus.pending:
                          case HomeEventStatus.confirmed:
                            sectionTitle = 'Next Event';
                            break;
                        }

                        return Column(
                          children: [
                            SectionBlock(
                              title: sectionTitle,
                              child: HomeEventCard(
                                event: event,
                                state: _mapStatusToHomeCardState(event.status),
                                onTap: () async {
                                  // Navigate based on event status
                                  if (event.status == HomeEventStatus.living) {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRouter.eventLiving,
                                      arguments: {'eventId': event.id},
                                    );
                                  } else if (event.status ==
                                      HomeEventStatus.recap) {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRouter.memory,
                                      arguments: {'memoryId': event.id},
                                    );
                                  } else {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRouter.event,
                                      arguments: {'eventId': event.id},
                                    );
                                  }
                                },
                                onVoteChanged: _handleVoteChanged,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SectionBlock(
                        title: 'Next Event',
                        child: HomeEventCardSkeleton(),
                      ),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    );
                  },
                ),

                // Confirmed Events Section
                confirmedEventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    // Limit to 10 events for home display
                    final displayEvents = events.take(10).toList();
                    final hasMore = events.length > 10;

                    return Column(
                      children: [
                        SectionBlock(
                          title: 'Confirmed Events',
                          // Show "See All" button when there are more than 10 events
                          trailing: hasMore
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.confirmedEventsList,
                                    );
                                  },
                                  child: Text(
                                    'See All',
                                    style: AppText.labelLarge.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                              : null,
                          child: Column(
                            children:
                                displayEvents.asMap().entries.map((entry) {
                              final index = entry.key;
                              final event = entry.value;
                              final isExpired = event.date != null &&
                                  event.date!.isBefore(DateTime.now());
                              return Column(
                                children: [
                                  EventSmallCard(
                                    emoji: event.emoji,
                                    title: event.name,
                                    dateTime: _formatEventDate(event.date),
                                    location: event.date == null
                                        ? null // Don't show location when date is TBD
                                        : (event.location ??
                                            'Location to be decided'),
                                    state: _mapStatusToSmallCardState(
                                        event.status),
                                    isExpired: isExpired,
                                    onTap: () async {
                                      // âœ… Navigate based on actual calculated status
                                      if (event.status ==
                                          HomeEventStatus.living) {
                                        await Navigator.pushNamed(
                                          context,
                                          AppRouter.eventLiving,
                                          arguments: {'eventId': event.id},
                                        );
                                      } else if (event.status ==
                                          HomeEventStatus.recap) {
                                        await Navigator.pushNamed(
                                          context,
                                          AppRouter.memory,
                                          arguments: {'memoryId': event.id},
                                        );
                                      } else {
                                        // pending or confirmed -> event planning page
                                        await Navigator.pushNamed(
                                          context,
                                          AppRouter.event,
                                          arguments: {'eventId': event.id},
                                        );
                                      }
                                    },
                                  ),
                                  if (index < displayEvents.length - 1)
                                    const SizedBox(height: Gaps.sm),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: Gaps.lg),
                      ],
                    );
                  },
                  loading: () => const SectionBlock(
                    title: 'Confirmed Events',
                    child: EventSmallCardSkeletonList(count: 3),
                  ),
                  error: (error, stackTrace) => ErrorRetryWidget(
                    message: 'Could not load confirmed events',
                    onRetry: () => ref.invalidate(confirmedEventsControllerProvider),
                  ),
                ),

                // Pending Events Section
                pendingEventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    // Limit to 10 events for home display
                    final displayEvents = events.take(10).toList();
                    final hasMore = events.length > 10;

                    return Column(
                      children: [
                        SectionBlock(
                          title: 'Pending Events',
                          // Show "See All" button when there are more than 10 events
                          trailing: hasMore
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.pendingEventsList,
                                    );
                                  },
                                  child: Text(
                                    'See All',
                                    style: AppText.labelLarge.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                              : null,
                          child: Column(
                            children:
                                displayEvents.asMap().entries.map((entry) {
                              final index = entry.key;
                              final event = entry.value;
                              final isExpired = event.date != null &&
                                  event.date!.isBefore(DateTime.now());
                              return Column(
                                children: [
                                  EventSmallCard(
                                    emoji: event.emoji,
                                    title: event.name,
                                    dateTime: _formatEventDate(event.date),
                                    location: event.date == null
                                        ? null // Don't show location when date is TBD
                                        : (event.location ??
                                            'Location to be decided'),
                                    state: _mapStatusToSmallCardState(
                                        event.status),
                                    isExpired: isExpired,
                                    onTap: () async {
                                      // âœ… Navigate based on actual calculated status
                                      if (event.status ==
                                          HomeEventStatus.living) {
                                        await Navigator.pushNamed(
                                          context,
                                          AppRouter.eventLiving,
                                          arguments: {'eventId': event.id},
                                        );
                                      } else if (event.status ==
                                          HomeEventStatus.recap) {
                                        await Navigator.pushNamed(
                                          context,
                                          AppRouter.memory,
                                          arguments: {'memoryId': event.id},
                                        );
                                      } else {
                                        // pending or confirmed -> event planning page
                                        await Navigator.pushNamed(
                                          context,
                                          AppRouter.event,
                                          arguments: {'eventId': event.id},
                                        );
                                      }
                                    },
                                  ),
                                  if (index < displayEvents.length - 1)
                                    const SizedBox(height: Gaps.sm),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: Gaps.lg),
                      ],
                    );
                  },
                  loading: () => const SectionBlock(
                    title: 'Pending Events',
                    child: EventSmallCardSkeletonList(count: 3),
                  ),
                  error: (error, stackTrace) => ErrorRetryWidget(
                    message: 'Could not load pending events',
                    onRetry: () => ref.invalidate(homeEventsControllerProvider),
                  ),
                ),

                // To Dos Section removed from MVP (P1 only - awaiting P2 backend)
                // Component preserved: TodoCard in shared/components/cards/
                // Provider preserved: todosControllerProvider (inactive)
              ], // End of EVENT SECTIONS

              // Spacing after event sections
              const SizedBox(height: Gaps.lg),

              // LAZZO 2.0: Payments Section removed

              // Recent Memories Section
              recentMemoriesAsync.when(
                data: (memories) {
                  if (memories.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Calculate card width: (screen width - screen padding * 2 - gap between cards) / 2
                  final cardWidth = (MediaQuery.of(context).size.width -
                          (Insets.screenH * 2) -
                          Gaps.sm) /
                      2;

                  return Column(
                    children: [
                      // Section title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Insets.screenH,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recent Memories',
                            style: AppText.titleMediumEmph.copyWith(
                              color: BrandColors.text1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Gaps.md),

                      // Horizontal scroll with memory cards
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.screenH,
                          ),
                          itemCount: memories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: Gaps.sm),
                          itemBuilder: (context, index) {
                            final memory = memories[index];
                            return SizedBox(
                              width: cardWidth,
                              child: RecentMemoryCard(
                                memory: memory,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRouter.memory,
                                    arguments: {
                                      'memoryId': memory.id,
                                      'eventStatus': FakeEventStatus.ended,
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Gaps.lg),
                    ],
                  );
                },
                loading: () {
                  final cardWidth = (MediaQuery.of(context).size.width -
                          (Insets.screenH * 2) -
                          Gaps.sm) /
                      2;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Insets.screenH,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recent Memories',
                            style: AppText.titleMediumEmph.copyWith(
                              color: BrandColors.text1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Gaps.md),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.screenH,
                          ),
                          itemCount: 3,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: Gaps.sm),
                          itemBuilder: (_, __) =>
                              MemoryCardSkeleton(width: cardWidth),
                        ),
                      ),
                      const SizedBox(height: Gaps.lg),
                    ],
                  );
                },
                error: (error, stackTrace) => ErrorRetryWidget(
                  message: 'Could not load recent memories',
                  onRetry: () => ref.invalidate(recentMemoriesControllerProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

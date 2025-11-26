import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/inputs/search_bar.dart' as custom;
import '../../../../shared/components/sections/section_block.dart';
import '../../../../shared/components/cards/home_event_card.dart';
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../shared/components/cards/todo_card.dart';
import '../../../../shared/components/cards/payment_summary_card.dart';
import '../../../../shared/components/cards/recent_memory_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/layouts/main_layout_providers.dart';
import '../../../create_event/presentation/widgets/event_created_banner.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../widgets/no_groups_yet_card.dart';
import '../widgets/no_upcoming_events_card.dart';
import '../providers/banner_provider.dart';
import '../providers/home_event_providers.dart';
import '../../domain/entities/home_event.dart';
import '../../../../routes/app_router.dart';
import 'dart:async';

/// Home page - main screen showing next event, confirmed/pending events, todos, payments, and memories
///
/// TESTING EMPTY STATES (for P1 development):
/// To test different empty state scenarios, modify the static variables in fake repositories:
///
/// 1. Test "No groups yet" card:
///    - Set: FakeGroupRepository.mockNoGroups = true
///    - Result: Shows NoGroupsYetCard with CTA to create first group
///
/// 2. Test "No upcoming events" card:
///    - Set: FakeGroupRepository.mockNoGroups = false (has groups)
///    - Set: FakeHomeEventRepository.mockEmptyState = 'no-events'
///    - Result: Shows NoUpcomingEventsCard with group chips and create event CTA
///
/// 3. Test normal home (default):
///    - Set: FakeGroupRepository.mockNoGroups = false
///    - Set: FakeHomeEventRepository.mockEmptyState = 'normal'
///    - Result: Shows regular home with events, todos, payments, memories
///
/// This page purely consumes provider data - no mock logic here (Clean Architecture).

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _autoRefreshTimer;
  bool _isNoEventsCardDismissed = false;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh(); // ✅ Start auto-refresh timer
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Listen to tab changes and refresh when coming back to home
    final currentTab = ref.watch(mainLayoutTabProvider);
    if (currentTab == 0 && mounted) {
      // We're on home tab - refresh data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshAllData();
        }
      });
    }
  }

  void _refreshAllData() {
    // ✅ Invalidate all providers to fetch fresh data
    print('🔄 Refreshing home data...');
    ref.invalidate(nextEventControllerProvider);
    ref.invalidate(confirmedEventsControllerProvider);
    ref.invalidate(homeEventsControllerProvider);
    ref.invalidate(todosControllerProvider);
    ref.invalidate(paymentSummariesControllerProvider);
    ref.invalidate(totalBalanceControllerProvider);
    ref.invalidate(recentMemoriesControllerProvider);
    ref.invalidate(groupsProvider);

    // Force rebuild to pick up new provider data
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel(); // ✅ ADD cleanup
    super.dispose();
  }

  void _startAutoRefresh() {
    // ✅ Refresh a cada 1 minuto para capturar mudanças de estado
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        // Apenas invalidar se ainda estiver montado
        if (mounted) {
          _refreshAllData();
        }
      },
    );
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'Date to be decided';

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

  @override
  Widget build(BuildContext context) {
    final nextEventAsync = ref.watch(nextEventControllerProvider);
    final confirmedEventsAsync = ref.watch(confirmedEventsControllerProvider);
    final pendingEventsAsync = ref.watch(homeEventsControllerProvider);
    final todosAsync = ref.watch(todosControllerProvider);
    final paymentsAsync = ref.watch(paymentSummariesControllerProvider);
    final totalBalanceAsync = ref.watch(totalBalanceControllerProvider);
    final recentMemoriesAsync = ref.watch(recentMemoriesControllerProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final nextEventStatus = ref.watch(navBarStateProvider);

    // Calculate empty states based on provider data
    // IMPORTANT: Only show empty states when data is LOADED, not during loading
    // Empty state logic:
    // - Show "No groups yet" if user has no groups (data loaded)
    // - Show "No upcoming events" if user has groups but no events (data loaded)
    // - Show normal home if user has groups and events

    // Check if groups data is loaded
    final groupsLoaded = groupsAsync.hasValue;
    final groups = groupsAsync.asData?.value ?? [];
    final hasGroups = groups.isNotEmpty;

    // Check if events data is loaded
    final eventsLoaded = nextEventAsync.hasValue &&
        confirmedEventsAsync.hasValue &&
        pendingEventsAsync.hasValue;
    final hasEvents = (nextEventAsync.asData?.value != null ||
        (confirmedEventsAsync.asData?.value.isNotEmpty ?? false) ||
        (pendingEventsAsync.asData?.value.isNotEmpty ?? false));

    // Determine which empty state to show (only when data is loaded)
    final showNoGroupsCard = groupsLoaded && !hasGroups;
    final showNoEventsCard = groupsLoaded &&
        eventsLoaded &&
        hasGroups &&
        !hasEvents &&
        !_isNoEventsCardDismissed; // Don't show if dismissed

    return Scaffold(
      appBar: CommonAppBar(
        title: 'LAZZO',
        centerTitle: true,
        trailing: (nextEventStatus == HomeEventStatus.living ||
                nextEventStatus == HomeEventStatus.recap)
            ? IconButton(
                icon: Container(
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
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.createEvent);
                },
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: Gaps.xs),

            // Success banner if needed
            Consumer(
              builder: (context, ref, child) {
                final isVisible = ref.watch(
                  bannerProvider.select((state) => state.isVisible),
                );
                if (!isVisible) {
                  return const SizedBox.shrink();
                }

                final bannerState = ref.watch(bannerProvider);

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Insets.screenH),
                  child: Column(
                    children: [
                      EventCreatedBanner(
                        eventName: bannerState.eventName,
                        groupName: bannerState.groupName,
                        onClose: () {
                          ref.read(bannerProvider.notifier).hideBanner();
                        },
                      ),
                      const SizedBox(height: Gaps.md),
                    ],
                  ),
                );
              },
            ),

            // Search Bar - only show if user has groups
            if (!showNoGroupsCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
                child: custom.SearchBar(
                  placeholder: 'Search groups, events, memories...',
                  enabled: false,
                  onTap: () {
                    // TODO: Navigate to search page
                  },
                ),
              ),
            if (!showNoGroupsCard) const SizedBox(height: Gaps.md),

            // Empty States - purely based on provider data
            // IMPORTANT: Only show when data is loaded to avoid flickering
            // Show "No groups yet" if user has no groups (when data loaded)
            if (showNoGroupsCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
                child: Column(
                  children: [
                    NoGroupsYetCard(
                      onCreateGroup: () {
                        Navigator.pushNamed(context, AppRouter.createGroup);
                        // TODO P2: After group created, auto-open create event
                      },
                    ),
                    const SizedBox(height: Gaps.lg),
                  ],
                ),
              )
            // Show "No upcoming events" if user has groups but no events (when data loaded)
            else if (showNoEventsCard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
                child: Column(
                  children: [
                    groupsAsync.when(
                      data: (groups) {
                        // Convert groups to GroupChipData
                        final groupChips = groups
                            .take(5) // Max 5 most active groups
                            .map(
                              (g) => GroupChipData(
                                id: g.id,
                                name: g.name,
                                photoUrl:
                                    g.photoPath, // Using photoPath for now
                              ),
                            )
                            .toList();

                        return NoUpcomingEventsCard(
                          groups: groupChips,
                          onCreateEvent: (groupId) {
                            // TODO P2: Navigate to create event with group prefilled
                            Navigator.pushNamed(
                              context,
                              AppRouter.createEvent,
                              arguments: {'groupId': groupId},
                            );
                          },
                          onDismiss: () {
                            setState(() {
                              _isNoEventsCardDismissed = true;
                            });
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: Gaps.lg),
                  ],
                ),
              ),

            // EVENT SECTIONS - Only show if NOT in empty state
            if (!showNoGroupsCard && !showNoEventsCard) ...[
              // Next Event Section
              nextEventAsync.when(
                data: (event) {
                  if (event == null) {
                    return const SizedBox.shrink();
                  }

                  // Determine section title based on event status
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
                            // ✅ Navigate to event details
                            await Navigator.pushNamed(
                              context,
                              AppRouter.event,
                              arguments: {'eventId': event.id},
                            );
                            // ✅ Refresh data when returning from event page
                            if (mounted) {
                              _refreshAllData();
                            }
                          },
                          onChatPressed: () {
                            debugPrint(
                                '🟢 [HomePage] Chat pressed for event: ${event.id}');
                            // Navigate to event chat
                            Navigator.pushNamed(
                              context,
                              AppRouter.eventChat,
                              arguments: {'eventId': event.id},
                            );
                          },
                          onExpensePressed: () {
                            debugPrint(
                                '🟡 [HomePage] Expense pressed for event: ${event.id}');
                            // TODO P2: Implement expense creation
                          },
                          onVoteChanged: (eventId, vote) {
                            // TODO: Update vote in backend
                            debugPrint(
                              'Vote changed for event $eventId: $vote',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Gaps.lg),
                    ],
                  );
                },
                loading: () => SectionBlock(
                  title: 'Next Event',
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),

              // Confirmed Events Section
              confirmedEventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      SectionBlock(
                        title: 'Confirmed Events',
                        child: Column(
                          children: events.asMap().entries.map((entry) {
                            final index = entry.key;
                            final event = entry.value;
                            return Column(
                              children: [
                                EventSmallCard(
                                  emoji: event.emoji,
                                  title: event.name,
                                  dateTime: _formatEventDate(event.date),
                                  location: event.location ?? 'Location TBD',
                                  state:
                                      _mapStatusToSmallCardState(event.status),
                                  onTap: () async {
                                    // ✅ Navigate to event details
                                    await Navigator.pushNamed(
                                      context,
                                      AppRouter.event,
                                      arguments: {'eventId': event.id},
                                    );
                                    // ✅ Refresh data when returning
                                    if (mounted) {
                                      _refreshAllData();
                                    }
                                  },
                                ),
                                if (index < events.length - 1)
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
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),

              // Pending Events Section
              pendingEventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      SectionBlock(
                        title: 'Pending Events',
                        child: Column(
                          children: events.asMap().entries.map((entry) {
                            final index = entry.key;
                            final event = entry.value;
                            return Column(
                              children: [
                                EventSmallCard(
                                  emoji: event.emoji,
                                  title: event.name,
                                  dateTime: _formatEventDate(event.date),
                                  location: event.location ?? 'Location TBD',
                                  state:
                                      _mapStatusToSmallCardState(event.status),
                                  onTap: () async {
                                    // ✅ Navigate to event details
                                    await Navigator.pushNamed(
                                      context,
                                      AppRouter.event,
                                      arguments: {'eventId': event.id},
                                    );
                                    // ✅ Refresh data when returning
                                    if (mounted) {
                                      _refreshAllData();
                                    }
                                  },
                                ),
                                if (index < events.length - 1)
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
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),

              // To Dos Section (only show if there are events)
              todosAsync.when(
                data: (todos) {
                  if (todos.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      SectionBlock(
                        title: 'To Dos',
                        child: Column(
                          children: todos.asMap().entries.map((entry) {
                            final index = entry.key;
                            final todo = entry.value;
                            return Column(
                              children: [
                                TodoCard(
                                  todo: todo,
                                  onTap: () {
                                    // TODO P2: Navigate to event details
                                  },
                                ),
                                if (index < todos.length - 1)
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
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            ], // End of EVENT SECTIONS

            // Payments Section (shows even without events)
            paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    // Section title with total balance
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.screenH,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Payments',
                            style: AppText.titleMediumEmph.copyWith(
                              color: BrandColors.text1,
                            ),
                          ),
                          const Spacer(),
                          totalBalanceAsync.when(
                            data: (balance) {
                              return Text(
                                balance >= 0
                                    ? '+€${balance.toStringAsFixed(0)}'
                                    : '-€${balance.abs().toStringAsFixed(0)}',
                                style: AppText.titleMediumEmph.copyWith(
                                  color: balance >= 0
                                      ? BrandColors.planning // Green
                                      : BrandColors.cantVote, // Red
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gaps.md),

                    // Payment cards - 2 per row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.screenH,
                      ),
                      child: Wrap(
                        spacing: Gaps.sm,
                        runSpacing: Gaps.sm,
                        children: payments.take(4).map((payment) {
                          return SizedBox(
                            width: (MediaQuery.of(context).size.width -
                                    (Insets.screenH * 2) -
                                    Gaps.sm) /
                                2,
                            child: PaymentSummaryCard(
                              payment: payment,
                              onTap: () {
                                // Set inbox tab to Payments (index 2)
                                ref.read(inboxTabIndexProvider.notifier).state =
                                    2;
                                // Navigate to Inbox tab (index 2)
                                ref.read(mainLayoutTabProvider.notifier).state =
                                    2;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: Gaps.lg),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),

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
                                // TODO P2: Navigate to memory detail
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
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

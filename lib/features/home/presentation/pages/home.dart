import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/inputs/search_bar.dart' as custom;
import '../../../../shared/components/sections/section_block.dart';
import '../../../../shared/components/cards/home_event_card.dart';
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../shared/components/cards/todo_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../create_event/presentation/widgets/event_created_banner.dart';
import '../providers/banner_provider.dart';
import '../providers/home_event_providers.dart';
import '../../domain/entities/home_event.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _formatEventDate(DateTime? date) {
    if (date == null) return 'To be decided';

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
    final pendingEventsAsync = ref.watch(homePendingEventsControllerProvider);
    final todosAsync = ref.watch(todosControllerProvider);

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'LAZZO',
        centerTitle: true,
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

            // Search Bar
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
            const SizedBox(height: Gaps.md),

            // Next Event Section
            nextEventAsync.when(
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
                        state: _mapStatusToHomeCardState(event.status),
                        onTap: () {
                          // TODO: Navigate to event details
                        },
                        onChatPressed: () {
                          // TODO: Navigate to event chat
                        },
                        onExpensePressed: () {
                          // TODO: Open add expense bottom sheet
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
                                state: _mapStatusToSmallCardState(event.status),
                                onTap: () {
                                  // TODO: Navigate to event details
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
                                state: _mapStatusToSmallCardState(event.status),
                                onTap: () {
                                  // TODO: Navigate to event details
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

            // To Dos Section
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
              loading: () => const SectionBlock(
                title: 'To Dos',
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

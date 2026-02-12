import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/page_segmented_control.dart';
import '../../../../shared/components/cards/event_full_card.dart';
import '../../../event/domain/entities/event_display_entity.dart'; // LAZZO 2.0: dead code import for compilation
import '../../../../shared/components/cards/memory_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../routes/app_router.dart';
import '../../../../services/event_status_service.dart';
import '../providers/group_hub_providers.dart';
import '../../domain/entities/group_memory_entity.dart';
import '../../../event/domain/entities/rsvp.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../../domain/entities/group_event_entity.dart';
import '../../../memory/data/fakes/fake_memory_repository.dart';
import 'group_details_page.dart';

class GroupHubPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;

  const GroupHubPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupPhotoUrl,
  });

  @override
  ConsumerState<GroupHubPage> createState() => _GroupHubPageState();
}

class _GroupHubPageState extends ConsumerState<GroupHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Scroll snap state and controllers
  bool _isSnapped = false;
  late ScrollController _eventsScrollController;
  late ScrollController _memoriesScrollController;

  // Track primary scroll axis to detect vertical vs horizontal movement
  Axis? _primaryScrollAxis;

  // Prevent multiple rapid unsnap calls
  bool _isUnsnapping = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeScrollControllers();

    // Update event statuses before loading data
    _updateEventStatuses();
  }

  /// Update event statuses on page load
  /// This ensures events transition correctly between states
  Future<void> _updateEventStatuses() async {
    try {
      final statusService = EventStatusService(Supabase.instance.client);

      // Get events that need updating (for logging)
      final needsUpdate = await statusService.getEventsNeedingUpdate();
      final confirmedToLiving = needsUpdate['confirmed_to_living']!;
      final livingToRecap = needsUpdate['living_to_recap']!;
      final recapToEnded = needsUpdate['recap_to_ended']!;

      if (confirmedToLiving.isNotEmpty ||
          livingToRecap.isNotEmpty ||
          recapToEnded.isNotEmpty) {
        // Update all event statuses
        final updatedCount = await statusService.updateEventStatuses();

        if (updatedCount > 0) {
          // Refresh providers to show updated data
          if (mounted) {
            ref.invalidate(groupEventsProvider(widget.groupId));
            ref.invalidate(groupMemoriesProvider(widget.groupId));
          }
        }
      }
    } catch (e) {
      // Error updating event statuses
    }
  }

  void _initializeScrollControllers() {
    _eventsScrollController = ScrollController();
    _memoriesScrollController = ScrollController();

    // Listen for scroll down at the top of section scrolls to unsnap
    _eventsScrollController.addListener(_onSectionScrollChanged);
    _memoriesScrollController.addListener(_onSectionScrollChanged);
  }

  void _onSectionScrollChanged() {
    final currentController = _getCurrentSectionScrollController();
    if (currentController == null || !currentController.hasClients) return;

    final pixels = currentController.position.pixels;
    final direction = currentController.position.userScrollDirection;

    // If scrolling down and at/near the top of section, unsnap
    // Check for pixels <= 1 to account for floating point precision and overscroll
    if (_isSnapped &&
        !_isUnsnapping &&
        pixels <= 1.0 &&
        direction == ScrollDirection.forward) {
      _isUnsnapping = true;
      _setSnapState(false);
      // Reset flag after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _isUnsnapping = false;
      });
    }
  }

  ScrollController? _getCurrentSectionScrollController() {
    switch (_tabController.index) {
      case 0:
        return _eventsScrollController;
      case 1:
        return _memoriesScrollController;
      default:
        return null;
    }
  }

  void _setSnapState(bool snapped) {
    if (_isSnapped != snapped) {
      setState(() {
        _isSnapped = snapped;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventsScrollController.dispose();
    _memoriesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: BrandColors.planning,
          backgroundColor: BrandColors.bg2,
          notificationPredicate: (notification) =>
              notification.depth == 0 && notification.metrics.extentBefore == 0,
          child: GestureDetector(
            // Detect vertical drag up to snap when not snapped
            onVerticalDragUpdate: (details) {
              if (!_isSnapped && details.delta.dy < 0) {
                // Only snap if drag is primarily vertical (not diagonal)
                final horizontalMovement = details.delta.dx.abs();
                final verticalMovement = details.delta.dy.abs();

                if (verticalMovement > horizontalMovement * 1.5) {
                  // Trigger snap immediately
                  _setSnapState(true);
                }
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: _isSnapped ? _buildSnappedView() : _buildNormalView(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    // Refresh events
    await ref.read(groupEventsProvider(widget.groupId).notifier).refresh();

    // Refresh memories
    await ref.read(groupMemoriesProvider(widget.groupId).notifier).refresh();
  }

  PreferredSizeWidget _buildAppBar() {
    return CommonAppBar(
      title: _isSnapped ? widget.groupName : '',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
        onPressed: () => Navigator.of(context).pop(),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.settings, color: BrandColors.text1),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GroupDetailsPage(groupId: widget.groupId),
            ),
          );
        },
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Track scroll start to determine primary axis
    if (notification is ScrollStartNotification) {
      _primaryScrollAxis = null; // Reset
      return false;
    }

    if (notification is ScrollUpdateNotification && !_isSnapped) {
      final scrollDelta = notification.scrollDelta;
      final axis = notification.metrics.axis;

      // On first update, determine the primary scroll axis
      if (_primaryScrollAxis == null &&
          scrollDelta != null &&
          scrollDelta.abs() > 0) {
        _primaryScrollAxis = axis;
      }

      // Only respond if primary axis is vertical
      if (_primaryScrollAxis == Axis.vertical && axis == Axis.vertical) {
        if (scrollDelta != null && scrollDelta < 0) {
          // Scrolling up vertically - snap the view immediately
          _setSnapState(true);
          return true;
        }
      }
    }

    // Reset on scroll end
    if (notification is ScrollEndNotification) {
      _primaryScrollAxis = null;
    }

    return false;
  }

  Widget _buildNormalView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Group information section
        _buildGroupInfo(),
        const SizedBox(height: Gaps.lg),

        // Segmented control
        _buildSegmentedControl(),
        const SizedBox(height: Gaps.md),

        // Content sections - fixed height for TabBarView
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEventsSection(),
              _buildMemoriesSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSnappedView() {
    return Column(
      children: [
        // Segmented control fixed at top
        NotificationListener<ScrollNotification>(
          onNotification: _handleSegmentedControlScroll,
          child: _buildSegmentedControl(),
        ),

        // Content sections with individual scroll controllers
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEventsSection(),
              _buildMemoriesSection(),
            ],
          ),
        ),
      ],
    );
  }

  bool _handleSegmentedControlScroll(ScrollNotification notification) {
    // When in snapped mode, detect vertical scroll down to unsnap
    if (_isSnapped && notification is ScrollUpdateNotification) {
      final scrollDelta = notification.scrollDelta;
      final axis = notification.metrics.axis;

      // Only detect vertical scrolls, not horizontal (TabBarView swipes)
      if (axis == Axis.vertical) {
        if (scrollDelta != null && scrollDelta > 0) {
          // Scrolling down vertically - unsnap immediately
          _setSnapState(false);
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildMemoriesGrid(List<GroupMemoryEntity> memories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - Gaps.xs) / 2;

        return Column(
          children: [
            for (int i = 0; i < memories.length; i += 2)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i + 2 < memories.length ? Gaps.xs : 0,
                ),
                child: Row(
                  children: [
                    // First memory in row
                    Expanded(
                      child: SizedBox(
                        width: cardWidth,
                        child: MemoryCard(
                          title: memories[i].title,
                          coverImageUrl: memories[i].coverImageUrl,
                          date: memories[i].date,
                          location: memories[i].location,
                          borderColor: _isMemoryInRecap(memories[i])
                              ? BrandColors.recap
                              : null,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.memory,
                              arguments: {
                                'memoryId': memories[i].id,
                                'eventStatus': FakeEventStatus.ended,
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // Spacing between cards
                    const SizedBox(width: Gaps.xs),

                    // Second memory in row (if exists)
                    if (i + 1 < memories.length)
                      Expanded(
                        child: SizedBox(
                          width: cardWidth,
                          child: MemoryCard(
                            title: memories[i + 1].title,
                            coverImageUrl: memories[i + 1].coverImageUrl,
                            date: memories[i + 1].date,
                            location: memories[i + 1].location,
                            borderColor: _isMemoryInRecap(memories[i + 1])
                                ? BrandColors.recap
                                : null,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRouter.memory,
                                arguments: {
                                  'memoryId': memories[i + 1].id,
                                  'eventStatus': FakeEventStatus.ended,
                                },
                              );
                            },
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: SizedBox(),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGroupInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      child: Column(
        children: [
          // Group photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: BrandColors.bg3,
            ),
            child: widget.groupPhotoUrl == null || widget.groupPhotoUrl!.isEmpty
                ? const Icon(
                    Icons.group,
                    size: 40,
                    color: BrandColors.text2,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.groupPhotoUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.group,
                          size: 40,
                          color: BrandColors.text2,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: BrandColors.text2,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: Gaps.md),

          // Group name
          Text(
            widget.groupName,
            style: AppText.headlineMedium.copyWith(
              color: BrandColors.text1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gaps.xs),

          // Member count (dynamic from groupDetailsProvider)
          Consumer(
            builder: (context, ref, child) {
              final detailsAsync =
                  ref.watch(groupDetailsProvider(widget.groupId));
              final memberCount = detailsAsync.value?.memberCount ?? 0;
              return Text(
                '$memberCount Members',
                style: AppText.bodyMediumEmph.copyWith(
                  color: BrandColors.text2,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return PageSegmentedControl(
      controller: _tabController,
      labels: const ['Events', 'Memories'],
    );
  }

  Widget _buildEventsSection() {
    final eventsState = ref.watch(groupEventsProvider(widget.groupId));

    // Loading state
    if (eventsState.isLoading && eventsState.events.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      );
    }

    // Error state
    if (eventsState.error != null && eventsState.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'Error loading events',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
            const SizedBox(height: Gaps.sm),
            TextButton(
              onPressed: () {
                ref
                    .read(groupEventsProvider(widget.groupId).notifier)
                    .refresh();
              },
              child: Text(
                'Try again',
                style: AppText.labelLarge.copyWith(color: BrandColors.planning),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (eventsState.events.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_outlined,
        title: 'No events yet',
        subtitle: 'Events will appear here when created',
      );
    }

    final events = eventsState.events;

    // Sort events: Living (max 1) > Recap (multiple) > Confirmed > Pending
    final sortedEvents = List<GroupEventEntity>.from(events)
      ..sort((a, b) {
        // Living has highest priority
        if (a.status == GroupEventStatus.living &&
            b.status != GroupEventStatus.living) {
          return -1;
        }
        if (b.status == GroupEventStatus.living &&
            a.status != GroupEventStatus.living) {
          return 1;
        }

        // Recap has second priority
        if (a.status == GroupEventStatus.recap &&
            b.status != GroupEventStatus.recap) {
          return -1;
        }
        if (b.status == GroupEventStatus.recap &&
            a.status != GroupEventStatus.recap) {
          return 1;
        }

        // Confirmed has third priority
        if (a.status == GroupEventStatus.confirmed &&
            b.status != GroupEventStatus.confirmed) {
          return -1;
        }
        if (b.status == GroupEventStatus.confirmed &&
            a.status != GroupEventStatus.confirmed) {
          return 1;
        }

        // Within same status, sort by date (earlier dates first)
        if (a.date != null && b.date != null) {
          return a.date!.compareTo(b.date!);
        }
        return 0;
      });

    // ✅ Add scroll listener for infinite scroll
    _eventsScrollController.addListener(_onEventsScroll);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Load more when 200px from bottom
        if (notification is ScrollEndNotification &&
            _eventsScrollController.position.extentAfter < 200) {
          ref.read(groupEventsProvider(widget.groupId).notifier).loadMore();
        }
        return false;
      },
      child: ListView.separated(
        controller: _eventsScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: Insets.screenH,
          right: Insets.screenH,
          top: _isSnapped ? Gaps.md : 0,
          bottom: Gaps.md,
        ),
        // +1 for loading indicator at the bottom
        itemCount: sortedEvents.length + (eventsState.hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          if (index == sortedEvents.length - 1 && !eventsState.hasMore) {
            // After last event, no separator (bottom padding handled below)
            return const SizedBox.shrink();
          }
          return const SizedBox(height: Gaps.md);
        },
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index >= sortedEvents.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: Gaps.lg),
              child: Center(
                child: eventsState.isLoadingMore
                    ? const CircularProgressIndicator(
                        color: BrandColors.planning)
                    : const SizedBox.shrink(),
              ),
            );
          }

          final event = sortedEvents[index];
          final currentUser = Supabase.instance.client.auth.currentUser;
          final currentUserId = currentUser?.id;

          // Try to get avatar from the event's vote list (more reliable than userMetadata)
          String? currentUserAvatar;
          if (currentUserId != null && event.allVotes.isNotEmpty) {
            try {
              final userVote = event.allVotes.firstWhere(
                (vote) => vote.userId == currentUserId,
              );
              currentUserAvatar = userVote.userAvatar;
            } catch (e) {
              // User vote not found - will use fallback avatar
            }
          }
          // Fallback to userMetadata if not found in votes
          final fallbackAvatar =
              currentUser?.userMetadata?['avatar_url'] as String?;
          currentUserAvatar ??= fallbackAvatar;

          // Map GroupEventStatus to EventFullCardState
          EventFullCardState cardState;
          switch (event.status) {
            case GroupEventStatus.confirmed:
              cardState = EventFullCardState.confirmed;
            case GroupEventStatus.living:
              cardState = EventFullCardState.living;
            case GroupEventStatus.recap:
              cardState = EventFullCardState.recap;
            case GroupEventStatus.pending:
              cardState = EventFullCardState.pending;
          }

          // LAZZO 2.0: displayEvent variable removed (dead code, location handled in EventDisplayEntity below)

          return EventFullCard(
            event: EventDisplayEntity(
              id: event.id,
              name: event.name,
              emoji: event.emoji,
              date: event.date,
              endDate: event.endDate,
              location: event.location ?? 'Location to be decided',
              status: EventDisplayStatus.values.byName(event.status.name),
              goingCount: event.goingCount,
              participantCount: event.participantCount,
              attendeeAvatars: event.attendeeAvatars,
              attendeeNames: event.attendeeNames,
              allVotes: event.allVotes,
              userVote: event.userVote,
              photoCount: event.photoCount,
              maxPhotos: event.maxPhotos,
              participantPhotos: event.participantPhotos,
            ), // LAZZO 2.0: dead code — group_hub will be removed
            state: cardState,
            onTap: () async {
              // Navigate based on event status
              if (event.status == GroupEventStatus.living) {
                // Living event → EventLivingPage
                await Navigator.pushNamed(
                  context,
                  AppRouter.eventLiving,
                  arguments: {'eventId': event.id},
                );
              } else if (event.status == GroupEventStatus.recap) {
                await Navigator.pushNamed(
                  context,
                  '/memory',
                  arguments: {'memoryId': event.id},
                );
              } else {
                // Other statuses → EventPage (planning/confirmed/recap)
                await Navigator.pushNamed(
                  context,
                  AppRouter.event,
                  arguments: {'eventId': event.id},
                );
              }

              // Refresh only this specific event instead of entire list
              // This will fetch updated status, votes, and participant counts
              await ref
                  .read(groupEventsProvider(widget.groupId).notifier)
                  .refreshSingleEvent(event.id);
            },
            onVoteChanged: (eventId, vote) async {
              // Persist RSVP to Supabase
              try {
                final rsvpRepo = ref.read(rsvpRepositoryProvider);
                final userId = Supabase.instance.client.auth.currentUser?.id;

                if (userId == null) {
                  return;
                }

                // Convert vote to RsvpStatus
                final status = vote == null
                    ? RsvpStatus.pending
                    : (vote ? RsvpStatus.going : RsvpStatus.notGoing);

                await rsvpRepo.submitRsvp(eventId, userId, status);

                // Refresh ONLY this specific event (no full page reload)
                await ref
                    .read(groupEventsProvider(widget.groupId).notifier)
                    .refreshSingleEvent(eventId);

                // Also invalidate event-specific providers for consistency
                ref.invalidate(eventRsvpsProvider(eventId));
                ref.invalidate(userRsvpProvider(eventId));
              } catch (e) {
                // Failed to invalidate providers - UI will update on next load
              }
            },
          );
        },
      ),
    );
  }

  /// Scroll listener for infinite scroll
  void _onEventsScroll() {
    // This is now handled by NotificationListener above
  }

  Widget _buildMemoriesSection() {
    final memoriesAsync = ref.watch(groupMemoriesProvider(widget.groupId));

    return memoriesAsync.when(
      loading: () {
        return const Center(
          child: CircularProgressIndicator(color: BrandColors.planning),
        );
      },
      error: (error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: BrandColors.text2,
              ),
              const SizedBox(height: Gaps.md),
              Text(
                'Error loading memories',
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
              const SizedBox(height: Gaps.sm),
              Text(
                error.toString(),
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      data: (memories) {
        if (memories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No memories yet',
            subtitle: 'Group memories will appear here',
          );
        }

        return SingleChildScrollView(
          controller: _memoriesScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: Insets.screenH,
            right: Insets.screenH,
            top: _isSnapped ? Gaps.md : 0,
            bottom: Gaps.lg,
          ),
          child: _buildMemoriesGrid(memories),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Pads.sectionH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.lg),
            Text(
              title,
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              subtitle,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Check if memory is in recap phase (event ended within last 24 hours)
  bool _isMemoryInRecap(GroupMemoryEntity memory) {
    final now = DateTime.now();
    final eventDate = memory.date;
    final hoursSinceEvent = now.difference(eventDate).inHours;

    // Memory is in recap if event ended within the last 24 hours
    return hoursSinceEvent >= 0 && hoursSinceEvent <= 24;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/page_segmented_control.dart';
import '../../../../shared/components/cards/group_event_card.dart';
import '../../../../shared/components/cards/memory_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/group_hub_providers.dart';
import '../../domain/entities/group_memory_entity.dart';
import '../../../event/domain/entities/rsvp.dart';
import '../../../event/presentation/providers/event_providers.dart';
import 'group_details_page.dart';

class GroupHubPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final int memberCount;

  const GroupHubPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupPhotoUrl,
    required this.memberCount,
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
    );
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
    return Column(
      children: [
        // Group information section
        _buildGroupInfo(),
        const SizedBox(height: Gaps.lg),

        // Segmented control
        _buildSegmentedControl(),
        const SizedBox(height: Gaps.md),

        // Content sections
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
              image: widget.groupPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.groupPhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.groupPhotoUrl == null
                ? const Icon(
                    Icons.group,
                    size: 40,
                    color: BrandColors.text2,
                  )
                : null,
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

          // Member count
          Text(
            '${widget.memberCount} Members',
            style: AppText.bodyMediumEmph.copyWith(
              color: BrandColors.text2,
            ),
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
    final eventsAsync = ref.watch(groupEventsProvider(widget.groupId));

    return eventsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, stackTrace) => Center(
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
      ),
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_outlined,
            title: 'No events yet',
            subtitle: 'Events will appear here when created',
          );
        }

        return ListView.separated(
          controller: _eventsScrollController,
          physics: _isSnapped
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: Insets.screenH,
            right: Insets.screenH,
            top: _isSnapped ? Gaps.md : 0,
            bottom: Gaps.md,
          ),
          itemCount: events.length + 1,
          separatorBuilder: (context, index) {
            if (index == events.length - 1) {
              // After last event, no separator (bottom padding handled below)
              return const SizedBox.shrink();
            }
            return const SizedBox(height: Gaps.md);
          },
          itemBuilder: (context, index) {
            if (index < events.length) {
              final event = events[index];
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
                  print('⚠️ [PAGE] Current user not found in votes, using fallback');
                }
              }
              // Fallback to userMetadata if not found in votes
              final fallbackAvatar = currentUser?.userMetadata?['avatar_url'] as String?;
              currentUserAvatar ??= fallbackAvatar;
              
              
              return GroupEventCard(
                event: event,
                currentUserId: currentUserId,
                currentUserAvatar: currentUserAvatar,
                onTap: () async {
                  print('\n🚀 [NAVIGATION] Opening event page: ${event.id}');
                  
                  // Navigate to event detail page and refresh on return
                  await Navigator.pushNamed(
                    context,
                    '/event',
                    arguments: {'eventId': event.id},
                  );
                  
                  print('⬅️ [NAVIGATION] Returned from event page');
                  print('🔄 [NAVIGATION] Refreshing event ${event.id}...');
                  
                  // Refresh only this specific event instead of entire list
                  // This maintains scroll position and improves UX
                  await ref.read(groupEventsProvider(widget.groupId).notifier)
                    .refreshSingleEvent(event.id);
                },
                onVoteChanged: (eventId, vote) async {
                  print('\n🗳️ [VOTE SHORTCUT] Vote changed on card');
                  print('   📍 Event ID: $eventId');
                  print('   ✅ Vote: $vote');
                  
                  // Persist RSVP to Supabase
                  try {
                    final rsvpRepo = ref.read(rsvpRepositoryProvider);
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    
                    if (userId == null) {
                      print('❌ [VOTE SHORTCUT] User not authenticated');
                      return;
                    }

                    // Convert vote to RsvpStatus
                    final status = vote == null 
                        ? RsvpStatus.pending 
                        : (vote ? RsvpStatus.going : RsvpStatus.notGoing);

                    print('📤 [VOTE SHORTCUT] Submitting RSVP to Supabase...');
                    print('   👤 User ID: $userId');
                    print('   📊 Status: $status');
                    
                    await rsvpRepo.submitRsvp(eventId, userId, status);
                    
                    print('✅ [VOTE SHORTCUT] RSVP submitted successfully');
                    
                    // Refresh ONLY this specific event (no full page reload)
                    print('🔄 [VOTE SHORTCUT] Refreshing only this event...');
                    await ref.read(groupEventsProvider(widget.groupId).notifier)
                        .refreshSingleEvent(eventId);
                    
                    // Also invalidate event-specific providers for consistency
                    ref.invalidate(eventRsvpsProvider(eventId));
                    ref.invalidate(userRsvpProvider(eventId));
                    
                    print('✅ [VOTE SHORTCUT] Event refreshed without full reload');
                  } catch (e, stackTrace) {
                    print('❌ [VOTE SHORTCUT] Error submitting RSVP: $e');
                    print('   Stack: $stackTrace');
                  }
                },
              );
            } else {
              return const SizedBox(height: Gaps.md);
            }
          },
        );
      },
    );
  }

  Widget _buildMemoriesSection() {
    final memoriesAsync = ref.watch(groupMemoriesProvider(widget.groupId));

    return memoriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, stackTrace) => Center(
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
          ],
        ),
      ),
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
          physics: _isSnapped
              ? const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
              : const NeverScrollableScrollPhysics(),
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
}

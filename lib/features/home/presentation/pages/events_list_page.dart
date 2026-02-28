import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/home_event_providers.dart';
import '../../domain/entities/home_event.dart';
import '../../../../routes/app_router.dart';

/// Enum to determine which events to show
enum EventsListType {
  confirmed,
  pending,
}

/// Full list page for confirmed or pending events with infinite scroll
class EventsListPage extends ConsumerStatefulWidget {
  final EventsListType type;

  const EventsListPage({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends ConsumerState<EventsListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitial() {
    if (widget.type == EventsListType.confirmed) {
      ref.read(confirmedEventsListControllerProvider.notifier).loadInitial();
    } else {
      ref.read(pendingEventsListControllerProvider.notifier).loadInitial();
    }
  }

  Future<void> _handleRefresh() async {
    if (widget.type == EventsListType.confirmed) {
      await ref
          .read(confirmedEventsListControllerProvider.notifier)
          .loadInitial();
    } else {
      await ref
          .read(pendingEventsListControllerProvider.notifier)
          .loadInitial();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (widget.type == EventsListType.confirmed) {
      ref.read(confirmedEventsListControllerProvider.notifier).loadMore();
    } else {
      ref.read(pendingEventsListControllerProvider.notifier).loadMore();
    }
  }

  String get _title {
    return widget.type == EventsListType.confirmed
        ? 'Confirmed Events'
        : 'Pending Events';
  }

  void _navigateToEvent(HomeEventEntity event) {
    // Navigate based on status
    if (event.status == HomeEventStatus.living) {
      Navigator.pushNamed(
        context,
        AppRouter.eventLiving,
        arguments: {'eventId': event.id},
      );
    } else if (event.status == HomeEventStatus.recap) {
      Navigator.pushNamed(
        context,
        AppRouter.memory,
        arguments: {
          'memoryId': event.id,
          'viewSource': 'home',
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        AppRouter.event,
        arguments: {'eventId': event.id},
      );
    }
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
    return '${date.day} ${months[date.month - 1]}';
  }

  EventSmallCardState _mapStatusToSmallCardState(HomeEventStatus status) {
    switch (status) {
      case HomeEventStatus.pending:
        return EventSmallCardState.pending;
      case HomeEventStatus.confirmed:
        return EventSmallCardState.confirmed;
      case HomeEventStatus.living:
        return EventSmallCardState.living;
      case HomeEventStatus.recap:
        return EventSmallCardState.recap;
      case HomeEventStatus.expired:
        return EventSmallCardState.expired;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.type == EventsListType.confirmed
        ? ref.watch(confirmedEventsListControllerProvider)
        : ref.watch(pendingEventsListControllerProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: _title,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: BrandColors.planning,
        backgroundColor: BrandColors.bg2,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(PaginatedHomeEventsState state) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.events.isEmpty) {
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
              'Failed to load events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Gaps.sm),
            TextButton(
              onPressed: _loadInitial,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_available,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              widget.type == EventsListType.confirmed
                  ? 'No confirmed events'
                  : 'No pending events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(Insets.screenH),
        itemCount: state.events.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: Gaps.sm),
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index >= state.events.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: Gaps.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final event = state.events[index];
          final isExpired =
              event.date != null && event.date!.isBefore(DateTime.now());
          return EventSmallCard(
            emoji: event.emoji,
            title: event.name,
            dateTime: _formatEventDate(event.date),
            location: event.date == null
                ? null // Don't show location when date is TBD
                : (event.location ?? 'Location to be decided'),
            state: _mapStatusToSmallCardState(event.status),
            isExpired: isExpired,
            onTap: () => _navigateToEvent(event),
          );
        },
      ),
    );
  }
}

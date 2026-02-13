import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/entities/recent_memory_entity.dart';
import '../../domain/repositories/home_event_repository.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/repositories/recent_memory_repository.dart';
import '../../domain/usecases/get_next_event.dart';
import '../../domain/usecases/get_confirmed_events.dart';
import '../../domain/usecases/get_home_pending_events.dart';
import '../../domain/usecases/get_living_and_recap_events.dart';
import '../../domain/usecases/get_todos.dart';
import '../../domain/usecases/get_recent_memories.dart';
import '../../data/fakes/fake_home_event_repository.dart';
import '../../data/fakes/fake_todo_repository.dart';
import '../../data/fakes/fake_recent_memory_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
// LAZZO 2.0: payment_group + payments_provider imports removed

// Repository providers - default to fake implementations
final homeEventRepositoryProvider = Provider<HomeEventRepository>((ref) {
  return FakeHomeEventRepository();
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return FakeTodoRepository();
});

final recentMemoryRepositoryProvider = Provider<RecentMemoryRepository>((ref) {
  return FakeRecentMemoryRepository();
});

// ✅ NEW: Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.valueOrNull?.id;
});

// Use case providers
final getNextEventProvider = Provider<GetNextEvent>((ref) {
  return GetNextEvent(ref.watch(homeEventRepositoryProvider));
});

final getConfirmedEventsProvider = Provider<GetConfirmedEvents>((ref) {
  return GetConfirmedEvents(ref.watch(homeEventRepositoryProvider));
});

final getHomePendingEventsProvider = Provider<GetHomePendingEvents>((ref) {
  return GetHomePendingEvents(ref.watch(homeEventRepositoryProvider));
});

final getLivingAndRecapEventsProvider =
    Provider<GetLivingAndRecapEvents>((ref) {
  return GetLivingAndRecapEvents(ref.watch(homeEventRepositoryProvider));
});

final getTodosProvider = Provider<GetTodos>((ref) {
  return GetTodos(ref.watch(todoRepositoryProvider));
});

final getRecentMemoriesProvider = Provider<GetRecentMemories>((ref) {
  return GetRecentMemories(ref.watch(recentMemoryRepositoryProvider));
});

// Controller providers that expose AsyncValue for UI
// ✅ Using autoDispose to ensure fresh data on every invalidation
final nextEventControllerProvider =
    FutureProvider.autoDispose<HomeEventEntity?>((ref) async {
  final useCase = ref.watch(getNextEventProvider);
  return await useCase();
});

final confirmedEventsControllerProvider =
    FutureProvider.autoDispose<List<HomeEventEntity>>((ref) async {
  // Fetch both confirmed events and next event in parallel
  final results = await Future.wait([
    ref.watch(getConfirmedEventsProvider)(),
    ref.watch(nextEventControllerProvider.future),
  ]);

  final confirmedEvents = results[0] as List<HomeEventEntity>;
  final nextEvent = results[1] as HomeEventEntity?;

  // Filter out the next event to avoid duplication
  if (nextEvent == null) return confirmedEvents;
  return confirmedEvents.where((e) => e.id != nextEvent.id).toList();
});

final homeEventsControllerProvider =
    FutureProvider.autoDispose<List<HomeEventEntity>>((ref) async {
  // Fetch both pending events and next event in parallel
  final results = await Future.wait([
    ref.watch(getHomePendingEventsProvider)(),
    ref.watch(nextEventControllerProvider.future),
  ]);

  final pendingEvents = results[0] as List<HomeEventEntity>;
  final nextEvent = results[1] as HomeEventEntity?;

  // Filter out the next event to avoid duplication
  if (nextEvent == null) return pendingEvents;
  return pendingEvents.where((e) => e.id != nextEvent.id).toList();
});

final todosControllerProvider =
    FutureProvider.autoDispose<List<TodoEntity>>((ref) async {
  final useCase = ref.watch(getTodosProvider);
  return await useCase();
});

// LAZZO 2.0: paymentSummariesControllerProvider + totalBalanceControllerProvider removed

final recentMemoriesControllerProvider =
    FutureProvider.autoDispose<List<RecentMemoryEntity>>((ref) async {
  final useCase = ref.watch(getRecentMemoriesProvider);
  return await useCase();
});

final livingAndRecapEventsControllerProvider =
    FutureProvider.autoDispose<List<HomeEventEntity>>((ref) async {
  final useCase = ref.watch(getLivingAndRecapEventsProvider);
  return await useCase();
});

// ═══════════════════════════════════════════════════════════════════════════
// COUNT PROVIDERS (for "See All" button visibility)
// ═══════════════════════════════════════════════════════════════════════════

/// Total count of confirmed events (for showing "See All" when > 10)
final confirmedEventsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(homeEventRepositoryProvider);
  return await repo.getConfirmedEventsCount();
});

/// Total count of pending events (for showing "See All" when > 10)
final pendingEventsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(homeEventRepositoryProvider);
  return await repo.getPendingEventsCount();
});

// ═══════════════════════════════════════════════════════════════════════════
// PAGINATION STATE & CONTROLLERS (for Events List Page)
// ═══════════════════════════════════════════════════════════════════════════

/// State class for paginated events list
class PaginatedHomeEventsState {
  final List<HomeEventEntity> events;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PaginatedHomeEventsState({
    this.events = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PaginatedHomeEventsState copyWith({
    List<HomeEventEntity>? events,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return PaginatedHomeEventsState(
      events: events ?? this.events,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Controller for paginated confirmed events (See All page)
class ConfirmedEventsListController
    extends StateNotifier<PaginatedHomeEventsState> {
  final HomeEventRepository _repository;
  static const int _pageSize = 20;

  ConfirmedEventsListController(this._repository)
      : super(const PaginatedHomeEventsState());

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, events: []);

    try {
      final events = await _repository.getConfirmedEventsPaginated(
        limit: _pageSize,
        offset: 0,
      );
      state = state.copyWith(
        events: events,
        hasMore: events.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final moreEvents = await _repository.getConfirmedEventsPaginated(
        limit: _pageSize,
        offset: state.events.length,
      );
      state = state.copyWith(
        events: [...state.events, ...moreEvents],
        hasMore: moreEvents.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

/// Controller for paginated pending events (See All page)
class PendingEventsListController
    extends StateNotifier<PaginatedHomeEventsState> {
  final HomeEventRepository _repository;
  static const int _pageSize = 20;

  PendingEventsListController(this._repository)
      : super(const PaginatedHomeEventsState());

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, events: []);

    try {
      final events = await _repository.getPendingEventsPaginated(
        limit: _pageSize,
        offset: 0,
      );
      state = state.copyWith(
        events: events,
        hasMore: events.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final moreEvents = await _repository.getPendingEventsPaginated(
        limit: _pageSize,
        offset: state.events.length,
      );
      state = state.copyWith(
        events: [...state.events, ...moreEvents],
        hasMore: moreEvents.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

/// Provider for confirmed events list controller
final confirmedEventsListControllerProvider = StateNotifierProvider.autoDispose<
    ConfirmedEventsListController, PaginatedHomeEventsState>((ref) {
  final repo = ref.watch(homeEventRepositoryProvider);
  return ConfirmedEventsListController(repo);
});

/// Provider for pending events list controller
final pendingEventsListControllerProvider = StateNotifierProvider.autoDispose<
    PendingEventsListController, PaginatedHomeEventsState>((ref) {
  final repo = ref.watch(homeEventRepositoryProvider);
  return PendingEventsListController(repo);
});

// NavBar state provider - calculates state based on next event status
// Planning: default state or when next event is pending/confirmed
// Living: when next event is living
// Recap: when next event is recap
final navBarStateProvider = Provider<HomeEventStatus?>((ref) {
  final nextEventAsync = ref.watch(nextEventControllerProvider);

  return nextEventAsync.when(
    data: (event) => event?.status,
    loading: () => null,
    error: (_, __) => null,
  );
});

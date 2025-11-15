import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/entities/payment_summary_entity.dart';
import '../../domain/entities/recent_memory_entity.dart';
import '../../domain/repositories/home_event_repository.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/repositories/payment_summary_repository.dart';
import '../../domain/repositories/recent_memory_repository.dart';
import '../../domain/usecases/get_next_event.dart';
import '../../domain/usecases/get_confirmed_events.dart';
import '../../domain/usecases/get_home_pending_events.dart';
import '../../domain/usecases/get_todos.dart';
import '../../domain/usecases/get_payment_summaries.dart';
import '../../domain/usecases/get_total_balance.dart';
import '../../domain/usecases/get_recent_memories.dart';
import '../../data/fakes/fake_home_event_repository.dart';
import '../../data/fakes/fake_todo_repository.dart';
import '../../data/fakes/fake_payment_summary_repository.dart';
import '../../data/fakes/fake_recent_memory_repository.dart';

// Repository providers - default to fake implementations
final homeEventRepositoryProvider = Provider<HomeEventRepository>((ref) {
  return FakeHomeEventRepository();
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return FakeTodoRepository();
});

final paymentSummaryRepositoryProvider =
    Provider<PaymentSummaryRepository>((ref) {
  return FakePaymentSummaryRepository();
});

final recentMemoryRepositoryProvider = Provider<RecentMemoryRepository>((ref) {
  return FakeRecentMemoryRepository();
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

final getTodosProvider = Provider<GetTodos>((ref) {
  return GetTodos(ref.watch(todoRepositoryProvider));
});

final getPaymentSummariesProvider = Provider<GetPaymentSummaries>((ref) {
  return GetPaymentSummaries(ref.watch(paymentSummaryRepositoryProvider));
});

final getTotalBalanceProvider = Provider<GetTotalBalance>((ref) {
  return GetTotalBalance(ref.watch(paymentSummaryRepositoryProvider));
});

final getRecentMemoriesProvider = Provider<GetRecentMemories>((ref) {
  return GetRecentMemories(ref.watch(recentMemoryRepositoryProvider));
});

// Controller providers that expose AsyncValue for UI
final nextEventControllerProvider =
    FutureProvider<HomeEventEntity?>((ref) async {
  final useCase = ref.watch(getNextEventProvider);
  return await useCase();
});

final confirmedEventsControllerProvider =
    FutureProvider<List<HomeEventEntity>>((ref) async {
  final useCase = ref.watch(getConfirmedEventsProvider);
  return await useCase();
});

final homePendingEventsControllerProvider =
    FutureProvider<List<HomeEventEntity>>((ref) async {
  final useCase = ref.watch(getHomePendingEventsProvider);
  return await useCase();
});

final todosControllerProvider = FutureProvider<List<TodoEntity>>((ref) async {
  final useCase = ref.watch(getTodosProvider);
  return await useCase();
});

final paymentSummariesControllerProvider =
    FutureProvider<List<PaymentSummaryEntity>>((ref) async {
  final useCase = ref.watch(getPaymentSummariesProvider);
  return await useCase();
});

final totalBalanceControllerProvider = FutureProvider<double>((ref) async {
  final useCase = ref.watch(getTotalBalanceProvider);
  return await useCase();
});

final recentMemoriesControllerProvider =
    FutureProvider<List<RecentMemoryEntity>>((ref) async {
  final useCase = ref.watch(getRecentMemoriesProvider);
  return await useCase();
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

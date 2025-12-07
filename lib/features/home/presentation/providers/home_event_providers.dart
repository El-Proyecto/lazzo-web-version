import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/entities/payment_summary_entity.dart';
import '../../domain/entities/recent_memory_entity.dart';
import '../../domain/repositories/home_event_repository.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/repositories/recent_memory_repository.dart';
import '../../domain/usecases/get_next_event.dart';
import '../../domain/usecases/get_confirmed_events.dart';
import '../../domain/usecases/get_home_pending_events.dart';
import '../../domain/usecases/get_todos.dart';
import '../../domain/usecases/get_recent_memories.dart';
import '../../data/fakes/fake_home_event_repository.dart';
import '../../data/fakes/fake_todo_repository.dart';
import '../../data/fakes/fake_recent_memory_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../inbox/domain/entities/payment_group.dart';
import '../../../inbox/presentation/providers/payments_provider.dart';

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

/// Payment summaries for home page - reuses inbox payment data
/// Converts PaymentGroup to PaymentSummaryEntity for display
final paymentSummariesControllerProvider =
    FutureProvider.autoDispose<List<PaymentSummaryEntity>>((ref) async {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  if (currentUserId == null) {
    throw Exception('User not authenticated');
  }

  // Get payments from both directions (reuses inbox providers)
  final owedToUserAsync = ref.watch(paymentsOwedToUserProvider);
  final userOwesAsync = ref.watch(paymentsUserOwesProvider);

  final owedToUser = owedToUserAsync.asData?.value ?? [];
  final userOwes = userOwesAsync.asData?.value ?? [];

  final allPayments = [...owedToUser, ...userOwes];

  // Helper to get user name from payment based on current user
  String getUserName(String userId) {
    final payment = allPayments.firstWhere(
      (p) => p.fromUserId == userId || p.toUserId == userId,
      orElse: () => allPayments.first,
    );
    return userId == payment.fromUserId
        ? payment.fromUserName ?? 'Unknown'
        : payment.toUserName ?? 'Unknown';
  }

  // Group in both directions
  final owedGroups =
      PaymentGroup.groupByUser(allPayments, true, currentUserId, getUserName);
  final owingGroups =
      PaymentGroup.groupByUser(allPayments, false, currentUserId, getUserName);

  // Combine and convert to PaymentSummaryEntity
  final allGroups = [...owedGroups, ...owingGroups];
  final summaries = allGroups.map((group) {
    // Amount is positive if owed to user, negative if user owes
    final amount = group.isOwedToUser ? group.totalAmount : -group.totalAmount;
    return PaymentSummaryEntity(
      userId: group.userId,
      userName: group.userName,
      userPhotoUrl: null,
      amount: amount,
      expenseCount: group.payments.length,
      currency: 'EUR',
    );
  }).toList();

  // Sort by absolute amount (impact)
  summaries.sort((a, b) => b.absoluteAmount.compareTo(a.absoluteAmount));

  return summaries;
});

/// Total balance for home page - sum of all payment summaries
final totalBalanceControllerProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final summaries = await ref.watch(paymentSummariesControllerProvider.future);
  return summaries.fold<double>(0.0, (sum, s) => sum + s.amount);
});

final recentMemoriesControllerProvider =
    FutureProvider.autoDispose<List<RecentMemoryEntity>>((ref) async {
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

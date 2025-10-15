import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group_event_entity.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../domain/entities/group_memory_entity.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../../domain/repositories/group_expense_repository.dart';
import '../../domain/repositories/group_memory_repository.dart';
import '../../domain/usecases/get_group_events.dart';
import '../../domain/usecases/get_group_expenses.dart';
import '../../domain/usecases/get_group_memories.dart';
import '../../data/fakes/fake_group_event_repository.dart';
import '../../data/fakes/fake_group_expense_repository.dart';
import '../../data/fakes/fake_group_memory_repository.dart';

// Repository providers - defaults to fake
final groupEventRepositoryProvider = Provider<GroupEventRepository>((ref) {
  return FakeGroupEventRepository();
});

final groupExpenseRepositoryProvider = Provider<GroupExpenseRepository>((ref) {
  return FakeGroupExpenseRepository();
});

final groupMemoryRepositoryProvider = Provider<GroupMemoryRepository>((ref) {
  return FakeGroupMemoryRepository();
});

// Use case providers
final getGroupEventsUseCaseProvider = Provider<GetGroupEvents>((ref) {
  return GetGroupEvents(ref.watch(groupEventRepositoryProvider));
});

final getGroupExpensesUseCaseProvider = Provider<GetGroupExpenses>((ref) {
  return GetGroupExpenses(ref.watch(groupExpenseRepositoryProvider));
});

final getGroupMemoriesUseCaseProvider = Provider<GetGroupMemories>((ref) {
  return GetGroupMemories(ref.watch(groupMemoryRepositoryProvider));
});

// State providers
final groupEventsProvider = StateNotifierProvider.family<GroupEventsController,
    AsyncValue<List<GroupEventEntity>>, String>((
  ref,
  groupId,
) {
  return GroupEventsController(
    ref.watch(getGroupEventsUseCaseProvider),
    groupId,
  );
});

final groupExpensesProvider = StateNotifierProvider.family<
    GroupExpensesController, AsyncValue<List<GroupExpenseEntity>>, String>((
  ref,
  groupId,
) {
  return GroupExpensesController(
    ref.watch(getGroupExpensesUseCaseProvider),
    groupId,
  );
});

final groupMemoriesProvider = StateNotifierProvider.family<
    GroupMemoriesController, AsyncValue<List<GroupMemoryEntity>>, String>((
  ref,
  groupId,
) {
  return GroupMemoriesController(
    ref.watch(getGroupMemoriesUseCaseProvider),
    groupId,
  );
});

// Controllers
class GroupEventsController
    extends StateNotifier<AsyncValue<List<GroupEventEntity>>> {
  final GetGroupEvents _getGroupEvents;
  final String _groupId;

  GroupEventsController(this._getGroupEvents, this._groupId)
      : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _getGroupEvents(_groupId);
      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadEvents();
  }
}

class GroupExpensesController
    extends StateNotifier<AsyncValue<List<GroupExpenseEntity>>> {
  final GetGroupExpenses _getGroupExpenses;
  final String _groupId;

  GroupExpensesController(this._getGroupExpenses, this._groupId)
      : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _getGroupExpenses(_groupId);
      state = AsyncValue.data(expenses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadExpenses();
  }
}

class GroupMemoriesController
    extends StateNotifier<AsyncValue<List<GroupMemoryEntity>>> {
  final GetGroupMemories _getGroupMemories;
  final String _groupId;

  GroupMemoriesController(this._getGroupMemories, this._groupId)
      : super(const AsyncValue.loading()) {
    loadMemories();
  }

  Future<void> loadMemories() async {
    state = const AsyncValue.loading();
    try {
      final memories = await _getGroupMemories(_groupId);
      state = AsyncValue.data(memories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadMemories();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event_expense_entity.dart';
import '../../domain/repositories/event_expense_repository.dart';
import '../../domain/usecases/get_event_expenses.dart';
import '../../domain/usecases/create_event_expense.dart';
import '../../data/fakes/fake_event_expense_repository.dart';

// ✅ Repository provider (default: fake)
final eventExpenseRepositoryProvider = Provider<EventExpenseRepository>((ref) {
  return FakeEventExpenseRepository();
});

// ✅ Use case providers
final getEventExpensesUseCaseProvider = Provider<GetEventExpenses>((ref) {
  return GetEventExpenses(ref.watch(eventExpenseRepositoryProvider));
});

final createEventExpenseUseCaseProvider = Provider<CreateEventExpense>((ref) {
  return CreateEventExpense(ref.watch(eventExpenseRepositoryProvider));
});

// ✅ State provider (family: one controller per event)
final eventExpensesProvider = StateNotifierProvider.family<
    EventExpensesController, AsyncValue<List<EventExpenseEntity>>, String>((
  ref,
  eventId,
) {
  return EventExpensesController(
    ref.watch(getEventExpensesUseCaseProvider),
    ref.watch(createEventExpenseUseCaseProvider),
    eventId,
  );
});

// ✅ Controller (gerencia estado de despesas de um evento)
class EventExpensesController
    extends StateNotifier<AsyncValue<List<EventExpenseEntity>>> {
  final GetEventExpenses _getEventExpenses;
  final CreateEventExpense _createEventExpense;
  final String _eventId;

  EventExpensesController(
    this._getEventExpenses,
    this._createEventExpense,
    this._eventId,
  ) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _getEventExpenses(_eventId);
      state = AsyncValue.data(expenses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadExpenses();
  }

  Future<void> addExpense({
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    try {
      await _createEventExpense(
        eventId: _eventId,
        description: description,
        amount: amount,
        paidBy: paidBy,
        participantsOwe: participantsOwe,
        participantsPaid: participantsPaid,
      );
      await loadExpenses();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event_expense_entity.dart';
import '../../domain/repositories/event_expense_repository.dart';
import '../../domain/usecases/get_event_expenses.dart';
import '../../domain/usecases/create_event_expense.dart';
import '../../domain/usecases/mark_expense_as_paid.dart';
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
    ref.watch(markExpenseAsPaidUseCaseProvider),
    eventId,
  );
});

final markExpenseAsPaidUseCaseProvider = Provider<MarkExpenseAsPaid>((ref) {
  return MarkExpenseAsPaid(ref.watch(eventExpenseRepositoryProvider));
});

// ✅ Controller (gerencia estado de despesas de um evento)
class EventExpensesController
    extends StateNotifier<AsyncValue<List<EventExpenseEntity>>> {
  final GetEventExpenses _getEventExpenses;
  final CreateEventExpense _createEventExpense;
  final MarkExpenseAsPaid _markExpenseAsPaid;
  final String _eventId;

  EventExpensesController(
    this._getEventExpenses,
    this._createEventExpense,
    this._markExpenseAsPaid,
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

  Future<void> markAsPaid({
    required String expenseId,
    required String userId,
  }) async {
    try {
      await _markExpenseAsPaid.call(
        expenseId: expenseId,
        userId: userId,
      );

      // Atualizar estado localmente sem loading state
      final currentState = state;
      if (currentState is AsyncData<List<EventExpenseEntity>>) {
        final updatedExpenses = currentState.value.map((expense) {
          if (expense.id == expenseId) {
            // Adicionar userId a participantsPaid se ainda não estiver
            final updatedPaid = expense.participantsPaid.contains(userId)
                ? expense.participantsPaid
                : [...expense.participantsPaid, userId];

            // Remover userId de participantsOwe se estiver lá
            final updatedOwe =
                expense.participantsOwe.where((id) => id != userId).toList();

            // Verificar se todos os participantes pagaram (settled)
            final allParticipants = {
              ...expense.participantsOwe,
              ...expense.participantsPaid
            };
            final isNowSettled = updatedOwe.isEmpty &&
                updatedPaid.length == allParticipants.length;

            return expense.copyWith(
              participantsPaid: updatedPaid,
              participantsOwe: updatedOwe,
              isSettled: isNowSettled,
            );
          }
          return expense;
        }).toList();

        state = AsyncValue.data(updatedExpenses);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

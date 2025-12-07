import '../../domain/entities/event_expense_entity.dart';
import '../../domain/repositories/event_expense_repository.dart';
import '../data_sources/event_expense_remote_data_source.dart';

class EventExpenseRepositoryImpl implements EventExpenseRepository {
  final EventExpenseRemoteDataSource _dataSource;

  EventExpenseRepositoryImpl(this._dataSource);

  @override
  Future<EventExpenseEntity> createExpense({
    required String eventId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    final dto = await _dataSource.createExpense(
      eventId: eventId,
      description: description,
      amount: amount,
      paidBy: paidBy,
      participantsOwe: participantsOwe,
      participantsPaid: participantsPaid,
    );
    return dto.toEntity();
  }

  @override
  Future<List<EventExpenseEntity>> getEventExpenses(String eventId) async {
    final dtos = await _dataSource.getEventExpenses(eventId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<EventExpenseEntity?> getExpenseById(String expenseId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> markExpenseAsPaid({
    required String expenseId,
    required String userId,
  }) async {
    await _dataSource.markExpenseAsPaid(
      expenseId: expenseId,
      userId: userId,
    );
  }
}

import '../repositories/event_expense_repository.dart';

class MarkExpenseAsPaid {
  final EventExpenseRepository repository;

  const MarkExpenseAsPaid(this.repository);

  Future<void> call({
    required String expenseId,
    required String userId,
  }) async {
    await repository.markExpenseAsPaid(
      expenseId: expenseId,
      userId: userId,
    );
  }
}

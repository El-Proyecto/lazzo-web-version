import '../../domain/entities/group_expense_entity.dart';
import '../../domain/repositories/group_expense_repository.dart';
import '../data_sources/group_expense_remote_data_source.dart';

class GroupExpenseRepositoryImpl implements GroupExpenseRepository {
  final GroupExpenseRemoteDataSource _dataSource;

  GroupExpenseRepositoryImpl(this._dataSource);

  @override
  Future<GroupExpenseEntity> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    final dto = await _dataSource.createExpense(
      groupId: groupId,
      description: description,
      amount: amount,
      paidBy: paidBy,
      participantsOwe: participantsOwe,
      participantsPaid: participantsPaid,
    );
    return dto.toEntity();
  }

  @override
  Future<List<GroupExpenseEntity>> getGroupExpenses(String groupId) async {
    final dtos = await _dataSource.getGroupExpenses(groupId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<GroupExpenseEntity?> getExpenseById(String expenseId) async {
    // TODO: Implement if needed
    throw UnimplementedError();
  }
}
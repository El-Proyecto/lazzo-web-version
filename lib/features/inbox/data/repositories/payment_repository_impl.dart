import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../data_source/payments_remote_data_source.dart';
import '../models/payment_debt_model.dart';

/// Real implementation of PaymentRepository using Supabase
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentsRemoteDataSource _remoteDataSource;
  final SupabaseClient _supabase;

  PaymentRepositoryImpl(this._remoteDataSource, this._supabase);

  String get _currentUserId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  @override
  Future<List<PaymentEntity>> getPayments({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  }) async {
    print(
        '🔍 [PaymentRepositoryImpl] getPayments called - currentUserId: $_currentUserId');

    // Get all debts for current user
    final debts = await _remoteDataSource.getAllUserDebts(_currentUserId);
    print(
        '✅ [PaymentRepositoryImpl] Got ${debts.length} debts from data source');

    // Filter by groupId or eventId if provided
    var filtered = debts;
    if (groupId != null) {
      filtered = filtered.where((d) => d.groupId == groupId).toList();
      print(
          '🔍 [PaymentRepositoryImpl] Filtered by groupId: ${filtered.length} debts');
    }
    if (eventId != null) {
      filtered = filtered.where((d) => d.eventId == eventId).toList();
      print(
          '🔍 [PaymentRepositoryImpl] Filtered by eventId: ${filtered.length} debts');
    }

    // Apply pagination
    final paginated = filtered.skip(offset).take(limit).toList();

    // Convert to entities
    final entities = paginated
        .map((dto) => dto.toEntity(currentUserId: _currentUserId))
        .toList();
    print(
        '✅ [PaymentRepositoryImpl] Returning ${entities.length} payment entities');
    return entities;
  }

  @override
  Future<List<PaymentEntity>> getPaymentsOwedToUser(String userId) async {
    print(
        '🔍 [PaymentRepositoryImpl] getPaymentsOwedToUser for userId: $userId');
    final debts = await _remoteDataSource.getDebtsOwedToUser(userId);
    print('✅ [PaymentRepositoryImpl] Got ${debts.length} debts owed to user');
    final entities =
        debts.map((dto) => dto.toEntity(currentUserId: userId)).toList();
    print('✅ [PaymentRepositoryImpl] Returning ${entities.length} entities');
    return entities;
  }

  @override
  Future<List<PaymentEntity>> getPaymentsUserOwes(String userId) async {
    print('🔍 [PaymentRepositoryImpl] getPaymentsUserOwes for userId: $userId');
    final debts = await _remoteDataSource.getDebtsUserOwes(userId);
    print('✅ [PaymentRepositoryImpl] Got ${debts.length} debts user owes');
    final entities =
        debts.map((dto) => dto.toEntity(currentUserId: userId)).toList();
    print('✅ [PaymentRepositoryImpl] Returning ${entities.length} entities');
    return entities;
  }

  @override
  Future<PaymentEntity?> getPaymentById(String id) async {
    // Payment ID format: "expenseId_userId"
    final parts = id.split('_');
    if (parts.length != 2) return null;

    final expenseId = parts[0];
    final userId = parts[1];

    // Get all user debts and find matching one
    final debts = await _remoteDataSource.getAllUserDebts(_currentUserId);
    final matching = debts
        .where((d) => d.expenseId == expenseId && d.debtorUserId == userId)
        .firstOrNull;

    return matching?.toEntity(currentUserId: _currentUserId);
  }

  @override
  Future<void> markAsPaid(String id) async {
    // Payment ID format: "expenseId_userId"
    final parts = id.split('_');
    if (parts.length != 2) {
      throw Exception('Invalid payment ID format');
    }

    final expenseId = parts[0];
    final userId = parts[1];

    await _remoteDataSource.markDebtAsPaid(expenseId, userId);
  }

  @override
  Future<double> getTotalOwedToUser(String userId) async {
    final debts = await _remoteDataSource.getDebtsOwedToUser(userId);
    return debts.fold<double>(0.0, (sum, debt) => sum + debt.debtAmount);
  }

  @override
  Future<double> getTotalUserOwes(String userId) async {
    final debts = await _remoteDataSource.getDebtsUserOwes(userId);
    return debts.fold<double>(0.0, (sum, debt) => sum + debt.debtAmount);
  }

  @override
  Stream<List<PaymentEntity>> watchPayments() {
    // Stream implementation: listen to expense_splits changes
    return _supabase
        .from('expense_splits')
        .stream(primaryKey: ['expense_id', 'user_id']).asyncMap((_) async {
      // When any split changes, refetch all user debts
      final debts = await _remoteDataSource.getAllUserDebts(_currentUserId);
      return debts
          .map((dto) => dto.toEntity(currentUserId: _currentUserId))
          .toList();
    });
  }
}

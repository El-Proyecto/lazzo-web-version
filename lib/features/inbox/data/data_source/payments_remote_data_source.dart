import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_debt_model.dart';

/// Remote data source for fetching payment debts from Supabase view
class PaymentsRemoteDataSource {
  final SupabaseClient _supabase;

  PaymentsRemoteDataSource(this._supabase);

  /// Get all debts where the user owes money (user is debtor)
  ///
  /// Returns list of debts from user_payment_debts_view where
  /// debtor_user_id matches the provided userId
  Future<List<PaymentDebtDto>> getDebtsUserOwes(String userId) async {
    try {
      final response = await _supabase
          .from('user_payment_debts_view')
          .select()
          .eq('debtor_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentDebtDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch debts user owes: $e');
    }
  }

  /// Get all debts where the user is owed money (user is creditor)
  ///
  /// Returns list of debts from user_payment_debts_view where
  /// paid_by_user_id matches the provided userId
  Future<List<PaymentDebtDto>> getDebtsOwedToUser(String userId) async {
    try {
      final response = await _supabase
          .from('user_payment_debts_view')
          .select()
          .eq('paid_by_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentDebtDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch debts owed to user: $e');
    }
  }

  /// Get all debts involving the user (both directions)
  ///
  /// Returns combined list of debts where user is either debtor or creditor
  Future<List<PaymentDebtDto>> getAllUserDebts(String userId) async {
    try {
      final response = await _supabase
          .from('user_payment_debts_view')
          .select()
          .or('debtor_user_id.eq.$userId,paid_by_user_id.eq.$userId')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentDebtDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all user debts: $e');
    }
  }

  /// Get all debts between the user and a specific person (bidirectional)
  ///
  /// Returns debts where user and otherPersonId are on either side of the debt
  Future<List<PaymentDebtDto>> getDebtsWithPerson(
    String userId,
    String otherPersonId,
  ) async {
    try {
      final response = await _supabase
          .from('user_payment_debts_view')
          .select()
          .or('debtor_user_id.eq.$userId,paid_by_user_id.eq.$userId')
          .or('debtor_user_id.eq.$otherPersonId,paid_by_user_id.eq.$otherPersonId')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentDebtDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch debts with person: $e');
    }
  }

  /// Mark a debt as paid by updating expense_splits.has_paid
  ///
  /// Requires proper RLS policies on expense_splits table that allow:
  /// 1. Debtor (user_id) to update their own splits
  /// 2. Creditor (created_by in event_expenses) to update splits owed to them
  Future<void> markDebtAsPaid(String expenseId, String userId) async {
    try {
      final result = await _supabase
          .from('expense_splits')
          .update({'has_paid': true})
          .eq('expense_id', expenseId)
          .eq('user_id', userId)
          .select();

      if ((result as List).isEmpty) {
        throw Exception('Failed to update expense_split - no rows affected');
      }
    } catch (e) {
      throw Exception('Failed to mark debt as paid: $e');
    }
  }
}

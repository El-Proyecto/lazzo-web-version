import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_expense_model.dart';

class GroupExpenseRemoteDataSource {
  final SupabaseClient _client;

  GroupExpenseRemoteDataSource(this._client);

  /// Create expense in Supabase
  Future<GroupExpenseDto> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    final response = await _client
        .from('group_expenses')
        .insert({
          'group_id': groupId,
          'description': description,
          'amount': amount,
          'paid_by': paidBy,
          'participants_owe': participantsOwe,
          'participants_paid': participantsPaid,
          'is_settled': false,
        })
        .select()
        .single();

    return GroupExpenseDto.fromJson(response);
  }

  /// Fetch expenses (já existente, mas vou mostrar exemplo)
  Future<List<GroupExpenseDto>> getGroupExpenses(String groupId) async {
    final response = await _client
        .from('group_expenses')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GroupExpenseDto.fromJson(json))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final response = await _client
        .from('group_members')
        .select('''
          user_id,
          role,
          users:user_id (
            id,
            display_name,
            avatar_url
          )
        ''')
        .eq('group_id', groupId)
        .order('role', ascending: false); // Admins first

    return List<Map<String, dynamic>>.from(response);
  }
}



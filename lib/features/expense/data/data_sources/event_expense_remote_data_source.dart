import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_expense_model.dart';

class EventExpenseRemoteDataSource {
  final SupabaseClient _client;

  EventExpenseRemoteDataSource(this._client);

  /// Cria despesa associada a um evento
  Future<EventExpenseDto> createExpense({
    required String eventId, // ✅ event_id
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    try {
      print('💰 [DataSource] Creating expense for event: $eventId');
      
      final response = await _client
          .from('event_expenses') // ✅ Nova tabela
          .insert({
            'event_id': eventId,
            'description': description,
            'amount': amount,
            'paid_by': paidBy,
            'participants_owe': participantsOwe,
            'participants_paid': participantsPaid,
            'is_settled': false,
          })
          .select()
          .single();

      print('   ✅ Expense created: ${response['id']}');
      return EventExpenseDto.fromJson(response);
    } catch (e) {
      print('   ❌ Failed to create expense: $e');
      throw Exception('Failed to create expense: $e');
    }
  }

  /// Busca despesas de um evento
  Future<List<EventExpenseDto>> getEventExpenses(String eventId) async {
    try {
      print('💰 [DataSource] Fetching expenses for event: $eventId');
      
      final response = await _client
          .from('event_expenses')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      print('   ✅ Found ${response.length} expenses');
      return (response as List)
          .map((json) => EventExpenseDto.fromJson(json))
          .toList();
    } catch (e) {
      print('   ❌ Failed to fetch expenses: $e');
      throw Exception('Failed to get expenses: $e');
    }
  }
}
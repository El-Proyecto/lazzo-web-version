import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_expense_model.dart';

class EventExpenseRemoteDataSource {
  final SupabaseClient _client;

  EventExpenseRemoteDataSource(this._client);

  /// Cria despesa associada a um evento
  Future<EventExpenseDto> createExpense({
    required String eventId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> participantsOwe,
    required List<String> participantsPaid,
  }) async {
    try {
      print('💰 [DataSource] Creating expense for event: $eventId');
      print('   title: $description');
      print('   total_amount: $amount');
      print('   created_by: $paidBy');

      // Step 1: Create expense record
      final expenseResponse = await _client
          .from('event_expenses')
          .insert({
            'event_id': eventId,
            'title': description, // ✅ Corrected: title not description
            'total_amount': amount, // ✅ Corrected: total_amount not amount
            'created_by': paidBy, // ✅ Corrected: created_by not paid_by
          })
          .select()
          .single();

      final expenseId = expenseResponse['id'] as String;
      print('   ✅ Expense created: $expenseId');

      // Step 2: Insert expense_splits (who owes)
      if (participantsOwe.isNotEmpty) {
        print('   💸 Inserting ${participantsOwe.length} splits...');
        final amountPerPerson = amount / participantsOwe.length;
        await _client.from('expense_splits').insert(
              participantsOwe
                  .map((userId) => {
                        'expense_id': expenseId,
                        'user_id': userId,
                        'amount': amountPerPerson,
                        'has_paid': userId ==
                            paidBy, // ✅ Person who paid already has their part paid
                      })
                  .toList(),
            );
      }

      print('   ✅ All expense data inserted successfully!');
      return EventExpenseDto.fromJson(expenseResponse);
    } catch (e, stack) {
      print('   ❌ Failed to create expense: $e');
      print('   Stack: $stack');
      throw Exception('Failed to create expense: $e');
    }
  }

  /// Busca despesas de um evento com splits
  Future<List<EventExpenseDto>> getEventExpenses(String eventId) async {
    try {
      print('💰 [DataSource] Fetching expenses for event: $eventId');

      // Fetch expenses
      final expensesResponse = await _client
          .from('event_expenses')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      print('   ✅ Found ${expensesResponse.length} expenses');

      // For each expense, fetch splits
      final expenses = <EventExpenseDto>[];
      for (final expenseJson in expensesResponse as List) {
        final expenseId = expenseJson['id'] as String;

        // Fetch splits for this expense
        final splitsResponse = await _client
            .from('expense_splits')
            .select()
            .eq('expense_id', expenseId);

        // Build participantsOwe list (user_ids from splits)
        final participantsOwe = (splitsResponse as List)
            .map((split) => split['user_id'] as String)
            .toList();

        // Create DTO with splits data
        final dto = EventExpenseDto.fromJson(expenseJson);
        expenses.add(EventExpenseDto(
          id: dto.id,
          eventId: dto.eventId,
          description: dto.description,
          amount: dto.amount,
          paidBy: dto.paidBy,
          participantsOwe: participantsOwe, // ✅ Real data from splits
          participantsPaid: [], // Not tracking this yet
          createdAt: dto.createdAt,
          isSettled: dto.isSettled,
        ));
      }

      return expenses;
    } catch (e) {
      print('   ❌ Failed to fetch expenses: $e');
      throw Exception('Failed to get expenses: $e');
    }
  }
}

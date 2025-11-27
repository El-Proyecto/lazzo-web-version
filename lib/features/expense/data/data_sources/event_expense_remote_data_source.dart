import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_expense_model.dart';
import '../models/user_event_expense_view_model.dart';

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

  /// Busca despesas de um evento usando a view user_event_expenses
  Future<List<EventExpenseDto>> getEventExpenses(String eventId) async {
    try {
      print('💰 [DataSource] Fetching expenses from view for event: $eventId');

      // Get current user ID
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        print('   ❌ No authenticated user');
        return [];
      }

      // Query the view - gets all expenses for this event (all participants)
      final response = await _client
          .from('user_event_expenses')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      // Group by expense_id and build DTOs with all participants
      final expenseMap = <String, List<UserEventExpenseViewDto>>{};

      for (final row in response as List) {
        final viewDto = UserEventExpenseViewDto.fromJson(row);
        expenseMap.putIfAbsent(viewDto.expenseId, () => []).add(viewDto);
      }

      // Convert to EventExpenseDto
      final expenses = <EventExpenseDto>[];
      for (final expenseRows in expenseMap.values) {
        final first = expenseRows.first;

        // Get all participants who owe (exclude 'not_related')
        final participantsOwe = expenseRows
            .where((row) => row.userRole != 'not_related')
            .map((row) => row.participantId)
            .toList();

        // Get participants who already paid
        final participantsPaid = expenseRows
            .where((row) => row.participantHasPaid == true)
            .map((row) => row.participantId)
            .toList();

        expenses.add(EventExpenseDto(
          id: first.expenseId,
          eventId: first.eventId,
          description: first.title,
          amount: first.totalAmount,
          paidBy: first.paidByUserId,
          participantsOwe: participantsOwe,
          participantsPaid: participantsPaid,
          createdAt: first.createdAt,
          isSettled: false,
        ));
      }

      return expenses;
    } catch (e) {
      throw Exception('Failed to get expenses: $e');
    }
  }

  /// Busca todos os participantes de uma despesa específica usando a view
  Future<List<UserEventExpenseViewDto>> getExpenseParticipants(
      String expenseId) async {
    try {
      print('💰 [DataSource] Fetching participants for expense: $expenseId');

      final response = await _client
          .from('user_event_expenses')
          .select()
          .eq('expense_id', expenseId);

      return (response as List)
          .map((json) => UserEventExpenseViewDto.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expense participants: $e');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_expense_model.dart';
import '../models/user_event_expense_view_model.dart';
import '../../../../services/notification_service.dart';

class EventExpenseRemoteDataSource {
  final SupabaseClient _client;
  final NotificationService _notificationService;

  EventExpenseRemoteDataSource(this._client, this._notificationService);

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
      
      // Step 2: Insert expense_splits (who owes)
      if (participantsOwe.isNotEmpty) {
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
                
        // Step 3: Send notifications to participants who owe money (excluding payer)
        try {
                    final creatorData = await _client
              .from('users')
              .select('name')
              .eq('id', paidBy)
              .single();
          
          final eventData = await _client
              .from('events')
              .select('name, emoji')
              .eq('id', eventId)
              .single();
          
          final creatorName = creatorData['name'] ?? 'Someone';
          final eventName = eventData['name'];
          final eventEmoji = eventData['emoji'];
                    
          // Send notification to each participant (except the payer)
                    for (final userId in participantsOwe) {
            if (userId != paidBy) {
                            final notificationId = await _notificationService.sendExpenseAddedYouOwe(
                recipientUserId: userId,
                creatorName: creatorName,
                amount: amountPerPerson.toStringAsFixed(2),
                eventId: eventId,
                eventEmoji: eventEmoji,
                eventName: eventName,
              );
                          }
          }
        } catch (notifError) {
          // Don't fail expense creation if notifications fail
                            }
      } else {
              }

            return EventExpenseDto.fromJson(expenseResponse);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  /// Busca despesas de um evento usando a view user_event_expenses
  Future<List<EventExpenseDto>> getEventExpenses(String eventId) async {
    try {
      // Get current user ID
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        return [];
      }

      // Query the view - gets all expenses for this event (all participants)
      // Add timestamp to force fresh data (bypass any cache)
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

        // Get participants who already paid
        final participantsPaid = expenseRows
            .where((row) => row.participantHasPaid == true)
            .map((row) => row.participantId)
            .toList();

        // Get participants who still owe (haven't paid yet)
        final participantsOwe = expenseRows
            .where((row) =>
                row.userRole != 'not_related' && row.participantHasPaid != true)
            .map((row) => row.participantId)
            .toList();

        // Calcular se está settled: todos os participantes pagaram
        final allParticipants =
            expenseRows.where((row) => row.userRole != 'not_related').toList();
        final isSettled = allParticipants.isNotEmpty &&
            allParticipants.every((row) => row.participantHasPaid == true);

        expenses.add(EventExpenseDto(
          id: first.expenseId,
          eventId: first.eventId,
          description: first.title,
          amount: first.totalAmount,
          paidBy: first.paidByUserId,
          participantsOwe: participantsOwe,
          participantsPaid: participantsPaid,
          createdAt: first.createdAt,
          isSettled: isSettled,
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

  Future<void> markExpenseAsPaid({
    required String expenseId,
    required String userId,
  }) async {
    try {
      final updateResult = await _client
          .from('expense_splits')
          .update({'has_paid': true})
          .eq('expense_id', expenseId)
          .eq('user_id', userId)
          .select();

      final updatedCount = (updateResult as List).length;

      if (updatedCount == 0) {
        throw Exception(
            'No rows updated - check if record exists and RLS policies allow UPDATE');
      }
    } catch (e) {
      throw Exception('Failed to mark expense as paid: $e');
    }
  }
}

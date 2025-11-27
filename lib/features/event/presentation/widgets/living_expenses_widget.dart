import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/dialogs/add_expense_bottom_sheet.dart';
import 'event_expense_card.dart';
import 'expense_detail_bottom_sheet.dart';
// ✅ MUDAR: import de expense/ em vez de event/
import '../../../expense/domain/entities/event_expense_entity.dart';
// ✅ MUDAR: import provider de expense/
import '../../../expense/presentation/providers/event_expense_providers.dart';
import 'chat_preview_widget.dart'; // For ChatMode enum

/// Widget showing event expenses in both planning and living modes
class EventExpensesWidget extends ConsumerWidget {
  final String eventId;
  final List<ExpenseParticipantOption> participants;
  final ChatMode mode;
  final Future<void> Function(
    String title,
    String paidById, // ✅ Mudou de List<String> para String
    List<String> participantsOwe,
    double totalAmount,
  ) onAddExpense;

  const EventExpensesWidget({
    super.key,
    required this.eventId,
    required this.participants,
    required this.mode,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ MUDAR: usar eventExpensesProvider de expense/
    final expensesAsync = ref.watch(eventExpensesProvider(eventId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const SizedBox.shrink();
        }

        final userTotal = _calculateUserTotal(expenses);
        final isOwedToUser = userTotal > 0;

        return Container(
          padding: const EdgeInsets.all(Pads.sectionH),
          decoration: BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expenses',
                    style: AppText.labelLarge.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                  Text(
                    '${isOwedToUser ? '+' : '-'}€${userTotal.abs().toStringAsFixed(2)}',
                    style: AppText.bodyMediumEmph.copyWith(
                      color: isOwedToUser
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gaps.md),

              // Expenses list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: Gaps.md),
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  final userAmount = _calculateUserAmount(expense);
                  final userOwed = _isOwedToUser(expense);

                  // Get current user ID
                  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

                  // Find payer name from participants
                  final payerParticipant = participants.firstWhere(
                    (p) => p.id == expense.paidBy,
                    orElse: () => ExpenseParticipantOption(
                      id: expense.paidBy,
                      name: 'Unknown',
                      avatarUrl: null,
                    ),
                  );
                  
                  // Show "You" if current user is payer, otherwise show name
                  final payerName = expense.paidBy == currentUserId 
                      ? 'You' 
                      : payerParticipant.name;

                  // ✅ MUDAR: GroupExpenseCard → EventExpenseCard
                  return EventExpenseCard(
                    expense: expense,
                    payerName: payerName, // ✅ Pass name (shows "You" if current user)
                    userAmount: userAmount,
                    isOwedToUser: userOwed,
                    onTap: () => _showExpenseDetail(context, expense),
                  );
                },
              ),
              const SizedBox(height: Gaps.md),

              // Add Expense button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => _showAddExpenseSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Pads.ctlH,
                      vertical: Pads.ctlV,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColors.bg3,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Center(
                      child: Text(
                        'Add Expense',
                        style: AppText.bodyMediumEmph.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    AddExpenseBottomSheet.show(
      context: context,
      participants: participants,
      onAddExpense: onAddExpense,
    );
  }

  void _showExpenseDetail(BuildContext context, EventExpenseEntity expense) {
    // Get current user ID
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    // Find payer name
    final payerParticipant = participants.firstWhere(
      (p) => p.id == expense.paidBy,
      orElse: () => ExpenseParticipantOption(
        id: expense.paidBy,
        name: 'Unknown',
        avatarUrl: null,
      ),
    );
    
    // Show "You" if current user is payer, otherwise show name
    final payerName = expense.paidBy == currentUserId ? 'You' : payerParticipant.name;
    
    // Map participant IDs to names using the participants list
    final participantDisplayList = (expense.participantsOwe + expense.participantsPaid)
        .toSet() // Remove duplicados
        .map((id) {
          // Find participant name from the list
          final participant = participants.firstWhere(
            (p) => p.id == id,
            orElse: () => ExpenseParticipantOption(
              id: id,
              name: 'Unknown',
              avatarUrl: null,
            ),
          );
          
          // Calculate individual split amount for this participant
          final splitAmount = expense.participantsOwe.length > 0 
              ? expense.amount / expense.participantsOwe.length 
              : 0.0;
          
          // Check if this participant has paid (person who paid the expense has their part paid)
          final participantHasPaid = id == expense.paidBy;
          
          return ExpenseParticipantDisplay(
            id: id,
            name: participant.name, // ✅ Use real name
            avatarUrl: participant.avatarUrl,
            amount: splitAmount, // ✅ Individual split amount
            hasPaid: participantHasPaid, // ✅ True if this person paid the expense
            paidAt: participantHasPaid ? expense.date : null,
          );
        })
        .toList();

    ExpenseDetailBottomSheet.show(
      context: context,
      expense: expense,
      payerName: payerName, // ✅ Pass payer name (shows "You" if current user)
      participants: participantDisplayList,
      isCurrentUserPayer: expense.paidBy == currentUserId, // ✅ Compare with actual user ID
      mode: mode,
      onMarkAsPaid: () {
        // TODO: Implementar mark as paid
      },
      onNotifyParticipant: (participantId) {
        // TODO: Implementar notificação
      },
    );
  }

  double _calculateUserTotal(List<EventExpenseEntity> expenses) {
    double total = 0;
    for (final expense in expenses) {
      if (expense.isSettled) continue;
      final amount = _calculateUserAmount(expense);
      final isOwed = _isOwedToUser(expense);
      total += isOwed ? amount : -amount;
    }
    return total;
  }

  double _calculateUserAmount(EventExpenseEntity expense) {
    // Get current user ID
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return 0.0;
    
    // If user is not part of this expense, return 0
    if (!expense.participantsOwe.contains(currentUserId)) return 0.0;
    
    // Calculate split amount (total divided by number of people who owe)
    final totalParticipants = expense.participantsOwe.length;
    return totalParticipants > 0 ? expense.amount / totalParticipants : 0.0;
  }

  bool _isOwedToUser(EventExpenseEntity expense) {
    // Get current user ID
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return false;
    
    // User is owed money if they paid the expense
    return expense.paidBy == currentUserId;
  }
}

// ✅ CRIAR: Modelo local para display de participantes (não é entity de domínio)
class ExpenseParticipantDisplay {
  final String id;
  final String name;
  final String? avatarUrl;
  final double amount;
  final bool hasPaid;
  final DateTime? paidAt;

  const ExpenseParticipantDisplay({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.amount,
    required this.hasPaid,
    this.paidAt,
  });
}

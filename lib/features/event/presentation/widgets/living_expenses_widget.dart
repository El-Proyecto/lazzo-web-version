import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final Function(
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

                  // ✅ MUDAR: GroupExpenseCard → EventExpenseCard
                  return EventExpenseCard(
                    expense: expense,
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
    // ✅ CRIAR: Modelo local para participantes (em vez de entity separada)
    final participants = (expense.participantsOwe + expense.participantsPaid)
        .toSet() // Remove duplicados
        .map((id) => ExpenseParticipantDisplay(
              id: id,
              name: id == 'current_user' ? 'You' : id,
              avatarUrl: null,
              amount: _calculateUserAmount(expense),
              hasPaid: expense.participantsPaid.contains(id),
              paidAt: expense.participantsPaid.contains(id) ? expense.date : null,
            ))
        .toList();

    ExpenseDetailBottomSheet.show(
      context: context,
      expense: expense,
      participants: participants,
      isCurrentUserPayer: expense.paidBy == 'current_user',
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
    // TODO: Lógica real de cálculo (por agora split igualitário)
    final totalParticipants = 
        (expense.participantsOwe.length + expense.participantsPaid.length);
    return totalParticipants > 0 ? expense.amount / totalParticipants : 0.0;
  }

  bool _isOwedToUser(EventExpenseEntity expense) {
    return expense.paidBy == 'current_user';
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
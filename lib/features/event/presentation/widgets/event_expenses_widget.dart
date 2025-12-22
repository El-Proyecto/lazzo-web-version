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
    String paidById,
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

    final expensesAsync = ref.watch(eventExpensesProvider(eventId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const SizedBox.shrink();
        }

        final userTotal = _calculateUserTotal(expenses);
        final isOwedToUser = userTotal > 0;
        final allSettled = _areAllExpensesSettled(expenses);

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
                    allSettled
                        ? 'Settled'
                        : '${userTotal.abs().toStringAsFixed(2)}€',
                    style: AppText.bodyMediumEmph.copyWith(
                      color: allSettled
                          ? BrandColors.text2
                          : (isOwedToUser
                              ? BrandColors.planning
                              : BrandColors.cantVote),
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
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;

                  // Find payer name from participants
                  // final payerParticipant = participants.firstWhere(
                  //   (p) => p.id == expense.paidBy,
                  //   orElse: () => ExpenseParticipantOption(
                  //     id: expense.paidBy,
                  //     name: 'Unknown',
                  //     avatarUrl: null,
                  //   ),
                  // );

                  // Show "You" if current user is payer, otherwise show name
                  // final payerName = expense.paidBy == currentUserId
                  //     ? 'You'
                  //     : payerParticipant.name;

                  final isUserRelated = _isUserRelated(expense);

                  // Determine payment status
                  // Only show 'Paid' if user paid someone else's expense (not their own)
                  final hasUserPaid = currentUserId != null &&
                      expense.participantsPaid.contains(currentUserId) &&
                      expense.paidBy != currentUserId; // Not the creator
                  final paymentStatus = expense.isSettled
                      ? 'Settled'
                      : (hasUserPaid && isUserRelated ? 'Paid' : '');

                  // ✅ MUDAR: GroupExpenseCard → EventExpenseCard
                  return EventExpenseCard(
                    expense: expense,
                    eventName:
                        '', // Empty for event page (we're already in event context)
                    userAmount: userAmount,
                    totalAmount: expense.amount,
                    isOwedToUser: userOwed,
                    paymentStatus: paymentStatus,
                    isUserRelated: isUserRelated,
                    onTap: () => _showExpenseDetail(context, ref, expense),
                  );
                },
              ),

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

  void _showExpenseDetail(
      BuildContext context, WidgetRef ref, EventExpenseEntity expense) {
    // Get current user ID
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // 🔄 Buscar estado MAIS RECENTE da despesa antes de abrir bottom sheet
    final expensesState = ref.read(eventExpensesProvider(eventId));
    final latestExpense = expensesState.maybeWhen(
      data: (expenses) {
        try {
          return expenses.firstWhere((e) => e.id == expense.id);
        } catch (_) {
          return expense; // fallback se não encontrar
        }
      },
      orElse: () => expense,
    );

    // Find payer name usando dados atualizados
    final payerParticipant = participants.firstWhere(
      (p) => p.id == latestExpense.paidBy,
      orElse: () => ExpenseParticipantOption(
        id: latestExpense.paidBy,
        name: 'Unknown',
        avatarUrl: null,
      ),
    );

    // Show "You" if current user is payer, otherwise show name
    final payerName =
        latestExpense.paidBy == currentUserId ? 'You' : payerParticipant.name;

    // Construir lista de participantes com dados atualizados
    final participantDisplayList =
        (latestExpense.participantsOwe + latestExpense.participantsPaid)
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
      // Total participants = those who owe + those who already paid
      final totalParticipants =
          (latestExpense.participantsOwe + latestExpense.participantsPaid)
              .toSet()
              .length;
      final splitAmount = totalParticipants > 0
          ? latestExpense.amount / totalParticipants
          : 0.0;

      // ✅ Check if participant has paid (in participantsPaid list)
      final participantHasPaid = latestExpense.participantsPaid.contains(id);

      return ExpenseParticipantDisplay(
        id: id,
        name: participant.name,
        avatarUrl: participant.avatarUrl,
        amount: splitAmount,
        hasPaid: participantHasPaid, // ✅ Vem da lista atualizada
        paidAt: participantHasPaid ? latestExpense.date : null,
      );
    }).toList();

    ExpenseDetailBottomSheet.show(
      context: context,
      expense: latestExpense,
      payerName: payerName, // ✅ Pass payer name (shows "You" if current user)
      participants: participantDisplayList,
      isCurrentUserPayer: latestExpense.paidBy ==
          currentUserId, // ✅ Compare with actual user ID
      mode: mode,
      onMarkAsPaid: () async {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId == null) return;

        await ref.read(eventExpensesProvider(eventId).notifier).markAsPaid(
              expenseId: latestExpense.id,
              userId: currentUserId,
            );

        if (context.mounted) {
          Navigator.pop(context);
        }
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

  bool _areAllExpensesSettled(List<EventExpenseEntity> expenses) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return true;

    // Check if user has any pending expenses (owes or is owed)
    for (final expense in expenses) {
      if (expense.isSettled) continue;

      // Check if user owes money and hasn't paid
      if (expense.participantsOwe.contains(currentUserId) &&
          !expense.participantsPaid.contains(currentUserId)) {
        return false;
      }

      // Check if user is owed money and not everyone has paid
      if (expense.paidBy == currentUserId) {
        final hasUnpaidParticipants = expense.participantsOwe
            .any((id) => !expense.participantsPaid.contains(id));
        if (hasUnpaidParticipants) {
          return false;
        }
      }
    }

    return true;
  }

  double _calculateUserAmount(EventExpenseEntity expense) {
    // Get current user ID
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return 0.0;

    // Total number of participants (who owe + who already paid)
    final allParticipants =
        {...expense.participantsOwe, ...expense.participantsPaid}.length;
    if (allParticipants == 0) return 0.0;

    final amountPerPerson = expense.amount / allParticipants;

    // If user is the payer, calculate how much is owed to them (only unpaid participants)
    if (expense.paidBy == currentUserId) {
      // Count only those who haven't paid yet
      final unpaidCount = expense.participantsOwe.length;
      return amountPerPerson * unpaidCount;
    }

    // If user is not part of this expense, return 0
    final isUserInExpense = expense.participantsOwe.contains(currentUserId) ||
        expense.participantsPaid.contains(currentUserId);
    if (!isUserInExpense) return 0.0;

    // If user already paid their part, return 0
    if (expense.participantsPaid.contains(currentUserId)) return 0.0;

    // User still owes their share
    return amountPerPerson;
  }

  bool _isOwedToUser(EventExpenseEntity expense) {
    // Get current user ID
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    // User is owed money if they paid the expense AND there are unpaid participants
    if (expense.paidBy != currentUserId) return false;

    // Check if anyone still owes money
    final hasUnpaidParticipants = expense.participantsOwe
        .any((id) => !expense.participantsPaid.contains(id));

    return hasUnpaidParticipants;
  }

  bool _isUserRelated(EventExpenseEntity expense) {
    // Get current user ID
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    // User is related if they created it, owe, or already paid
    return expense.paidBy == currentUserId ||
        expense.participantsOwe.contains(currentUserId) ||
        expense.participantsPaid.contains(currentUserId);
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

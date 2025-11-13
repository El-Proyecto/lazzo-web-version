import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/dialogs/add_expense_bottom_sheet.dart';
import 'group_expense_card.dart';
import 'expense_detail_bottom_sheet.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../domain/entities/expense_participant_entity.dart';
import '../providers/event_providers.dart';
import 'chat_preview_widget.dart'; // For ChatMode enum

/// Widget showing event expenses in both planning and living modes
/// Uses same cards as group hub expenses section
class EventExpensesWidget extends ConsumerWidget {
  final String eventId;
  final List<ExpenseParticipantOption> participants;
  final ChatMode mode;
  final Function(
    String title,
    List<String> paidByIds,
    List<String> payerIds,
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
    // TODO: Replace groupId with actual eventId when P2 implements event expenses
    final expensesAsync = ref.watch(groupExpensesProvider('event-1'));

    return expensesAsync.when(
      data: (expenses) {
        // Don't show widget if no expenses (user can use top action row button)
        if (expenses.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calculate total owed to/by user
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
                  // Total amount (green = owed to user, red = user owes)
                  Text(
                    '${isOwedToUser ? '+' : '-'}€${userTotal.abs().toStringAsFixed(2)}',
                    style: AppText.bodyMediumEmph.copyWith(
                      color: isOwedToUser
                          ? const Color(0xFF10B981) // Green
                          : const Color(0xFFEF4444), // Red
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

                  return GroupExpenseCard(
                    expense: expense,
                    eventName: '', // Empty for living mode - all same event
                    userAmount: userAmount,
                    totalAmount: expense.amount,
                    isOwedToUser: userOwed,
                    paymentStatus: _getPaymentStatus(expense),
                    onTap: () => _showExpenseDetail(context, expense),
                  );
                },
              ),
              const SizedBox(height: Gaps.md),

              // Add Expense button (full width, color based on mode)
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

  void _showExpenseDetail(BuildContext context, GroupExpenseEntity expense) {
    // Generate mock participants based on expense participant IDs
    final participants = (expense.participantIds ?? [])
        .map((id) => ExpenseParticipant(
              id: id,
              name: id == 'current_user' ? 'You' : id,
              avatarUrl: null,
              amount: _calculateUserAmount(expense),
              hasPaid: expense.isSettled || id == expense.paidBy,
              paidAt: (expense.isSettled || id == expense.paidBy)
                  ? expense.date
                  : null,
            ))
        .toList();

    ExpenseDetailBottomSheet.show(
      context: context,
      expense: expense,
      participants: participants,
      isCurrentUserPayer: expense.paidBy == 'current_user',
      mode: mode,
      onMarkAsPaid: () {
        // TODO: Implement mark as paid
      },
      onNotifyParticipant: (participantId) {
        // TODO: Implement notify participant
      },
    );
  }

  // Calculate total amount owed to/by user across all expenses
  double _calculateUserTotal(List<GroupExpenseEntity> expenses) {
    double total = 0;
    for (final expense in expenses) {
      // Skip settled expenses in total calculation
      if (expense.isSettled) continue;

      final amount = _calculateUserAmount(expense);
      final isOwed = _isOwedToUser(expense);
      total += isOwed ? amount : -amount;
    }
    return total;
  }

  // Helper methods - TODO: Replace with actual logic from P2
  double _calculateUserAmount(GroupExpenseEntity expense) {
    // Simplified calculation - will be replaced with actual logic
    return expense.amount / 2;
  }

  bool _isOwedToUser(GroupExpenseEntity expense) {
    // TODO: Check if current user is owed money
    // For now, check if current user paid
    return expense.paidBy == 'current_user';
  }

  String _getPaymentStatus(GroupExpenseEntity expense) {
    return expense.isSettled ? 'Settled' : '';
  }
}

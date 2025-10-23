import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../providers/group_hub_providers.dart';
import 'group_expense_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class GroupExpensesSection extends ConsumerWidget {
  final String groupId;

  const GroupExpensesSection({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
          child: Text(
            'Expenses',
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
        ),

        const SizedBox(height: Gaps.md),

        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
          child: expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return _buildEmptyState();
              }
              return _buildExpensesList(expenses);
            },
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesList(List<GroupExpenseEntity> expenses) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: Gaps.md),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return GroupExpenseCard(
          expense: expense,
          eventName: _getEventName(expense.id),
          userAmount: _calculateUserAmount(expense),
          totalAmount: expense.amount,
          isOwedToUser: _isOwedToUser(expense),
          paymentStatus: _getPaymentStatus(expense),
          onTap: () => _handleExpenseTap(expense),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: BrandColors.bg3, width: 1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: BrandColors.text2,
          ),
          const SizedBox(height: Gaps.md),
          Text(
            'No expenses yet',
            style: AppText.bodyMediumEmph.copyWith(
              color: BrandColors.text2,
            ),
          ),
          const SizedBox(height: Gaps.xs),
          Text(
            'Group expenses will appear here',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: BrandColors.bg3, width: 1),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: BrandColors.bg3, width: 1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: BrandColors.cantVote,
          ),
          const SizedBox(height: Gaps.md),
          Text(
            'Error loading expenses',
            style: AppText.bodyMediumEmph.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  // Mock methods - in real implementation these would come from proper data sources
  String _getEventName(String expenseId) {
    switch (expenseId) {
      case '1':
        return 'Churrasco Casa Marco';
      case '2':
        return 'Concert Night';
      case '3':
        return 'Weekend Trip';
      default:
        return 'Group Event';
    }
  }

  double _calculateUserAmount(GroupExpenseEntity expense) {
    // Mock calculation - in real app this would be calculated based on split logic
    return expense.amount / 4; // Assuming 4 people split
  }

  bool _isOwedToUser(GroupExpenseEntity expense) {
    // Fixed logic: if current user paid, others owe them (positive amount)
    return expense.paidBy == 'current_user';
  }

  String _getPaymentStatus(GroupExpenseEntity expense) {
    if (expense.isSettled) {
      return 'Settled';
    }

    // If current user paid but not everyone has paid back
    if (expense.paidBy == 'current_user' && !expense.isSettled) {
      return 'Paid';
    }

    return ''; // Show total amount instead
  }

  void _handleExpenseTap(GroupExpenseEntity expense) {
    // Handle expense tap - could open detail view
    print('Tapped expense: ${expense.description}');
  }
}

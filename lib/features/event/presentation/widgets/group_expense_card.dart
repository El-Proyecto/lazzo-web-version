import 'package:flutter/material.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class GroupExpenseCard extends StatelessWidget {
  final GroupExpenseEntity expense;
  final String eventName;
  final double userAmount;
  final double totalAmount;
  final bool isOwedToUser;
  final String paymentStatus; // "Paid", "Settled", or empty
  final VoidCallback? onTap;

  const GroupExpenseCard({
    super.key,
    required this.expense,
    required this.eventName,
    required this.userAmount,
    required this.totalAmount,
    required this.isOwedToUser,
    required this.paymentStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlH),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: BrandColors.bg3, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and amount/status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expense.description,
                    style: AppText.bodyMediumEmph.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Show status (Settled/Paid) or amount
                Text(
                  paymentStatus.isNotEmpty
                      ? paymentStatus
                      : '${isOwedToUser ? '+' : '-'}€${userAmount.toStringAsFixed(2)}',
                  style: AppText.bodyMediumEmph.copyWith(
                    color: paymentStatus.isNotEmpty
                        ? BrandColors.text1
                        : (isOwedToUser
                            ? BrandColors.planning
                            : BrandColors.cantVote),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: Gaps.xs),

            // Date and Event info on left, Status or Total on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date and Event (hide event name if empty)
                Expanded(
                  child: Text(
                    eventName.isEmpty
                        ? _formatDate(expense.date)
                        : '${_formatDate(expense.date)} • $eventName',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Total amount (always show)
                Text(
                  'Total: €${totalAmount.toStringAsFixed(2)}',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}';
    }
  }
}

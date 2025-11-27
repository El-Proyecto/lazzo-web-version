import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../expense/domain/entities/event_expense_entity.dart';

/// Card displaying a single event expense
class EventExpenseCard extends StatelessWidget {
  final EventExpenseEntity expense;
  final String payerName; // ✅ Name of person who paid
  final double userAmount;
  final bool isOwedToUser;
  final VoidCallback? onTap;

  const EventExpenseCard({
    super.key,
    required this.expense,
    required this.payerName,
    required this.userAmount,
    required this.isOwedToUser,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.sectionH),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            // Expense icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandColors.bg2,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: BrandColors.text2,
                size: 20,
              ),
            ),
            const SizedBox(width: Gaps.md),

            // Expense details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: AppText.bodyMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Gaps.xxs),
                  Text(
                    'Paid by $payerName', // ✅ Show name instead of UUID
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Amount (green if owed to user, red if user owes)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isOwedToUser ? '+' : '-'}€${userAmount.toStringAsFixed(2)}',
                  style: AppText.bodyMediumEmph.copyWith(
                    color: isOwedToUser
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expense.isSettled) ...[
                  const SizedBox(height: Gaps.xxs),
                  Text(
                    'Settled',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
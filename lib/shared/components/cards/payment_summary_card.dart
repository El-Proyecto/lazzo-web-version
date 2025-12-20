import 'package:flutter/material.dart';
import '../../../features/home/domain/entities/payment_summary_entity.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Compact payment summary card for home page
/// Shows user photo/name, status, amount, and expense count
class PaymentSummaryCard extends StatelessWidget {
  final PaymentSummaryEntity payment;
  final VoidCallback? onTap;

  const PaymentSummaryCard({
    super.key,
    required this.payment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format name with initials for second name if it would be cut off
    final nameParts = payment.userName.split(' ');
    final displayName = nameParts.length > 1
        ? '${nameParts[0]} ${nameParts[1].substring(0, 1)}.'
        : payment.userName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.sectionH),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo + Name row
            Row(
              children: [
                // User photo/initial
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BrandColors.bg3,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Center(
                    child: Text(
                      payment.userName.isNotEmpty
                          ? payment.userName.substring(0, 1).toUpperCase()
                          : '💸',
                      style: AppText.bodyLarge.copyWith(
                        color: BrandColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Gaps.sm),

                // User name
                Expanded(
                  child: Text(
                    displayName,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gaps.sm),

            // Status line
            Text(
              payment.youOwe ? 'You owe' : 'You lend',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
            ),
            const SizedBox(height: Gaps.xs / 2),

            // Amount
            Text(
              '${payment.amount.abs().toStringAsFixed(2)}€',
              style: AppText.bodyLarge.copyWith(
                color: payment.isOwedToYou
                    ? BrandColors.planning // Green if they owe you
                    : BrandColors.cantVote, // Red if you owe them
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: Gaps.xs / 2),

            // Number of expenses
            Text(
              '${payment.expenseCount} ${payment.expenseCount == 1 ? 'expense' : 'expenses'}',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

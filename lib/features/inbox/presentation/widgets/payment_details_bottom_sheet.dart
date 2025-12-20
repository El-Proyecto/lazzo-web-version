import 'package:flutter/material.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_group.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/widgets/grabber_bar.dart';

class PaymentDetailsBottomSheet extends StatelessWidget {
  final PaymentGroup paymentGroup;
  final Function(PaymentEntity)? onPaymentTap;

  const PaymentDetailsBottomSheet({
    super.key,
    required this.paymentGroup,
    this.onPaymentTap,
  });

  static Future<void> show({
    required BuildContext context,
    required PaymentGroup paymentGroup,
    Function(PaymentEntity)? onPaymentTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Radii.md),
            topRight: Radius.circular(Radii.md),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GrabberBar(),

            // Custom header with name and amount on same line
            Padding(
              padding: const EdgeInsets.all(Pads.sectionH),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    paymentGroup.userName,
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                  Text(
                    '${paymentGroup.totalAmount.toStringAsFixed(2)}€',
                    style: AppText.titleMediumEmph.copyWith(
                      color: paymentGroup.isOwedToUser
                          ? BrandColors.planning
                          : BrandColors.cantVote,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: Pads.sectionH,
                    right: Pads.sectionH,
                    bottom: Pads.sectionH),
                child: PaymentDetailsBottomSheet(
                  paymentGroup: paymentGroup,
                  onPaymentTap: onPaymentTap,
                ),
              ),
            ),

            // Mark as paid button (only show if user owes money)
            if (!paymentGroup.isOwedToUser)
              Padding(
                padding: const EdgeInsets.only(
                  left: Pads.sectionH,
                  right: Pads.sectionH,
                  bottom: Pads.sectionH,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement mark all as paid functionality
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.planning,
                      foregroundColor: BrandColors.text1,
                      padding: const EdgeInsets.symmetric(
                        vertical: Gaps.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                    child: Text(
                      'Mark ${paymentGroup.totalAmount.toStringAsFixed(2)}€ as paid',
                      style: AppText.labelLarge.copyWith(
                        color: BrandColors.text1,
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: paymentGroup.payments.length,
      separatorBuilder: (context, index) => const SizedBox(height: Gaps.md),
      itemBuilder: (context, index) {
        final payment = paymentGroup.payments[index];
        return _buildPaymentItem(payment);
      },
    );
  }

  Widget _buildPaymentItem(PaymentEntity payment) {
    // Each individual payment has its own direction
    // Check if current user is the creditor (toUserId) = they owe us = green/+
    // Or if current user is the debtor (fromUserId) = we owe them = red/-
    final currentUserId = paymentGroup.userId; // This is the OTHER person's ID

    // If payment.fromUserId == other person → they owe us (green, +)
    // If payment.toUserId == other person → we owe them (red, -)
    final paymentIsOwedToUser = payment.fromUserId == currentUserId;

    return GestureDetector(
      onTap: () => onPaymentTap?.call(payment),
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlH),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: BrandColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    payment.title,
                    style: AppText.bodyMediumEmph.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${payment.amount.toStringAsFixed(2)}€',
                  style: AppText.bodyMediumEmph.copyWith(
                    color: paymentIsOwedToUser
                        ? BrandColors.planning
                        : BrandColors.cantVote,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: Gaps.xs),

            // Event and Group info
            Row(
              children: [
                const Icon(Icons.event, size: 14, color: BrandColors.text2),
                const SizedBox(width: Gaps.xs / 2),
                Text(
                  payment.eventName ?? 'Event',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
                const SizedBox(width: Gaps.sm),
                const Icon(Icons.group, size: 14, color: BrandColors.text2),
                const SizedBox(width: Gaps.xs / 2),
                Text(
                  payment.groupName ?? 'Group',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(payment.createdAt),
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

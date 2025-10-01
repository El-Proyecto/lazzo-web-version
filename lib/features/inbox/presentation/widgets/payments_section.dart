import 'package:flutter/material.dart';
import '../../domain/entities/payment_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'inbox_payment_card.dart';

class PaymentsSection extends StatelessWidget {
  final List<PaymentEntity> owedToUser;
  final List<PaymentEntity> userOwes;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(PaymentEntity)? onPaymentTap;
  final Function(PaymentEntity)? onMarkAsPaid;

  const PaymentsSection({
    super.key,
    required this.owedToUser,
    required this.userOwes,
    this.isLoading = false,
    this.onRefresh,
    this.onPaymentTap,
    this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      );
    }

    final hasOwedToUser = owedToUser.isNotEmpty;
    final hasUserOwes = userOwes.isNotEmpty;

    if (!hasOwedToUser && !hasUserOwes) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      color: BrandColors.planning,
      backgroundColor: BrandColors.bg2,
      child: ListView(
        padding: const EdgeInsets.all(Insets.screenH),
        children: [
          if (hasOwedToUser) ...[
            _buildSectionHeader('Owed to you', _calculateTotal(owedToUser)),
            const SizedBox(height: Gaps.md),
            ...owedToUser.map(
              (payment) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.md),
                child: InboxPaymentCard(
                  payment: payment,
                  isOwedToUser: true,
                  onTap: () => onPaymentTap?.call(payment),
                  onNotify: () => _handleNotifyPayment(payment),
                ),
              ),
            ),
          ],
          if (hasUserOwes) ...[
            if (hasOwedToUser) const SizedBox(height: Gaps.lg),
            _buildSectionHeader('You owe', _calculateTotal(userOwes)),
            const SizedBox(height: Gaps.md),
            ...userOwes.map(
              (payment) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.md),
                child: InboxPaymentCard(
                  payment: payment,
                  isOwedToUser: false,
                  onTap: () => onPaymentTap?.call(payment),
                  onMarkAsPaid: () => _handleMarkAsPaid(payment),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.md,
        vertical: Gaps.sm,
      ),
      decoration: ShapeDecoration(
        color: BrandColors.bg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
          ),
          Text(
            '€${total.toStringAsFixed(2)}',
            style: AppText.titleMediumEmph.copyWith(
              color: title.contains('owe')
                  ? BrandColors.recap
                  : BrandColors.planning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: ShapeDecoration(
                color: BrandColors.bg3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 32,
                color: BrandColors.text2,
              ),
            ),
            const SizedBox(height: Gaps.lg),
            Text(
              'No pending payments',
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              'When you have payments to make or receive, they\'ll be organized here.',
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal(List<PaymentEntity> payments) {
    return payments
        .where((p) => p.status != PaymentStatus.paid)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  void _handleNotifyPayment(PaymentEntity payment) {
    // Send notification to remind payment - card should NOT disappear
    // This is just a reminder, not a payment confirmation
    print('Sending payment reminder for payment: ${payment.id}');
    // TODO: Implement actual notification sending logic
    // The card stays visible because the payment is still pending
  }

  void _handleMarkAsPaid(PaymentEntity payment) {
    // This would trigger the mark as paid action
    onMarkAsPaid?.call(payment);
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_group.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'inbox_payment_card.dart';
import 'payment_details_bottom_sheet.dart';

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

    // Group payments by user (pass all payments for net calculation)
    final allPayments = [...owedToUser, ...userOwes];
    final owedToUserGroups = PaymentGroup.groupByUser(
      allPayments,
      true,
      _getUserName,
    );
    final userOwesGroups = PaymentGroup.groupByUser(
      allPayments,
      false,
      _getUserName,
    );
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      color: BrandColors.planning,
      backgroundColor: BrandColors.bg2,
      child: ListView(
        padding: const EdgeInsets.all(Insets.screenTop),
        children: [
          if (hasOwedToUser) ...[
            _buildSectionHeader(
              'Owed to you',
              _calculateGroupTotal(owedToUserGroups),
            ),
            const SizedBox(height: Gaps.md),
            ...owedToUserGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.md),
                child: InboxPaymentCard(
                  payment: _createGroupPayment(group),
                  isOwedToUser: true,
                  onTap: () => _showPaymentDetails(context, group),
                  onNotify: () => _handleNotifyPayment(group),
                ),
              ),
            ),
          ],
          if (hasUserOwes) ...[
            if (hasOwedToUser) const SizedBox(height: Gaps.md),
            _buildSectionHeader(
              'You owe',
              _calculateGroupTotal(userOwesGroups),
            ),
            const SizedBox(height: Gaps.md),
            ...userOwesGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.md),
                child: InboxPaymentCard(
                  payment: _createGroupPayment(group),
                  isOwedToUser: false,
                  onTap: () => _showPaymentDetails(context, group),
                  onMarkAsPaid: () => _handleMarkAsPaid(group),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double total) {
    return Row(
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
                ? BrandColors.cantVote
                : BrandColors.planning,
          ),
        ),
      ],
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

  double _calculateGroupTotal(List<PaymentGroup> groups) {
    return groups.fold(0.0, (sum, group) => sum + group.totalAmount);
  }

  void _handleNotifyPayment(PaymentGroup group) {
    // Send notification to remind payment for all payments in group
    print('Sending payment reminder for payment group: ${group.userId}');
    // TODO: Implement actual notification sending logic
    // The cards stay visible because the payments are still pending
  }

  void _handleMarkAsPaid(PaymentGroup group) {
    // This would trigger the mark as paid action for all payments in group
    for (final payment in group.payments) {
      onMarkAsPaid?.call(payment);
    }
  }

  String _getUserName(String userId) {
    // In a real app, this would come from a User entity or service
    switch (userId) {
      case 'ana':
        return 'Ana';
      case 'maria':
        return 'Maria';
      case 'joao':
        return 'João';
      case 'sofia':
        return 'Sofia';
      default:
        return 'Unknown User';
    }
  }

  PaymentEntity _createGroupPayment(PaymentGroup group) {
    // Create a summary payment entity representing the group
    return PaymentEntity(
      id: 'group_${group.userId}',
      title: group.displaySubtitle,
      description: group.displaySubtitle,
      type: PaymentType.split,
      status: PaymentStatus.pending,
      amount: group.totalAmount,
      createdAt: DateTime.now(),
      fromUserId: group.isOwedToUser ? group.userId : 'current_user',
      toUserId: group.isOwedToUser ? 'current_user' : group.userId,
    );
  }

  void _showPaymentDetails(BuildContext context, PaymentGroup group) {
    PaymentDetailsBottomSheet.show(
      context: context,
      paymentGroup: group,
      onPaymentTap: (payment) {
        // Handle individual payment tap if needed
        Navigator.of(context).pop();
      },
    );
  }
}

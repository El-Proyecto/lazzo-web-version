import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_group.dart';
import '../providers/payments_provider.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'inbox_payment_card.dart';
import 'payment_details_bottom_sheet.dart';

class PaymentsSection extends ConsumerStatefulWidget {
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
  ConsumerState<PaymentsSection> createState() => _PaymentsSectionState();
}

class _PaymentsSectionState extends ConsumerState<PaymentsSection> {
  @override
  void initState() {
    super.initState();
    // Check if there's a selected payment user ID after build and tab is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure tab animation completes
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkAndOpenPaymentDetails();
        }
      });
    });
  }

  void _checkAndOpenPaymentDetails() {
    final selectedUserId = ref.read(selectedPaymentUserIdProvider);
    if (selectedUserId != null && mounted) {
      // Clear the selection immediately
      ref.read(selectedPaymentUserIdProvider.notifier).state = null;

      // Find the payment group for this user
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final allPayments = [...widget.owedToUser, ...widget.userOwes];

      // Try in "owed to user" groups first
      final owedToUserGroups = PaymentGroup.groupByUser(
        allPayments,
        true,
        currentUserId,
        _getUserName,
      );

      final owedGroup = owedToUserGroups.cast<PaymentGroup?>().firstWhere(
            (g) => g?.userId == selectedUserId,
            orElse: () => null,
          );

      if (owedGroup != null) {
        _showPaymentDetails(context, owedGroup);
        return;
      }

      // Try in "user owes" groups
      final userOwesGroups = PaymentGroup.groupByUser(
        allPayments,
        false,
        currentUserId,
        _getUserName,
      );

      final owesGroup = userOwesGroups.cast<PaymentGroup?>().firstWhere(
            (g) => g?.userId == selectedUserId,
            orElse: () => null,
          );

      if (owesGroup != null) {
        _showPaymentDetails(context, owesGroup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      );
    }

    // final hasOwedToUser = widget.owedToUser.isNotEmpty;
    // final hasUserOwes = widget.userOwes.isNotEmpty;

    // Group payments by user (pass all payments for net calculation)
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final allPayments = [...widget.owedToUser, ...widget.userOwes];
    final owedToUserGroups = PaymentGroup.groupByUser(
      allPayments,
      true,
      currentUserId,
      _getUserName,
    );
    final userOwesGroups = PaymentGroup.groupByUser(
      allPayments,
      false,
      currentUserId,
      _getUserName,
    );

    // Check if there are any groups after netting (not raw payments)
    final hasOwedToUserGroups = owedToUserGroups.isNotEmpty;
    final hasUserOwesGroups = userOwesGroups.isNotEmpty;

    if (!hasOwedToUserGroups && !hasUserOwesGroups) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      color: BrandColors.planning,
      backgroundColor: BrandColors.bg2,
      child: ListView(
        padding: const EdgeInsets.all(Insets.screenTop),
        children: [
          if (hasOwedToUserGroups) ...[
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
          if (hasUserOwesGroups) ...[
            if (hasOwedToUserGroups) const SizedBox(height: Gaps.md),
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
          '${total.toStringAsFixed(2)}€',
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
    // TODO: Implement actual notification sending logic
  }

  Future<void> _handleMarkAsPaid(PaymentGroup group) async {
    // Mark ALL payments between current user and this person as paid
    // This includes both directions (what I owe them + what they owe me)
    // Because settling the net balance means all underlying debts are resolved

    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final otherUserId = group.userId;

    // Find all payments involving both users (in both directions)
    final allPayments = [...widget.owedToUser, ...widget.userOwes];
    final paymentsToSettle = allPayments.where((payment) {
      return (payment.fromUserId == currentUserId &&
              payment.toUserId == otherUserId) ||
          (payment.fromUserId == otherUserId &&
              payment.toUserId == currentUserId);
    }).toList();

    // Mark all of them as paid
    for (final payment in paymentsToSettle) {
      widget.onMarkAsPaid?.call(payment);
    }

    // Wait a bit for the database updates to complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Refresh payment lists to reflect the changes
    ref.invalidate(paymentsOwedToUserProvider);
    ref.invalidate(paymentsUserOwesProvider);
  }

  String _getUserName(String userId) {
    // Find user name from payments (already populated by DTO from view)
    final allPayments = [...widget.owedToUser, ...widget.userOwes];

    for (final payment in allPayments) {
      if (payment.fromUserId == userId && payment.fromUserName != null) {
        return payment.fromUserName!;
      }
      if (payment.toUserId == userId && payment.toUserName != null) {
        return payment.toUserName!;
      }
    }

    // Fallback
    return 'User ${userId.substring(0, 8)}';
  }

  PaymentEntity _createGroupPayment(PaymentGroup group) {
    // Create a summary payment entity representing the group
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final currentUserName = 'You'; // Could be fetched from profile if needed

    return PaymentEntity(
      id: 'group_${group.userId}',
      title: group.displaySubtitle,
      description: group.displaySubtitle,
      type: PaymentType.split,
      status: PaymentStatus.pending,
      amount: group.totalAmount,
      createdAt: DateTime.now(),
      fromUserId: group.isOwedToUser ? group.userId : currentUserId,
      fromUserName: group.isOwedToUser ? group.userName : currentUserName,
      toUserId: group.isOwedToUser ? currentUserId : group.userId,
      toUserName: group.isOwedToUser ? currentUserName : group.userName,
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

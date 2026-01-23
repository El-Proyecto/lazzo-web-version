import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_group.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/widgets/grabber_bar.dart';
import '../../../../routes/app_router.dart';

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
    Function(List<PaymentEntity>)? onMarkAsPaid,
  }) {
    // Calculate how much the current user owes (for Mark as Paid button)
    // Even if they're in "Owed to you" section (net positive), user might still owe some expenses
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final paymentsUserOwes = paymentGroup.payments
        .where((p) =>
            p.fromUserId == currentUserId && p.status != PaymentStatus.paid)
        .toList();
    final amountUserOwes =
        paymentsUserOwes.fold(0.0, (sum, p) => sum + p.amount);

    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
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

            // Content - List of payments (shrinkWrap for dynamic height)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(
                  left: Pads.sectionH,
                  right: Pads.sectionH,
                  bottom: Pads.sectionH,
                ),
                itemCount: paymentGroup.payments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: Gaps.md),
                itemBuilder: (context, index) {
                  final payment = paymentGroup.payments[index];
                  return _buildPaymentItem(
                    payment: payment,
                    currentUserId: paymentGroup.userId,
                    context: context,
                    onPaymentTap: onPaymentTap,
                  );
                },
              ),
            ),

            // Mark as paid button - show if user owes any amount to this person
            // (even if net balance shows they owe us more)
            if (amountUserOwes > 0)
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
                      // Mark all payments where user owes as paid
                      if (onMarkAsPaid != null && paymentsUserOwes.isNotEmpty) {
                        onMarkAsPaid(paymentsUserOwes);
                      }
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
                      'Mark ${amountUserOwes.toStringAsFixed(2)}€ as paid',
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

  static Widget _buildPaymentItem({
    required PaymentEntity payment,
    required String currentUserId,
    required BuildContext context,
    Function(PaymentEntity)? onPaymentTap,
  }) {
    // Each individual payment has its own direction
    // Check if current user is the creditor (toUserId) = they owe us = green/+
    // Or if current user is the debtor (fromUserId) = we owe them = red/-
    // If payment.fromUserId == other person → they owe us (green, +)
    // If payment.toUserId == other person → we owe them (red, -)
    final paymentIsOwedToUser = payment.fromUserId == currentUserId;

    return GestureDetector(
      onTap: () async {
                onPaymentTap?.call(payment);
        if (payment.eventId != null) {
                    await _navigateToEvent(context, payment.eventId!);
        } else {
                  }
      },
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Gaps.sm),
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
                Flexible(
                  flex: 1,
                  child: Text(
                    payment.eventName ?? 'Event',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Gaps.sm),
                const Icon(Icons.group, size: 14, color: BrandColors.text2),
                const SizedBox(width: Gaps.xs / 2),
                Flexible(
                  flex: 1,
                  child: Text(
                    payment.groupName ?? 'Group',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  static String _formatDate(DateTime date) {
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

  /// Navigate to event based on its current status
  /// pending/confirmed → event page
  /// living → eventLiving page
  /// recap/ended → memory page (both have memories)
  static Future<void> _navigateToEvent(
      BuildContext context, String eventId) async {
        try {
      // Fetch event status from events table
            final response = await Supabase.instance.client
          .from('events')
          .select('status')
          .eq('id', eventId)
          .maybeSingle();

      
      if (response == null || !context.mounted) {
                return;
      }

      final status = response['status'] as String?;
      
      // Close bottom sheet first
            Navigator.of(context).pop();

      // Navigate based on status
      // Event lifecycle: pending → confirmed → living → recap → ended
      // Both recap and ended have memories and go to memory page
      if (status == 'living') {
                await Navigator.pushNamed(
          context,
          AppRouter.eventLiving,
          arguments: {'eventId': eventId},
        );
      } else if (status == 'recap' || status == 'ended') {
                await Navigator.pushNamed(
          context,
          AppRouter.memory,
          arguments: {'memoryId': eventId},
        );
      } else if (status == 'pending' || status == 'confirmed') {
                await Navigator.pushNamed(
          context,
          AppRouter.event,
          arguments: {'eventId': eventId},
        );
      } else {
              }
    } catch (e) {
            // Silent fail - if can't fetch event status, don't navigate
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget is no longer used directly, keeping for compatibility
    return const SizedBox.shrink();
  }
}

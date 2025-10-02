import 'package:flutter/material.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_group.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'payment_details_bottom_sheet.dart';

class InboxPaymentGroupCard extends StatefulWidget {
  final PaymentGroup paymentGroup;
  final VoidCallback? onMarkAsPaid;
  final VoidCallback? onNotify;

  const InboxPaymentGroupCard({
    super.key,
    required this.paymentGroup,
    this.onMarkAsPaid,
    this.onNotify,
  });

  @override
  State<InboxPaymentGroupCard> createState() => _InboxPaymentGroupCardState();
}

class _InboxPaymentGroupCardState extends State<InboxPaymentGroupCard> {
  bool _isNotificationSent = false;
  bool _showCooldownBanner = false;
  DateTime? _lastNotificationTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showPaymentDetails(context),
          child: Container(
            padding: const EdgeInsets.all(Insets.screenH),
            decoration: BoxDecoration(
              color: BrandColors.bg2,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: BrandColors.bg3, width: 1),
            ),
            child: Row(
              children: [
                // Profile photo or initial
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BrandColors.bg3,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Center(
                    child: Text(
                      widget.paymentGroup.userName.isNotEmpty
                          ? widget.paymentGroup.userName
                                .substring(0, 1)
                                .toUpperCase()
                          : '💸',
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: Gaps.sm),

                // Content area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment description with styled amount
                      RichText(
                        text: TextSpan(
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text1,
                          ),
                          children: [
                            TextSpan(
                              text: '${widget.paymentGroup.userName} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: widget.paymentGroup.isOwedToUser
                                  ? 'owes you '
                                  : 'you owe ',
                            ),
                            TextSpan(
                              text:
                                  '€${widget.paymentGroup.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: widget.paymentGroup.isOwedToUser
                                    ? BrandColors
                                          .planning // Green for "owed to you"
                                    : BrandColors.cantVote, // Red for "you owe"
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: Gaps.xs / 2),

                      // Subtitle showing expense title or count
                      Text(
                        widget.paymentGroup.displaySubtitle,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: Gaps.sm),

                // Action button or chevron
                if (widget.paymentGroup.isOwedToUser)
                  _buildNotificationButton()
                else if (_hasAnyPendingPayments())
                  _buildMarkAsPaidButton()
                else
                  const Icon(
                    Icons.chevron_right,
                    color: BrandColors.text2,
                    size: IconSizes.md,
                  ),
              ],
            ),
          ),
        ),

        // Notification cooldown banner
        if (_showCooldownBanner) _buildCooldownBanner(),
      ],
    );
  }

  void _showPaymentDetails(BuildContext context) {
    PaymentDetailsBottomSheet.show(
      context: context,
      paymentGroup: widget.paymentGroup,
      onPaymentTap: (payment) {
        // Handle individual payment tap if needed
        Navigator.of(context).pop();
      },
    );
  }

  bool _hasAnyPendingPayments() {
    return widget.paymentGroup.payments.any(
      (payment) => payment.status == PaymentStatus.pending,
    );
  }

  Widget _buildNotificationButton() {
    final isOnCooldown = _isOnCooldown();

    return IconButton(
      onPressed: isOnCooldown ? null : _handleNotificationSent,
      icon: Icon(
        _isNotificationSent ? Icons.check : Icons.notifications_outlined,
        size: IconSizes.md,
        color: isOnCooldown
            ? BrandColors.text2.withOpacity(0.5)
            : (_isNotificationSent ? BrandColors.planning : BrandColors.text1),
      ),
    );
  }

  Widget _buildMarkAsPaidButton() {
    return IconButton(
      onPressed: () => widget.onMarkAsPaid?.call(),
      icon: const Icon(
        Icons.check_circle_outline,
        size: IconSizes.md,
        color: BrandColors.planning,
      ),
    );
  }

  Widget _buildCooldownBanner() {
    return Container(
      margin: const EdgeInsets.only(top: Gaps.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH,
        vertical: Gaps.xs,
      ),
      decoration: BoxDecoration(
        color: BrandColors.planning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(
          color: BrandColors.planning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: IconSizes.sm, color: BrandColors.planning),
          const SizedBox(width: Gaps.xs),
          Expanded(
            child: Text(
              'Notification sent! Please wait 10 minutes before sending another.',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.planning,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showCooldownBanner = false),
            icon: const Icon(
              Icons.close,
              size: IconSizes.sm,
              color: BrandColors.planning,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  bool _isOnCooldown() {
    if (_lastNotificationTime == null) return false;
    final cooldownPeriod = const Duration(minutes: 10);
    return DateTime.now().difference(_lastNotificationTime!) < cooldownPeriod;
  }

  void _handleNotificationSent() {
    setState(() {
      _isNotificationSent = true;
      _showCooldownBanner = true;
      _lastNotificationTime = DateTime.now();
    });

    widget.onNotify?.call();

    // Reset the notification sent state after some time
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isNotificationSent = false);
      }
    });
  }
}

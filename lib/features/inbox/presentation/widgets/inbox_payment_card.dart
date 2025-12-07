import 'package:flutter/material.dart';
import '../../domain/entities/payment_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class InboxPaymentCard extends StatefulWidget {
  final PaymentEntity payment;
  final bool isOwedToUser;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsPaid;
  final VoidCallback? onNotify;

  const InboxPaymentCard({
    super.key,
    required this.payment,
    required this.isOwedToUser,
    this.onTap,
    this.onMarkAsPaid,
    this.onNotify,
  });

  @override
  State<InboxPaymentCard> createState() => _InboxPaymentCardState();
}

class _InboxPaymentCardState extends State<InboxPaymentCard> {
  bool _isNotificationSent = false;
  bool _showCooldownBanner = false;
  DateTime? _lastNotificationTime;

  @override
  Widget build(BuildContext context) {
    final String userName = _getUserName();

    return Column(
      children: [
        GestureDetector(
          onTap: widget.onTap,
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
                      userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase()
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
                              text: userName.isNotEmpty
                                  ? '$userName '
                                  : 'Someone ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: widget.isOwedToUser
                                  ? 'owes you '
                                  : 'you owe ',
                            ),
                            TextSpan(
                              text:
                                  '€${widget.payment.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: widget.isOwedToUser
                                    ? BrandColors
                                        .planning // Green for "owed to you"
                                    : BrandColors.cantVote, // Red for "you owe"
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (widget.payment.description.isNotEmpty) ...[
                        const SizedBox(
                          height: Gaps.xs / 2,
                        ), // Reduzido para metade
                        Text(
                          widget.payment.description,
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: Gaps.sm),

                // Action button - always show for "owed to you", different for "you owe"
                if (widget.isOwedToUser)
                  _buildNotificationButton()
                else if (widget.payment.status == PaymentStatus.pending)
                  _buildMarkAsPaidButton()
                else
                  Icon(
                    widget.payment.status == PaymentStatus.paid
                        ? Icons.check_circle
                        : Icons.schedule,
                    size: IconSizes.md,
                    color: widget.payment.status == PaymentStatus.paid
                        ? BrandColors.planning
                        : BrandColors.text2,
                  ),
              ],
            ),
          ),
        ),

        // Cooldown banner
        if (_showCooldownBanner) _buildCooldownBanner(),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: _handleNotificationTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _isNotificationSent ? BrandColors.bg2 : BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: _isNotificationSent
              ? Border.all(color: BrandColors.bg3, width: 1)
              : null,
        ),
        child: Center(
          child: Icon(
            _isNotificationSent ? Icons.schedule : Icons.notifications,
            size: 16,
            color: BrandColors.text1,
          ),
        ),
      ),
    );
  }

  Widget _buildMarkAsPaidButton() {
    return GestureDetector(
      onTap: widget.onMarkAsPaid,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: const Center(
          child: Icon(Icons.check, size: 16, color: BrandColors.text1),
        ),
      ),
    );
  }

  Widget _buildCooldownBanner() {
    final timeLeft = _getTimeUntilNextNotification();

    return Container(
      margin: const EdgeInsets.only(top: Gaps.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.sm,
        vertical: Gaps.xs,
      ),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 16, color: BrandColors.text2),
          const SizedBox(width: Gaps.xs),
          Text(
            'Can notify again in $timeLeft',
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap() {
    if (_isNotificationSent) {
      // Se já está no segundo estado (pending), mostra o banner com tempo restante
      setState(() {
        _showCooldownBanner = true;
      });

      // Hide banner after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showCooldownBanner = false;
          });
        }
      });
    } else {
      // Primeiro estado: envia notificação e muda para segundo estado (pending)
      setState(() {
        _isNotificationSent = true;
        _lastNotificationTime = DateTime.now();
      });

      // Chama callback para enviar a notificação push
      widget.onNotify?.call();

      // Reset notification status after 30 minutes
      Future.delayed(const Duration(minutes: 30), () {
        if (mounted) {
          setState(() {
            _isNotificationSent = false;
            _lastNotificationTime = null;
          });
        }
      });
    }
  }

  String _getTimeUntilNextNotification() {
    if (_lastNotificationTime == null) return '0m';

    final timeElapsed = DateTime.now().difference(_lastNotificationTime!);
    final timeLeft = const Duration(minutes: 30) - timeElapsed;

    if (timeLeft.inMinutes > 0) {
      return '${timeLeft.inMinutes}m';
    } else {
      return '${timeLeft.inSeconds}s';
    }
  }

  String _getUserName() {
    // Get the name of the other person involved in the payment
    if (widget.isOwedToUser) {
      // They owe us - get the debtor name (fromUser)
      return widget.payment.fromUserName ?? 'Someone';
    } else {
      // We owe them - get the creditor name (toUser)
      return widget.payment.toUserName ?? 'Someone';
    }
  }
}

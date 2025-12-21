import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'notification_card.dart';

class NotificationsSection extends StatelessWidget {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(NotificationEntity)? onNotificationTap;
  final Function(NotificationEntity)? onActionTap;
  final Function(String groupId)? onAcceptInvite;
  final Function(String groupId)? onDeclineInvite;
  final Function(String paymentId)? onMarkPaymentPaid;

  const NotificationsSection({
    super.key,
    required this.notifications,
    this.isLoading = false,
    this.onRefresh,
    this.onNotificationTap,
    this.onActionTap,
    this.onAcceptInvite,
    this.onDeclineInvite,
    this.onMarkPaymentPaid,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      );
    }

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      color: BrandColors.planning,
      backgroundColor: BrandColors.bg2,
      child: ListView.separated(
        padding: const EdgeInsets.all(Insets.screenH),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: Gaps.md),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () => onNotificationTap?.call(notification),
            onActionTap: () => onActionTap?.call(notification),
            onAccept: onAcceptInvite,
            onDecline: onDeclineInvite,
            onMarkPaid: onMarkPaymentPaid,
          );
        },
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
                Icons.notifications_outlined,
                size: 32,
                color: BrandColors.text2,
              ),
            ),
            const SizedBox(height: Gaps.lg),
            Text(
              'No notifications',
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              'When you have new notifications, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      ),
    );
  }
}

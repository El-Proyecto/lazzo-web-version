import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notifications_section.dart';

/// Inbox page — notifications only (LAZZO 2.0: payments/expenses removed)
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markNotificationsAsRead();
    });
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final markAllAsReadUseCase =
          ref.read(markAllNotificationsAsReadUseCaseProvider);
      await markAllAsReadUseCase();

      // Reset unread count to 0
      ref.read(unreadCountProvider.notifier).resetCount();

      // Refresh notifications list to reflect read status
      await ref.read(notificationsProvider.notifier).refresh();
    } catch (e) {
      // Silently fail - not critical for user experience
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: const CommonAppBar(title: 'Inbox'),
      body: _buildNotificationsTab(),
    );
  }

  Widget _buildNotificationsTab() {
    final notificationsState = ref.watch(notificationsProvider);

    return notificationsState.when(
      data: (notifications) {
        // Filter out notifications that should ONLY appear in push (not in inbox)
        final inboxNotifications = notifications.where((n) {
          return n.type != NotificationType.eventLive &&
              n.type != NotificationType.eventEndsSoon &&
              n.type != NotificationType.chatMention;
        }).toList();

        return NotificationsSection(
          notifications: inboxNotifications,
          onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
          onNotificationTap: (notification) {
            _handleNotificationTap(notification);
          },
          onActionTap: (notification) {
            _handleActionButtonTap(notification);
          },
          onAcceptInvite: null,
          onDeclineInvite: null,
          onMarkPaymentPaid: null,
        );
      },
      loading: () {
        return const NotificationsSection(notifications: [], isLoading: true);
      },
      error: (error, stack) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading notifications',
                style:
                    AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
              ),
              const SizedBox(height: Gaps.md),
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: Text(
                  'Try again',
                  style:
                      AppText.labelLarge.copyWith(color: BrandColors.planning),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleNotificationTap(NotificationEntity notification) {
    // Mark as read
    ref.read(markNotificationAsReadUseCaseProvider).call(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      // Event notifications → Navigate to event page
      case NotificationType.eventStartsSoon:
      case NotificationType.eventExtended:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      // Memory ready → Navigate to memory ready page
      case NotificationType.memoryReady:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/memory-ready',
            arguments: {'memoryId': notification.eventId},
          );
        }
        break;

      // Upload notifications → Navigate to event uploads
      case NotificationType.uploadsOpen:
      case NotificationType.uploadsClosing:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      // Chat notifications → Navigate to event chat
      case NotificationType.chatMention:
      case NotificationType.chatMessage:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event-chat',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      // Event info notifications → Navigate to event
      case NotificationType.eventCreated:
      case NotificationType.eventDateSet:
      case NotificationType.eventCanceled:
      case NotificationType.eventRestored:
      case NotificationType.eventConfirmed:
      case NotificationType.eventEndsSoon:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      // Planning notifications → Navigate to event
      case NotificationType.dateSuggestionAdded:
      case NotificationType.suggestionAdded:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      // RSVP notifications → Navigate to event
      case NotificationType.rsvpUpdated:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      // Payment/expense notifications → Navigate to event (no payments tab)
      case NotificationType.paymentsRequest:
      case NotificationType.paymentsPaidYou:
      case NotificationType.paymentsAddedYouOwe:
      case NotificationType.paymentsAddedOwesYou:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      default:
    }
  }

  void _handleActionButtonTap(NotificationEntity notification) {
    switch (notification.type) {
      case NotificationType.uploadsOpen:
      case NotificationType.uploadsClosing:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      default:
        break;
    }
  }
}

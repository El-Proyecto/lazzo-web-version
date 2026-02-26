import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/inputs/photo_selector.dart';
import '../../../event/presentation/providers/event_photo_providers.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/action.dart';
import '../providers/notifications_provider.dart';
import '../providers/actions_provider.dart';
import '../widgets/notifications_section.dart';
import '../widgets/actions_section.dart';
import '../../../../services/analytics_service.dart';

/// Inbox page — Notifications + Actions tabs (LAZZO 2.0)
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  int _selectedTab = 0; // 0 = Notifications, 1 = Actions

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
      body: Column(
        children: [
          _buildSegmentedControl(),
          Expanded(
            child: _selectedTab == 0
                ? _buildNotificationsTab()
                : _buildActionsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Insets.screenH,
        vertical: Gaps.sm,
      ),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.smAlt),
      ),
      child: Row(
        children: [
          _buildSegmentButton('Notifications', 0),
          _buildSegmentButton('Actions', 1),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          if (index == 1) {
            AnalyticsService.screenViewed('actions');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
          decoration: BoxDecoration(
            color: isSelected ? BrandColors.bg3 : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.smAlt),
          ),
          child: Center(
            child: Text(
              label,
              style: AppText.labelLarge.copyWith(
                color: isSelected ? BrandColors.text1 : BrandColors.text2,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsTab() {
    final actionsState = ref.watch(actionsProvider);

    return actionsState.when(
      data: (actions) {
        return ActionsSection(
          actions: actions,
          onRefresh: () => ref.read(actionsProvider.notifier).refresh(),
          onActionTap: (action) => _handleActionEntityTap(action),
        );
      },
      loading: () {
        return const ActionsSection(actions: [], isLoading: true);
      },
      error: (error, stack) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading actions',
                style:
                    AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
              ),
              const SizedBox(height: Gaps.md),
              TextButton(
                onPressed: () => ref.read(actionsProvider.notifier).refresh(),
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

  void _handleActionEntityTap(ActionEntity action) {
    if (action.eventId == null) return;

    switch (action.type) {
      case ActionType.remindMaybeVoters:
      case ActionType.reviewGuests:
        // Navigate to Manage Guests
        Navigator.pushNamed(
          context,
          AppRouter.manageGuests,
          arguments: {'eventId': action.eventId},
        );
        break;
      case ActionType.confirmEvent:
        // Navigate to event page to confirm
        Navigator.pushNamed(
          context,
          AppRouter.event,
          arguments: {'eventId': action.eventId},
        );
        break;
      case ActionType.rescheduleExpiredEvent:
        // Navigate to event page (host can edit dates there)
        Navigator.pushNamed(
          context,
          AppRouter.event,
          arguments: {'eventId': action.eventId},
        );
        break;
      case ActionType.addPhotos:
        // Open photo picker, then navigate to manage memory
        _handleAddPhotoAction(action.eventId!);
        break;
    }
  }

  /// Opens camera/gallery picker and uploads the photo to the event.
  void _handleAddPhotoAction(String eventId) {
    PhotoSelectionBottomSheet.show(
      context: context,
      title: 'Upload Photo',
      showRemoveOption: false,
      onAction: (action) async {
        final photoNotifier = ref.read(
          eventPhotoUploadNotifierProvider(eventId).notifier,
        );

        if (action == PhotoSourceAction.camera) {
          await photoNotifier.takePhoto(eventId: eventId);
        } else if (action == PhotoSourceAction.gallery) {
          await photoNotifier.pickPhotoFromGallery(eventId: eventId);
        }

        if (!mounted) return;
        final uploadState = ref.read(eventPhotoUploadNotifierProvider(eventId));
        uploadState.when(
          data: (photoUrl) {
            if (photoUrl != null) {
              TopBanner.showSuccess(context,
                  message: 'Photo uploaded successfully!');
            }
          },
          loading: () {},
          error: (error, _) {
            TopBanner.showError(context,
                message: 'Failed to upload photo: $error');
          },
        );
      },
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/components/common/page_segmented_control.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/layouts/main_layout_providers.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_group.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';
// import '../providers/actions_provider.dart'; // MVP: Actions removed, preserved for P2
import '../providers/payments_provider.dart';
import '../widgets/notifications_section.dart';
// import '../widgets/actions_section.dart'; // MVP: Actions removed, preserved for P2
import '../widgets/payments_section.dart';
import '../widgets/payment_details_bottom_sheet.dart';
import '../../../profile/presentation/providers/other_profile_providers.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Track notifications being optimistically removed
  final Set<String> _deletingNotificationIds = {};

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // MVP: 2 tabs (removed Actions)

    // Check for pending tab change after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingTabChange();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkPendingTabChange() {
    final pendingTab = ref.read(inboxTabIndexProvider);
    if (pendingTab != null && _tabController.index != pendingTab) {
      _tabController.animateTo(pendingTab);
      // Reset after applying
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          ref.read(inboxTabIndexProvider.notifier).state = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to inbox tab index changes from provider
    ref.listen<int?>(inboxTabIndexProvider, (previous, next) {
      if (next != null && _tabController.index != next) {
        _tabController.animateTo(next);
        // Reset the provider after using it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(inboxTabIndexProvider.notifier).state = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: const CommonAppBar(title: 'Inbox'),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsTab(),
                // _buildActionsTab(), // MVP: Actions removed, preserved for P2
                _buildPaymentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return PageSegmentedControl(
      controller: _tabController,
      labels: const ['Notifications', 'Payments'], // MVP: Removed Actions tab
    );
  }

  Widget _buildNotificationsTab() {
        final notificationsState = ref.watch(notificationsProvider);
        

        
    return notificationsState.when(
      data: (notifications) {
                if (notifications.isNotEmpty) {
                  }
        
        // Filter out notifications that should ONLY appear in push (not in inbox)
        // Also filter out payment requests and paid confirmations (they appear in Payments tab)
        // paymentsAddedYouOwe now appears in Notifications tab (navigates to event)
        // Also filter out notifications being optimistically deleted
        final inboxNotifications = notifications.where((n) {
          return n.type != NotificationType.eventLive &&
                 n.type != NotificationType.eventEndsSoon &&
                 n.type != NotificationType.chatMention &&
                 // ✅ Payment requests and confirmations stay in Payments tab
                 n.type != NotificationType.paymentsRequest &&
                 n.type != NotificationType.paymentsPaidYou &&
                 !_deletingNotificationIds.contains(n.id);
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
          onAcceptInvite: (groupId) async {
                        final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId == null) {
                            _showSnackBar('Error: Not logged in', isError: true);
              return;
            }

            final acceptUseCase = ref.read(acceptGroupInviteProvider);
            final success = await acceptUseCase(userId: userId, groupId: groupId);
            
            if (success) {
                            
              // Find and mark the notification as read to hide it
              final notificationsState = ref.read(notificationsProvider);
              notificationsState.whenData((notifications) {
                final inviteNotification = notifications.firstWhere(
                  (n) => n.groupId == groupId && n.type == NotificationType.groupInviteReceived,
                  orElse: () => notifications.first,
                );
                // Mark as read to remove from inbox
                ref.read(markNotificationAsReadUseCaseProvider).call(inviteNotification.id);
              });
              
              _showSnackBar('Joined group successfully!');
              // Refresh notifications to show updated list
              ref.read(notificationsProvider.notifier).refresh();
            } else {
                            _showSnackBar('Failed to join group', isError: true);
            }
          },
          onDeclineInvite: (groupId) async {
                        final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId == null) {
                            _showSnackBar('Error: Not logged in', isError: true);
              return;
            }

            final declineUseCase = ref.read(declineGroupInviteProvider);
            final success = await declineUseCase(userId: userId, groupId: groupId);
            
            if (success) {
                            
              // Find and mark the notification as read to hide it
              final notificationsState = ref.read(notificationsProvider);
              notificationsState.whenData((notifications) {
                final inviteNotification = notifications.firstWhere(
                  (n) => n.groupId == groupId && n.type == NotificationType.groupInviteReceived,
                  orElse: () => notifications.first,
                );
                // Mark as read to remove from inbox
                ref.read(markNotificationAsReadUseCaseProvider).call(inviteNotification.id);
              });
              
              _showSnackBar('Invite declined');
              // Refresh notifications to show updated list
              ref.read(notificationsProvider.notifier).refresh();
            } else {
                            _showSnackBar('Failed to decline invite', isError: true);
            }
          },
          onMarkPaymentPaid: (notificationId) async {
                        
            try {
              // Optimistic UI: Add to deleting set to hide immediately
              setState(() {
                _deletingNotificationIds.add(notificationId);
              });
              
              // Show TopBanner immediately
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Payment marked as paid!',
                          style: AppText.bodyMedium.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    backgroundColor: BrandColors.planning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    margin: const EdgeInsets.all(Insets.screenH),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              
              // P2: Mark expense split as paid + mark notification as read in background
              await ref.read(markExpenseAsPaidFromNotificationUseCaseProvider).call(notificationId);
              
              // Refresh to sync with server (notification will be gone)
              ref.read(notificationsProvider.notifier).refresh();
              
              // Clean up deleting set after refresh
              setState(() {
                _deletingNotificationIds.remove(notificationId);
              });
            } catch (e) {
                            
              // Revert optimistic update on error
              setState(() {
                _deletingNotificationIds.remove(notificationId);
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Failed to mark as paid',
                          style: AppText.bodyMedium.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFFF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    margin: const EdgeInsets.all(Insets.screenH),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
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
                style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
              ),
              const SizedBox(height: Gaps.md),
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: Text(
                  'Try again',
                  style: AppText.labelLarge.copyWith(color: BrandColors.planning),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : BrandColors.planning,
        duration: const Duration(seconds: 2),
      ),
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

      // Memory ready → Navigate to memory viewer
      case NotificationType.memoryReady:
        if (notification.eventId != null) {
                    Navigator.pushNamed(
            context,
            '/memory-viewer',
            arguments: {'eventId': notification.eventId},
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
          // TODO: Navigate to uploads tab specifically
        }
        break;

      // Payment notifications → Navigate based on type
      case NotificationType.paymentsRequest:
      case NotificationType.paymentsPaidYou:
                ref.read(inboxTabIndexProvider.notifier).state = 1; // Payments tab
        break;
      
      // Expense added notification → Navigate based on event status
      case NotificationType.paymentsAddedYouOwe:
        if (notification.eventId != null) {
          // Check event status to decide navigation
          _handleExpenseNotificationTap(context, notification);
        }
        break;

      // Group notifications → Navigate to group hub
      case NotificationType.groupInviteReceived:
      case NotificationType.groupPhotoChanged:
        if (notification.groupId != null) {
                    Navigator.pushNamed(
            context,
            '/group-hub',
            arguments: {'groupId': notification.groupId},
          );
        }
        break;

      // Event info notifications → Navigate to event
      case NotificationType.eventCreated:
      case NotificationType.eventDateSet:
      case NotificationType.eventLocationSet:
      case NotificationType.eventDetailsUpdated:
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

      // Planning notifications → Navigate to event planning tab
      case NotificationType.dateSuggestionAdded:
      case NotificationType.suggestionAdded:
        if (notification.eventId != null) {
                    Navigator.pushNamed(
            context,
            '/event',
            arguments: {
              'eventId': notification.eventId,
              // TODO: Add support for initialTab parameter in event page
            },
          );
        }
        break;

      // Group member notifications → Navigate to group
      case NotificationType.groupInviteAccepted:
        if (notification.groupId != null) {
                    Navigator.pushNamed(
            context,
            '/group-hub',
            arguments: {'groupId': notification.groupId},
          );
        }
        break;

      // RSVP notifications → Navigate to event (show participants)
      case NotificationType.rsvpUpdated:
        if (notification.eventId != null) {
                    Navigator.pushNamed(
            context,
            '/event',
            arguments: {
              'eventId': notification.eventId,
              // TODO: Add support for showParticipants parameter in event page
            },
          );
        }
        break;

      default:
            }
  }

  /// Handle expense notification tap - navigate based on event status
  Future<void> _handleExpenseNotificationTap(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final eventId = notification.eventId;
    if (eventId == null) return;

    try {
      // Fetch event status from Supabase
      final response = await Supabase.instance.client
          .from('events')
          .select('status')
          .eq('id', eventId)
          .single();

      final eventStatus = response['status'] as String?;

      // Check if event is NOT active (pending, confirmed, living)
      // If event is recap, ended, cancelled, etc., navigate to Payments tab
      final isActiveEvent = eventStatus == 'pending' || 
                           eventStatus == 'confirmed' || 
                           eventStatus == 'living';
      
      if (!isActiveEvent) {
        // Switch to Payments tab for non-active events
        ref.read(inboxTabIndexProvider.notifier).state = 1;
        
        // Wait for tab switch to complete
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Try to find and show the payment details bottom sheet if expenseId exists
        if (notification.expenseId != null && mounted) {
          await _tryShowExpenseBottomSheet(context, notification.expenseId!);
        }
      } else {
        // For active events (pending/confirmed/living), navigate to event page
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': eventId},
          );
        }
      }
    } catch (e) {
      // On error, fallback to navigating to event
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/event',
          arguments: {'eventId': eventId},
        );
      }
    }
  }

  /// Try to show expense bottom sheet for a specific expenseId
  Future<void> _tryShowExpenseBottomSheet(BuildContext context, String expenseId) async {
    // Force refresh providers to ensure we have latest data
    await ref.read(paymentsOwedToUserProvider.notifier).refresh();
    await ref.read(paymentsUserOwesProvider.notifier).refresh();
    
    // Wait a bit for data to settle
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) {
      return;
    }
    
    // Get current payments from providers
    final owedToUserState = ref.read(paymentsOwedToUserProvider);
    final userOwesState = ref.read(paymentsUserOwesProvider);
    
    final owedToUser = owedToUserState.asData?.value ?? <PaymentEntity>[];
    final userOwes = userOwesState.asData?.value ?? <PaymentEntity>[];
    
    // Combine all payments
    final allPayments = [...owedToUser, ...userOwes];
    
    if (allPayments.isEmpty) {
      return;
    }
    
    // Find payment with matching expense ID
    // Note: PaymentEntity.id format is "expenseId_userId"
    PaymentEntity? matchingPayment;
    try {
      matchingPayment = allPayments.firstWhere(
        (p) => p.id.startsWith(expenseId),
      );
    } catch (e) {
      // No matching payment found
      return;
    }
    
    // Get current user ID to determine payment group
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    
    // Find which list contains this payment to determine direction
    final isOwedToUser = owedToUser.any((p) => p.id == matchingPayment!.id);
    
    // Get the other user ID (the one who isn't current user)
    final otherUserId = isOwedToUser 
        ? matchingPayment.fromUserId 
        : matchingPayment.toUserId;
    
    if (otherUserId == null) {
      return;
    }
    
    // Get user name
    final otherUserName = isOwedToUser
        ? matchingPayment.fromUserName ?? 'Unknown'
        : matchingPayment.toUserName ?? 'Unknown';
    
    // Filter payments for this specific user
    final userPayments = allPayments.where((p) {
      return isOwedToUser
          ? (p.fromUserId == otherUserId && p.toUserId == currentUserId)
          : (p.toUserId == otherUserId && p.fromUserId == currentUserId);
    }).toList();
    
    // Create payment group for this user
    final paymentGroup = PaymentGroup(
      userId: otherUserId,
      userName: otherUserName,
      payments: userPayments,
      totalAmount: userPayments.fold(0.0, (sum, p) => sum + p.amount),
      isOwedToUser: isOwedToUser,
    );
    
    // Show bottom sheet
    await PaymentDetailsBottomSheet.show(
      context: context,
      paymentGroup: paymentGroup,
      onPaymentTap: (payment) {
        Navigator.of(context).pop();
      },
    );
  }

  void _handleActionButtonTap(NotificationEntity notification) {
        
    switch (notification.type) {
      case NotificationType.uploadsOpen:
      case NotificationType.uploadsClosing:
        // Navigate to event uploads
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event',
            arguments: {'eventId': notification.eventId},
          );
        }
        break;

      case NotificationType.paymentsRequest:
        // Navigate to payments
        ref.read(inboxTabIndexProvider.notifier).state = 1;
        break;

      default:
        break;
    }
  }

  // MVP: Actions tab removed, preserved for P2 implementation
  // Widget _buildActionsTab() {
  //   final actionsState = ref.watch(actionsProvider);
  //
  //   return actionsState.when(
  //     data: (actions) => ActionsSection(
  //       actions: actions,
  //       onRefresh: () => ref.read(actionsProvider.notifier).refresh(),
  //       onActionTap: (action) {
  //         // Handle action tap and complete it
  //         ref.read(completeActionUseCaseProvider).call(action.id);
  //         ref.read(actionsProvider.notifier).refresh();
  //       },
  //     ),
  //     loading: () => const ActionsSection(actions: [], isLoading: true),
  //     error: (error, stack) => Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text(
  //             'Error loading actions',
  //             style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
  //           ),
  //           const SizedBox(height: Gaps.md),
  //           TextButton(
  //             onPressed: () => ref.read(actionsProvider.notifier).refresh(),
  //             child: Text(
  //               'Try again',
  //               style: AppText.labelLarge.copyWith(color: BrandColors.planning),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPaymentsTab() {
    final owedToUserState = ref.watch(paymentsOwedToUserProvider);
    final userOwesState = ref.watch(paymentsUserOwesProvider);

    final isLoading = owedToUserState.isLoading || userOwesState.isLoading;
    final hasError = owedToUserState.hasError || userOwesState.hasError;

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading payments',
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.md),
            TextButton(
              onPressed: () {
                ref.read(paymentsOwedToUserProvider.notifier).refresh();
                ref.read(paymentsUserOwesProvider.notifier).refresh();
              },
              child: Text(
                'Try again',
                style: AppText.labelLarge.copyWith(color: BrandColors.planning),
              ),
            ),
          ],
        ),
      );
    }

    final owedToUser = owedToUserState.asData?.value ?? <PaymentEntity>[];
    final userOwes = userOwesState.asData?.value ?? <PaymentEntity>[];

    return PaymentsSection(
      owedToUser: owedToUser,
      userOwes: userOwes,
      isLoading: isLoading,
      onRefresh: () {
        ref.read(paymentsOwedToUserProvider.notifier).refresh();
        ref.read(paymentsUserOwesProvider.notifier).refresh();
      },
      onPaymentTap: (payment) {
        // Handle payment tap
        // Navigate to payment details
      },
      onMarkAsPaid: (payment) {
        // Handle mark as paid
        ref.read(markPaymentAsPaidUseCaseProvider).call(payment.id);
        ref.read(paymentsOwedToUserProvider.notifier).refresh();
        ref.read(paymentsUserOwesProvider.notifier).refresh();
      },
    );
  }
}

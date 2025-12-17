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
import '../providers/notifications_provider.dart';
// import '../providers/actions_provider.dart'; // MVP: Actions removed, preserved for P2
import '../providers/payments_provider.dart';
import '../widgets/notifications_section.dart';
// import '../widgets/actions_section.dart'; // MVP: Actions removed, preserved for P2
import '../widgets/payments_section.dart';
import '../../../profile/presentation/providers/other_profile_providers.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      data: (notifications) => NotificationsSection(
        notifications: notifications,
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        onNotificationTap: (notification) {
          // Handle notification tap
          ref.read(markNotificationAsReadUseCaseProvider).call(notification.id);
        },
        onActionTap: (notification) {
          // Handle action tap
          if (notification.actionUrl != null) {
            // Navigate to action URL
          }
        },
        onAcceptInvite: (groupId) async {
          print('[InboxPage] 🟢 Accept invite clicked for group: $groupId');
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) {
            print('[InboxPage] ❌ No user logged in');
            _showSnackBar('Error: Not logged in', isError: true);
            return;
          }

          final acceptUseCase = ref.read(acceptGroupInviteProvider);
          final success = await acceptUseCase(userId: userId, groupId: groupId);
          
          if (success) {
            print('[InboxPage] ✅ Invite accepted successfully');
            _showSnackBar('Joined group successfully!');
            // Refresh notifications to remove the invite
            ref.read(notificationsProvider.notifier).refresh();
          } else {
            print('[InboxPage] ❌ Failed to accept invite');
            _showSnackBar('Failed to join group', isError: true);
          }
        },
        onDeclineInvite: (groupId) async {
          print('[InboxPage] 🔴 Decline invite clicked for group: $groupId');
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) {
            print('[InboxPage] ❌ No user logged in');
            _showSnackBar('Error: Not logged in', isError: true);
            return;
          }

          final declineUseCase = ref.read(declineGroupInviteProvider);
          final success = await declineUseCase(userId: userId, groupId: groupId);
          
          if (success) {
            print('[InboxPage] ✅ Invite declined successfully');
            _showSnackBar('Invite declined');
            // Refresh notifications to remove the invite
            ref.read(notificationsProvider.notifier).refresh();
          } else {
            print('[InboxPage] ❌ Failed to decline invite');
            _showSnackBar('Failed to decline invite', isError: true);
          }
        },
      ),
      loading: () =>
          const NotificationsSection(notifications: [], isLoading: true),
      error: (error, stack) => Center(
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
      ),
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

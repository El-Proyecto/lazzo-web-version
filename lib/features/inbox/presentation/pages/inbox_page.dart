import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../domain/entities/payment_entity.dart';
import '../providers/notifications_provider.dart';
import '../providers/actions_provider.dart';
import '../providers/payments_provider.dart';
import '../widgets/notifications_section.dart';
import '../widgets/actions_section.dart';
import '../widgets/payments_section.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationsTab(),
                  _buildActionsTab(),
                  _buildPaymentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.screenH,
        vertical: Gaps.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Inbox',
            style: AppText.headlineMedium.copyWith(color: BrandColors.text1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: BrandColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: ShapeDecoration(
          color: BrandColors.bg3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: BrandColors.text1,
        unselectedLabelColor: BrandColors.text2,
        labelStyle: AppText.labelLarge,
        unselectedLabelStyle: AppText.labelLarge,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        tabs: const [
          Tab(text: 'Notifications'),
          Tab(text: 'Actions'),
          Tab(text: 'Payments'),
        ],
      ),
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

  Widget _buildActionsTab() {
    final actionsState = ref.watch(actionsProvider);

    return actionsState.when(
      data: (actions) => ActionsSection(
        actions: actions,
        onRefresh: () => ref.read(actionsProvider.notifier).refresh(),
        onActionTap: (action) {
          // Handle action tap and complete it
          ref.read(completeActionUseCaseProvider).call(action.id);
          ref.read(actionsProvider.notifier).refresh();
        },
      ),
      loading: () => const ActionsSection(actions: [], isLoading: true),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading actions',
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.md),
            TextButton(
              onPressed: () => ref.read(actionsProvider.notifier).refresh(),
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

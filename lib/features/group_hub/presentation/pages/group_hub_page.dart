import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/page_segmented_control.dart';
import '../../../../shared/components/cards/group_event_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/group_hub_providers.dart';

class GroupHubPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final int memberCount;

  const GroupHubPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupPhotoUrl,
    required this.memberCount,
  });

  @override
  ConsumerState<GroupHubPage> createState() => _GroupHubPageState();
}

class _GroupHubPageState extends ConsumerState<GroupHubPage>
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
      appBar: CommonAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.settings, color: BrandColors.text1),
          onPressed: () {
            // TODO: Navigate to group settings
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Group information section
            _buildGroupInfo(),
            const SizedBox(height: Gaps.lg),

            // Segmented control
            _buildSegmentedControl(),
            const SizedBox(height: Gaps.lg),

            // Content sections
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsSection(),
                  _buildExpensesSection(),
                  _buildMemoriesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      child: Column(
        children: [
          // Group photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandColors.bg3,
              image: widget.groupPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.groupPhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.groupPhotoUrl == null
                ? const Icon(
                    Icons.group,
                    size: 40,
                    color: BrandColors.text2,
                  )
                : null,
          ),
          const SizedBox(height: Gaps.md),

          // Group name
          Text(
            widget.groupName,
            style: AppText.headlineMedium.copyWith(
              color: BrandColors.text1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gaps.xs),

          // Member count
          Text(
            '${widget.memberCount} Members',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return PageSegmentedControl(
      controller: _tabController,
      labels: const ['Events', 'Expenses', 'Memories'],
    );
  }

  Widget _buildEventsSection() {
    final eventsAsync = ref.watch(groupEventsProvider(widget.groupId));

    return eventsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'Error loading events',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
            const SizedBox(height: Gaps.sm),
            TextButton(
              onPressed: () {
                ref
                    .read(groupEventsProvider(widget.groupId).notifier)
                    .refresh();
              },
              child: Text(
                'Try again',
                style: AppText.labelLarge.copyWith(color: BrandColors.planning),
              ),
            ),
          ],
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_outlined,
            title: 'No events yet',
            subtitle: 'Events will appear here when created',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: Gaps.md),
          itemBuilder: (context, index) {
            final event = events[index];
            return GroupEventCard(
              event: event,
              onTap: () {
                // TODO: Navigate to event detail
                print('Navigate to event: ${event.id}');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildExpensesSection() {
    final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));

    return expensesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'Error loading expenses',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      ),
      data: (expenses) => _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses yet',
        subtitle: 'Group expenses will appear here',
      ),
    );
  }

  Widget _buildMemoriesSection() {
    final memoriesAsync = ref.watch(groupMemoriesProvider(widget.groupId));

    return memoriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'Error loading memories',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      ),
      data: (memories) => _buildEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No memories yet',
        subtitle: 'Group memories will appear here',
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Pads.sectionH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.lg),
            Text(
              title,
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              subtitle,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/action.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'inbox_action_card.dart';

class ActionsSection extends StatelessWidget {
  final List<ActionEntity> actions;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(ActionEntity)? onActionTap;

  const ActionsSection({
    super.key,
    required this.actions,
    this.isLoading = false,
    this.onRefresh,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      );
    }

    if (actions.isEmpty) {
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
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(height: Gaps.md),
        itemBuilder: (context, index) {
          final action = actions[index];
          return InboxActionCard(
            action: action,
            onTap: () => onActionTap?.call(action),
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
                Icons.task_alt_outlined,
                size: 32,
                color: BrandColors.text2,
              ),
            ),
            const SizedBox(height: Gaps.lg),
            Text(
              'No pending actions',
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              'When you have tasks to complete, they\'ll be organized here by time left.',
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      ),
    );
  }
}

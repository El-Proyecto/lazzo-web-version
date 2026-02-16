import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/event_photo_providers.dart';

/// Photos widget for the living page.
/// bg2 container matching LocationWidget style.
/// 3-column grid with 4:5 aspect ratio (same as manage memory).
/// Max 9 visible slots: when full, no Add card — last photo shows "+N".
/// Tapping the widget opens the Memory page.
class LivingPhotosWidget extends ConsumerWidget {
  final String eventId;
  final VoidCallback onTakePhoto;
  final VoidCallback onViewAll;

  const LivingPhotosWidget({
    super.key,
    required this.eventId,
    required this.onTakePhoto,
    required this.onViewAll,
  });

  static const int _columns = 3;
  static const int _maxSlots = 9;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(eventPhotosProvider(eventId));

    return photosAsync.when(
      data: (photos) => _buildContent(context, photos),
      loading: () => _buildLoading(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context, List<dynamic> photos) {
    final totalCount = photos.length;

    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Pads.sectionH),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(totalCount),
            const SizedBox(height: Gaps.md),

            // Grid
            if (totalCount == 0)
              _buildEmptyState()
            else
              _buildGrid(context, photos),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photos', style: AppText.labelLarge),
            if (count > 0) ...[
              const SizedBox(height: 2),
              Text(
                '$count photo${count != 1 ? 's' : ''} added',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        if (count > 0)
          const Icon(
            Icons.chevron_right,
            color: BrandColors.text2,
            size: IconSizes.md,
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: onTakePhoto,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Gaps.xl,
          horizontal: Pads.sectionH,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt,
              size: IconSizes.lg,
              color: BrandColors.living,
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              'Add first photo',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.living,
              ),
            ),
            const SizedBox(height: Gaps.xxs),
            Text(
              'Capture moments from your event',
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

  Widget _buildGrid(BuildContext context, List<dynamic> photos) {
    final totalCount = photos.length;
    final isFull = totalCount >= _maxSlots;

    // If full (>=9): show 9 photos, last has +N overlay
    // If not full (<9): show all photos + 1 add card
    final int photoSlotsToShow;
    final bool showAddCard;

    if (isFull) {
      photoSlotsToShow = _maxSlots;
      showAddCard = false;
    } else {
      photoSlotsToShow = totalCount;
      showAddCard = true;
    }

    final hasOverflow = totalCount > _maxSlots;
    final overflowCount =
        totalCount - _maxSlots + 1; // +1 because last slot is the overlay

    final List<Widget> children = [];

    for (int i = 0; i < photoSlotsToShow; i++) {
      final photo = photos[i] as Map<String, dynamic>;
      final isLastSlot = i == _maxSlots - 1;

      if (isLastSlot && hasOverflow) {
        children.add(_OverflowPhotoTile(
          imageUrl: photo['url'] as String? ?? '',
          overflowCount: overflowCount,
          onTap: onViewAll,
        ));
      } else {
        children.add(_PhotoTile(
          imageUrl: photo['url'] as String? ?? '',
          onTap: onViewAll,
        ));
      }
    }

    if (showAddCard) {
      children.add(_AddPhotoCard(onTap: onTakePhoto));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = Gaps.xs.toDouble();
        final tileWidth =
            (constraints.maxWidth - spacing * (_columns - 1)) / _columns;
        final tileHeight = tileWidth * 5 / 4; // 4:5 aspect ratio

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photos', style: AppText.labelLarge),
          const SizedBox(height: Gaps.md),
          const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                color: BrandColors.living,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const _PhotoTile({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: BrandColors.bg3,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.living,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: BrandColors.bg3,
            child: const Icon(
              Icons.broken_image_outlined,
              color: BrandColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

class _OverflowPhotoTile extends StatelessWidget {
  final String imageUrl;
  final int overflowCount;
  final VoidCallback onTap;

  const _OverflowPhotoTile({
    required this.imageUrl,
    required this.overflowCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: BrandColors.bg3),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Text(
                  '+$overflowCount',
                  style: AppText.titleMediumEmph.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: IconSizes.md,
              color: BrandColors.living,
            ),
            const SizedBox(height: Gaps.xxs),
            Text(
              'Add Photo',
              style: AppText.labelLarge.copyWith(
                color: BrandColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

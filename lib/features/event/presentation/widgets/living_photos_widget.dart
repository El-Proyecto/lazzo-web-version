import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/event_photo_providers.dart';

/// Photos grid widget for the living page.
/// Shows a 3‑column grid (max 9 visible), an add‑photo card,
/// and a "+N" overflow indicator when there are more photos.
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
  static const int _maxVisible = 9;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildHeader(totalCount),
        const SizedBox(height: Gaps.sm),

        // Grid
        if (totalCount == 0)
          _buildEmptyState()
        else
          _buildGrid(context, photos),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Photos${count > 0 ? ' ($count)' : ''}',
          style: AppText.titleMediumEmph,
        ),
        if (count > 0)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'See all',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.living,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return _AddPhotoCard(onTap: onTakePhoto);
  }

  Widget _buildGrid(BuildContext context, List<dynamic> photos) {
    final totalCount = photos.length;
    // How many photo slots we show (reserve 1 slot for the add‑photo card)
    final photoSlots = (_maxVisible - 1).clamp(0, totalCount); // max 8 photos
    final hasOverflow = totalCount > photoSlots;
    final overflowCount = totalCount - photoSlots;

    // Build grid children: photo tiles + add card
    final List<Widget> children = [];

    for (int i = 0; i < photoSlots; i++) {
      final photo = photos[i] as Map<String, dynamic>;
      final isLast = i == photoSlots - 1;

      Widget tile = _PhotoTile(
        imageUrl: photo['url'] as String? ?? '',
        onTap: onViewAll,
      );

      // Show overlay on last photo tile if there's overflow
      if (isLast && hasOverflow) {
        tile = _OverflowPhotoTile(
          imageUrl: photo['url'] as String? ?? '',
          overflowCount: overflowCount,
          onTap: onViewAll,
        );
      }

      children.add(tile);
    }

    // Always add the "add photo" card at the end if we have room
    if (children.length < _maxVisible) {
      children.add(_AddPhotoCard(onTap: onTakePhoto));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = Gaps.xs;
        final tileSize =
            (constraints.maxWidth - spacing * (_columns - 1)) / _columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: tileSize,
              height: tileSize,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: AppText.titleMediumEmph),
        const SizedBox(height: Gaps.sm),
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
              color: BrandColors.bg2,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.living,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: BrandColors.bg2,
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
              errorBuilder: (_, __, ___) => Container(color: BrandColors.bg2),
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
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: BrandColors.border),
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

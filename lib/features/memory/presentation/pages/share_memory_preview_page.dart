import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/cards/share_card.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/memory_providers.dart';

/// Full-screen preview of ShareCard for Instagram Story export
/// Shows exactly how the card will appear when exported
class ShareMemoryPreviewPage extends ConsumerWidget {
  final String memoryId;

  const ShareMemoryPreviewPage({
    super.key,
    required this.memoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(memoryDetailProvider(memoryId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen card preview
            memoryAsync.when(
              data: (memory) {
                if (memory == null) {
                  return const Center(
                    child: Text(
                      'Memory not found',
                      style: TextStyle(color: BrandColors.text2),
                    ),
                  );
                }

                // Get cover photos for the card
                final covers = memory.coverPhotos;
                final heroPhoto =
                    covers.isNotEmpty ? covers.first : memory.photos.first;

                // Get up to 3 thumbnails (excluding hero)
                final thumbnails = memory.photos
                    .where((p) => p.id != heroPhoto.id)
                    .take(3)
                    .map((p) => p.thumbnailUrl ?? p.url)
                    .toList();

                return Center(
                  child: ShareCard(
                    title: memory.title,
                    location: memory.location,
                    eventDate: memory.eventDate,
                    peopleCount: _getUniquePeopleCount(memory.photos),
                    heroPhotoUrl: heroPhoto.coverUrl ?? heroPhoto.url,
                    thumbnailUrls: thumbnails,
                    isPreview: false,
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: BrandColors.planning,
                ),
              ),
              error: (error, stack) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: BrandColors.text2,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load memory',
                      style: TextStyle(color: BrandColors.text2),
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getUniquePeopleCount(List photos) {
    final uploaders = photos.map((p) => p.uploaderId).toSet();
    return uploaders.length;
  }
}

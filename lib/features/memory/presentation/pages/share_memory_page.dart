import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/cards/share_card.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../widgets/share_options_section.dart';
import '../providers/memory_providers.dart';
import 'share_memory_preview_page.dart';

/// Share Memory page with preview card and share options
class ShareMemoryPage extends ConsumerWidget {
  final String memoryId;

  const ShareMemoryPage({
    super.key,
    required this.memoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(memoryDetailProvider(memoryId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Share Memory',
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios,
              color: BrandColors.text1,
              size: 20,
            ),
          ),
        ),
      ),
      body: memoryAsync.when(
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

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Gaps.md),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShareMemoryPreviewPage(
                              memoryId: memoryId,
                            ),
                          ),
                        );
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate max height to fit screen without scroll
                          final maxHeight = constraints.maxHeight;
                          final maxWidth = constraints.maxWidth;
                          
                          // Maintain 9:16 aspect ratio
                          final cardWidth = maxWidth < maxHeight * 9 / 16
                              ? maxWidth
                              : maxHeight * 9 / 16;
                          
                          return SizedBox(
                            width: cardWidth,
                            child: ShareCard(
                              title: memory.title,
                              location: memory.location,
                              eventDate: memory.eventDate,
                              peopleCount: _getUniquePeopleCount(memory.photos),
                              heroPhotoUrl: heroPhoto.coverUrl ?? heroPhoto.url,
                              thumbnailUrls: thumbnails,
                              isPreview: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              ShareOptionsSection(
                onInstagramPressed: () => _handleInstagramShare(context),
                onWhatsAppPressed: () => _handleWhatsAppShare(context),
                onSavePressed: () => _handleSave(context),
                onMorePressed: () => _handleMore(context),
              ),
            ],
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
              SizedBox(height: Gaps.md),
              Text(
                'Failed to load memory',
                style: TextStyle(color: BrandColors.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getUniquePeopleCount(List photos) {
    final uploaders = photos.map((p) => p.uploaderId).toSet();
    return uploaders.length;
  }

  void _handleInstagramShare(BuildContext context) {
    // TODO: Implement Instagram story share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instagram share coming soon')),
    );
  }

  void _handleWhatsAppShare(BuildContext context) {
    // TODO: Implement WhatsApp share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp share coming soon')),
    );
  }

  void _handleSave(BuildContext context) {
    // TODO: Implement save to gallery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save coming soon')),
    );
  }

  void _handleMore(BuildContext context) {
    // TODO: Implement native share sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('More options coming soon')),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/memory_entity.dart';
import '../providers/memory_providers.dart';
import '../widgets/memory_viewer_app_bar.dart';
import '../widgets/photo_viewer_item.dart';

/// Memory Viewer Page - Full screen photo viewer
/// Accessed when tapping a photo on the memory page
/// Opens directly at the selected photo
/// Photos are ordered: covers first (by votes), then grid (by timestamp)
class MemoryViewerPage extends ConsumerWidget {
  final String memoryId;
  final String? initialPhotoId;

  const MemoryViewerPage({
    super.key,
    required this.memoryId,
    this.initialPhotoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(memoryDetailProvider(memoryId));
    final photosAsync = ref.watch(memoryPhotosProvider(memoryId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: memoryAsync.when(
        data: (memory) => memory != null
            ? MemoryViewerAppBar(
                title: memory.title,
                subtitle: _buildSubtitle(memory.location, memory.eventDate),
                onBackPressed: () => Navigator.of(context).pop(),
              )
            : MemoryViewerAppBar(
                title: 'Memory',
                onBackPressed: () => Navigator.of(context).pop(),
              ),
        loading: () => MemoryViewerAppBar(
          title: 'Loading...',
          onBackPressed: () => Navigator.of(context).pop(),
        ),
        error: (_, __) => MemoryViewerAppBar(
          title: 'Error',
          onBackPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Text(
                'No photos available',
                style: TextStyle(color: BrandColors.text2),
              ),
            );
          }

          // Find initial index (if initialPhotoId provided)
          final initialIndex = initialPhotoId != null
              ? photos.indexWhere((p) => p.id == initialPhotoId)
              : 0;

          final startIndex = initialIndex >= 0 ? initialIndex : 0;

          // Determine if event is multi-day
          final isMultiDay = _isMultiDayEvent(photos);

          return PageView.builder(
            controller: PageController(initialPage: startIndex),
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return PhotoViewerItem(
                photo: photo,
                eventDate: memoryAsync.maybeWhen(
                  data: (memory) => memory?.eventDate ?? DateTime.now(),
                  orElse: () => DateTime.now(),
                ),
                isMultiDay: isMultiDay,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.screenH),
            child: Text(
              'Error loading photos: $error',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Build subtitle text: "Location • Date"
  String _buildSubtitle(String? location, DateTime? eventDate) {
    if (eventDate == null) return location ?? '';

    final dateStr = DateFormat('d MMMM yyyy').format(eventDate);
    if (location != null && location.isNotEmpty) {
      return '$location • $dateStr';
    }
    return dateStr;
  }

  /// Check if event spans multiple days based on photo timestamps
  bool _isMultiDayEvent(List<MemoryPhoto> photos) {
    if (photos.length < 2) return false;

    final firstDate = DateTime(
      photos.first.capturedAt.year,
      photos.first.capturedAt.month,
      photos.first.capturedAt.day,
    );

    for (final photo in photos) {
      final photoDate = DateTime(
        photo.capturedAt.year,
        photo.capturedAt.month,
        photo.capturedAt.day,
      );
      if (photoDate != firstDate) {
        return true;
      }
    }

    return false;
  }
}

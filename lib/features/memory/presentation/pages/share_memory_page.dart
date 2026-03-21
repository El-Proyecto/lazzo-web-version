import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/cards/share_card.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../widgets/share_options_section.dart';
import '../widgets/edit_share_photos_sheet.dart';
import '../providers/memory_providers.dart';
import '../../domain/entities/memory_entity.dart';
import 'share_memory_preview_page.dart';
import '../../../../services/analytics_service.dart';

/// Share Memory page with preview card and share options
class ShareMemoryPage extends ConsumerStatefulWidget {
  final String memoryId;

  const ShareMemoryPage({
    super.key,
    required this.memoryId,
  });

  @override
  ConsumerState<ShareMemoryPage> createState() => _ShareMemoryPageState();
}

class _ShareMemoryPageState extends ConsumerState<ShareMemoryPage> {
  final GlobalKey _repaintKey = GlobalKey();
  Uint8List? _cachedImageBytes;
  bool _isGeneratingImage = false;
  List<String>? _selectedPhotoIds;

  void _openEditPhotosSheet(BuildContext context, MemoryEntity memory) {
    // Initialize with current photo IDs if not set
    final currentPhotoIds = _selectedPhotoIds ?? _getInitialPhotoIds(memory);

    EditSharePhotosSheet.show(
      context: context,
      memory: memory,
      initialSelectedPhotoIds: currentPhotoIds,
      onSave: (photoIds) {
        setState(() {
          _selectedPhotoIds = photoIds;
          _cachedImageBytes = null; // Clear cache to regenerate
        });

        // Track share card edited
        AnalyticsService.track('share_card_edited', properties: {
          'memory_id': widget.memoryId,
        });

        // Regenerate image with new photos in the correct order
        final selectedPhotos = <MemoryPhoto>[];
        for (final photoId in photoIds) {
          final photo = memory.photos.firstWhere(
            (p) => p.id == photoId,
            orElse: () => memory.photos.first,
          );
          selectedPhotos.add(photo);
        }

        if (selectedPhotos.isNotEmpty) {
          final heroPhoto = selectedPhotos[0];
          final thumbnails = selectedPhotos.length > 1
              ? selectedPhotos
                  .sublist(1, selectedPhotos.length.clamp(0, 4))
                  .map((p) => p.thumbnailUrl ?? p.url)
                  .toList()
              : <String>[];

          _generateShareImage(
            heroPhoto.coverUrl ?? heroPhoto.url,
            thumbnails,
            photoIds,
          );
        }
      },
    );
  }

  List<String> _getInitialPhotoIds(MemoryEntity memory) {
    if (_selectedPhotoIds != null) return _selectedPhotoIds!;

    // Get cover photos (up to 1) + other photos (up to 3)
    final covers = memory.coverPhotos;
    final heroPhoto = covers.isNotEmpty ? covers.first : memory.photos.first;

    final remaining =
        memory.photos.where((p) => p.id != heroPhoto.id).take(3).toList();

    // If fewer than 4 photos available, use single-photo mode (just hero)
    if (remaining.length < 3) {
      return [heroPhoto.id];
    }

    return [heroPhoto.id, ...remaining.map((p) => p.id)];
  }

  @override
  Widget build(BuildContext context) {
    final memoryAsync = ref.watch(memoryDetailProvider(widget.memoryId));

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

          // Get photos based on selection or use defaults
          final photoIds = _selectedPhotoIds ?? _getInitialPhotoIds(memory);

          // Get selected photos in order
          final selectedPhotos = <MemoryPhoto>[];
          for (final photoId in photoIds) {
            final photo = memory.photos.firstWhere(
              (p) => p.id == photoId,
              orElse: () => memory.photos.first,
            );
            selectedPhotos.add(photo);
          }

          final heroPhoto = selectedPhotos.isNotEmpty
              ? selectedPhotos[0]
              : memory.photos.first;

          // Get up to 3 thumbnails (excluding hero)
          final thumbnails = selectedPhotos.length > 1
              ? selectedPhotos
                  .sublist(1, selectedPhotos.length.clamp(0, 4))
                  .map((p) => p.thumbnailUrl ?? p.url)
                  .toList()
              : <String>[];

          final heroUrl = heroPhoto.coverUrl ?? heroPhoto.url;

          // Generate image when data is first loaded or changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_cachedImageBytes == null && !_isGeneratingImage) {
              _generateShareImage(heroUrl, thumbnails, photoIds);
            }
          });

          return Stack(
            children: [
              Column(
                children: [
                  // Preview area
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: Gaps.md,
                            left: Gaps.md,
                            right: Gaps.md,
                            top: Gaps.xs),
                        child: GestureDetector(
                          onTap: () {
                            if (_cachedImageBytes != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ShareMemoryPreviewPage(
                                    imageBytes: _cachedImageBytes!,
                                  ),
                                ),
                              );
                            }
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

                              // Always show the cached PNG image thumbnail (or loading)
                              if (_cachedImageBytes != null) {
                                return Stack(
                                  children: [
                                    SizedBox(
                                      width: cardWidth,
                                      child: AspectRatio(
                                        aspectRatio: 9 / 16,
                                        child: Image.memory(
                                          _cachedImageBytes!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    // Edit button
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _openEditPhotosSheet(
                                            context, memory),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return SizedBox(
                                  width: cardWidth,
                                  child: const AspectRatio(
                                    aspectRatio: 9 / 16,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: BrandColors.planning,
                                      ),
                                    ),
                                  ),
                                );
                              }
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
              ),

              // Hidden full-size card for high-res capture
              // 360x640 logical pixels @ 3x = 1080x1920 physical pixels
              // Positioned off-screen but still rendered
              Positioned(
                left: -10000,
                top: 0,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: SizedBox(
                    width: 360,
                    height: 640,
                    child: ShareCard(
                      title: memory.title,
                      location: memory.location,
                      eventDate: memory.eventDate,
                      peopleCount: _getUniquePeopleCount(memory.photos),
                      heroPhotoUrl: heroPhoto.coverUrl ?? heroPhoto.url,
                      thumbnailUrls: thumbnails,
                    ),
                  ),
                ),
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

  /// Generates PNG image from ShareCard widget
  Future<void> _generateShareImage(
      String heroUrl, List<String> thumbnails, List<String> photoIds) async {
    if (_isGeneratingImage) {
      return;
    }

    setState(() {
      _isGeneratingImage = true;
    });

    try {
      // Fast path: reuse a previously generated PNG (same memory + selection).
      final cacheFile = await _getShareCardCacheFile(photoIds);
      try {
        if (await cacheFile.exists()) {
          final cachedBytes = await cacheFile.readAsBytes();
          if (!mounted) return;
          setState(() {
            _cachedImageBytes = cachedBytes;
            _isGeneratingImage = false;
          });

          AnalyticsService.track('share_card_viewed', properties: {
            'memory_id': widget.memoryId,
          });
          return;
        }
      } catch (_) {
        // If cache read fails, fall back to regeneration.
      }

      final widgetContext = _repaintKey.currentContext;

      if (widgetContext == null) {
        if (mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
        return;
      }

      // Preload all images first to ensure they're cached
      final imageUrls = [heroUrl, ...thumbnails];

      await Future.wait(
        imageUrls.map((url) => precacheImage(NetworkImage(url), widgetContext)),
        eagerError: false,
      );

      // Wait for the next frame after images are loaded
      await WidgetsBinding.instance.endOfFrame;

      // Small delay to ensure render pipeline completes
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) {
        return;
      }

      final context = _repaintKey.currentContext;

      if (context == null) {
        if (mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
        return;
      }

      if (!mounted) return;
      if (!context.mounted) return;
      final renderObject = context.findRenderObject();
      final boundary = renderObject as RenderRepaintBoundary?;

      if (boundary == null) {
        if (!mounted) return;
        if (context.mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
        return;
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 500));

        if (boundary.debugNeedsPaint) {
          if (mounted) {
            setState(() {
              _isGeneratingImage = false;
            });
          }
          return;
        }
      }

      // Convert to image with pixelRatio 3.0 (standard for modern devices)
      // This ensures text and elements render at proper size for 1080x1920
      final image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      if (mounted) {
        setState(() {
          _cachedImageBytes = pngBytes;
          _isGeneratingImage = false;
        });
      }

      // Persist cache for future openings (best-effort).
      try {
        await cacheFile.writeAsBytes(pngBytes, flush: true);
      } catch (_) {
        // ignore cache write failures
      }

      // Track share card viewed when card image is generated and displayed.
      AnalyticsService.track('share_card_viewed', properties: {
        'memory_id': widget.memoryId,
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }

  int _getUniquePeopleCount(List photos) {
    final uploaders = photos.map((p) => p.uploaderId).toSet();
    return uploaders.length;
  }

  /// Returns a temporary file path for the share card PNG
  Future<String> _getShareCardTempPath() async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/lazzo_memory_${widget.memoryId}.png';
    final file = File(filePath);
    await file.writeAsBytes(_cachedImageBytes!);
    return filePath;
  }

  Future<File> _getShareCardCacheFile(List<String> photoIds) async {
    final dir = await getTemporaryDirectory();
    final safeIds = photoIds
        .join('_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final filePath =
        '${dir.path}/lazzo_share_card_${widget.memoryId}_$safeIds.png';
    return File(filePath);
  }

  void _handleInstagramShare(BuildContext context) async {
    if (_cachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, generating image...')),
      );
      return;
    }

    try {
      // Try opening Instagram Stories with the image
      // Instagram Stories deep link: instagram-stories://share
      // Requires the image to be shared via the native share sheet
      // On iOS, we can use the share sheet which shows Instagram Story option
      final filePath = await _getShareCardTempPath();

      // Try Instagram Stories URL scheme first
      final instagramUri = Uri.parse('instagram-stories://share');
      if (await canLaunchUrl(instagramUri)) {
        // Share via native share targeting Instagram
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath, mimeType: 'image/png')],
          ),
        );
      } else {
        // Fallback to native share sheet
        if (!context.mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath, mimeType: 'image/png')],
          ),
        );
      }

      AnalyticsService.track('share_card_shared', properties: {
        'memory_id': widget.memoryId,
        'share_channel': 'instagram_story',
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share to Instagram')),
      );
    }
  }

  void _handleWhatsAppShare(BuildContext context) async {
    if (_cachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, generating image...')),
      );
      return;
    }

    try {
      final filePath = await _getShareCardTempPath();

      // Try opening WhatsApp with the image
      final whatsappUri = Uri.parse('whatsapp://send');
      if (await canLaunchUrl(whatsappUri)) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath, mimeType: 'image/png')],
          ),
        );
      } else {
        // Fallback to native share sheet
        if (!context.mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath, mimeType: 'image/png')],
          ),
        );
      }

      AnalyticsService.track('share_card_shared', properties: {
        'memory_id': widget.memoryId,
        'share_channel': 'whatsapp',
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share to WhatsApp')),
      );
    }
  }

  void _handleSave(BuildContext context) async {
    if (_cachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, generating image...')),
      );
      return;
    }

    try {
      // Save to gallery using gal package
      final filePath = await _getShareCardTempPath();
      await Gal.putImage(filePath);

      AnalyticsService.track('share_card_saved', properties: {
        'memory_id': widget.memoryId,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to gallery')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save to gallery')),
      );
    }
  }

  void _handleMore(BuildContext context) async {
    if (_cachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, generating image...')),
      );
      return;
    }

    try {
      final filePath = await _getShareCardTempPath();

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'image/png')],
        ),
      );

      AnalyticsService.track('share_card_shared', properties: {
        'memory_id': widget.memoryId,
        'share_channel': 'native_share',
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share')),
      );
    }
  }
}

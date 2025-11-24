import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/cards/share_card.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../widgets/share_options_section.dart';
import '../widgets/edit_share_photos_sheet.dart';
import '../providers/memory_providers.dart';
import '../../domain/entities/memory_entity.dart';
import 'share_memory_preview_page.dart';

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
              _generateShareImage(heroUrl, thumbnails);
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
      String heroUrl, List<String> thumbnails) async {
    if (_isGeneratingImage) {
      return;
    }

    setState(() {
      _isGeneratingImage = true;
    });

    try {
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

      final renderObject = context.findRenderObject();
      final boundary = renderObject as RenderRepaintBoundary?;

      if (boundary == null) {
        if (mounted) {
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

  void _handleInstagramShare(BuildContext context) {
    if (_cachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, generating image...')),
      );
      return;
    }

    // TODO: Implement Instagram story share using _cachedImageBytes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instagram share coming soon')),
    );
  }

  void _handleWhatsAppShare(BuildContext context) {
    if (_cachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, generating image...')),
      );
      return;
    }

    // TODO: Implement WhatsApp share using _cachedImageBytes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp share coming soon')),
    );
  }

  void _handleSave(BuildContext context) {
    if (_cachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, generating image...')),
      );
      return;
    }

    // TODO: Implement save to gallery using _cachedImageBytes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save coming soon')),
    );
  }

  void _handleMore(BuildContext context) {
    if (_cachedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, generating image...')),
      );
      return;
    }

    // TODO: Implement native share sheet using _cachedImageBytes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('More options coming soon')),
    );
  }
}

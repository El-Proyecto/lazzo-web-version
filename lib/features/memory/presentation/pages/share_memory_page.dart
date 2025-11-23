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
import '../providers/memory_providers.dart';
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
                        padding: const EdgeInsets.all(Gaps.md),
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
                                return SizedBox(
                                  width: cardWidth,
                                  child: AspectRatio(
                                    aspectRatio: 9 / 16,
                                    child: Image.memory(
                                      _cachedImageBytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
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

              // Hidden full-size card for high-res capture (1080x1920)
              // Positioned off-screen but still rendered
              Positioned(
                left: -10000,
                top: 0,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: SizedBox(
                    width: 1080,
                    height: 1920,
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
    debugPrint('🔵 [ShareImage] Starting image generation...');
    debugPrint('🔵 [ShareImage] Hero URL: $heroUrl');
    debugPrint('🔵 [ShareImage] Thumbnails count: ${thumbnails.length}');

    if (_isGeneratingImage) {
      debugPrint('⚠️ [ShareImage] Already generating, skipping...');
      return;
    }

    setState(() {
      _isGeneratingImage = true;
    });
    debugPrint('✅ [ShareImage] Set _isGeneratingImage = true');

    try {
      // Get the context first
      debugPrint('🔍 [ShareImage] Getting context...');
      final widgetContext = _repaintKey.currentContext;
      debugPrint(
          '🔍 [ShareImage] Context: ${widgetContext != null ? 'Found' : 'NULL'}');

      if (widgetContext == null) {
        debugPrint('❌ [ShareImage] Context is null, aborting');
        if (mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
        return;
      }

      // Preload all images first to ensure they're cached
      debugPrint('🔄 [ShareImage] Starting image preload...');
      final imageUrls = [heroUrl, ...thumbnails];
      debugPrint(
          '🔄 [ShareImage] Total images to preload: ${imageUrls.length}');

      await Future.wait(
        imageUrls.map((url) {
          debugPrint('📥 [ShareImage] Preloading: $url');
          return precacheImage(NetworkImage(url), widgetContext);
        }),
        eagerError: false, // Continue even if some images fail
      );
      debugPrint('✅ [ShareImage] All images preloaded');

      // Wait for the next frame after images are loaded
      debugPrint('⏳ [ShareImage] Waiting for endOfFrame...');
      await WidgetsBinding.instance.endOfFrame;
      debugPrint('✅ [ShareImage] endOfFrame reached');

      // Small delay to ensure render pipeline completes
      debugPrint('⏳ [ShareImage] Waiting 100ms for render pipeline...');
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('✅ [ShareImage] Delay complete');

      if (!mounted) {
        debugPrint('❌ [ShareImage] Widget not mounted, aborting');
        return;
      }

      // Get the RenderObject
      debugPrint('🔍 [ShareImage] Getting RenderObject...');
      final context = _repaintKey.currentContext;
      debugPrint(
          '🔍 [ShareImage] Context: ${context != null ? 'Found' : 'NULL'}');

      if (context == null) {
        debugPrint('❌ [ShareImage] Context is null, aborting');
        if (mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
        return;
      }

      final renderObject = context.findRenderObject();
      debugPrint(
          '🔍 [ShareImage] RenderObject type: ${renderObject.runtimeType}');

      final boundary = renderObject as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ [ShareImage] Boundary is null, aborting');
        if (mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
        return;
      }

      debugPrint('✅ [ShareImage] Boundary found');
      debugPrint(
          '🔍 [ShareImage] Boundary.debugNeedsPaint: ${boundary.debugNeedsPaint}');
      debugPrint('🔍 [ShareImage] Boundary.attached: ${boundary.attached}');
      debugPrint(
          '🔍 [ShareImage] Boundary.owner: ${boundary.owner != null ? 'Has owner' : 'NULL'}');

      if (boundary.debugNeedsPaint) {
        debugPrint(
            '⚠️ [ShareImage] Boundary still needs paint! Waiting 500ms more...');
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint(
            '🔍 [ShareImage] After wait - debugNeedsPaint: ${boundary.debugNeedsPaint}');

        if (boundary.debugNeedsPaint) {
          debugPrint(
              '❌ [ShareImage] Boundary STILL needs paint after wait, aborting this attempt');
          if (mounted) {
            setState(() {
              _isGeneratingImage = false;
            });
          }
          return;
        }
      }

      // Convert to image with pixelRatio 1.0 for exact 1080x1920 dimensions
      debugPrint('🎨 [ShareImage] Converting to image (pixelRatio: 1.0)...');
      final image = await boundary.toImage(pixelRatio: 1.0);
      debugPrint(
          '✅ [ShareImage] Image created: ${image.width}x${image.height}');

      // Convert to PNG bytes
      debugPrint('💾 [ShareImage] Converting to PNG bytes...');
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ [ShareImage] ByteData is null, aborting');
        if (mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      debugPrint(
          '✅ [ShareImage] PNG bytes generated: ${pngBytes.length} bytes (${(pngBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');

      if (mounted) {
        setState(() {
          _cachedImageBytes = pngBytes;
          _isGeneratingImage = false;
        });
        debugPrint(
            '🎉 [ShareImage] SUCCESS! Image cached and ready to display');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ShareImage] ERROR: $e');
      debugPrint('📚 [ShareImage] StackTrace: $stackTrace');
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
